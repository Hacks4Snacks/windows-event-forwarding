###########################################
#
# Windows Event Forwarding GPO Script
#
# To execute this script:
# 1) Open powershell window as administrator
# 2) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"
# 3) Execute the script by running ".\gpo.ps1" in the same folder as the GPO backup folder
#
# Version: 0.1.0
# Last modification: 2019-10-23
###########################################


Write-Host "[+] Checking if script is running as administrator."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "`t[ERR] Please run this script as administrator`n" -ForegroundColor Red
  Read-Host  "Press any key to continue"
  exit
}

Write-Host "[+] Checking if Group Policy Module is installed."
if (Get-Module -ListAvailable -Name GroupPolicy) {
  Write-Host "[*] Group Policy Module exists" -ForegroundColor Green
} 
else {
  Write-Host "`t[ERR] Group Policy Module does not exist, please import the GroupPolicy module or manually import GPO file`n" -ForegroundColor Red
  Read-Host "Press any key to continue"
  exit
}

Write-Host "[+] Checking to make sure this is a Domain Controller" 
if ((([System.Environment]::OSVersion.Platform.value__ -ne 2))){
    Write-Host "`t[ERR] Please run this script on a Domain Controller" -ForegroundColor Red
    Read-Host  "Press any key to continue"
    exit
}
else
  {
    Write-Host "`t[+] Continuing.." -ForegroundColor Green
}

$path = Get-location
$response_gpo = (Read-Host -Prompt "[+] Pre-Check is complete. Would you like to import the GPO? Y/N").ToUpper()
if ($response_gpo -ne "Y") {
    Write-Host "[*] Exiting..." -ForegroundColor Yellow
    exit
}
else {
    Write-Host "`t[+] Importing GPO.." -ForegroundColor Green
    import-gpo -backupgponame "Event_Collection" -Path $path -Targetname "Event Collection" -createifneeded
    Write-Host "[*] GPO Import is complete. Please be sure to change the hostname of the target Subscription Manager under Computer Configuation\Policies\Administrative Templates\Windows Components\EventForwarding as well as the status of the GPO to 'Enabled', link, and enforce it where applicable." -ForegroundColor Yellow
}
