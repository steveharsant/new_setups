# v1.0.0

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
$packages = 'firefox bitwarden conemu docker git grep powertoys vlc vscode ferdium spotify python 7zip tailscale powershell-core'

choco install $packages -y

# Install and update to WSL2
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Install alpine linux distro
choco install -y
