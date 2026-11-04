$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$docker = (Get-Command docker -ErrorAction SilentlyContinue).Source
if (!$docker) { $docker = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' }
$env:PATH = (Split-Path $docker -Parent) + ';' + $env:PATH
$run = 'codyssey-' + (Get-Date -Format 'yyyyMMddHHmmss')
$web = "$run-web"; $mount = "$run-mount"; $vol = "$run-data"
$first = "$run-first"; $second = "$run-second"
function D {
  Write-Output ('$ docker ' + ($args -join ' '))
  $ErrorActionPreference = 'Continue'
  & $docker @args 2>&1 | ForEach-Object { "$_" }
  $result = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  if ($result -ne 0) { throw "docker failed: $args" }
}
function Probe($port, $marker) {
  $url = "http://127.0.0.1:$port/"
  Write-Output ('$ Invoke-WebRequest ' + $url)
  $response = $null
  for ($i=0;$i -lt 20;$i++) {
    try { $response = Invoke-WebRequest $url -UseBasicParsing; break } catch { Start-Sleep -Milliseconds 500 }
  }
  if (!$response -or !$response.Content.Contains($marker)) { throw "HTTP verification failed: $marker" }
  Write-Output "HTTP $($response.StatusCode)"
  Write-Output $response.Content
}
Start-Transcript -Path evidence/docker-verification.txt -Force
try {
  D --version
  D info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}}'
  D pull hello-world
  D run --rm hello-world
  D pull ubuntu:24.04
  D run --rm ubuntu:24.04 bash -lc 'set -eux; pwd; mkdir -p /tmp/practice; cd /tmp/practice; touch empty.txt .hidden; echo terminal-ok > original.txt; cp original.txt copy.txt; mv copy.txt renamed.txt; ls -la; cat renamed.txt; rm renamed.txt; mkdir permissions; touch permissions/file; chmod 600 permissions/file; chmod 700 permissions; stat -c %a:%n permissions permissions/file; chmod 644 permissions/file; chmod 755 permissions; stat -c %a:%n permissions permissions/file; ls -la'
  D run -d --name $first ubuntu:24.04 sleep infinity
  D exec $first bash -lc 'ls /; echo exec-session-finished'
  D inspect --format '{{.State.Running}}' $first
  D stop $first
  D ps -a --filter "name=$run"
  D rm $first
  D build -t codyssey-workspace:1.0 .
  D images codyssey-workspace
  D run -d --name $web -p 127.0.0.1:18080:80 codyssey-workspace:1.0
  Probe 18080 'workspace-v1'
  D port $web
  D logs $web
  D stats --no-stream $web
  $bindPath = (Join-Path (Get-Location) 'evidence/bind-site')
  New-Item -ItemType Directory -Force $bindPath | Out-Null
  Set-Content -LiteralPath (Join-Path $bindPath 'index.html') -Value 'bind-before' -Encoding utf8
  D run -d --name $mount -p 127.0.0.1:18081:80 --mount "type=bind,source=$bindPath,target=/usr/share/nginx/html,readonly" codyssey-workspace:1.0
  Probe 18081 'bind-before'
  Write-Output '$ Set-Content evidence/bind-site/index.html bind-after'
  Set-Content -LiteralPath (Join-Path $bindPath 'index.html') -Value 'bind-after' -Encoding utf8
  Probe 18081 'bind-after'
  D volume create $vol
  D run -d --name $first --mount "type=volume,source=$vol,target=/data" ubuntu:24.04 sleep infinity
  D exec $first bash -lc 'echo persistent-workspace > /data/proof.txt; cat /data/proof.txt'
  D rm -f $first
  D run -d --name $second --mount "type=volume,source=$vol,target=/data" ubuntu:24.04 sleep infinity
  D exec $second cat /data/proof.txt
  D volume inspect $vol --format 'Name={{.Name}} Driver={{.Driver}}'
  D ps -a --filter "name=$run"
  Write-Output 'PASS: all automated Docker checks completed.'
} finally {
  foreach ($name in @($mount,$first,$second)) { & $docker rm -f $name 2>$null | Out-Null }
  # Keep the web container for browser evidence; preserve the volume as evidence.
  Write-Output "Web container: $web; preserved volume: $vol"
  Stop-Transcript
}
