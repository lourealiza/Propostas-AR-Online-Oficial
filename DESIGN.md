---
name: Gerador de Propostas AR Online
description: Sistema visual da proposta PDF AIDA — briefing comercial B2B com chrome de validade jurídica.
colors:
  azul-dossie: "#103b61"
  ciano-prova: "#2582c5"
  ambar-selo: "#fbba00"
  cinza-corpo: "#5f6b77"
  branco-folha: "#ffffff"
  borda-suave: "#e2e9f0"
  fundo-bloco: "#f3f7fb"
  faixa-cinza: "#b2b2b2"
  link: "#0073cf"
  link-hover: "#005a9e"
  form-azul: "#1f497d"
  form-azul-claro: "#2e5f9e"
  form-fundo: "#f2f5f9"
  form-borda: "#c9d4e2"
typography:
  display:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "34px"
    fontWeight: 700
    lineHeight: 1.15
  headline:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: "32px"
  title:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: "24px"
  body:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "21px"
  label:
    fontFamily: "Poppins, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: "16px"
    letterSpacing: "0.12em"
rounded:
  sm: "2px"
  md: "8px"
  lg: "12px"
  pill: "999px"
  full: "50%"
spacing:
  page-pad-y-top: "151px"
  page-pad-x: "113px"
  page-pad-y-bottom: "174px"
  gap-section: "28px"
  gap-strip: "6px"
  card-pad: "14px"
components:
  button-primary:
    backgroundColor: "{colors.form-azul}"
    textColor: "{colors.branco-folha}"
    rounded: "{rounded.md}"
    padding: "14px 34px"
  button-primary-hover:
    backgroundColor: "{colors.form-azul-claro}"
    textColor: "{colors.branco-folha}"
  button-secondary:
    backgroundColor: "#e3ebf5"
    textColor: "{colors.form-azul}"
    rounded: "{rounded.md}"
    padding: "8px 14px"
  card-proposta:
    backgroundColor: "{colors.branco-folha}"
    textColor: "{colors.azul-dossie}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-pad}"
  input-form:
    backgroundColor: "{colors.branco-folha}"
    textColor: "#262626"
    rounded: "{rounded.md}"
    padding: "8px 10px"
---

# Design System: Gerador de Propostas AR Online

## Overview

**Creative North Star: "O Briefing Comercial"**

A face da marca é a proposta PDF AIDA: um briefing de venda claro e denso para o decisor B2B ler e comparar a oferta. Hierarquia tipográfica forte, Poppins no miolo, azul institucional no texto, e um chrome de validade jurídica (logo AR + ABES + ICP-Brasil) que prova sem competir com o conteúdo. Não é revista, não é landing page — é proposta comercial de 12 páginas em folha A4 digital (794×1123).

O formulário do gerador (`index.html`) é superfície **utilitária separada**: Arial, azul `#1f497d`, cards brancos em fundo `#f2f5f9`. Serve o comercial a preencher e gerar PDF; não carrega a identidade visual da proposta. Trabalho futuro no formulário não deve “puxar” Poppins/`#103b61` sem decisão explícita de alinhar.

**Key Characteristics:**
- PDF = marca; formulário = ferramenta operacional
- Folha fixa 794×1123 com padding 151 / 113 / 174
- Poppins + Azul Dossiê no corpo; faixa de rodapé em quatro tons
- Plano por padrão — profundidade por borda e fundo suave, sem sombra
- Chrome com selos ABES/ICP no miolo; capa só com AR centralizado

## Colors

Paleta corporativa curta: um azul de autoridade, um ciano de prova, um âmbar de selo, e neutros de papel.

### Primary
- **Azul Dossiê** (`#103b61`): texto principal, títulos, círculos numerados, faixas de capa/rodapé. É a cor da voz institucional.

### Secondary
- **Ciano prova** (`#2582c5`): barra lateral de 4px, cápsulas do strip do cabeçalho, acentos de lista e passos. Marca “evento registrado / evidência”.

### Tertiary
- **Âmbar selo** (`#fbba00`): ponto do strip e segmento do rodapé. Raro — aparece no chrome, não no corpo corrido.

### Neutral
- **Branco folha** (`#ffffff`): fundo da página PDF.
- **Cinza corpo** (`#5f6b77`): texto secundário, rodapé tipográfico, labels muted.
- **Borda suave** (`#e2e9f0`): divisórias de tabela/card e pilulas inativas do strip.
- **Fundo bloco** (`#f3f7fb`): cards e callouts tonais sem sombra.
- **Faixa cinza** (`#b2b2b2`): último segmento da barra do rodapé.
- **Link** (`#0073cf` / hover `#005a9e`): âncoras no PDF.

Formulário (utilitário, não marca):
- **Form azul** (`#1f497d`), **Form azul claro** (`#2e5f9e`), **Form fundo** (`#f2f5f9`), **Form borda** (`#c9d4e2`).

**The Chrome Accent Rule.** Âmbar selo e Ciano prova vivem no chrome (barra, strip, rodapé) e em acentos pontuais. Não pintar blocos inteiros de âmbar.

**The One Voice Rule.** Azul Dossiê é a voz tipográfica do miolo. Não introduzir um segundo azul de texto no PDF.

## Typography

**Display Font:** Poppins (com system-ui, sans-serif)
**Body Font:** Poppins (com system-ui, sans-serif)
**Form Font:** Arial, Helvetica, sans-serif (somente formulário)

**Character:** Sem serifa, comercial e legível — pesos 600/700 para títulos, corpo 14–15px com entrelinha ~21px. Labels de seção usam tracking aberto e uppercase.

### Hierarchy
- **Display** (700, ~34px / até 68px na capa): títulos de abertura raros.
- **Headline** (700, 24px / 32px): `h2` de página.
- **Title** (600, 15–16px): subtítulos e rótulos de card forte.
- **Body** (400–600, 13–15px / 19–23px): texto corrido, listas, tabelas.
- **Label** (600, 11–12px, letter-spacing ~0.12em, uppercase quando for eyebrow): “Hoje”, “Impacto”, legendas de fieldset no form.

**The Poppins-on-PDF Rule.** Miolo da proposta sempre Poppins. Arial fica no formulário.

## Layout

Folha AIDA fixa: **794×1123** (A4 digital). Padding de conteúdo **151px (topo) / 113px (laterais) / 174px (base)** para reservar cabeçalho e rodapé absolutos. Gap vertical típico entre blocos: **28px**.

- Cabeçalho (`.hd`): `top: 48px`, laterais 113px — logo AR à esquerda; ABES + ICP à direita no miolo.
- Strip de cápsulas: sob o header à direita (`top: 110px`).
- Rodapé (`.ft`): `bottom: 56px` — faixa segmentada + URL/contato + `página / total`.
- Barra lateral: 4px `#2582c5` do topo ao fundo.
- Formulário: coluna única `max-width: 860px`; grid 2 colunas → 1 coluna abaixo de 640px.

**The Fixed Sheet Rule.** Novas páginas PDF herdam 794×1123 e o padding 151/113/174. Não “esticar” a folha nem inventar margem diferente sem atualizar o pipeline em `_fonte`.

## Elevation & Depth

**Plano por padrão.** Não há vocabulário de `box-shadow` no miolo. Profundidade vem de (1) borda `#e2e9f0`, (2) fundo tonal `#f3f7fb`, (3) contraste Azul Dossiê sobre branco, (4) a faixa de rodapé em quatro cores.

**The Flat-By-Default Rule.** Superfícies em repouso são planas. Não adicionar sombra a cards da proposta para “parecer moderno”.

## Shapes

- Cards e blocos de conteúdo: cantos **12px** (`rounded.lg`).
- Placeholders / campos leves: **8px**.
- Segmento do rodapé: **2px**.
- Cápsulas do strip: **999px** (pill) + ponto circular **50%**.
- Números de passo: círculo pleno **50%**.
- Formulário: fieldsets e botões em **6–8px**.

**The Soft Card Rule.** Card da proposta = borda suave + radius 12px (+ fundo `#f3f7fb` quando precisar destacar). Sem sombra, sem borda grossa.

## Components

Caráter geral: **claro e comercial** — tipografia forte, cards leves, chrome de prova.

### Buttons (formulário)
- **Shape:** radius 6px
- **Primary (Gerar PDF):** fundo Form azul, texto branco, padding 14×34, full width
- **Hover:** Form azul claro
- **Secondary:** fundo `#e3ebf5`, texto Form azul

### Cards / Containers (PDF)
- **Corner Style:** 12px
- **Background:** branco ou `#f3f7fb`
- **Border:** 1px `#e2e9f0` (ou 1px Azul Dossiê em card “Impacto”)
- **Shadow Strategy:** nenhuma — ver Elevation
- **Internal Padding:** ~12–16px

### Inputs / Fields (formulário)
- **Style:** borda Form borda, radius 6px, padding 8×10, fundo branco
- **Focus:** outline 2px Form azul claro

### Navigation / Chrome (PDF)
- **Header miolo:** logo AR 32px + ABES (~28px) + ICP (~30px) + strip cinza/ciano/âmbar
- **Header capa:** só logo AR ~72px centralizado (sem ABES/ICP)
- **Footer:** segmentos `#103b61` / `#2582c5` / `#fbba00` / `#b2b2b2` + contato + paginação

### Signature: Folha AIDA
Container `.folha` com barra lateral, CAB/ROD e miolo em coluna flex. Fonte canônica: scripts em `Projetos Lou\_fonte\` → `paginas.js` (não editar o JS à mão).

### Signature: Passo numerado
Círculo Azul Dossiê + título 14px/600 + texto muted 13px sobre fundo `#f3f7fb`.

## Do's and Don'ts

### Do:
- **Do** tratar o PDF como a superfície de marca e o formulário como ferramenta utilitária.
- **Do** reusar padding 151/113/174, Poppins e a tríade Azul Dossiê / Ciano prova / Âmbar selo em páginas novas.
- **Do** manter ABES + ICP no chrome do miolo e AR sozinho na capa.
- **Do** alterar visual do miolo via scripts em `_fonte`, não editando `paginas.js` direto.
- **Do** preferir borda + `#f3f7fb` a sombra.

### Don't:
- **Don't** misturar Arial no miolo PDF nem Poppins no formulário sem decisão de alinhar as superfícies.
- **Don't** inventar depoimentos, logos de cliente ou preços não confirmados só para “preencher o layout”.
- **Don't** colocar ABES/ICP na capa nem remover o strip/rodapé do miolo.
- **Don't** adicionar box-shadow genérico ou gradientes decorativos à proposta.
- **Don't** publicar o visual no OneDrive do setor sem ok da Lou.
