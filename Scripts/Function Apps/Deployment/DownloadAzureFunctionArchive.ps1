##########
#
# Script that can be used to download a function app to an app content ZIP file (as per https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/azure-functions/deployment-zip-push.md)
#
# Pre-requisites: 
#   - The function must already exist have already been deployed.
#   - Deployment credentials are required, these can be created on the target function under Platform features -> Deployment credentials.
#
# Parameters (all mandatory):
#   - FunctionAppName    - the name of the function app (e.g. if the URL is https://myfunctionapp.azurewebsites.net the function app name is myfunctionapp)
#   - DeploymentUsername - the deployment credential username (the script will prompt for the password)
#   - SaveTo             - the location to save the app content ZIP file to (e.g. C:\backup\myfunctionapp.zip)
#
# Sample Usage:
#   DownloadAzureFunctionArchive.ps1 -FunctionAppName "myfunctionapp" -DeploymentUsername "functionappdeploy" -SaveTo "C:\backup\myapp.zip"
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
    [string] $SaveTo
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
$apiUrl = ("https://{0}.scm.azurewebsites.net/api/zip/site/wwwroot/" -f $FunctionAppName)

# Prompt as to whether the script should continue or not
#
""
Write-Output ("This will download the deployment file for the Function app {0}" -f $FunctionAppName)

# Download the zip
$response = Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent "powershell/1.0" -Method GET -ContentType "application/zip" -OutFile $SaveTo
