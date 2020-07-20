# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Software if it isn't already installed
$AppPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe" 
$IsAppInstalled = Test-Path $AppPath -PathType Leaf

if (-not($IsAppInstalled)) {
    choco install sql-server-management-studio -y
} 

$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$IsBrowserInstalled = Test-Path $BrowserPath -PathType Leaf

if (-not($IsBrowserInstalled)) {
    choco install microsoft-edge -y
} 
