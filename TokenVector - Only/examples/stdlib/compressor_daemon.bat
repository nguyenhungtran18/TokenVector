@echo off
:: compressor_daemon.bat - HTTP daemon cho Universal AI Context Compressor.
::
:: KHAC ban truoc: ban truoc dat bien %EXE% roi KHONG BAO GIO goi no - noi
:: dung duoc "nen" bang regex -replace cua PowerShell, tuc la KHONG he chay
:: engine TokenVector du nhan la ENGINE=TokenVector-*. Ban nay goi THAT
:: compress_cli.exe (bien dich tu compress_cli.tkv) cho moi request.
setlocal

set "DIR=%~dp0"
set "EXE=%DIR%compress_cli.exe"
set "IN=%DIR%_compress_in.txt"
set "OUT=%DIR%_compress_out.txt"
set "STATUS=C:\Users\Nguyen Hung\.gemini\antigravity\scratch\tokenvector_native_service.status"
set "PORT=8888"

if not exist "%EXE%" (
    echo [TokenVector] Thieu %EXE% - chay truoc: python tkv.py build "TokenVector - Only\examples\stdlib\compress_cli.tkv"
    exit /b 1
)

echo [TokenVector] Universal AI Context Compressor Daemon - port %PORT%
echo [TokenVector] Engine: %EXE%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$listener = New-Object System.Net.HttpListener; ^
    $listener.Prefixes.Add('http://localhost:%PORT%/'); ^
    $listener.Start(); ^
    Set-Content -Encoding utf8 -Path '%STATUS%' -Value @('STATUS=OK','ENGINE=TokenVector-compress_cli.exe','PORT=%PORT%','PYTHON_ALLOWED=FALSE','MODE=HTTP_DAEMON',\"PID=$PID\"); ^
    Write-Host '[TokenVector] Listening on port %PORT%'; ^
    try { ^
      while ($true) { ^
        $ctx = $listener.GetContext(); ^
        $req = $ctx.Request; $resp = $ctx.Response; ^
        $body = ''; ^
        if ($req.HasEntityBody) { $body = (New-Object System.IO.StreamReader($req.InputStream)).ReadToEnd() } ^
        if ($req.Url.AbsolutePath -eq '/compress') { ^
            [System.IO.File]::WriteAllText('%IN%', $body); ^
            $null = ^& '%EXE%'; ^
            $result = [System.IO.File]::ReadAllText('%OUT%'); ^
            $resp.ContentType = 'text/plain; charset=utf-8'; ^
        } else { ^
            $result = '{\"status\":\"ok\",\"engine\":\"TokenVector-compress_cli.exe\",\"port\":%PORT%,\"python\":false}'; ^
            $resp.ContentType = 'application/json; charset=utf-8'; ^
        } ^
        $outBytes = [System.Text.Encoding]::UTF8.GetBytes($result); ^
        $resp.ContentLength64 = $outBytes.Length; ^
        $resp.OutputStream.Write($outBytes, 0, $outBytes.Length); ^
        $resp.Close(); ^
      } ^
    } finally { $listener.Stop(); Remove-Item -Force '%STATUS%' -ErrorAction SilentlyContinue }"

echo [TokenVector] Daemon stopped.
