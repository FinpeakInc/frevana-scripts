param(
    [string]$PythonVersion = '3.12.5',
    [string]$BuildDate = '20240814',
    [string]$FREVANA_HOME = "$env:USERPROFILE\.frevana",
    [switch]$Verbose
)

function Write-JsonResult($success, $message, $pythonVersion, $pipVersion, $installPath) {
    $obj = [pscustomobject]@{
        success = $success
        message = $message
        python_version = $pythonVersion
        pip_version = $pipVersion
        install_path = $installPath
    }
    $obj | ConvertTo-Json -Depth 4
}

try {
    if ($Verbose) { Write-Host "FREVANA_HOME: $FREVANA_HOME" }

    # Ensure frevana home and bin exist
    $binDir = Join-Path $FREVANA_HOME 'bin'
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null

    # Detect architecture - prefer x64 for ARM64 Windows since ARM64 builds may not be available
    # x64 Python works on ARM64 Windows via emulation
    $procArch = $env:PROCESSOR_ARCHITECTURE
    $archList = @()
    switch ($procArch) {
        'AMD64' { $archList = @('x86_64') }
        'ARM64' { $archList = @('x86_64', 'aarch64') }  # Try x64 first for better compatibility
        default { $archList = @('x86_64') }
    }

    $variant = 'install_only'
    $ext = 'tar.gz'
    $baseUrl = 'https://github.com/astral-sh/python-build-standalone/releases/download'

    # Mirror defaults: allow environment override, otherwise use frevana static mirror
    if (-not $env:FREVANA_PYTHON_MIRROR) { $env:FREVANA_PYTHON_MIRROR = 'https://static.frevana.com/installer/python' }
    if (-not $env:PYTHON_MIRROR) { $env:PYTHON_MIRROR = 'https://static.frevana.com/installer/python' }
    $mirrorBase = $env:FREVANA_PYTHON_MIRROR
    if (-not $mirrorBase -and $env:PYTHON_MIRROR) { $mirrorBase = $env:PYTHON_MIRROR }

    $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    # Try each architecture until one succeeds
    $downloaded = $false
    $downloadPath = ''
    foreach ($arch in $archList) {
        $platform = "$arch-pc-windows-msvc-shared"
        $filename = "cpython-$PythonVersion+$BuildDate-$platform-$variant.$ext"
        $url = "$baseUrl/$BuildDate/$filename"

        # Prepare mirror URL (encode '+' as %2B for mirror requests)
        $encodedFilename = $filename -replace '\+','%2B'
        $mirrorUrl = $null
        if ($mirrorBase) {
            $m = $mirrorBase.TrimEnd('/')
            $mirrorUrl = "$m/$BuildDate/$encodedFilename"
        }

        # Candidate URLs: primary first, then mirror
        $candidateUrls = @($url)
        if ($mirrorUrl) { $candidateUrls += $mirrorUrl }

        foreach ($candidate in $candidateUrls) {
            if ($Verbose) { Write-Host "Trying to download: $candidate" }
            $downloadPath = Join-Path $tmp (Split-Path -Leaf $candidate)

            # Download with retries
            $maxRetries = 3
            $attempt = 0
            while ($attempt -lt $maxRetries -and -not $downloaded) {
                try {
                    Invoke-WebRequest -Uri $candidate -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
                    $downloaded = $true
                    if ($Verbose) { Write-Host "Successfully downloaded from $candidate" }
                    break
                } catch {
                    $attempt++
                    if ($attempt -lt $maxRetries) { Start-Sleep -Seconds 2 }
                }
            }

            if ($downloaded) { break }
        }

        if ($downloaded) { break }
    }

    if (-not $downloaded) {
        throw "Failed to download Python for any supported architecture after trying: $($archList -join ', ')"
    }

    # Extract using tar command (Windows 10+ has tar built-in)
    $extractDir = Join-Path $tmp 'extract'
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    
    # Use tar to extract .tar.gz
    $tarExitCode = (Start-Process -FilePath 'tar' -ArgumentList '-xzf', "`"$downloadPath`"", '-C', "`"$extractDir`"" -Wait -PassThru -NoNewWindow).ExitCode
    if ($tarExitCode -ne 0) { throw "Failed to extract tar.gz file (exit code: $tarExitCode)" }

    # Find the extracted folder
    $firstDir = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $firstDir) { throw 'Extraction failed: no directory found inside archive' }

    $targetPythonDir = Join-Path $FREVANA_HOME 'python'
    if (Test-Path $targetPythonDir) { Remove-Item -Recurse -Force $targetPythonDir }
    Move-Item -Path $firstDir.FullName -Destination $targetPythonDir

    # Locate python.exe in the extracted directory
    $pythonExe = Get-ChildItem -Path $targetPythonDir -Filter 'python.exe' -File | Select-Object -First 1
    if (-not $pythonExe) { throw 'python.exe not found in extracted content' }

    # Create wrapper scripts using UTF8 without BOM to support CJK characters
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    
    $pythonCmd = Join-Path $binDir 'python.cmd'
    [System.IO.File]::WriteAllText($pythonCmd, "@echo off`r`nchcp 65001 >nul`r`n`"$($pythonExe.FullName)`" %*`r`n", $utf8NoBom)

    $pythonBat = Join-Path $binDir 'python.bat'
    [System.IO.File]::WriteAllText($pythonBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($pythonExe.FullName)`" %*`r`n", $utf8NoBom)

    # Create pip wrapper
    $pipCmd = Join-Path $binDir 'pip.cmd'
    [System.IO.File]::WriteAllText($pipCmd, "@echo off`r`nchcp 65001 >nul`r`n`"$($pythonExe.FullName)`" -m pip %*`r`n", $utf8NoBom)

    $pipBat = Join-Path $binDir 'pip.bat'
    [System.IO.File]::WriteAllText($pipBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($pythonExe.FullName)`" -m pip %*`r`n", $utf8NoBom)

    # Output success and versions
    $pythonVersionOut = & $pythonExe.FullName --version 2>&1
    $pipVersionOut = & $pythonExe.FullName -m pip --version 2>&1

    Write-JsonResult $true 'Python installed' $pythonVersionOut $pipVersionOut $FREVANA_HOME

} catch {
    Write-JsonResult $false $_.Exception.Message '' '' $FREVANA_HOME
    exit 1
} finally {
    # cleanup temp
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}
