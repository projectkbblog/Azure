param(
    [Parameter(mandatory=$false)]
    [string] $OnPremAdmin,
    [Parameter(mandatory=$false)]
    [string] $AzureAdmin
)

$OnPremAdministrator = Get-Credential -Message "Enter on-premises domain administrator credentials" -UserName $OnPremAdmin
$CloudAdmin = Get-Credential -Message "Enter Azure AD administrator credentials" -UserName $AzureAdmin

Import-Module 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADSSO.psd1'
New-AzureADSSOAuthenticationContext -CloudCredentials $CloudCred
Update-AzureADSSOForest -OnPremCredentials $OnpremCred