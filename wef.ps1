<#

.SYNOPSIS
Windows Event Forwarding Collection Server Configuration Script.

.DESCRIPTION
This script is designed to run on a "to be" Windows Event Collection Server to assist
in automating the required configurations. The NXLog msi, conf, and patterndb file must 
be in the same directory as the script in order for it to function properly.

To execute this script:
1) Open powershell window as administrator
2) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"

.EXAMPLE
PS > .\wef.ps1
Interactive prompts will appear in the terminal.

.LINK

#>

# Check to make sure script is running as admin
Write-Verbose "[+] Checking if script is running as administrator.."
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Verbose "`t[ERR] Please run this script as administrator`n" -ForegroundColor Red
    Read-Host  "Press any key to continue"
  exit
}

# Check to make sure host has been updated
Write-Verbose "[+] Checking if host has been configured with updates"
if (-Not (get-hotfix | where { (Get-Date($_.InstalledOn)) -gt (get-date).adddays(-30) })) {
    Write-Verbose "`t[ERR] This machine has not been updated in the last 30 days, please run Windows Updates to continue`n" -ForegroundColor Red
    Read-Host  "Press any key to continue"
    exit
}
else
{
	Write-Verbose "`t[*] Updates appear to be in order" -ForegroundColor Green
}

#Check to make sure host has enough disk space
Write-Verbose "[+] Checking if host has enough disk space"
$disk = Get-PSDrive C
Start-Sleep -Seconds 1
if (-Not (($disk.used + $disk.free)/1GB -gt 58.8)){
    Write-Verbose "`t[ERR] We recommend a minimum 60 GB hard drive, please increase hard drive space to continue`n" -ForegroundColor Red
    Read-Host "Press any key to continue"
    exit
}
else
{
    Write-Verbose "`t> 60 GB hard drive. looks good" -ForegroundColor Green
}

# Prompt user to remind them to take a snapshot

$response = (Read-Host -Prompt "[-] Do you need to take a snapshot before continuing? Y/N").ToUpper()
if ($response -ne "N") {
    Write-Verbose "[*] Exiting.." -ForegroundColor Red
    exit
}
Write-Verbose "`t[*] Continuing.." -ForegroundColor Green

#Setting WinRM Service to automatic start and running quickconfig
Set-Service -Name winrm -StartupType Automatic
winrm quickconfig -quiet


# It is recommended that the event log files are moved to a seperate hard drive, so the user will be provided the option
# TODO: Staging for creating custom location for EVTX logs
#$log_location_option = (Read-Host -Prompt "[-] Would you like to store the collected events in a non-default location? Y/N").ToUpper()
#if ($log_location_option -eq "Y") {
#    $log_folder_path = (Read-Host -Prompt "[-] Please enter the desired folder path.")
    # Add trailing '\' if not included in the input
#    if ($log_folder_path -notmatch '.+?\\$') {
#        $log_folder_path += '\'
#    }
#    write-Verbose "[*] Verifying log folder path: $log_folder_path" -ForegroundColor Yellow
#    if ((Test-Path $log_folder_path) -And (Test-Path $log_folder_path -PathType Container)){
#        Write-Verbose "[*] Desired log folder path is valid." -foregroundcolor Green 
#    }
#    else {
#        Write-Verbose "[*] Log folder path not found."  -foregroundcolor Red
#        $create_path = (Read-Host -Prompt "[-] Would you like to create the path now? Y/N").ToUpper()
#        if ($create_path -eq "N"){
#            "[*] Aborting operation."
#            Break
#        } 
#        else {
#            New-Item -ItemType "directory" -Path $log_folder_path
#            Write-Verbose "[*] Log folder path created."  -foregroundcolor Green
#        }
#    }
#}
#else {
#    write-Verbose "Event log files will be kept in the default location C:\Windows\System32\winevt\Logs\" -foregroundcolor Yellow
#}
#}

<#
Set the size of the forwarded events log to 2GB, as all logs are being sent to the sensor.
This size can be set to whatever is desired, but remember the main performance bottleneck of WEF is the log size - there must be enough memory to hold the log +5GB or so for normal OS functions
so if had a reason to make this 10GB of log, you'll need roughly 15GB of RAM allocated to the host.
#>

#10GB
wevtutil sl forwardedevents /ms:10485760

#Running quickconfig for subscription service
wecutil qc -quiet

#If you need to export any existing subscriptions, or want to export a subscription made via the gui to get SDDLs of domains
#wecutil gs "%subscriptionname%" /f:xml >>"C:\Temp\%subscriptionname%.xml"

<#
This is where we actually import the Windows Event Collector subscriptions, i.e. the events we're going to collect.
MtdrCore.xml = Collects all Security and PowerShell events.
InterestingAccounts.xml =
MalwareEvents.xml =
#>

#Import the desired subscriptions 

#$response_subs = (Read-Host -Prompt "[+] Would you like to autoload the included subscriptions? Y/N").ToUpper()
#if ($response_subs -ne "N") {
#    Write-Verbose "[*] Loading configurations. Be sure to change the Source Computer Groups" -ForegroundColor Green
    #wecutil cs "InterestingAccounts.xml"
    #wecutil cs "MalwareEvents.xml"
#    wecutil cs "mtdrcore.xml"
#    Write-Verbose "[*] Done. Be sure to change the Source Computer Groups" -ForegroundColor Yellow
#}
#else {
#    Write-Verbose "`t[*] Continuing.." -ForegroundColor Green
#}


#Set the Windows Event Collector Service to start type automatic, it's automatic with delayed start by default, which is fine as that lets the dependencies churn in. 

Set-Service -Name Wecsvc -StartupType "Automatic" *>$null

<#
In the default configuration of Windows Server 2016, a single svchost process runs both WinRM and WecSvc. Because the process has access, both services function correctly. 
However, if the configuration is changed so that the services run on separate host processes, WecSvc no longer has access and event forwarding no longer functions. So the commands
below are required to reinstate the appropriate permissions. These may not be necessary to run, however we are going to run them just incase.
#>

Write-Verbose "[+] Checking to make sure Operating System is compatible." 
  if ((([System.Environment]::OSVersion.Version.Major -eq 10))){
      $port=5985
      $acl="D:(A;;GX;;;S-1-5-80-569256582-2953403351-2909559716-1301513147-412116970)(A;;GX;;;S-1-5-80-4059739203-877974739-1245631912-527174227-2996563517)"
      Write-Verbose "`t[+] $((Get-WmiObject -class Win32_OperatingSystem).Caption) is supported, just need to make a quick aqjustment to the URL ACL." -ForegroundColor Yellow
      & netsh http delete urlacl url=http://+:$port/wsman *>$null
      & netsh http add urlacl url=http://+:$port/wsman sddl=$acl *>$null
  }
  else
  {
    Write-Verbose "`t[+] $((Get-WmiObject -class Win32_OperatingSystem).Caption) supported no changes needed." -ForegroundColor Green
  }

  # Install NXLog, Modify sensor IP in the configuration, and copy the patterndb file to the conf dir

  $response_nxlog = (Read-Host -Prompt "[*] Would you like to install NXLog now? Y/N").ToUpper()
  $installdir = "C:\Program Files (x86)\nxlog"
  $path = Get-location
  if ($response_nxlog -ne "Y") {
      Write-Verbose "`t[*] Continuing. Be advised, NXLog must be installed to send logs to the sensor" -ForegroundColor Yellow
  }
  else {
      Write-Verbose "[*] What is the IP of the Sensor? "
      $response_ip = Read-Host
      Write-Verbose "`t[+] Installing NXLog" -ForegroundColor Green
      & msiexec.exe /i "nxlog-ce-2.10.2150.msi" /quiet
      Start-Sleep 20
      Rename-Item -Path "$installdir\conf\nxlog.conf" -NewName "nxlog.conf.orig"
      Start-Sleep 2
      ((Get-Content -path "$path\nxlog.conf" -Raw) -replace 'SENSORIP', "$response_ip") | Set-Content -Path "$installdir\conf\nxlog.conf"
      Copy-Item -Path "$path\patterndb.xml" -Destination "$installdir\conf"
      Set-Service -Name nxlog -StartupType "Automatic" *>$null
      Start-Service -Name nxlog
      Write-Verbose "[*] NXLog install is complete." -ForegroundColor Green
  }

<#
It is a good idea to go ahead and reboot now.
#>

$response_reboot = (Read-Host -Prompt "[+] Configuration is complete. Would you like to reboot the machine? Y/N").ToUpper()
if ($response_reboot -ne "Y") {
    Write-Verbose "[*] Please reboot when it is convenient. Exiting..." -ForegroundColor Yellow
    exit
}
else {
    Write-Verbose "`tRebooting now." -ForegroundColor Green
    Restart-Computer
}
