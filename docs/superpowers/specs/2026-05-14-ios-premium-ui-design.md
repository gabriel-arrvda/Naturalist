# Design Spec: UI premium para Scanner e Plantas

## Objetivo
Deixar o app iOS do Naturalist com aparência de produto real e elegante, mantendo a linguagem visual consistente entre Scanner e Plantas.

## Direção aprovada
Seguir o estilo **editorial premium**:
- Hierarquia forte com títulos grandes e subtítulos curtos.
- Cards mais altos, com bordas suaves, sombra discreta e bastante respiro.
- Imagens em destaque como elemento principal do layout.
- Interface limpa, sofisticada e nativa, sem excesso de brilho ou decoração.

## Escopo
- Refinar a tela **Scanner**.
- Refinar a tela **Plantas**.
- Manter o fluxo atual de dados e navegação.
- Preservar PT-BR e acessibilidade.

## Arquitetura visual

### Scanner
- Hero mais editorial, com título forte e texto de apoio menor.
- Prévia da imagem com sensação de painel principal.
- Botões de câmera e galeria com presença visual mais refinada.
- Resultado em cartão destacado, com imagem, nome e resumo bem separados.

### Plantas
- Cabeçalho com título forte e descrição curta.
- Lista de cards com thumbnail maior e mais espaço vertical.
- Metadados em chips discretos.
- Banner de confirmação mais polido quando uma planta é salva.
- Tela de detalhe com imagem grande e leitura confortável.

## Sistema visual
- Fundo em tons verdes muito suaves ou neutros claros.
- Cards brancos com borda sutil e sombra leve.
- Radius alto para um aspecto contemporâneo.
- Tipografia com hierarquia clara: título > nome > metadados > resumo.
- Cores sempre puxadas do `Theme` existente.

## Componentes afetados
- `PlantScannerView`
- `PlantGalleryView`
- `PlantCardView`
- `SavedAnalysisModalView`
- `PlantDetailModalView`

## Acessibilidade
- Contraste mínimo de 4.5:1 para textos.
- Alvos de toque de pelo menos 44x44 px.
- Semântica nativa do SwiftUI preservada.
- Estados de carregamento e erro com texto explícito.

## Responsividade
- Layout de coluna única para iPhone compacto até Pro Max.
- Cards com largura fluida e imagem adaptável.
- Sem scroll horizontal.

## Critério de sucesso
- O app parece um app iOS real e premium.
- Scanner e Plantas compartilham a mesma linguagem visual.
- A leitura continua clara e confortável em qualquer tamanho de tela.

