#####
#
# Sample script that can be used to demonstrate the Delta capabilities of the Microsoft Graph API for users.
#
# The script will connect to an Azure AD using the provided ClientID, Secret and TenantID (variables), and after performing the inital get all users will
#  then query only for changes using the delta link.
#
# Note - this script requires:
#   - An application in the Azure AD tenancy (update $ClientID, $Secret and $TenantID)
#   - the correct permissions assigned (details available here: https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/user_delta)
#   - the script itself doesn't process or perform any actions based on a user being updated, however this logic can be extended where the comment '# do some stuff with each user' is in the script
#
# Author: Andrew Silcock
# Date Created: 25-Jul-2018
# Version: 0.1
#
#####

Function GetAuthtoken
{
    param
    (
        [string]$ClientID,
        [string]$Secret,
        [string]$TenantID
    )
    $resource = "https://graph.microsoft.com"

    #$clientSecret = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Secret))
    $clientSecret = $Secret

    $tokenEndpoint =  [string]::Format("https://login.microsoftonline.com/{0}/oauth2/token", $TenantID)
    
    $clientSecretEncoded = [System.Web.HttpUtility]::UrlEncode($clientSecret)

    $body = "grant_type=client_credentials&client_id=$ClientID&client_secret=$clientSecretEncoded&resource=$resource"
    $Authorization = Invoke-RestMethod $tokenEndpoint -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body -ErrorAction STOP

    return $Authorization
}

function ProcessResponseStatus
{
    param
    (
        $response
    )

    # if there is a nextLink - this means there are more pages to be processed
    if ($response.'@odata.nextLink')
    {
        return "{'completed':false, 'nextLink':'"+$response.'@odata.nextLink'+"' }"
    } 
    # if there is a deltaLink - this means there are no more pages, and the deltaLink shoudl be used at the next query interval
    elseif ($response.'@odata.deltaLink')
    {
       return "{'completed':true, 'deltaLink':'"+$response.'@odata.deltaLink'+"' }"
    }
}

function GetInitialQueryURL
{
    # default queyr URL if there is a no delta link file to use
    $InitialQueryURL = "https://graph.microsoft.com/v1.0/users/delta" 
    
    # If the delta file exists, read the delta query URL from the file
    if (Test-Path $DeltaFile)
    {
        $DeltaLink = Get-Content $DeltaFile | ConvertFrom-JSON
        $InitialQueryURL = $DeltaLink.DeltaLink
    }

    return $InitialQueryURL
}

# Import the System.Web assembly so the HttpUtility is available
Add-Type -AssemblyName System.Web

# File to save the Delta Link to
#
$DeltaFile = "C:\Scripts\GraphAPI_Delta\deltaLink.json"

# Tenancy and app configuration
#
$ClientID = ""  # Replace with the Application ID of the Azure Applicate
$Secret = ""    # Replace with the key for the application
$TenantID = "" # replace with the tenant ID for the Azure AD tenancy

try
{
    # Get the authentication token 
    $token = GetAuthToken -ClientID $ClientID -Secret $Secret -TenantID $TenantID
    $bearerToken = [string]::Format("Bearer {0}",$token.access_token);

    try
    {
        # Get the query URL either from the delta file, or default if no delta file
        $InitialQueryURL = GetInitialQueryURL
        $response = Invoke-RestMethod -Uri $InitialQueryURL -Headers @{Authorization = "$bearerToken"} -Method Get
    }
    catch 
    {
        Write-Error ("Query broke - {0} " -f $_.Exception.Message)
        exit
    }

    # determine the status from the first page of results
    $statusObj = (ProcessResponseStatus -response $response) | ConvertFrom-Json

    if ($statusObj.completed)
    {
        ""
        "No changes to process"
        ""
    }
    $PageCounter = 1
    while (-not ($statusObj.completed))
    {
        "Processing page {0}" -f $PageCounter
        
        $PageUserCount = 1
        # iterate through the users that have changed
        foreach ($user in $response.value)
        {
            ##
            # do some stuff with each user
            # ..
            ("(Page {0} - Page User count: {1}) - User UPN: {2}" -f $PageCounter, $PageUserCount, $user.UserPrincipalName)
            $PageUserCount++
            #
            ###
        }

        # read the next page
        $response = Invoke-RestMethod -Uri $statusObj.nextLink -Headers @{Authorization = "$bearerToken"} -Method Get

        # process the resposne to determine if we are done or not
        $statusObj = (ProcessResponseStatus -response $response) | ConvertFrom-Json
        $PageCounter++
    } 

    $EndObject = @{ TimeStamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'); DeltaLink=$statusObj.deltaLink }

    Write-Host ("Completed - Delta Link saved to '{0}'" -f $DeltaFile)
    ($EndObject | ConvertTo-Json) | Out-File $DeltaFile
}
catch
{
    Write-Error ("It broke - {0}" -f $_.Exception.Message)
    exit
}