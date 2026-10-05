# Design system do ICEIBank

Referência visual: protótipo "Bento glass grid" feito na Lovable (repositório `iceibank-pink-glow`). Este documento descreve os tokens e componentes usados no frontend Vue. A fonte da verdade no código é `src/styles/tokens.css`.

## Princípios

- Preto profundo com um único acento rosa. O rosa aparece em ações principais, foco, valores positivos e brilhos. Nunca como cor de fundo de áreas grandes.
- Superfícies de vidro: cartões translúcidos com borda de 1px e blur, sobre um fundo escuro com brilho (glow) rosa.
- Hierarquia por tipografia e espaço, não por caixas coloridas.
- Movimento discreto: transições curtas, brilhos que se movem devagar, e tudo respeita `prefers-reduced-motion`.
- Tema escuro é o padrão. O tema claro usa as mesmas variáveis semânticas.

## Cores

Todas as cores são variáveis CSS semânticas. Os componentes nunca usam valores fixos.

| Token | Escuro | Claro | Uso |
|---|---|---|---|
| `--background` | oklch(0.145 0.006 340) | oklch(0.985 0.003 340) | Fundo da página |
| `--foreground` | oklch(0.96 0.005 350) | oklch(0.17 0.01 340) | Texto principal |
| `--card` | branco 4% | branco | Superfície de cartão |
| `--muted-foreground` | oklch(0.68 0.015 350) | oklch(0.5 0.02 345) | Texto secundário |
| `--primary` | oklch(0.65 0.25 352) | oklch(0.62 0.25 352) | Acento, ações principais |
| `--primary-foreground` | oklch(0.99 0.002 350) | igual | Texto sobre o acento |
| `--secondary` | branco 6% | oklch(0.95 0.008 350) | Botões secundários, campos |
| `--accent` | oklch(0.3 0.06 352) | oklch(0.94 0.02 352) | Hover de itens |
| `--border` | branco 10% | oklch(0.92 0.008 350) | Bordas e divisórias |
| `--input` | branco 15% | oklch(0.92 0.008 350) | Borda de campos |
| `--destructive` | oklch(0.704 0.191 22) | oklch(0.577 0.245 27) | Erros e saídas |
| `--ink` | oklch(0.16 0.008 340) | igual | Blocos sempre escuros |

## Tipografia

| Papel | Fonte | Uso |
|---|---|---|
| Display | Space Grotesk | Títulos, valores monetários, logotipo |
| Corpo | Inter | Texto corrido, rótulos, botões |
| Mono | JetBrains Mono | IDs de conta, números de cartão, carimbos de Lamport |

As fontes são instaladas via `@fontsource-variable`, sem depender de CDN, porque o laboratório pode estar sem internet.

Escala: rótulos em caixa alta usam 11px a 12px com `letter-spacing` de 0.15em. Títulos de seção usam 24px a 32px com `letter-spacing` negativo leve. O título principal da home usa 56px a 64px.

## Forma e espaço

- Raio base 10px. Cartões usam 20px a 24px. Botões principais são pílulas (9999px).
- Espaçamento em múltiplos de 4px. Largura máxima de conteúdo 1280px com 24px de margem lateral.
- Cartões usam borda de 1px (`--border`) em vez de sombra pesada.

## Componentes

- **Botão primário (`.btn-primary`):** pílula rosa com brilho (`box-shadow` rosa difuso) que sobe 2px ao passar o mouse.
- **Botão secundário (`.btn-secondary`):** fundo `--secondary`, borda `--border`.
- **Botão fantasma (`.btn-ghost`):** só texto e borda, para ações terciárias.
- **Cartão (`.surface`):** fundo `--card`, borda, raio 24px, blur de fundo.
- **Tile (`.tile`):** cartão da grade bento que sobe 3px no hover.
- **Campo (`.field`):** rótulo em caixa alta pequena, entrada com borda `--input` e foco rosa.
- **Chip (`.chip`):** pílula pequena com ponto colorido, usada para status de agência e tipos de operação.
- **Cartão metal (`MetalCard`):** cartão 3D que inclina conforme o mouse, com brilho que acompanha o cursor e verso ao clicar.

## Efeitos de fundo

- **Glow mesh:** três gradientes radiais rosa sobrepostos. No `AmbientBackground` eles se movem devagar (deriva de 18s a 30s).
- **Grade pontilhada:** padrão de pontos de 1px com máscara radial, no fundo da home.
- **Ruído:** camada de ruído sutil para quebrar degradês.

## Movimento

- Transições de 150ms a 350ms com `ease`.
- Entrada de seções com fade e deslocamento de 12px.
- Com `prefers-reduced-motion: reduce`, brilhos ficam estáticos e o cartão 3D não inclina.

## Responsividade

- Mobile first: a base é uma coluna e os breakpoints sobem a partir de 768px (grade de 3 colunas) e 1024px (layout de 2 colunas no painel e na home).
- Itens de grid e flex que contêm texto longo ou selects usam `min-width: 0`, para que a coluna possa encolher em vez de estourar a largura da tela.
- O cartão metal é fluido: usa container queries (`cqi`) para escalar fontes, espaçamentos e raio conforme a largura do cartão, sem breakpoints próprios.
- Cartões usam padding fluido (`clamp(18px, 5vw, 28px)`). Em telas até 420px as abas do painel escondem os ícones.
- Tabelas ficam dentro de um contêiner com rolagem horizontal própria, nunca na página.
- Links de âncora passam pelo roteador, que rola uma única vez com deslocamento de 72px para não ficar sob o cabeçalho fixo.
- Verificado de 320px a 1024px sem rolagem horizontal em todas as telas.

## Acessibilidade

- Contraste mínimo AA para texto sobre `--background` e `--card`.
- Foco visível com anel rosa em todo elemento interativo.
- Valores de erro e sucesso usam texto além da cor.
