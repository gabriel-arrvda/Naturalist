# Design Spec: App iOS 18 para identificação de plantas

## Objetivo
Criar um app em Swift (iOS 18+) que capture foto de planta (câmera) ou selecione da galeria, envie para a API local (`POST /predict`) e exiba o resultado formatado para o usuário com interface elegante em PT-BR, usando verde como cor principal.

## Escopo aprovado
- Plataforma: iOS 18+
- Stack: SwiftUI + MVVM + URLSession
- API inicial: local (`http://127.0.0.1:8000/predict`)
- Fluxo principal: câmera + galeria
- Resultado padrão: melhor correspondência + resumo da planta
- Idioma: PT-BR

## Arquitetura
### Camadas
1. `PlantScannerView`
   - Interface principal
   - Ações de captura/seleção de imagem
   - Renderização de estados (`idle`, `loading`, `success`, `error`)
2. `PlantScannerViewModel`
   - Coordena envio da imagem
   - Mantém estado observável da tela
   - Converte respostas e erros para mensagens amigáveis
3. `PlantAPIClient`
   - Constrói `multipart/form-data`
   - Executa `POST /predict` via `URLSession`
   - Decodifica payload JSON da API
4. Modelos (`PlantResponse` e relacionados)
   - Mapeiam `melhor_correspondencia`, `resumo_planta`, `órgãos_previstos`, `resultados`

## Fluxo de dados
1. Usuário toca em **Fotografar planta** ou **Escolher da galeria**.
2. App valida se há imagem selecionada.
3. ViewModel envia imagem para `PlantAPIClient`.
4. Cliente chama a API `/predict`.
5. Resposta JSON é decodificada para `PlantResponse`.
6. View renderiza:
   - Nome da melhor correspondência
   - Resumo formatado e legível

## Interface e experiência
### Direção visual
- Cor primária: verde folha
- Cores de suporte: verde escuro + neutros claros
- Cartões arredondados, sombra suave, tipografia limpa
- Hierarquia visual clara para ação principal e resultado

### Telas/estados
1. **Tela inicial**
   - CTA principal: `Fotografar planta`
   - CTA secundária: `Escolher da galeria`
2. **Análise**
   - Indicador de carregamento com texto claro
3. **Resultado**
   - Card com nome da planta (`melhor_correspondencia`)
   - Bloco de resumo (`resumo_planta`) com boa legibilidade
4. **Erro**
   - Mensagem em PT-BR com ação de retry

## Rede e tratamento de erros
- Erros tratados explicitamente:
  - Sem imagem selecionada
  - Timeout/falha de conexão
  - API indisponível
  - Payload inválido
- Cada erro mapeado para mensagem clara e acionável no app.

## Qualidade e testes
- Testes de parsing de `PlantResponse`.
- Testes de ViewModel com `PlantAPIClient` mockado:
  - sucesso
  - falha de rede
  - payload inválido
  - ausência de imagem

## Fora de escopo (YAGNI)
- Exibir ranking completo de espécies por padrão.
- Persistência local de histórico.
- Sincronização em nuvem.

## Critérios de sucesso
- Usuário consegue capturar ou selecionar imagem e obter resposta da API local.
- Resultado exibe melhor correspondência e resumo em PT-BR.
- Interface mantém identidade visual em verde com boa legibilidade.
- Erros são compreensíveis e recuperáveis.
