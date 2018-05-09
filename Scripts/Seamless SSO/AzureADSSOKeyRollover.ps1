#####
#
# Script that will perform the Kerberos Key rollover for Seamless SSO as per the procedure on https://docs.microsoft.com/en-us/azure/active-directory/connect/active-directory-aadconnect-sso-faq#how-can-i-roll-over-the-kerberos-decryption-key-of-the-azureadssoacc-computer-account
#
# The script must be run on an Azure AD Connect Server, and the process at the URL above should be followed to determine what Domains the script needs to be run for
#
# Note: 
#   - The script will prompt for an administrative account for accessing Azure AD.
#   - The script will prompt for on-premises Domain Administrator credentials which is required as the cmdlet requires this is a mandatory paramter.
# 
# Sample Usage:
#     Perform the kerberos key rollover
#     - AzureADSSOKeyRollover.ps1
#
# Author: Andrew Silcock
# Date Created: 9-May-2018
# Version: 0.1
#
#####

# Get the on-premise credentials for domain administrator and perform the key rollover
#
function DoKerberosRollover
{
    $OnPremCreds = Get-Credential -Message "Please provide domain administrator credentials"
    Update-AzureADSSOForest -OnPremCredentials $OnPremCreds
}

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

# Import the required module for managing Azure AD Seamless SSO
Import-Module 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1'

"Azure AD Seamless SSO Kereberos key rollover helper"
"---------------------------------------------------"
"This script will rollover the Kerberos encryption key used for Seamless SSO as per the procedure"
"https://docs.microsoft.com/en-us/azure/active-directory/connect/active-directory-aadconnect-sso-faq#how-can-i-roll-over-the-kerberos-decryption-key-of-the-azureadssoacc-computer-account"
""
Write-Warning "This process should only be run once per Active Directory domain within a 30 day period and can cause user experience issues if run more frequently"
""
if (-not (ShouldContinue))
{ 
    "`nExiting - no action will be taken"
    exit 
}

# Authenticate to Azure AD
New-AzureADSSOAuthenticationContext #-CloudCredentials $CloudCred

# Get the current status of Seamless SSO
"`nChecking the current status of Seamless SSO"
$SsoStatus = Get-AzureADSSOStatus | ConvertFrom-Json

if  ($SSOStatus.Enable)
{
    "`nSeamless SSO is enabled and the Kerberos Key will be rolled over"
    if (-not (ShouldContinue))
    { 
        "`nExiting - no action will be taken"
        exit 
    }

    DoKerberosRollover
}
else
{
    ""
    Write-Warning "Seamless SSO is not enabled for the Azure AD tenancy you logged into, no changes have been made and the script will now exit"
    exit
}