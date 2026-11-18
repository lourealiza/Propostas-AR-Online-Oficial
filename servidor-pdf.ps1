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
