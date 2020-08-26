# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

refreshenv

$packages = @['bitwarden', 'conemu', 'Cura', 'egnyte-connect', 'Firefox', 'git', 'heroku-cli', 'microsoft-teams', 'nodejs', 'powertoys', 'vlc', 'vscode', 'teamviewer', 'zoom']

for