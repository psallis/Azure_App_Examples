write-host "
  _____      _                        _____                 _          
 |  __ \    | |                      / ____|               (_)         
 | |__) |___| | ___  __ _ ___  ___  | (___   ___ _ ____   ___  ___ ___ 
 |  _  // _ \ |/ _ \/ _` / __|/ _ \  \___ \ / _ \ '__\ \ / / |/ __/ _ \
 | | \ \  __/ |  __/ (_| \__ \  __/  ____) |  __/ |   \ V /| | (_|  __/
 |_|  \_\___|_|\___|\__,_|___/\___| |_____/ \___|_|    \_/ |_|\___\___|
"                                                                       
# Wait 3 seconds
    Start-Sleep -s 3
#USE TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"
$ProgressPreference= "SilentlyContinue"
#Azure Subscription ID
$SubscriptionId ="XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
$DeployScript ="Deploy"

#Expected build no for release
$Expected_BuildNo = read-host "Please enter your expected Build number"

#Check expected build No. with dev slots
$web_client = new-object system.net.webclient
#Capture UK Dev Slot Build No
$UK_South_Dev_Build_Info = $web_client.DownloadString("https://[URL_FOR_BUILD_No]")
#Capture US Dev Slot Build No
$US_South_Dev_Build_Info = $web_client.DownloadString("https://[URL_FOR_BUILD_No]")

#If statement to compare UK and US Builds.Then final check to compare with expected build.
if( $UK_South_Dev_Build_Info.Contains($US_South_Dev_Build_Info) -and $US_South_Dev_Build_Info.Contains($Expected_BuildNo)) 
{ write-host "Expected Build No.$Expected_BuildNo Matches UK and US Dev Builds.
UK Dev Slot:$UK_South_Dev_Build_Info
US Dev Slot:$US_South_Dev_Build_Info"} 
ELSE { write-host "***Build No. $Expected_BuildNo is NOT OK, Found
UK Dev Slot:$UK_South_Dev_Build_Info
US Dev Slot:$US_South_Dev_Build_Info" | Pause}


#UK South Variables
$UKSouthAppSlotName = "[App_Name]"
$UKSouthAppSlot = "[App_Slot_Name]"
$UKSouthResourceGroupName = "[Resoruce_Group]"
$UKSouthURL = "https://[URL_CHECK_STATUS]" #Endpoint of your service that can be used to check your service
$UKSouthWebClient = new-object system.net.webclient

#US South Variables
$USSouthAppSlotName = "[App_Name]"
$USSouthAppSlot = "[App_Slot_Name]"
$USSouthResourceGroupName = "[Resoruce_Group]"
$USSouthURL = "https://[URL_CHECK_STATUS]" #Endpoint of your service that can be used to check your service
$USSouthWebClient = new-object system.net.webclient

#Login to Azure
Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId "$SubscriptionId"

#UK Region---------------------------------------------------------------------------------------------------------------------------------------------------------------
#Swap UK South
Write-Host "$UKSouthAppSlotName Swap Requested"
    Switch-AzureRmWebAppSlot -SourceSlotName $UKSouthAppSlot -DestinationSlotName "production" -ResourceGroupName $UKSouthResourceGroupName -Name $UKSouthAppSlotName
    Write-Host "Wait 10 Seconds"
    # Wait 10 seconds for the service to start.
    Start-Sleep -s 10
    # First we create the request.
    $HTTP_Request = [System.Net.WebRequest]::Create($UKSouthURL)
    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()
    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    If ($HTTP_Status -eq 200) { 
        Write-Host "Site is OK! $UKSouthAppSlotName"
        # Finally, we clean up the http request by closing it.
        $HTTP_Response.Close()
        #Check Production Build No
        $UKSouthBuildInfo =$UKSouthWebClient.DownloadString("https://[URL_FOR_BUILD_No]")
        Write-Host "Checking latest release build No is $Expected_BuildNo"
        If($UKSouthBuildInfo.contains($Expected_BuildNo)){
            write-host "Build No. is OK, Found $UKSouthBuildInfo" } 
            Else { Write-Host "***Build No. is NOT OK, Found $UKSouthBuildInfo***" | Pause}
            }
        Else {
        Write-Host "The site may be down, please check! $UKSouthAppSlotName" | pause}

#Post to Slack
Set-StrictMode -Version Latest
Write-Host "Posting to slack"

	$payload = @{
	"channel" = "#[SLACK_Channel]";
	"icon_emoji" = ":zap:";
	"text" = "*$UKSouthAppSlotName and $UKWestAppSlotName*: Has been updated, swapped and is now live! @channel";
    "link_names" = "true";
	"username" = "Swapped by $env:UserName";}
Invoke-WebRequest `
	-Body (ConvertTo-Json -Compress -InputObject $payload) `
	-Method Post `
	-Uri "https://hooks.slack.com/[WEB_HOOK]" | Out-Null

#US Region--------------------------------------------------------------------------------------------------------------------------------------------------------------
#Swap US South
Write-Host "$USSouthAppSlotName Swap Requested"
    Switch-AzureRmWebAppSlot -SourceSlotName $USSouthAppSlot -DestinationSlotName "production" -ResourceGroupName $USSouthResourceGroupName -Name $USSouthAppSlotName
    Write-Host "Wait 10 Seconds"
    # Wait 10 seconds for the service to start.
    Start-Sleep -s 10
    # First we create the request.
    $HTTP_Request = [System.Net.WebRequest]::Create($USSouthURL)
    # We then get a response from the site.
    $HTTP_Response = $HTTP_Request.GetResponse()
    # We then get the HTTP code as an integer.
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    If ($HTTP_Status -eq 200) { 
        Write-Host "Site is OK! $USSouthAppSlotName"
        # Finally, we clean up the http request by closing it.
        $HTTP_Response.Close()
        #Check Production Build No
        $USSouthBuildInfo =$USSouthWebClient.DownloadString("https://[URL_FOR_BUILD_No]")
        Write-Host "Checking latest release build No is $Expected_BuildNo"
        If($USSouthBuildInfo.contains($Expected_BuildNo)){
            write-host "Build No. is OK, Found $USSouthBuildInfo" } 
            Else { Write-Host "***Build No. is NOT OK, Found $USSouthBuildInfo***" | Pause}
            }
        Else {
        Write-Host "The site may be down, please check! $USSouthAppSlotName" | Pause}

#Post to Slack
Set-StrictMode -Version Latest
Write-Host "Posting to slack"

	$payload = @{
	"channel" = "#[SLACK_Channel]";
	"icon_emoji" = ":zap:";
	"text" = "*$USSouthAppSlotName and $USNorthAppSlotName*: Has been updated, swapped and is now live! @channel";
    "link_names" = "true";
	"username" = "Swapped by $env:UserName";}
Invoke-WebRequest `
	-Body (ConvertTo-Json -Compress -InputObject $payload) `
	-Method Post `
	-Uri "https://hooks.slack.com/[WEB_HOOK]" | Out-Null

#Update Dev Slots
Write-Host "Sync dev slots"
#What ever code you use to update your dev slots, dropbox, github, ftp and etc....