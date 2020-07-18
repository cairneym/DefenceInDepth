# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; 
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));

# Install Software if it isn't already installed
$AppPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe" 
$IsInstalled = Test-Path $AppPath -PathType Leaf

if ($IsInstalled) {
    choco install sql-server-management-studio -y;
    exit 0
} else {
    exit 1
}
 
