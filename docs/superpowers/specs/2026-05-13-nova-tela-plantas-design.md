# Design Spec: UI premium para scanner + tela de plantas

## Objetivo
Atualizar o app iOS do Naturalist para um visual mais moderno, com aparência de app atual, e adicionar uma nova tela que consome `GET /plants` para exibir todas as plantas já buscadas com foto, nome comum e resumo.

## Direção aprovada
Seguir a opção **A / feed premium**:
- Visual mais limpo, com cards grandes, cantos arredondados e sombras suaves.
- Hierarquia clara: ação principal no scanner, lista rica na tela de plantas.
- Mesma linguagem visual nas duas telas para parecer um produto único.

## Escopo
- Refinar a tela principal de scanner.
- Adicionar a tela **Plantas salvas**.
- Conectar a nova tela ao endpoint `GET /plants`.
- Exibir a última foto enviada de cada planta, o nome comum e o resumo.
- Manter o app em PT-BR.

## Arquitetura visual
### Navegação
Usar `TabView` com duas abas:
1. **Scanner**
2. **Plantas**

Isso deixa a nova tela descoberta sem esconder o fluxo principal de captura.

### Tela Scanner
- Hero com título, subtítulo e CTA principal.
- Botões de câmera e galeria em estilo moderno.
- Card de resultado com:
  - nome da melhor correspondência
  - resumo formatado
  - status vazio/carregando/erro

### Tela Plantas
- Cabeçalho com título + contagem de itens.
- Lista em cards verticais com:
  - thumbnail da última imagem salva
  - nome comum em destaque
  - nome científico menor
  - resumo curto
  - chip de confiança quando existir
- Estado vazio amigável se não houver plantas salvas.
- Pull-to-refresh para recarregar o endpoint.

## Requisitos de dados
O endpoint `GET /plants` precisa fornecer a imagem de cada planta em formato utilizável pela UI.

### Contrato esperado
- `id`
- `name`
- `summary`
- `common`
- `confidence`
- `sent_images`
- `thumbnail_url` ou `thumbnail_base64` para a última imagem enviada

Se o backend ainda não expuser essa imagem, a implementação da tela deve ajustar o payload para devolver a última foto salva junto do registro.

## Componentes
- `PlantScannerView`
- `PlantGalleryView`
- `PlantCardView`
- `PlantSummaryCard`
- `EmptyStateView`
- `LoadingStateView`

## Sistema visual
- Fundo claro com verde suave.
- Cards brancos com borda sutil e sombra discreta.
- Radius alto para aparência mais contemporânea.
- Tipografia com hierarquia forte: título > nome comum > detalhes > resumo.
- Uso de chips para confiança e metadados.

## Acessibilidade
- Contraste mínimo de 4.5:1 para textos.
- Alvos de toque com pelo menos 44x44 px.
- Labels acessíveis nos botões de câmera, galeria, atualizar e navegação.
- Conteúdo textual legível com Dynamic Type.
- Estados de carregamento e erro com mensagens explícitas.

## Responsividade
- Layout deve funcionar em iPhone compacto e Pro Max.
- Lista de plantas em coluna única.
- Cards com imagem fixa e texto fluido.
- Sem necessidade de rolagem horizontal.

## Estados
### Scanner
- vazio
- carregando
- sucesso
- erro

### Plantas
- carregando
- vazio
- carregado
- erro

## Implementação prevista
- Reestruturar a tela atual para um shell mais moderno.
- Criar a aba de plantas com fetch no `onAppear`.
- Adicionar modelo de dados para a resposta de `/plants`.
- Normalizar thumbnail da última imagem enviada para renderização no SwiftUI.

## Critérios de sucesso
- O app parece um app moderno atual, não uma tela utilitária.
- O usuário consegue alternar entre scanner e plantas salvas.
- A nova tela mostra foto, nome comum e resumo corretamente.
- A navegação e os cartões continuam claros e acessíveis.

