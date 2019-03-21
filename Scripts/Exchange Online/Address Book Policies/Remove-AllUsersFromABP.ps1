#####
#
# Script that can be run to remove all users from the specific Address Book Policy (APB) in Exchange Online.  
#  By default the script will only report on the number of users assigned to the ABP, the parameter -PerformRemoval can be used to actual remove the ABP from all users.
#
#  The script will prompt for Office 365 credentials if a PSCredential object is not provided as a parameter
#
# Sample Usage:
#    1.  View the number of users allocated to the ABP 'Corporate Address Book Policy'
#     - Remove-AllUsersFromABP.ps1 -PolicyName 'Corporate Address Book Policy'
#
#    2.  View the number of users allocated to the ABP 'Corporate Address Book Policy' providing a PSCredential Object
#     - Remove-AllUsersFromABP.ps1 -PolicyName 'Corporate Address Book Policy' -Credential $Credential
#  
#    3.  Remove all users allocated to the ABP 'Corporate Address Book Policy' providing a PSCredential Object
#     - Remove-AllUsersFromABP.ps1 -PolicyName 'Corporate Address Book Policy' -Credential $Credential -PerformRemoval
#
# Author: Andrew Silcock
# Date Created: 21-Mar-2019
# Version: 1.0
#
#####
param
(
    [Parameter(Mandatory=$true)]
    [string] $PolicyName,
    [Parameter(Mandatory=$false)]
    [PSCredential] $Credential,
    [switch] $PerformRemoval
)

if (-not $Credential)
{
    $Credential = Get-Credential -Message "Enter the Exchange Online Administrator credentials"
}

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri  https://ps.outlook.com/powershell -Credential $Credential -Authentication Basic -AllowRedirection 
Import-PSSession $Session -AllowClobber -CommandName "Set-Mailbox","Get-Mailbox","Get-AddressBookPolicy" | Out-Null

$ABP = Get-AddressBookPolicy -Identity $PolicyName
if (-not $ABP)
{
    Write-Warning "The Address Book Policy '{0}' was not found" -f $PolicyName
    exit 0
}

# unable to get the -filter approach working with any attribute/value coming from a variable.
#$Users = Get-Mailbox -Filter { AddressBookPolicy -eq $ABP.Name }
$Users = Get-Mailbox | Where {$_.AddressBookPolicy -eq $ABP.Name }

if ($PerformRemoval)
{    
    $count = 1
    "Users found: {0}" -f $Users.Count
    foreach ($u in $Users)
    {
        "({0}) {1} of {2} - {3}: {4}" -f (Get-Date), $count, $Users.count, $u.userPrincipalName, $u.AddressBookPolicy
        # remove the address book policy from the user's mailbox
        Set-Mailbox -Identity $u.UserPrincipalName -AddressBookPolicy $null
        $count++
    }
}
else
{
    "There were '{0}' users found that have been assigned the ABP '{1}'" -f $Users.count, $PolicyName
    "The Address Book Policy '{0}' can be remove from the users by running the script again with the -PerformRemoval parameter" -f $PolicyName
}
Get-PSSession | Remove-PSSession