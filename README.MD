# Naturalist

API de reconhecimento de plantas usando, momentaneamente, a API do Pl@ntNet. O notebook de treino deixa de ser a fonte principal do fluxo por enquanto.

## Visão geral

O projeto recebe uma imagem e encaminha a consulta para a API do Pl@ntNet para retornar as espécies mais prováveis. A base local com notebook treinado fica como referência histórica e pode voltar em uma etapa futura.

### Stack

- FastAPI + Uvicorn
- Integração com API externa do Pl@ntNet
- Pillow para leitura de imagem
- Suporte a variáveis de ambiente via `.env`

## Estrutura do projeto

```text
Naturalist/
├── README.MD
├── requirements.txt
├── data/
│   ├── labels.npy
│   └── plants.index
├── notebooks/
│   └── plant_recognition_clip_faiss.ipynb
└── src/
    └── app.py
```

## Requisitos

- Python 3.10+
- Pip
- Arquivo `.env` para configuração local

## Instalação

1. Criar e ativar ambiente virtual:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

2. Instalar dependências:

```bash
pip install -r requirements.txt
```

3. Criar o arquivo `.env` na raiz do projeto com as configurações necessárias. Exemplo:

```env
PLANTNET_API_KEY=sua-chave-aqui
PLANTNET_API_URL=https://my-api.plantnet.org/v2/identify/all
CLIP_MODEL_NAME=openai/clip-vit-base-patch32
FAISS_INDEX_PATH=./data/plants.index
LABELS_PATH=./data/labels.npy
```

## Como executar

Inicie a API em modo de desenvolvimento:

```bash
python3 -m uvicorn src.app:app --reload
```

Servidor disponível em:

- API: http://127.0.0.1:8000
- Docs Swagger: http://127.0.0.1:8000/docs

## Endpoint

### POST /predict

Recebe uma imagem via multipart/form-data e retorna as 5 espécies mais similares.

#### Exemplo com curl

```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/caminho/para/imagem.jpg"
```

#### Resposta esperada

```json
{
  "predictions": [
    {
      "species": "Monstera deliciosa",
      "confidence": 0.8732
    },
    {
      "species": "Philodendron bipinnatifidum",
      "confidence": 0.8421
    }
  ]
}
```

## Observações importantes

- O fluxo principal passa a depender da API do Pl@ntNet enquanto o modelo treinado no notebook fica em espera.
- Se quiser alterar caminhos locais ou credenciais, use o arquivo `.env`.
- O projeto usa GPU automaticamente quando CUDA está disponível; caso contrário, roda em CPU.

## Desenvolvimento

- Código principal da API: src/app.py
- Notebook de experimentação: notebooks/plant_recognition_clip_faiss.ipynb
- Configuração local: `.env`

## Próximos passos sugeridos

- Implementar a integração efetiva com o endpoint do Pl@ntNet.
- Incluir testes automatizados para o endpoint /predict.
- Revisitar o pipeline local de modelo treinado quando o fluxo com Pl@ntNet sair do modo temporário.