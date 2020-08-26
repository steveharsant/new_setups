# Check script is run as administrator
if (! ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))) {
    Write-Output 'Not runnging as administrator. Exiting'
    exit 1
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

refreshenv

# Install Applications
$packages = 'bitwarden', 'conemu', 'Cura', 'docker', 'egnyte-connect', 'Firefox', 'git', 'grep', 'heroku-cli', `
            'microsoft-teams', 'nodejs', 'notion', 'powertoys', 'vlc', 'vscode', 'teamviewer', 'terraform', 'zoom'

foreach ($package in $packages) {
    choco install $package -y
}

# Install and update to WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install alpine linux distro
choco install wsl-alpine -y
