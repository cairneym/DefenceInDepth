# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Software if it isn't already installed
$AppPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe" 
$IsInstalled = Test-Path $AppPath -PathType Leaf

if (-not($IsInstalled)) {
    choco install sql-server-management-studio -y
} 
