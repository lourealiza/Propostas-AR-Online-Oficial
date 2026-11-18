# Servidor local do gerador. So escuta em 127.0.0.1.
# Entrega a pagina e converte o Word gerado em PDF, pelo Word instalado.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$porta = "http://127.0.0.1:8766/"

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".txt"  = "text/plain; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".png"  = "image/png"
  ".docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
}

function Cabecalhos($res) {
  $origem = "*"
  if ($script:pedido -and $script:pedido.Headers["Origin"]) {
    $origem = [string]$script:pedido.Headers["Origin"]
  }
  $res.Headers["Access-Control-Allow-Origin"] = $origem
  $res.Headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
  $res.Headers["Access-Control-Allow-Headers"] = "Content-Type"
  $res.Headers["Access-Control-Allow-Private-Network"] = "true"
}

function Responder($res, [int]$codigo, [byte[]]$bytes, [string]$tipo) {
  Cabecalhos $res
  $res.StatusCode = $codigo
  if ($tipo) { $res.ContentType = $tipo }
  if ($bytes -and $bytes.Length -gt 0) {
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  }
  $res.OutputStream.Close()
}

function Texto($res, [int]$codigo, [string]$msg) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
  Responder $res $codigo $bytes "text/plain; charset=utf-8"
}

function Converter-Pdf([byte[]]$docxBytes) {
  $pasta = Join-Path $env:TEMP ("arprop_" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $pasta | Out-Null
  $docx = Join-Path $pasta "proposta.docx"
  $pdf = Join-Path $pasta "proposta.pdf"
  $script = Join-Path $pasta "converter.ps1"
  [System.IO.File]::WriteAllBytes($docx, $docxBytes)
  @'
param([string]$In, [string]$Out)
$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $doc = $word.Documents.Open($In, $false, $true)
  $doc.ExportAsFixedFormat($Out, 17)
  $doc.Close(0)
} finally {
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
'@ | Set-Content -LiteralPath $script -Encoding ASCII
  $exe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
  $proc = Start-Process -FilePath $exe -ArgumentList @("-NoProfile","-Sta","-ExecutionPolicy","Bypass","-File",$script,"-In",$docx,"-Out",$pdf) -PassThru -WindowStyle Hidden
  if (-not $proc.WaitForExit(90000)) {
    try { Stop-Process -Id $proc.Id -Force } catch {}
    throw "O Word demorou demais para gerar o PDF."
  }
  if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $pdf)) {
    throw "O Word nao gerou o PDF."
  }
  $bytes = [System.IO.File]::ReadAllBytes($pdf)
  Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction SilentlyContinue
  return $bytes
}

function Achar-Edge {
  $candidatos = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
  )
  foreach ($c in $candidatos) {
    if ($c -and (Test-Path -LiteralPath $c)) { return $c }
  }
  throw "O Microsoft Edge nao foi encontrado neste computador."
}

function Converter-Html([byte[]]$htmlBytes) {
  $pasta = Join-Path $env:TEMP ("arprop_" + [guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Path $pasta | Out-Null
  $html = Join-Path $pasta "proposta.html"
  $pdf = Join-Path $pasta "proposta.pdf"
  $perfil = Join-Path $pasta "perfil"
  [System.IO.File]::WriteAllBytes($html, $htmlBytes)
  $uri = ([Uri]$html).AbsoluteUri
  $edge = Achar-Edge
  $proc = Start-Process -FilePath $edge -ArgumentList @(
    "--headless=new",
    "--disable-gpu",
    "--no-first-run",
    "--no-pdf-header-footer",
    "--virtual-time-budget=25000",
    "--user-data-dir=$perfil",
    "--print-to-pdf=$pdf",
    $uri
  ) -PassThru -WindowStyle Hidden
  if (-not $proc.WaitForExit(90000)) {
    try { Stop-Process -Id $proc.Id -Force } catch {}
    throw "O Edge demorou demais para gerar o PDF."
  }
  if (-not (Test-Path -LiteralPath $pdf)) {
    throw "O Edge nao gerou o PDF."
  }
  $bytes = [System.IO.File]::ReadAllBytes($pdf)
  Remove-Item -LiteralPath $pasta -Recurse -Force -ErrorAction SilentlyContinue
  return $bytes
}

# --- Consulta ao CRM (Vtiger 7, instalado em servidor proprio). So leitura.
# As credenciais vem do arquivo .env (VTIGER_URL, VTIGER_USERNAME,
# VTIGER_ACCESS_KEY). Este servidor nunca entrega o .env ao navegador.
# Nomes dos campos conferidos no CRM em 17/11/2026:
#   potential_no = No. Oportunidade | related_to = Nome Organizacao | cf_874 = CNPJ
$crmCampoNumero = "potential_no"
$crmCampoOrg = "related_to"
$crmCampoCnpj = "Accounts/cf_874"
$script:crmSessao = ""

function Crm-Config {
  $arquivo = $null
  $perfil = Join-Path $env:APPDATA "AR Online\Gerador de Propostas\.env"
  foreach ($c in @($perfil, (Join-Path $root ".env"), (Join-Path $root "Gerador de Propostas\.env"))) {
    if (Test-Path -LiteralPath $c) { $arquivo = $c; break }
  }
  if (-not $arquivo) { return $null }
  $v = @{}
  try {
    foreach ($linha in (Get-Content -LiteralPath $arquivo)) {
      $t = $linha.Trim()
      if (-not $t -or $t.StartsWith("#")) { continue }
      $i = $t.IndexOf("=")
      if ($i -lt 1) { continue }
      $v[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim().Trim('"').Trim("'")
    }
  } catch { return $null }
  $endereco = (([string]$v["VTIGER_URL"]).TrimEnd("/")) -replace "/webservice\.php$", ""
  return [pscustomobject]@{
    endereco    = $endereco
    ws          = $endereco + "/webservice.php"
    usuario     = [string]$v["VTIGER_USERNAME"]
    chave       = [string]$v["VTIGER_ACCESS_KEY"]
    campoNumero = $crmCampoNumero
    campoOrg    = $crmCampoOrg
    campoCnpj   = $crmCampoCnpj
  }
}

function Crm-Chamar([string]$url, $corpo) {
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
  $ProgressPreference = "SilentlyContinue"
  $p = @{ Uri = $url; UseBasicParsing = $true; TimeoutSec = 20 }
  if ($corpo) { $p.Method = "POST"; $p.Body = $corpo }
  $r = Invoke-WebRequest @p
  $txt = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
  return ($txt | ConvertFrom-Json)
}

# Abre a sessao no CRM. A chave nao trafega: vai so o resumo dela com o
# codigo que o CRM entrega a cada entrada.
function Crm-Entrar($cfg) {
  $script:crmSessao = ""
  $d = Crm-Chamar ($cfg.ws + "?operation=getchallenge&username=" + [Uri]::EscapeDataString($cfg.usuario)) $null
  if (-not $d.success) { return $false }
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes([string]$d.result.token + $cfg.chave))
  $resumo = -join ($bytes | ForEach-Object { $_.ToString("x2") })
  $l = Crm-Chamar $cfg.ws @{ operation = "login"; username = $cfg.usuario; accessKey = $resumo }
  if (-not $l.success) { return $false }
  $script:crmSessao = [string]$l.result.sessionName
  return [bool]$script:crmSessao
}

function Crm-Sair($cfg) {
  if (-not $script:crmSessao) { return }
  try { Crm-Chamar $cfg.ws @{ operation = "logout"; sessionName = $script:crmSessao } | Out-Null } catch {}
  $script:crmSessao = ""
}

# Confere a configuracao e entra. Devolve $null se entrou, ou o erro.
function Crm-Abrir($cfg) {
  if (-not (Crm-CfgOk $cfg) -or -not $cfg.usuario -or -not $cfg.chave) {
    return @{ ok = $false; codigo = "sem_config" }
  }
  try {
    if (Crm-Entrar $cfg) { return $null }
    return @{ ok = $false; codigo = "acesso_negado" }
  } catch {
    return @{ ok = $false; codigo = "falha_crm" }
  }
}

# $operacao no formato "query?query=..." ou "retrieve?id=...".
function Crm-Get($cfg, [string]$operacao) {
  $i = $operacao.IndexOf("?")
  $url = $cfg.ws + "?operation=" + $operacao.Substring(0, $i) + "&sessionName=" + $script:crmSessao + "&" + $operacao.Substring($i + 1)
  return (Crm-Chamar $url $null)
}

# O CRM devolve alguns textos com codigos HTML no lugar do acento
# (ex.: "&acirc;"). Converte para o caractere certo.
function Crm-Texto([string]$s) {
  if (-not $s) { return "" }
  $t = $s
  for ($i = 0; $i -lt 2; $i++) {
    $d = [System.Net.WebUtility]::HtmlDecode($t)
    if ($d -eq $t) { break }
    $t = $d
  }
  return $t.Trim()
}

function Crm-Valor($v) {
  if ($null -eq $v) { return "" }
  if ($v -is [string]) { return (Crm-Texto $v) }
  if ($v -is [System.Management.Automation.PSCustomObject]) {
    foreach ($n in @("value", "id")) {
      if ($v.PSObject.Properties[$n]) { return (Crm-Texto ([string]$v.$n)) }
    }
    return ""
  }
  return (Crm-Texto ([string]$v))
}

function Crm-CfgOk($cfg) {
  if ($null -eq $cfg) { return $false }
  if ([string]$cfg.endereco -notmatch "^https://") { return $false }
  if ([string]$cfg.campoNumero -notmatch "^[A-Za-z0-9_]+$") { return $false }
  return $true
}

# Roda uma consulta. Devolve @{ ok; lista } ou @{ ok = $false; codigo }.
function Crm-Consulta($cfg, [string]$q) {
  try {
    $r = Crm-Get $cfg ("query?query=" + [Uri]::EscapeDataString($q))
    if (-not $r.success) {
      if ([string]$r.error.code -match "ACCESS|AUTH") { return @{ ok = $false; codigo = "acesso_negado" } }
      return @{ ok = $false; codigo = "falha_crm" }
    }
    return @{ ok = $true; lista = @($r.result | Where-Object { $_ }) }
  } catch {
    $codigo = "falha_crm"
    try {
      $http = [int]$_.Exception.Response.StatusCode
      if ($http -eq 401 -or $http -eq 403) { $codigo = "acesso_negado" }
    } catch {}
    return @{ ok = $false; codigo = $codigo }
  }
}

# Busca pelo numero da oportunidade.
function Crm-Buscar([string]$numero) {
  $numero = ([string]$numero).Trim()
  if ($numero -notmatch "^[A-Za-z0-9 ._/-]{1,40}$") {
    return @{ ok = $false; codigo = "numero_invalido" }
  }
  $cfg = Crm-Config
  $erro = Crm-Abrir $cfg
  if ($erro) { return $erro }
  try {
    $c = Crm-Consulta $cfg ("select * from Potentials where " + $cfg.campoNumero + " = '" + $numero + "' limit 0, 1;")
    if (-not $c.ok) { return $c }
    if ($c.lista.Count -eq 0) { return @{ ok = $false; codigo = "nao_encontrada" } }
    return (Crm-Detalhe $cfg $c.lista[0])
  } finally {
    Crm-Sair $cfg
  }
}

# Busca pelo CNPJ. Uma oportunidade: devolve os dados dela.
# Mais de uma: devolve a lista (numero e nome) para a pessoa escolher.
function Crm-BuscarCnpj([string]$cnpj) {
  $limpo = (([string]$cnpj) -replace "[\s./-]", "").ToUpperInvariant()
  if ($limpo -notmatch "^[A-Z0-9]{12}[0-9]{2}$") { return @{ ok = $false; codigo = "cnpj_invalido" } }
  $cfg = Crm-Config
  $erro = Crm-Abrir $cfg
  if ($erro) { return $erro }
  try {
    $campo = ([string]$cfg.campoCnpj).Split("/")[1]
    # No CRM o CNPJ aparece com pontuacoes diferentes (ou sem nenhuma).
    # A busca casa os blocos de digitos e depois confere o CNPJ inteiro.
    $padrao = "%" + $limpo.Substring(0, 2) + "%" + $limpo.Substring(2, 3) + "%" + $limpo.Substring(5, 3) + "%" + $limpo.Substring(8, 4) + "%" + $limpo.Substring(12, 2) + "%"
    $c = Crm-Consulta $cfg ("select * from Accounts where " + $campo + " like '" + $padrao + "' limit 0, 20;")
    if (-not $c.ok) { return $c }
    $orgs = @($c.lista | Where-Object { ((Crm-Valor $_.$campo) -replace "[^0-9A-Za-z]", "").ToUpperInvariant() -eq $limpo })
    if ($orgs.Count -eq 0) { return @{ ok = $false; codigo = "cnpj_nao_encontrado" } }
    # O mesmo CNPJ pode estar em mais de uma organizacao: junta as oportunidades de todas.
    $pots = @()
    foreach ($o in $orgs) {
      $orgId = Crm-Valor $o.id
      if ($orgId -notmatch "^\d+x\d+$") { continue }
      $c = Crm-Consulta $cfg ("select * from Potentials where " + $cfg.campoOrg + " = '" + $orgId + "' order by createdtime desc limit 0, 20;")
      if (-not $c.ok) { return $c }
      $pots += @($c.lista)
    }
    if ($pots.Count -eq 0) { return @{ ok = $false; codigo = "sem_oportunidade" } }
    if ($pots.Count -eq 1) { return (Crm-Detalhe $cfg $pots[0]) }
    $lista = @()
    foreach ($p in $pots) {
      $lista += @{
        numero  = (Crm-Valor $p.($cfg.campoNumero))
        nome    = (Crm-Valor $p.potentialname)
        estagio = (Crm-Valor $p.sales_stage)
      }
    }
    return @{ ok = $true; varias = $true; lista = $lista; limite = ($pots.Count -ge 20) }
  } finally {
    Crm-Sair $cfg
  }
}

# Monta a resposta a partir do registro da oportunidade.
function Crm-Detalhe($cfg, $pot) {
  try {
    $numero = Crm-Valor $pot.($cfg.campoNumero)
    $nomeOportunidade = Crm-Valor $pot.label
    if (-not $nomeOportunidade) { $nomeOportunidade = Crm-Valor $pot.potentialname }

    # empresa: registro da organizacao ligada a oportunidade
    $orgId = ""
    if ($cfg.campoOrg) { $orgId = Crm-Valor $pot.($cfg.campoOrg) }
    $org = $null
    if ($orgId -match "^\d+x\d+$") {
      try {
        $ro = Crm-Get $cfg ("retrieve?id=" + $orgId)
        if ($ro.success) { $org = $ro.result }
      } catch {}
    }
    $empresa = ""
    $empresaSituacao = "nao_lida"
    if (-not $orgId) {
      $empresaSituacao = "sem_vinculo"
    } elseif ($org) {
      $empresa = Crm-Valor $org.label
      if (-not $empresa) { $empresa = Crm-Valor $org.accountname }
      if ($empresa) { $empresaSituacao = "preenchida" }
    }

    # CNPJ: o campo foi localizado na configuracao (modulo/campo)
    $cnpj = ""
    $cnpjSituacao = "sem_campo"
    $partes = ([string]$cfg.campoCnpj).Split("/")
    if ($partes.Count -eq 2 -and $partes[1]) {
      if ($partes[0] -eq "Potentials") {
        $cnpj = Crm-Valor $pot.($partes[1])
        if ($cnpj) { $cnpjSituacao = "preenchido" } else { $cnpjSituacao = "vazio" }
      } elseif (-not $orgId) {
        $cnpjSituacao = "sem_vinculo"
      } elseif ($org) {
        $cnpj = Crm-Valor $org.($partes[1])
        if ($cnpj) { $cnpjSituacao = "preenchido" } else { $cnpjSituacao = "vazio" }
      } else {
        $cnpjSituacao = "nao_lido"
      }
    }

    return @{
      ok = $true
      numero = $numero
      oportunidade = $nomeOportunidade
      empresa = $empresa
      empresaSituacao = $empresaSituacao
      cnpj = $cnpj
      cnpjSituacao = $cnpjSituacao
    }
  } catch {
    $codigo = "falha_crm"
    try {
      $http = [int]$_.Exception.Response.StatusCode
      if ($http -eq 401 -or $http -eq 403) { $codigo = "acesso_negado" }
    } catch {}
    return @{ ok = $false; codigo = $codigo }
  }
}

# Resposta do CRM: sem os cabecalhos que liberam leitura por outros sites.
function Responder-Crm($res, [int]$codigo, $objeto) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes(($objeto | ConvertTo-Json -Compress -Depth 5))
  $res.StatusCode = $codigo
  $res.ContentType = "application/json; charset=utf-8"
  $res.Headers["Cache-Control"] = "no-store"
  $res.ContentLength64 = $bytes.Length
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
  $res.OutputStream.Close()
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($porta)
try {
  $listener.Start()
} catch {
  Start-Process $porta
  Write-Host "O gerador ja esta aberto."
  exit 0
}

Start-Process $porta
Write-Host "Gerador no ar: $porta"
Write-Host "Deixe esta janela aberta. Feche para encerrar."

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $script:pedido = $req
  $res = $ctx.Response
  try {
    if ($req.HttpMethod -eq "OPTIONS") {
      Responder $res 204 $null ""
      continue
    }
    $caminho = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if ($req.HttpMethod -eq "POST" -and $caminho -eq "/pdf") {
      $ms = New-Object System.IO.MemoryStream
      $req.InputStream.CopyTo($ms)
      $dados = $ms.ToArray()
      if ($dados.Length -lt 100) {
        Texto $res 400 "A proposta chegou vazia."
        continue
      }
      if ($dados[0] -eq 60) {
        $pdf = Converter-Html $dados
      } else {
        $pdf = Converter-Pdf $dados
      }
      Responder $res 200 $pdf "application/pdf"
      continue
    }
    if ($req.HttpMethod -eq "GET" -and $caminho -eq "/crm") {
      # So a propria pagina do gerador pode consultar o CRM.
      $origem = [string]$req.Headers["Origin"]
      $sitio = [string]$req.Headers["Sec-Fetch-Site"]
      $minha = $porta.TrimEnd("/")
      if (($origem -and $origem -ne $minha) -or ($sitio -and $sitio -ne "same-origin")) {
        Responder-Crm $res 403 @{ ok = $false; codigo = "origem_recusada" }
        continue
      }
      $porNumero = [string]$req.QueryString["numero"]
      $porCnpj = [string]$req.QueryString["cnpj"]
      if ($porNumero) {
        Responder-Crm $res 200 (Crm-Buscar $porNumero)
      } elseif ($porCnpj) {
        Responder-Crm $res 200 (Crm-BuscarCnpj $porCnpj)
      } else {
        Responder-Crm $res 200 @{ ok = $false; codigo = "numero_invalido" }
      }
      continue
    }
    if ($req.HttpMethod -ne "GET") {
      Texto $res 405 "Metodo nao aceito."
      continue
    }
    if ($caminho -eq "/") { $caminho = "/index.html" }
    $rel = $caminho.TrimStart("/").Replace("/", "\")
    if ($rel -match "\.\.") {
      Texto $res 403 "Caminho recusado."
      continue
    }
    $arquivo = [System.IO.Path]::GetFullPath((Join-Path $root $rel))
    $raizCheia = [System.IO.Path]::GetFullPath($root)
    if (-not $arquivo.StartsWith($raizCheia, [System.StringComparison]::OrdinalIgnoreCase)) {
      Texto $res 403 "Caminho recusado."
      continue
    }
    if (-not (Test-Path -LiteralPath $arquivo)) {
      Texto $res 404 "Nao encontrado."
      continue
    }
    $ext = [System.IO.Path]::GetExtension($arquivo).ToLowerInvariant()
    if (-not $mime.ContainsKey($ext)) {
      Texto $res 403 "Tipo nao servido."
      continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($arquivo)
    Responder $res 200 $bytes $mime[$ext]
  } catch {
    try { Texto $res 500 ("Nao foi possivel gerar o PDF. " + $_.Exception.Message) } catch {}
  }
}
