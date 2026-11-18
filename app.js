/* Gerador de Propostas — AR Online
   Preenche o modelo de 12 páginas e baixa a proposta em PDF. */
(function () {
  "use strict";

  var PLANOS = {
    "50":      { unit: "R$ 3,82", mensal: "R$ 191,00/mês",     excedente: "R$ 4,17" },
    "100":     { unit: "R$ 3,55", mensal: "R$ 355,00/mês",     excedente: "R$ 3,98" },
    "150":     { unit: "R$ 3,38", mensal: "R$ 507,00/mês",     excedente: "R$ 3,85" },
    "250":     { unit: "R$ 3,27", mensal: "R$ 817,50/mês",     excedente: "R$ 3,53" },
    "500":     { unit: "R$ 3,00", mensal: "R$ 1.500,00/mês",   excedente: "R$ 3,21" },
    "750":     { unit: "R$ 2,72", mensal: "R$ 2.040,00/mês",   excedente: "R$ 2,87" },
    "1000":    { unit: "R$ 2,45", mensal: "R$ 2.450,00/mês",   excedente: "R$ 2,71" },
    "1500":    { unit: "R$ 2,31", mensal: "R$ 3.465,00/mês",   excedente: "R$ 2,60" },
    "2000":    { unit: "R$ 2,21", mensal: "R$ 4.420,00/mês",   excedente: "R$ 2,53" },
    "5000":    { unit: "R$ 2,16", mensal: "R$ 10.800,00/mês",  excedente: "R$ 2,45" },
    "7000":    { unit: "R$ 2,08", mensal: "R$ 14.560,00/mês",  excedente: "R$ 2,33" },
    "10000":   { unit: "R$ 1,97", mensal: "R$ 19.700,00/mês",  excedente: "R$ 2,12" },
    "15000":   { unit: "R$ 1,80", mensal: "R$ 27.000,00/mês",  excedente: "R$ 1,90" },
    "20000":   { unit: "R$ 1,61", mensal: "R$ 32.200,00/mês",  excedente: "R$ 1,66" },
    "25000":   { unit: "R$ 1,42", mensal: "R$ 35.500,00/mês",  excedente: "R$ 1,44" },
    "30000":   { unit: "R$ 1,22", mensal: "R$ 36.600,00/mês",  excedente: "R$ 1,32" },
    "45000":   { unit: "R$ 1,13", mensal: "R$ 50.850,00/mês",  excedente: "R$ 1,28" },
    "60000":   { unit: "R$ 1,08", mensal: "R$ 64.800,00/mês",  excedente: "R$ 1,16" },
    "80000":   { unit: "R$ 0,99", mensal: "R$ 79.200,00/mês",  excedente: "R$ 1,08" },
    "100000":  { unit: "R$ 0,92", mensal: "R$ 92.000,00/mês",  excedente: "R$ 1,00" },
    "150000":  { unit: "R$ 0,89", mensal: "R$ 133.500,00/mês", excedente: "R$ 0,98" },
    "200000":  { unit: "R$ 0,86", mensal: "R$ 172.000,00/mês", excedente: "R$ 0,94" },
    "250000":  { unit: "R$ 0,84", mensal: "R$ 210.000,00/mês", excedente: "R$ 0,91" },
    "300000":  { unit: "R$ 0,82", mensal: "R$ 246.000,00/mês", excedente: "R$ 0,88" },
    "350000":  { unit: "R$ 0,79", mensal: "R$ 276.500,00/mês", excedente: "R$ 0,84" },
    "400000":  { unit: "R$ 0,77", mensal: "R$ 308.000,00/mês", excedente: "R$ 0,80" },
    "450000":  { unit: "R$ 0,76", mensal: "R$ 342.000,00/mês", excedente: "R$ 0,77" },
    "500000":  { unit: "R$ 0,73", mensal: "R$ 365.000,00/mês", excedente: "R$ 0,74" },
    "550000":  { unit: "R$ 0,70", mensal: "R$ 385.000,00/mês", excedente: "R$ 0,72" },
    "600000":  { unit: "R$ 0,68", mensal: "R$ 408.000,00/mês", excedente: "R$ 0,70" },
    "750000":  { unit: "R$ 0,65", mensal: "R$ 487.500,00/mês", excedente: "R$ 0,68" },
    "800000":  { unit: "R$ 0,63", mensal: "R$ 504.000,00/mês", excedente: "R$ 0,65" },
    "850000":  { unit: "R$ 0,61", mensal: "R$ 518.500,00/mês", excedente: "R$ 0,63" },
    "900000":  { unit: "R$ 0,59", mensal: "R$ 531.000,00/mês", excedente: "R$ 0,61" },
    "950000":  { unit: "R$ 0,56", mensal: "R$ 532.000,00/mês", excedente: "R$ 0,59" },
    "1000000": { unit: "R$ 0,54", mensal: "R$ 540.000,00/mês", excedente: "R$ 0,59" }
  };

  function fmtMilhar(n) {
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  }
  function rotuloPlano(sel) {
    if (sel === "1000000") return "1.000.000 ou mais";
    return fmtMilhar(sel);
  }
  var MESES = ["janeiro", "fevereiro", "março", "abril", "maio", "junho",
               "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];

  var $ = function (id) { return document.getElementById(id); };
  var dirHandle = null;
  var numeroReservado = null; // numero definitivo reservado no contador

  // ------------------------------------------------------------- utilidades
  function status(msg, tipo) {
    var el = $("status");
    el.textContent = msg || "";
    el.className = tipo || "";
  }

  function b64paraBytes(b64) {
    var bin = atob(b64);
    var out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  function dataPorExtenso(valor) {
    if (!valor) return "";
    var p = valor.split("-");
    if (p.length !== 3) return valor;
    return String(parseInt(p[2], 10)) + " de " + MESES[parseInt(p[1], 10) - 1] + " de " + p[0];
  }

  function anoDaData(valor) {
    if (!valor) return new Date().getFullYear();
    return parseInt(valor.split("-")[0], 10);
  }

  function formataNumero(n, ano) {
    return "OPT " + String(n).padStart(4, "0") + "/" + ano;
  }

  // ------------------------------------------------------------- plano
  function aplicaPlano() {
    var sel = $("plano").value;
    var p = PLANOS[sel] || PLANOS["1000"];
    if (sel !== "custom") {
      $("franquia").value = rotuloPlano(sel);
      $("valorMensal").value = p.mensal;
      $("valorExcedente").value = p.excedente;
    }
    var unit = sel === "custom" ? PLANOS["1000"].unit : p.unit;
    var enviosTxt = sel === "custom" ? ($("franquia").value || "XXX") : rotuloPlano(sel);
    $("volume").value = enviosTxt + " envios/mês (" + unit + ")";
  }

  $("plano").addEventListener("change", aplicaPlano);
  $("franquia").addEventListener("input", function () {
    if ($("plano").value === "custom") {
      var envios = $("franquia").value || "XXX";
      var m = $("volume").value.match(/\(R\$ [^)]+\)/);
      $("volume").value = envios + " envios/mês " + (m ? m[0] : "(R$ XXX)");
    }
  });

  // ------------------------------------------------------------- dados do comercial (localStorage)
  ["comercial", "comercialTel", "comercialEmail"].forEach(function (id) {
    var salvo = localStorage.getItem("arpro_" + id);
    if (salvo) $(id).value = salvo;
    $(id).addEventListener("change", function () {
      localStorage.setItem("arpro_" + id, $(id).value);
    });
  });

  // ------------------------------------------------------------- numeracao
  function abrirDB() {
    return new Promise(function (res, rej) {
      var req = indexedDB.open("ar_proposta", 1);
      req.onupgradeneeded = function () { req.result.createObjectStore("config"); };
      req.onsuccess = function () { res(req.result); };
      req.onerror = function () { rej(req.error); };
    });
  }

  function dbGet(chave) {
    return abrirDB().then(function (db) {
      return new Promise(function (res) {
        var tx = db.transaction("config", "readonly").objectStore("config").get(chave);
        tx.onsuccess = function () { res(tx.result || null); };
        tx.onerror = function () { res(null); };
      });
    });
  }

  function dbSet(chave, valor) {
    return abrirDB().then(function (db) {
      return new Promise(function (res) {
        var tx = db.transaction("config", "readwrite").objectStore("config").put(valor, chave);
        tx.onsuccess = function () { res(); };
        tx.onerror = function () { res(); };
      });
    });
  }

  function atualizaPrev() {
    var ano = anoDaData($("data").value);
    var base = numeroReservado || (parseInt(localStorage.getItem("arpro_seq_" + ano) || "0", 10) + 1);
    $("numeroPrev").textContent = formataNumero(base, ano);
  }

  async function conectarPasta() {
    if (!window.showDirectoryPicker) {
      $("pastaStatus").textContent = "Este navegador não permite acesso à pasta. Use Chrome ou Edge.";
      return;
    }
    try {
      dirHandle = await window.showDirectoryPicker({ mode: "readwrite" });
      await dbSet("pasta", dirHandle);
      $("pastaStatus").textContent = "Pasta conectada: " + dirHandle.name +
        " — o número sai do contador compartilhado.";
      numeroReservado = null;
      atualizaPrev();
    } catch (e) { /* cancelado pelo usuario */ }
  }

  async function tentaReconectar() {
    if (!window.showDirectoryPicker) return;
    try {
      var h = await dbGet("pasta");
      if (!h) return;
      var perm = await h.queryPermission({ mode: "readwrite" });
      if (perm === "granted") {
        dirHandle = h;
        $("pastaStatus").textContent = "Pasta conectada: " + h.name +
          " — o número sai do contador compartilhado.";
      } else {
        $("pastaStatus").textContent = "Clique em 'Conectar pasta compartilhada' para liberar o acesso novamente.";
      }
    } catch (e) { /* sem reconexao */ }
  }

  async function leContador() {
    try {
      var fh = await dirHandle.getFileHandle("contador.json", { create: true });
      var f = await fh.getFile();
      if (f.size === 0) return { handle: fh, dados: {} };
      var txt = await f.text();
      return { handle: fh, dados: JSON.parse(txt) };
    } catch (e) {
      return null;
    }
  }

  async function reservaNumero(ano) {
    if (dirHandle) {
      var c = await leContador();
      if (c) {
        var ultimo = (c.dados.ano === ano) ? (c.dados.ultimo || 0) : 0;
        var novo = { ano: ano, ultimo: ultimo + 1, atualizadoEm: new Date().toISOString() };
        try {
          var w = await c.handle.createWritable();
          await w.write(JSON.stringify(novo, null, 2));
          await w.close();
          numeroReservado = novo.ultimo;
          return novo.ultimo;
        } catch (e) { /* cai para o contador local */ }
      }
    }
    var chave = "arpro_seq_" + ano;
    var n = parseInt(localStorage.getItem(chave) || "0", 10) + 1;
    localStorage.setItem(chave, String(n));
    numeroReservado = n;
    return n;
  }

  // ------------------------------------------------------------- logo
  function tamanhoImagem(buf) {
    var v = new DataView(buf);
    if (v.getUint32(0) === 0x89504E47) { // PNG
      return { w: v.getUint32(16), h: v.getUint32(20), tipo: "png" };
    }
    if (v.getUint16(0) === 0xFFD8) { // JPEG
      var i = 2;
      while (i < v.byteLength - 9) {
        if (v.getUint8(i) !== 0xFF) { i++; continue; }
        var marc = v.getUint8(i + 1);
        if (marc >= 0xC0 && marc <= 0xCF && marc !== 0xC4 && marc !== 0xC8 && marc !== 0xCC) {
          return { w: v.getUint16(i + 7), h: v.getUint16(i + 5), tipo: "jpeg" };
        }
        i += 2 + v.getUint16(i + 2);
      }
    }
    return null;
  }

  function aplicaLogo(zip, nomeArquivo, buf) {
    var dim = tamanhoImagem(buf);
    if (!dim) return false;
    var ext = dim.tipo === "png" ? "png" : "jpeg";
    var alvo = "word/media/logo_cliente." + ext;
    zip.file(alvo, buf);

    // novo rId
    var relsXml = zip.file("word/_rels/document.xml.rels").asText();
    var maior = 0;
    relsXml.replace(/Id="rId(\d+)"/g, function (_, n) { maior = Math.max(maior, +n); return _; });
    var rid = "rId" + (maior + 1);
    relsXml = relsXml.replace("</Relationships>",
      '<Relationship Id="' + rid + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/logo_cliente.' + ext + '"/></Relationships>');
    zip.file("word/_rels/document.xml.rels", relsXml);

    // content types
    var ct = zip.file("[Content_Types].xml").asText();
    if (ext === "jpeg" && ct.indexOf('Extension="jpeg"') < 0) {
      ct = ct.replace("</Types>", '<Default Extension="jpeg" ContentType="image/jpeg"/></Types>');
    }
    if (ext === "png" && ct.indexOf('Extension="png"') < 0) {
      ct = ct.replace("</Types>", '<Default Extension="png" ContentType="image/png"/></Types>');
    }
    zip.file("[Content_Types].xml", ct);

    // dimensao: max 2.6 x 1.2 pol (preserva proporcao, 96 dpi)
    var wIn = dim.w / 96, hIn = dim.h / 96;
    var esc = Math.min(2.6 / wIn, 1.2 / hIn, 1);
    var cx = Math.round(wIn * esc * 914400);
    var cy = Math.round(hIn * esc * 914400);

    var docXml = zip.file("word/document.xml").asText();
    var drawing =
      '<w:r><w:rPr><w:noProof/></w:rPr><w:drawing>' +
      '<wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">' +
      '<wp:extent cx="' + cx + '" cy="' + cy + '"/>' +
      '<wp:effectExtent l="0" t="0" r="0" b="0"/>' +
      '<wp:docPr id="990001" name="Logo do cliente"/>' +
      '<wp:cNvGraphicFramePr/>' +
      '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">' +
      '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">' +
      '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">' +
      '<pic:nvPicPr><pic:cNvPr id="0" name="logo_cliente.' + ext + '"/><pic:cNvPicPr/></pic:nvPicPr>' +
      '<pic:blipFill><a:blip r:embed="' + rid + '" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>' +
      '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>' +
      '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="' + cx + '" cy="' + cy + '"/></a:xfrm>' +
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>' +
      '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>';

    var alvoTxt = "[INSERIR LOGO DO CLIENTE]";
    var idx = docXml.indexOf(alvoTxt);
    if (idx < 0) return false;
    var rIni = docXml.lastIndexOf("<w:r>", idx);
    var rIniAlt = docXml.lastIndexOf("<w:r ", idx);
    if (rIniAlt > rIni) rIni = rIniAlt;
    var rFim = docXml.indexOf("</w:r>", idx) + "</w:r>".length;
    docXml = docXml.slice(0, rIni) + drawing + docXml.slice(rFim);
    zip.file("word/document.xml", docXml);
    return true;
  }

  function removePlaceholderLogo(zip) {
    var docXml = zip.file("word/document.xml").asText();
    docXml = docXml.split("[INSERIR LOGO DO CLIENTE]").join("");
    zip.file("word/document.xml", docXml);
  }

  function preparaImpressao(html, titulo) {
    html = html.replace("<head>", "<head><title>" + escapa(titulo) + "</title>");
    html = html.replace("</style>",
      ".folha:last-child{page-break-after:auto;break-after:auto}</style>");
    return html;
  }

  function mostraProposta(html) {
    var antigo = $("visor");
    if (antigo) antigo.remove();
    var visor = document.createElement("div");
    visor.id = "visor";
    visor.innerHTML = "<div class=\"barra\"><button type=\"button\" id=\"visorSalvar\">Salvar PDF</button>"
      + "<span>No destino, escolha Salvar como PDF e desmarque cabeçalhos e rodapés.</span>"
      + "<button type=\"button\" id=\"visorFechar\" class=\"fechar\">Fechar</button></div>"
      + "<iframe title=\"Proposta\"></iframe>";
    document.body.appendChild(visor);
    var frame = visor.querySelector("iframe");
    var doc = frame.contentDocument;
    doc.open();
    doc.write(html);
    doc.close();
    function ajustaFolhas() {
      var largura = doc.documentElement.clientWidth || frame.clientWidth;
      var altura = doc.documentElement.clientHeight || frame.clientHeight;
      var escala = Math.min(1, (largura - 48) / 794, (altura - 48) / 1123);
      if (!isFinite(escala) || escala <= 0) escala = 1;
      doc.querySelectorAll(".folha").forEach(function (folha) {
        folha.style.setProperty("--escala", String(escala));
      });
    }
    ajustaFolhas();
    frame.contentWindow.addEventListener("resize", ajustaFolhas);
    $("visorSalvar").addEventListener("click", function () {
      frame.contentWindow.focus();
      frame.contentWindow.print();
    });
    $("visorFechar").addEventListener("click", function () { visor.remove(); });
  }

  var FAIXA = {
    "50": "50", "100": "100", "150": "150", "250": "250", "500": "500", "750": "750",
    "1000": "1.000", "1500": "1.500", "2000": "2.000", "5000": "5.000", "7000": "7.000",
    "10000": "10.000", "15000": "15.000", "20000": "20.000", "25000": "25.000",
    "30000": "30.000", "45000": "45.000", "60000": "60.000", "80000": "80.000",
    "100000": "100.000", "150000": "150.000", "200000": "200.000", "250000": "250.000",
    "300000": "300.000", "350000": "350.000", "400000": "400.000", "450000": "450.000",
    "500000": "500.000", "550000": "550.000", "600000": "600.000", "750000": "750.000",
    "800000": "800.000", "850000": "850.000", "900000": "900.000", "950000": "950.000",
    "1000000": "1.000.000 ou mais"
  };

  function soNumero(s) {
    return String(s || "").replace(/^R\$\s*/, "").replace(/\s*\/m[eê]s\s*$/i, "").trim();
  }

  function escapa(s) {
    return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function valorUnitario() {
    var plano = $("plano").value;
    if (PLANOS[plano]) return soNumero(PLANOS[plano].unit);
    var m = ($("volume").value || "").match(/\(R\$\s*([^)]+)\)/);
    return m ? m[1].trim() : "";
  }

  function trocaTokens(html, dados) {
    Object.keys(dados).forEach(function (k) {
      html = html.split("{{" + k + "}}").join(escapa(dados[k]));
    });
    return html.replace(/\{\{img:([^}]+)\}\}/g, function (_, id) {
      return (typeof IMAGENS !== "undefined" && IMAGENS[id]) || "";
    });
  }

  function removeDeAte(inicio, fim) {
    var n = inicio;
    while (n && n !== fim) {
      var prox = n.nextElementSibling;
      n.remove();
      n = prox;
    }
  }

  function montaHtml(dados, ativos) {
    var paginas = (typeof PAGINAS !== "undefined" ? PAGINAS : []).filter(function (p) {
      if (!p.canal) return true;
      if (p.canal === "whats-voz") return ativos.whats || ativos.voz;
      return !!ativos[p.canal];
    });
    var total = String(paginas.length).padStart(2, "0");
    var miolo = paginas.map(function (p, i) {
      var html = trocaTokens(p.html, dados);
      html = html.split("{{PAGINA}}").join(String(i + 1).padStart(2, "0"));
      html = html.split("{{TOTAL}}").join(total);
      return html;
    }).join("");
    var doc = "<!DOCTYPE html><html lang=\"pt-BR\"><head><meta charset=\"utf-8\">"
      + "<link href=\"https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap\" rel=\"stylesheet\">"
      + "<style>@page{size:794px 1123px;margin:0}"
      + "html,body{margin:0;padding:0;background:#fff}"
      + ".folha,.folha *{-webkit-print-color-adjust:exact;print-color-adjust:exact;font-family:Poppins,Arial,sans-serif}"
      + ".folha{width:794px;height:1123px;overflow:hidden;page-break-after:always;break-after:page;box-sizing:border-box;background:#fff}"
      + "table{width:100%;border-collapse:collapse}img{max-width:100%}"
      + "@media screen{html,body{background:#d8dbe3}"
      + "body{display:flex;flex-direction:column;align-items:center;gap:20px;padding:20px 0 40px}"
      + ".folha{--escala:1;box-shadow:0 10px 28px rgba(15,23,42,.18);"
      + "transform:scale(var(--escala));transform-origin:top center;"
      + "margin-bottom:calc((var(--escala) - 1) * 1123px)}}"
      + "@media print{html,body{background:#fff}.folha{box-shadow:none}}"
      + "</style></head><body>"
      + miolo + "</body></html>";
    var dom = new DOMParser().parseFromString(doc, "text/html");
    dom.querySelectorAll("[data-canal]").forEach(function (el) {
      var canal = el.getAttribute("data-canal");
      if (!ativos[canal]) el.remove();
    });
    var grade = dom.querySelector("[data-canais]");
    if (grade) {
      var n = grade.children.length || 1;
      grade.style.gridTemplateColumns = "repeat(" + n + ", minmax(0, 1fr))";
    }
    var whats = null;
    var voz = null;
    dom.querySelectorAll("h1").forEach(function (h) {
      var titulo = (h.textContent || "").trim();
      var bloco = h.parentElement && h.parentElement.parentElement;
      if (titulo === "AR-Whatsapp") whats = bloco;
      if (titulo === "AR-Voz") voz = bloco;
    });
    if (whats && voz && whats.parentElement === voz.parentElement) {
      if (!ativos.whats) removeDeAte(whats, voz);
      if (!ativos.voz) {
        var antes = voz.previousElementSibling;
        if (antes && /height:\s*1px/.test(antes.getAttribute("style") || "")) antes.remove();
        removeDeAte(voz, null);
      }
    }
    var faixa = FAIXA[$("plano").value];
    if (faixa) {
      dom.querySelectorAll('tr[data-faixa="' + faixa + '"]').forEach(function (tr) {
        tr.querySelectorAll("td").forEach(function (td) {
          td.style.background = "#e4f1fb";
          td.style.fontWeight = "600";
        });
      });
    }
    return "<!DOCTYPE html>\n" + dom.documentElement.outerHTML;
  }

  // ------------------------------------------------------------- gerar
  function valida() {
    var falta = [];
    if (!$("cliente").value.trim()) falta.push("nome do contato");
    if (!$("empresa").value.trim()) falta.push("empresa");
    if (!$("data").value) falta.push("data");
    if (!$("comercial").value.trim()) falta.push("seu nome");
    if (!$("canalEmail").checked && !$("canalWhats").checked &&
        !$("canalVoz").checked && !$("canalCartas").checked) falta.push("ao menos um canal");
    return falta;
  }

  async function gerar() {
    var falta = valida();
    if (falta.length) {
      status("Preencha: " + falta.join(", ") + ".", "erro");
      return;
    }
    if (typeof PAGINAS === "undefined") {
      status("O modelo da proposta não carregou. Recarregue a página.", "erro");
      return;
    }
    var btn = $("btnGerar");
    btn.disabled = true;
    status("Abrindo a proposta...", "");
    var nomePdf = "";
    try {
      var ano = anoDaData($("data").value);
      var n = $("numeroManual").value.trim() ? null : await reservaNumero(ano);
      var numero = $("numeroManual").value.trim() || formataNumero(n, ano);
      var ativos = {
        email: $("canalEmail").checked,
        whats: $("canalWhats").checked,
        voz: $("canalVoz").checked,
        cartas: $("canalCartas").checked
      };
      var dados = {
        NUMERO: numero,
        DATA: dataPorExtenso($("data").value),
        CLIENTE: $("cliente").value.trim(),
        EMPRESA: $("empresa").value.trim(),
        COMERCIAL: $("comercial").value.trim(),
        TEL: $("comercialTel").value.trim(),
        EMAIL: $("comercialEmail").value.trim(),
        VOLUME: $("franquia").value.trim(),
        MENSAL: soNumero($("valorMensal").value),
        UNITARIO: valorUnitario(),
        EXCEDENTE: soNumero($("valorExcedente").value)
      };

      nomePdf = dados.EMPRESA.replace(/[\\/:*?"<>|]/g, "") +
        "_Proposta AR Online " + numero.replace("/", "-");
      mostraProposta(preparaImpressao(montaHtml(dados, ativos), nomePdf));
      numeroReservado = null;
      atualizaPrev();
      status("Proposta " + numero + " pronta. Escolha Salvar como PDF e desmarque cabeçalhos e rodapés.", "ok");
    } catch (e) {
      console.error(e);
      var msg = e && e.message ? e.message : String(e);
      status("Não consegui abrir a proposta: " + msg, "erro");
    } finally {
      btn.disabled = false;
    }
  }

  // ------------------------------------------------------------- init
  $("btnPasta").addEventListener("click", conectarPasta);
  $("btnGerar").addEventListener("click", gerar);
  $("data").addEventListener("change", atualizaPrev);
  $("data").valueAsDate = new Date();
  aplicaPlano();
  tentaReconectar();
  atualizaPrev();
})();
