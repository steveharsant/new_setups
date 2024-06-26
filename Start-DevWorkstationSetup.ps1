# v1.2.0

# Check script is run as administrator
if (! ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544'))) {
    Write-Output 'Not runnging as administrator. Exiting'
    exit 1
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

refreshenv

# Install Applications
$packages = '7zip bitwarden conemu docker-desktop ferdium firefox git grammarly-for-windows grep lepton powershell-core powertoys python spotify tailscale vlc vscode'

choco install $packages -y

# Install and update to WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install ubuntu
wsl --install

# Install Ubuntu Mono fonts
Invoke-WebRequest `
    -Get `
    -Uri 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/UbuntuMono.zip' `
    -OutFile "$env:TEMP/UbuntuMono.zip"

Expand-Archive `
    -Path "$env:TEMP/UbuntuMono.zip" `
    -DestinationPath "$env:TEMP/UbuntuMono"

$fonts = Get-ChildItem `
    -Path "$env:TEMP/UbuntuMono\*" `
    -Name '*.ttf'

foreach ($font in $fonts) {
    Write-Host 'Installing font -' "$env:TEMP/UbuntuMono\$font"
    Copy-Item `
        -Path $font `
        -DestinationPath 'C:\Windows\Fonts'

    New-ItemProperty -Name $font `
        -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' `
        -PropertyType string `
        -Value $font
}

# Create common directories
$directories = @( '.ssh', 'applications', 'development' )
Foreach ($directory in $directories) {
    New-Item -ItemType Directory -Path "C:\Users\$env:USERNAME\$directory"
}

# Clone shell customisation repos
$repos = @( 'dotfiles', 'powershell_prompt' )
foreach ($repo in $repos) {
    git clone "https://github.com/steveharsant/$repo.git" "C:\Users\$env:USERNAME\development\$repo"
}

# Run install.ps1 script to setup customisation
& "C:\Users\$env:USERNAME\development\dotfiles\install.ps1"
