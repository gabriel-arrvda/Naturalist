from io import BytesIO
import logging
import os
import time
from typing import Optional

import requests
import google.generativeai as genai
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

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
    summary = summarize_plant(best_match) if best_match else None

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