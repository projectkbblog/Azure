#####
#
# Script that can be run to output the following details as a summary of an Address Book Policy (ABP) in Exchange Online:
#   1. The Global Address List (GAL) associated with the ABP
#   2. The Address Lists (AL) associated with the ABP
#   3. The Room List associated with the ABP
#   4. The Offline Address Book (OAB) associated with the ABP.
#
#  Using the -Detailed parameter the script can also list the recipient filters for each of the policy types listed above.
#
#  The script will prompt for Office 365 credentials if a PSCredential object is not provided as a parameter
#
# Sample Usage:
#    1.  Get a summary of the Address Book Policy configuration (not providing a PSCredential)
#     - ABPDetails.ps1 -AddressBookPolicy "Corporate Address Book Policy"
#
#    2.  Get a summary of the Address Book Policy configuration (providing a PSCredential object that has previously been created)
#     - ABPDetails.ps1 -AddressBookPolicy "Corporate Address Book Policy" -Credential $Credential
#  
#    3.  Get a detailed summary of the Address Book Policy configuration (not providing a PSCredential)
#     - ABPDetails.ps1 -AddressBookPolicy "Corporate Address Book Policy" -Detailed
#
# Author: Andrew Silcock
# Date Created: 21-Feb-2019
# Version: 1.0
#
#####

param
(
    [Parameter(Mandatory=$false)]
    [string] $AddressBookPolicy,
    [Parameter(Mandatory=$false)]
    [PSCredential] $Credential,
    [switch] $Detailed

)

# Default cmdlets to import relating to Address Book Policies and related configuration in Exchange
#
$PSCommandsToInclude = "*-AddressBookPolicy", "*-OfflineAddressBook", "*-GlobalAddressList",  "*-AddressList"

function ConnectTo-ExchangeOnline
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCredential] $Credential
    )
    
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri  https://ps.outlook.com/powershell -Credential $Credential -Authentication Basic -AllowRedirection 
    Import-PSSession $Session -AllowClobber -CommandName $psCommandstoInclude
}

# If credential not provided as a parameter then request it
if (-not $Credential)
{
    $Credential = Get-Credential -Message "Enter Office 365 Admin Credentials"
}
ConnectTo-ExchangeOnline -Credential $Credential

# Get the Address Book Policy object from Exchange Online
#
$ABP = Get-AddressBookPolicy $AddressBookPolicy
if (-not $ABP)
{
    "An address book policy with the name '{0}' was not found" -f $AddressBookPolicy
    exit -1
}
"Address Book Policy: {0}" -f $ABP.Name
$ABP | Format-List -Property GlobalAddressList, AddressLists, RoomList, OfflineAddressBook

# If displaying detailed information of the related configuration objects
if ($Detailed)
{
    # Global Address List
    #
    $ABP_GAL = Get-GlobalAddressList -Identity $ABP.GlobalAddressList
    "Global Address List: {0}" -f $ABP_GAL.Name
    "--------------------"
    $ABP_GAL | Format-List -Property RecipientFilter

    # Address Lists
    #
    "Address Lists"
    "--------------------"
    foreach ($AddressListName in $ABP.AddressLists)
    {
        $AddressListObj = Get-AddressList -Identity $AddressListName
        $AddressListObj | Format-List -Property Name, RecipientFilter
    }

    # Room List
    #
    #
    "Room List: {0}" -f $ABP.RoomList
    "--------------------"
    $RoomList = Get-AddressList -Identity $ABP.RoomList
    $RoomList | Format-List -Property RecipientFilter

    # Offline Address Book
    #
    #
    "Offline Address Book: {0}" -f $ABP.OfflineAddressBook
    "`nAddress Lists"
    "--------------------"
    $OAB = Get-OfflineAddressBook -Identity $ABP.OfflineAddressBook

    foreach ($AddressListName in $OAB.AddressLists)
    {
        $AddressListObj = Get-AddressList -Identity $AddressListName -ErrorAction SilentlyContinue
        # It could be an Address List or a Global Address List
        if (-not $AddressListObj)
        {
            $AddressListObj = Get-GlobalAddressList -Identity $AddressListName -ErrorAction SilentlyContinue
        }
        $AddressListObj | Format-List -Property Name, RecipientFilter
    }
}

Get-PSSession | Remove-PSSession