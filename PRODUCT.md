# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Comercial AR Online (vendedores e consultores). No dia a dia, preenchem a proposta no navegador e enviam o PDF ao cliente B2B. Não é ferramenta do cliente final.

## Product Purpose

Gerar a proposta comercial AR Online já preenchida, só em PDF (modelo visual de 12 páginas), a partir de um formulário no navegador — sem Word na entrega.

Sucesso confirmado:
- proposta PDF correta e enviável no mesmo dia;
- layout e discurso padronizados para o time;
- integração com o CRM (Vtiger) para reduzir retrabalho de preenchimento.

## Positioning

Proposta comercial com validade jurídica da notificação multicanal AR Online (ABES / ICP-Brasil no chrome), montada pelo próprio comercial com número controlado e canais cotados sob medida — não é um editor Word genérico nem um site de marketing.

## Operating Context

- App local: pasta `Propostas AR Online Oficial` (cópia Dev); abertura via `Iniciar.bat` / servidor PDF (`servidor-pdf.ps1`) e Chrome/Edge.
- Formulário em `index.html` + `app.js`; miolo visual em `paginas.js` (gerado por scripts em `Projetos Lou\_fonte\` — não editar à mão).
- Contador de número: pasta compartilhada + `contador.json` quando conectada; senão contador local do navegador.
- CRM: Vtiger 7.1 próprio (`webservice.php`); busca por nº de oportunidade ou CNPJ (CNPJ não aparece na proposta).
- Destino oficial do time (OneDrive do setor) só recebe versão pronta, com ok da Lou.
- Preview de trabalho: `http://127.0.0.1:8766/`.

## Capabilities and Constraints

**Capaz de:**
- preencher dados do cliente, comercial, modalidade, contexto e canais cotados;
- gerar/abrir PDF das páginas do modelo;
- buscar oportunidade/organização no CRM (leitura);
- salvar dados do comercial no navegador.

**Não faz / não inventa:**
- não altera conteúdo jurídico, valores oficiais ou referências sem fonte confirmada;
- não publica em ClickUp/Zendesk/produção sem aceite explícito da Lou;
- não envia e-mail/mensagem ao cliente;
- senha, token e connection string nunca vão para conversa, documento ou memória.

**Terminologia:** AR-Email, AR-SMS, AR-WhatsApp, AR-Voz, AR-Carta; proposta em PDF AIDA; número da proposta = nº da oportunidade + `/ano` (decisão Lou 17/11/2026; LEIA-ME ainda cita OPT legado).

**Em aberto (não inventar):**
- prazo de guarda (12+48 vs outro);
- setup/mensalidade AR-WhatsApp em fonte oficial;
- hospedagem com login Microsoft;
- texto Saúde ANS pendente de validação jurídica;
- total de páginas se Word P17 entrar como penúltima (12 vs 13).

## Brand Commitments

- Nome: **AR Online**.
- Voz: linguagem simples, legível por qualquer setor; sem marca de IA em texto que sai com o nome da Lou.
- Assets de marca no chrome: logo AR (header/capa), selos ABES e ICP-Brasil; capa sem ABES/ICP (só AR centralizado).
- Cores recorrentes do modelo: `#103b61`, `#2582c5`, `#fbba00`, `#b2b2b2`; tipografia Poppins no miolo.
- Mural «Quem utiliza nossos serviços» com logos de clientes (hoje na P3).

## Evidence on Hand

- `LEIA-ME.txt` — uso do gerador.
- `Projetos Lou\HANDOFF - Proposta AR Online e Gerador.md` — decisões e pendências.
- `Projetos Lou\Proposta comercial AR Online 2027.md` e mapa AIDA — copy/estrutura.
- Fonte de preços: `Todos - Planos, Serviços e Valores.docx` (oficial).
- Logos: `Imagens\`, mural de clientes; ABES/ICP embutidos em `paginas.js`.
- Relatório pericial na proposta usa dados fictícios (PDF de origem real — nunca exibir dados originais).
- Ausências que o trabalho futuro não deve fabricar: depoimentos inventados, benchmarks não documentados, preços WhatsApp não confirmados, prazo de guarda não confirmado.

## Product Principles

1. **Fato antes de copy** — preço, prazo, canal e regra jurídica só entram com fonte; vazio ≠ ok.
2. **PDF é a entrega** — o comercial preenche pouco e revisa o PDF; Word não é o artefato do cliente.
3. **Marca e prova juntas** — chrome AR + ABES/ICP sustentam a validade jurídica sem competir com o conteúdo.
4. **Escopo mínimo e local** — mexer só no Gerador Dev; OneDrive do setor e sistemas do time só com ok da Lou.
5. **Pipeline, não edição solta** — `paginas.js` regenera via scripts; mudança visual vira script em `_fonte`.
