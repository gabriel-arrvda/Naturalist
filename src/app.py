import json
from base64 import b64encode, b64decode
from io import BytesIO
from datetime import datetime, timezone
import logging
import os
from pathlib import Path
import time
from typing import Any, Optional

import requests
import google.generativeai as genai
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

try:
    import firebase_admin
    from firebase_admin import credentials, firestore, storage
except Exception:  # pragma: no cover - dependency is optional for local runs
    firebase_admin = None
    credentials = None
    firestore = None
    storage = None

db = None
PROJECT_ROOT = Path(__file__).resolve().parent.parent

load_dotenv(PROJECT_ROOT / ".env")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("naturalist")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = os.getenv("PLANTNET_API_KEY")
PROJECT = os.getenv("PLANTNET_PROJECT", "all")
API_BASE_URL = os.getenv(
    "PLANTNET_API_URL",
    f"https://my-api.plantnet.org/v2/identify/{PROJECT}",
)
API_ENDPOINT = f"{API_BASE_URL}?api-key={API_KEY}"
API_QUERY_PARAMS = {
    "include-related-images": "true",
    "no-reject": "false",
    "nb-results": "3",
    "lang": "pt-br",
    "detailed": "true",
}

LLM_API_KEY = os.getenv("LLM_API_KEY")
LLM_MODEL = os.getenv("LLM_MODEL", "gemini-1.5-flash")
LLM_CLIENT = None
PLANTS_STORE_PATH = Path(os.getenv("PLANTS_STORE_PATH", "data/plants.json"))


def _resolve_firestore_credentials() -> Optional[Any]:
    raw_json = os.getenv("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    if raw_json:
        try:
            payload = json.loads(raw_json)
        except json.JSONDecodeError:
            logger.warning("GOOGLE_APPLICATION_CREDENTIALS_JSON não contém JSON válido")
        else:
            if isinstance(payload, dict):
                private_key = payload.get("private_key")
                if isinstance(private_key, str) and "\\n" in private_key:
                    payload = dict(payload)
                    payload["private_key"] = private_key.replace("\\n", "\n")
                required_keys = {"type", "project_id", "private_key_id", "private_key", "client_email", "client_id", "token_uri"}
                if required_keys.issubset(payload.keys()):
                    try:
                        return credentials.Certificate(payload)
                    except Exception:
                        logger.exception(
                            "GOOGLE_APPLICATION_CREDENTIALS_JSON não gerou uma credencial válida"
                        )
                else:
                    logger.warning("GOOGLE_APPLICATION_CREDENTIALS_JSON não tem os campos esperados")
            else:
                logger.warning("GOOGLE_APPLICATION_CREDENTIALS_JSON precisa ser um objeto JSON")

    return None


def _get_firestore_db():
    global db
    if db is not None:
        return db

    if firebase_admin is None or credentials is None or firestore is None:
        logger.warning("firebase-admin indisponível; persistência remota desativada")
        return None

    try:
        if not firebase_admin._apps:
            cred_source = _resolve_firestore_credentials()
            if cred_source is None:
                logger.warning(
                    "Credenciais do Firebase ausentes; configure GOOGLE_APPLICATION_CREDENTIALS_JSON, "
                    "GOOGLE_APPLICATION_CREDENTIALS ou serviceAccountKey.json"
                )
                return None

            cred = cred_source
            storage_bucket = os.getenv("FIREBASE_STORAGE_BUCKET")
            # sanitize bucket value in case user provided a gs:// URL
            if storage_bucket:
                storage_bucket = storage_bucket.strip()
                if storage_bucket.startswith("gs://"):
                    storage_bucket = storage_bucket[5:]
                storage_bucket = storage_bucket.rstrip("/")

            if storage_bucket:
                firebase_admin.initialize_app(cred, {"storageBucket": storage_bucket})
                logger.info("Inicializando Firebase com bucket %s", storage_bucket)
            else:
                firebase_admin.initialize_app(cred)
                logger.info("Inicializando Firebase sem bucket de storage configurado")
        db = firestore.client()
        return db
    except Exception:
        logger.exception("Falha ao inicializar Firestore; persistência remota desativada")
        return None


def _get_gemini_client() -> genai.GenerativeModel:
    global LLM_CLIENT
    if LLM_CLIENT is None:
        genai.configure(api_key=LLM_API_KEY)
        LLM_CLIENT = genai.GenerativeModel(LLM_MODEL)
    return LLM_CLIENT


def summarize_plant(species_name: str) -> Optional[str]:
    if not LLM_API_KEY:
        logger.warning("LLM_API_KEY ausente; resumo desativado")
        return None

    prompt = (
        "Resuma a planta usando seus nomes populares: "
        f"{species_name}. Foque em usos comuns e cuidados basicos (luz, rega, solo), "
        "com recomendacoes praticas. Inclua alertas de toxicidade se conhecido. Não use uma linguagem excessivamente técnica, mas seja informativo e direto. Limite a resposta a 350 tokens mas faça um resumo completo e útil para um entusiasta de jardinagem ou botânica amadora." \
        "extremamente importante nao deixar o cuidados basicos de fora, resuma ao máximo mas não deixe de incluir as informações essenciais sobre luz, rega e solo, mesmo que isso signifique sacrificar detalhes menos importantes. O foco deve ser fornecer um guia prático e acessível para o cuidado da planta, especialmente para aqueles que podem não ter experiência prévia com jardinagem." \
    )

    max_attempts = 3
    backoff_seconds = 1.5

    for attempt in range(1, max_attempts + 1):
        try:
            client = _get_gemini_client()
            response = client.generate_content(
                prompt,
                generation_config={"temperature": 0.2, "max_output_tokens": 550},
            )
            text = getattr(response, "text", None)
            if text:
                return text
            logger.warning("Gemini sem texto na resposta")
            return None
        except Exception:
            _log_request_exception("erro na requisicao ao Gemini")
            if attempt < max_attempts:
                time.sleep(backoff_seconds * attempt)
                continue
            return None

    return None


def _log_request_exception(message: str) -> None:
    logger.exception("%s", message)


def make_thumbnail_base64(image_bytes: bytes, max_size: tuple[int, int] = (512, 512)) -> str:
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    image.thumbnail(max_size)

    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=82, optimize=True)
    return b64encode(buffer.getvalue()).decode("utf-8")


def _load_saved_plants() -> list[dict[str, Any]]:
    if not PLANTS_STORE_PATH.exists():
        return []

    raw = PLANTS_STORE_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return []

    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=500, detail="Arquivo local de plantas está inválido") from exc

    if not isinstance(payload, list):
        raise HTTPException(status_code=500, detail="Arquivo local de plantas está corrompido")

    return payload


def _save_saved_plants(plants: list[dict[str, Any]]) -> None:
    PLANTS_STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = PLANTS_STORE_PATH.with_suffix(".tmp")
    tmp_path.write_text(json.dumps(plants, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp_path.replace(PLANTS_STORE_PATH)


def _upsert_saved_plant(
    *,
    best_match: str,
    summary: Optional[str],
    results: list[dict[str, Any]],
    image_metadata: dict[str, Any],
    image_bytes: bytes,
    thumbnail_bytes: bytes,
) -> None:
    """
    Persist plant record exclusively to Firestore and Storage. Raises Exception if Firestore/Storage not configured or on write errors.
    """
    firestore_db = _get_firestore_db()
    if firestore_db is None:
        raise RuntimeError("Firestore não está configurado. Configure o Firebase para persistência remota.")

    # Prepare basic fields
    species = results[0].get("species", {}) if results else {}
    common_names = species.get("commonNames", []) if isinstance(species, dict) else []
    confidence = results[0].get("score") if results else None

    # Upload images to Firebase Storage (expects firebase_admin.storage initialized)
    image_url = None
    thumbnail_url = None
    try:
        from firebase_admin import storage as fb_storage

        bucket = fb_storage.bucket(app=firebase_admin.get_app())
        filename = image_metadata.get("filename") or f"{int(time.time())}.jpg"
        safe_name = f"{best_match}/{int(time.time())}_{filename}"

        blob = bucket.blob(safe_name)
        blob.upload_from_string(image_bytes, content_type=image_metadata.get("content_type", "image/jpeg"))
        try:
            blob.make_public()
            image_url = blob.public_url
        except Exception:
            image_url = None

        thumb_name = safe_name + "_thumb.jpg"
        thumb_blob = bucket.blob(thumb_name)
        thumb_blob.upload_from_string(thumbnail_bytes, content_type="image/jpeg")
        try:
            thumb_blob.make_public()
            thumbnail_url = thumb_blob.public_url
        except Exception:
            thumbnail_url = None
    except Exception as e:
        logger.exception("Falha ao enviar imagens para Storage: %s", e)
        # Fail fast: raise so caller knows persistence failed
        raise

    # Build sent entry with only primitives
    sent_entry = {
        "filename": image_metadata.get("filename"),
        "content_type": image_metadata.get("content_type"),
        "size_bytes": int(image_metadata.get("size_bytes") or 0),
        "captured_at": image_metadata.get("captured_at"),
        "image_url": image_url,
        "thumbnail_url": thumbnail_url,
    }

    plant_ref = firestore_db.collection("plants").document(best_match)
    doc = plant_ref.get()

    if not doc.exists:
        plant_ref.set(
            {
                "name": best_match,
                "created_at": firestore.SERVER_TIMESTAMP,
                "summary": summary,
                "common": [str(n) for n in common_names],
                "confidence": float(confidence) if confidence is not None else None,
                "sent_images": [sent_entry],
                "image_url": image_url,
                "thumbnail_url": thumbnail_url,
            }
        )
    else:
        plant_ref.update(
            {
                "sent_images": firestore.ArrayUnion([sent_entry]),
                "image_url": image_url,
                "thumbnail_url": thumbnail_url,
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if not API_KEY:
        raise HTTPException(status_code=500, detail="PLANTNET_API_KEY não configurada")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Arquivo de imagem vazio")

    payload = [
        ("organs", "flower"),
        ("organs", "leaf"),
    ]
    files = [
        (
            "images",
            (
                f"flor_{file.filename or 'image.jpg'}",
                BytesIO(image_bytes),
                file.content_type or "application/octet-stream",
            ),
        ),
        (
            "images",
            (
                f"folha_{file.filename or 'image.jpg'}",
                BytesIO(image_bytes),
                file.content_type or "application/octet-stream",
            ),
        ),
    ]

    response = requests.post(
        API_ENDPOINT,
        params=API_QUERY_PARAMS,
        data=payload,
        files=files,
        timeout=60,
    )

    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)

    response_data = response.json()
    results = response_data.get("results", [])
    best_match = response_data.get("bestMatch")

    thumbnail_base64 = make_thumbnail_base64(image_bytes)
    summary = summarize_plant(best_match) if best_match else None

    # Require Firestore configured (we no longer persist locally)
    firestore_db = _get_firestore_db()
    if firestore_db is None:
        raise HTTPException(status_code=500, detail="Firestore não configurado. Configure o Firebase para persistência remota.")

    image_metadata = {
        "filename": file.filename,
        "content_type": file.content_type,
        "size_bytes": len(image_bytes),
        "captured_at": datetime.now(timezone.utc).isoformat(),
    }

    # Prepare bytes for upload
    thumbnail_bytes = b64decode(thumbnail_base64)

    try:
        _upsert_saved_plant(
            best_match=best_match,
            summary=summary,
            results=results,
            image_metadata=image_metadata,
            image_bytes=image_bytes,
            thumbnail_bytes=thumbnail_bytes,
        )
        firestore_warning = None
    except Exception as e:
        logger.exception("Erro ao persistir em Firestore/Storage: %s", e)
        raise HTTPException(status_code=500, detail=f"Falha ao persistir em Firestore/Storage: {e}")


    return {
        "melhor_correspondencia": best_match,
        "órgãos_previstos": response_data.get("predictedOrgans", []),
        "resumo_planta": summary,
        "resultados": [
            {
                "espécie": item.get("species", {}).get("scientificName"),
                "nome_científico_sem_autor": item.get("species", {}).get(
                    "scientificNameWithoutAuthor"
                ),
                "nomes_comuns": item.get("species", {}).get("commonNames", []),
                "confiança": item.get("score"),
            }
            for item in results
        ],
        "firestore_warning": firestore_warning,
    }


@app.get("/plants")
def list_saved_plants():
    firestore_db = _get_firestore_db()
    if firestore_db is None:
        raise HTTPException(status_code=500, detail="Firestore não configurado. Configure o Firebase para usar este endpoint.")

    plants: list[dict[str, Any]] = []
    docs = firestore_db.collection("plants").stream()

    for doc in docs:
        data = doc.to_dict() or {}
        plants.append(
            {
                "id": doc.id,
                "name": data.get("name"),
                "summary": data.get("summary"),
                "common": data.get("common", []),
                "confidence": data.get("confidence"),
                "created_at": str(data.get("created_at")) if data.get("created_at") else None,
                "updated_at": str(data.get("updated_at")) if data.get("updated_at") else None,
                "sent_images": data.get("sent_images", []),
            }
        )

    return {"total": len(plants), "plants": plants}


# Fluxo antigo preservado para a futura volta do FAISS/modelo próprio.
#
# def generate_embeddings(images):
#     inputs = processor(images=images, return_tensors="pt", padding=True)
#     pixel_values = inputs["pixel_values"].to(DEVICE)
#
#     with torch.no_grad():
#         outputs = model.get_image_features(pixel_values=pixel_values)
#
#     if isinstance(outputs, torch.Tensor):
#         feats = outputs
#     elif hasattr(outputs, "image_embeds"):
#         feats = outputs.image_embeds
#     elif hasattr(outputs, "pooler_output"):
#         feats = outputs.pooler_output
#     else:
#         raise ValueError("Erro no output do modelo")
#
#     return feats.detach().cpu().numpy()
#
# @app.post("/predict")
# async def predict(file: UploadFile = File(...)):
#     image_bytes = await file.read()
#     img = Image.open(BytesIO(image_bytes)).convert("RGB")
#
#     emb = generate_embeddings([img])
#     faiss.normalize_L2(emb)
#
#     D, I = index.search(emb, 5)
#
#     results = [
#         {"species": labels[idx], "confidence": float(score)}
#         for idx, score in zip(I[0], D[0])
#     ]
#
#     return {"predictions": results}
