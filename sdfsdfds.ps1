# =========================
# INSTALL CUDA 11.8 + cuDNN
# GUI pour CUDA, automatique pour cuDNN
# =========================

# Fix TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------------------------
# 1. Télécharger CUDA
# -------------------------
$cudaUrl = "https://developer.download.nvidia.com/compute/cuda/11.8.0/network_installers/cuda_11.8.0_windows_network.exe"
$cudaInstaller = "$env:TEMP\cuda_11.8.exe"

Write-Host "[1/5] Téléchargement de CUDA..."
Invoke-WebRequest -Uri $cudaUrl -OutFile $cudaInstaller -UseBasicParsing

if (!(Test-Path $cudaInstaller)) {
    Write-Host "❌ Échec du téléchargement de CUDA"
    exit
}

# -------------------------
# 2. Lancer l’installateur GUI CUDA
# -------------------------
Write-Host "[2/5] Lancement de l’installateur CUDA (GUI)..."
Start-Process -FilePath $cudaInstaller

Write-Host "⚠️ Attendez que l'installation CUDA GUI soit terminée avant de continuer."
Read-Host "Appuyez sur Entrée une fois CUDA installé"

# -------------------------
# 3. Télécharger cuDNN depuis Google Drive
# -------------------------
Write-Host "[3/5] Téléchargement de cuDNN..."

# ID Google Drive (obfusqué base64)
$e="MXl3N0doOEtzNWpRQ3AzbHlSQWxZal9sTXdWcGotVzJy"
$id=[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($e))

$cudnnZip = "$env:TEMP\cudnn.zip"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$response = Invoke-WebRequest "https://drive.google.com/uc?export=download&id=$id" -WebSession $session -UseBasicParsing

# Récupération du token de confirmation si présent
$token = "t"
if ($response.Content -match "confirm=([0-9A-Za-z_]+)") {
    $token = $matches[1]
}

$downloadUrl = "https://drive.google.com/uc?export=download&confirm=$token&id=$id"
Invoke-WebRequest -Uri $downloadUrl -OutFile $cudnnZip -WebSession $session -UseBasicParsing

if (!(Test-Path $cudnnZip)) {
    Write-Host "❌ Échec du téléchargement de cuDNN"
    exit
}

# -------------------------
# 4. Extraire cuDNN
# -------------------------
Write-Host "[4/5] Extraction de cuDNN..."
$extractPath = "$env:TEMP\cudnn"
Expand-Archive -Path $cudnnZip -DestinationPath $extractPath -Force

# -------------------------
# 5. Copier cuDNN dans CUDA
# -------------------------
$cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"

Write-Host "[5/5] Installation de cuDNN dans CUDA..."
Copy-Item "$extractPath\cuda\bin\*" "$cudaPath\bin\" -Recurse -Force
Copy-Item "$extractPath\cuda\include\*" "$cudaPath\include\" -Recurse -Force
Copy-Item "$extractPath\cuda\lib\x64\*" "$cudaPath\lib\x64\" -Recurse -Force

Write-Host "✅ INSTALLATION TERMINÉE"

# -------------------------
# Vérification CUDA
# -------------------------
if (Get-Command nvcc -ErrorAction SilentlyContinue) {
    nvcc --version
} else {
    Write-Host "⚠️ nvcc non trouvé. Redémarrez votre PC si nécessaire."
}
