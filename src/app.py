import json
from base64 import b64encode
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

import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

load_dotenv()

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
) -> None:
    plants = _load_saved_plants()
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    species = results[0].get("species", {}) if results else {}
    common_names = species.get("commonNames", []) if isinstance(species, dict) else []
    confidence = results[0].get("score") if results else None

    existing = next((plant for plant in plants if plant.get("name") == best_match), None)
    if existing is None:
        plants.append(
            {
                "id": best_match,
                "name": best_match,
                "summary": summary,
                "common": common_names,
                "confidence": confidence,
                "created_at": now,
                "updated_at": now,
                "sent_images": [image_metadata],
                "thumbnail_base64": image_metadata["thumbnail_base64"],
            }
        )
    else:
        existing["summary"] = summary
        existing["common"] = common_names
        existing["confidence"] = confidence
        existing["updated_at"] = now
        existing["thumbnail_base64"] = image_metadata["thumbnail_base64"]
        sent_images = existing.setdefault("sent_images", [])
        sent_images.append(image_metadata)

    _save_saved_plants(plants)


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

    if not best_match:
        raise HTTPException(status_code=502, detail="Resposta do Pl@ntNet sem bestMatch")

    thumbnail_base64 = make_thumbnail_base64(image_bytes)

    plant_ref = db.collection("plants").document(best_match)
    doc = plant_ref.get()

    summary = None

    if not doc.exists:
        summary = summarize_plant(best_match) if best_match else None
        plant_ref.set({
            "name": best_match, 
            "created_at": firestore.SERVER_TIMESTAMP, 
            "summary": summary, 
            "common": results[0].get("species", {}).get("commonNames", []) if results else [],
            "confidence": results[0].get("score") if results else None,
            "sent_images": [image_metadata],
        })
    else:
        summary = doc.to_dict().get("summary")
        plant_ref.update(
            {
                "sent_images": firestore.ArrayUnion([image_metadata]),
                "updated_at": firestore.SERVER_TIMESTAMP,
            }
        )

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
    }


@app.get("/plants")
def list_saved_plants():
    docs = db.collection("plants").stream()

    plants: list[dict[str, Any]] = []
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
