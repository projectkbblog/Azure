##########
#
# Script that can be used for the deployment of function apps from the ZIP file export. The script is based on the process documented at: https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push
#
# Pre-requisites: 
#   - The function must already exist, and the Function App name be known (e.g. https://myfunctionapp.azurewebsites.net - the name would be myfunctionapp)
#   - Deployment credentials are required, these can be created on the target function under Platform features -> Deployment credentials.
#   - The zip file export of the function is required. (If migrating between environments the file can be exported via Function Overview -> Download app content.)
#
# Author: Andrew Silcock
# Date Created: 29-Aug-2018
# Version: 1.0
#
##########

param 
(
    [Parameter(Mandatory=$true)]
    [string] $FunctionAppName,
    [Parameter(Mandatory=$true)]
    [string] $DeploymentUsername,
    [Parameter(Mandatory=$true)]
    [string] $DeploymentZipFile
)


# Display a Yes/No propmt to the user and return $true if they entered Y or $false otherwise
#
function ShouldContinue
{
    write-host -nonewline "Are you sure you want to continue? (Y/N) "
    $response = read-host
    if ( $response -ne "Y" )
    { 
        return $false
    }
    else
    {
        return $true
    }

}

function ConvertSecureStringToPlainText
{
    param($securestring)

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

}

#Deployment credentials
$PasswordSecure = Read-Host -Prompt "Enter the deployment password" -AsSecureString
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $DeploymentUsername, (ConvertSecureStringToPlainText -securestring $PasswordSecure))))

# Deployment URL
$apiUrl = ("https://{0}.scm.azurewebsites.net/api/zipdeploy" -f $FunctionAppName)

# Prompt as to whether the script should continue or not
#
""
Write-Output ("This will deploy the file '{0}' `n`tto the function app '{1}'" -f $DeploymentZipFile, $FunctionAppName)
"`nThis may take several minutes depending on the size of the zip file being deployed`n"

if (ShouldContinue)
{
    # Perform the deployment
    try
    {
        Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent "powershell/1.0" -Method POST -InFile $DeploymentZipFile -ContentType "multipart/form-data"
        "Deployment completed"
    }
    catch
    {

    }
}
else
{
    "No action has been taken"
}