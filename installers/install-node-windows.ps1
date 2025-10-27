param(
    [string]$NodeVersion = 'v22.18.0',
    [string]$FREVANA_HOME = "$env:USERPROFILE\.frevana",
    [switch]$Verbose
)

function Write-JsonResult($success, $message, $nodeVersion, $npmVersion, $pnpmVersion, $installPath) {
    $obj = [pscustomobject]@{
        success = $success
        message = $message
        node_version = $nodeVersion
        npm_version = $npmVersion
        pnpm_version = $pnpmVersion
        install_path = $installPath
    }
    $obj | ConvertTo-Json -Depth 4
}

function Write-VerboseLog($message) {
    if ($Verbose) { Write-Host $message }
}

try {
    Write-VerboseLog "FREVANA_HOME: $FREVANA_HOME"

    # Ensure frevana home and bin exist
    $binDir = Join-Path $FREVANA_HOME 'bin'
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null

    # Detect architecture
    $procArch = $env:PROCESSOR_ARCHITECTURE
    $arch = switch ($procArch) {
        'AMD64' { 'x64' }
        'ARM64' { 'arm64' }
        default { 'x64' }
    }

    Write-VerboseLog "Detected architecture: $arch"
    Write-VerboseLog "Installing Node.js $NodeVersion for Windows..."

    # Construct download URL
    $platform = "win-$arch"
    $filename = "node-$NodeVersion-$platform.zip"
    $baseUrl = 'https://nodejs.org/dist'
    $url = "$baseUrl/$NodeVersion/$filename"

    Write-VerboseLog "Download URL: $url"

    # Create temp directory
    $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null

    # Download with retries
    $downloadPath = Join-Path $tmp $filename
    $maxRetries = 3
    $attempt = 0
    $downloaded = $false

    while ($attempt -lt $maxRetries -and -not $downloaded) {
        try {
            Write-VerboseLog "Download attempt $($attempt + 1) of $maxRetries..."
            Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing -ErrorAction Stop
            $downloaded = $true
            Write-VerboseLog "Successfully downloaded Node.js"
        } catch {
            $attempt++
            if ($attempt -lt $maxRetries) {
                Write-VerboseLog "Download failed, retrying..."
                Start-Sleep -Seconds 2
            }
        }
    }

    if (-not $downloaded) {
        throw "Failed to download Node.js after $maxRetries attempts"
    }

    # Extract using Expand-Archive
    Write-VerboseLog "Extracting Node.js..."
    $extractDir = Join-Path $tmp 'extract'
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    Expand-Archive -Path $downloadPath -DestinationPath $extractDir -Force

    # Find the extracted folder
    $extractedFolder = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
    if (-not $extractedFolder) { throw 'Extraction failed: no directory found inside archive' }

    # Move to target directory
    $targetNodeDir = Join-Path $FREVANA_HOME 'node'
    if (Test-Path $targetNodeDir) {
        Write-VerboseLog "Removing old Node.js installation..."
        Remove-Item -Recurse -Force $targetNodeDir
    }
    Move-Item -Path $extractedFolder.FullName -Destination $targetNodeDir

    # Locate node.exe in the extracted directory
    $nodeExe = Get-ChildItem -Path $targetNodeDir -Filter 'node.exe' -Recurse -File | Select-Object -First 1
    if (-not $nodeExe) { throw 'node.exe not found in extracted content' }

    $nodeBinDir = $nodeExe.Directory.FullName

    # Create symbolic links / wrapper scripts for Node.js tools
    Write-VerboseLog "Creating wrapper scripts..."
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

    # Node wrapper
    $nodeCmd = Join-Path $binDir 'node.cmd'
    [System.IO.File]::WriteAllText($nodeCmd, "@echo off`r`nchcp 65001 >nul`r`n`"$($nodeExe.FullName)`" %*`r`n", $utf8NoBom)

    $nodeBat = Join-Path $binDir 'node.bat'
    [System.IO.File]::WriteAllText($nodeBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($nodeExe.FullName)`" %*`r`n", $utf8NoBom)

    # npm wrapper
    $npmCmd = Get-ChildItem -Path $nodeBinDir -Filter 'npm.cmd' -File | Select-Object -First 1
    if ($npmCmd) {
        $npmCmdTarget = Join-Path $binDir 'npm.cmd'
        [System.IO.File]::WriteAllText($npmCmdTarget, "@echo off`r`nchcp 65001 >nul`r`n`"$($npmCmd.FullName)`" %*`r`n", $utf8NoBom)

        $npmBat = Join-Path $binDir 'npm.bat'
        [System.IO.File]::WriteAllText($npmBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($npmCmd.FullName)`" %*`r`n", $utf8NoBom)
    }

    # npx wrapper
    $npxCmd = Get-ChildItem -Path $nodeBinDir -Filter 'npx.cmd' -File | Select-Object -First 1
    if ($npxCmd) {
        $npxCmdTarget = Join-Path $binDir 'npx.cmd'
        [System.IO.File]::WriteAllText($npxCmdTarget, "@echo off`r`nchcp 65001 >nul`r`n`"$($npxCmd.FullName)`" %*`r`n", $utf8NoBom)

        $npxBat = Join-Path $binDir 'npx.bat'
        [System.IO.File]::WriteAllText($npxBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($npxCmd.FullName)`" %*`r`n", $utf8NoBom)
    }

    # corepack wrapper
    $corepackCmd = Get-ChildItem -Path $nodeBinDir -Filter 'corepack.cmd' -File | Select-Object -First 1
    if ($corepackCmd) {
        $corepackCmdTarget = Join-Path $binDir 'corepack.cmd'
        [System.IO.File]::WriteAllText($corepackCmdTarget, "@echo off`r`nchcp 65001 >nul`r`n`"$($corepackCmd.FullName)`" %*`r`n", $utf8NoBom)

        $corepackBat = Join-Path $binDir 'corepack.bat'
        [System.IO.File]::WriteAllText($corepackBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($corepackCmd.FullName)`" %*`r`n", $utf8NoBom)
    }

    # Verify installation
    Write-VerboseLog "Verifying Node.js installation..."
    $nodeVersionOut = (& $nodeExe.FullName --version 2>&1 | Select-Object -Last 1).ToString().Trim()
    $npmVersionOut = ''
    $pnpmVersionOut = ''

    if ($npmCmd) {
        $npmVersionOut = (& $npmCmd.FullName --version 2>&1 | Where-Object { $_ -match '^\d+\.\d+\.\d+' } | Select-Object -Last 1).ToString().Trim()
        Write-VerboseLog "Node.js version: $nodeVersionOut"
        Write-VerboseLog "npm version: $npmVersionOut"

        # Install pnpm
        Write-VerboseLog "Installing pnpm..."
        try {
            $env:PATH = "$binDir;$env:PATH"
            & $npmCmd.FullName install -g pnpm 2>&1 | Out-Null

            # Create pnpm wrapper
            $pnpmJs = Get-ChildItem -Path $targetNodeDir -Filter 'pnpm.cjs' -Recurse -File | Select-Object -First 1
            if (-not $pnpmJs) {
                $pnpmJs = Get-ChildItem -Path $targetNodeDir -Filter 'pnpm.js' -Recurse -File | Select-Object -First 1
            }

            if ($pnpmJs) {
                $pnpmCmd = Join-Path $binDir 'pnpm.cmd'
                [System.IO.File]::WriteAllText($pnpmCmd, "@echo off`r`nchcp 65001 >nul`r`n`"$($nodeExe.FullName)`" `"$($pnpmJs.FullName)`" %*`r`n", $utf8NoBom)

                $pnpmBat = Join-Path $binDir 'pnpm.bat'
                [System.IO.File]::WriteAllText($pnpmBat, "@echo off`r`nchcp 65001 >nul`r`n`"$($nodeExe.FullName)`" `"$($pnpmJs.FullName)`" %*`r`n", $utf8NoBom)

                # Get pnpm version
                $pnpmVersionOut = (& $nodeExe.FullName $pnpmJs.FullName --version 2>&1 | Where-Object { $_ -match '^\d+\.\d+\.\d+' } | Select-Object -Last 1).ToString().Trim()
                Write-VerboseLog "pnpm version: $pnpmVersionOut"
            } else {
                Write-VerboseLog "Warning: pnpm binary not found at expected location"
            }
        } catch {
            Write-VerboseLog "Warning: pnpm installation failed, but Node.js is installed successfully"
        }
    }

    Write-JsonResult $true 'Node.js installed successfully' $nodeVersionOut $npmVersionOut $pnpmVersionOut $FREVANA_HOME

} catch {
    Write-JsonResult $false $_.Exception.Message '' '' '' $FREVANA_HOME
    exit 1
} finally {
    # Cleanup temp
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}
