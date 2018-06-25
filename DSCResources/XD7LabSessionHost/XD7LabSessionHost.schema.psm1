configuration XD7LabSessionHost {
    param (
        ## Citrix XenDesktop installation source root
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $XenDesktopMediaPath,

        ## Citrix XenDesktop site name
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SiteName,

        ## Citrix XenDesktop delivery controller address(es)
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $ControllerAddress,

        ## RDS license server
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $RDSLicenseServer,

        ## Users/groups to add to the local Remote Desktop Users group
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $RemoteDesktopUsers,

        ## Active Directory domain account used to communicate with AD for Remote Desktop Users
        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    Import-DscResource -ModuleName XenDesktop7;

    foreach ($feature in @('RDS-RD-Server', 'Remote-Assistance', 'Desktop-Experience')) {

        WindowsFeature $feature {
            Name = $feature;
            Ensure = 'Present';
        }
    }

    XD7VDAFeature 'XD7SessionVDA' {
        Role = 'SessionVDA';
        SourcePath = $XenDesktopMediaPath;
        DependsOn = '[WindowsFeature]RDS-RD-Server';
    }
    #Wait until last DC is joined to the farm before connecting VDAs
    if ($ControllerAddress.count -gt 1){
        $WaitforSiteController = $ControllerAddress[-1]
    }
    XD7WaitForSite 'WaitForXD7Site' {
        SiteName = $SiteName;
        ExistingControllerName = $WaitforSiteControllerAddress;
        DependsOn = '[XD7Feature]XD7Controller';
    }

    foreach ($controller in $ControllerAddress) {

        XD7VDAController "XD7VDA_$controller" {
            Name = $controller;
            DependsOn = '[XD7VDAFeature]XD7SessionVDA';
        }
    }

    if ($PSBoundParameters.ContainsKey('RemoteDesktopUsers')) {

        

            Group 'RemoteDesktopUsers' {
                GroupName = 'Remote Desktop Users';
                MembersToInclude = $RemoteDesktopUsers;
                Ensure = 'Present';
            }      
    } #end if Remote Desktop Users

    Registry 'RDSLicenseServer' {
        Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TermService\Parameters\LicenseServers';
        ValueName = 'SpecifiedLicenseServers';
        ValueData = $RDSLicenseServer;
        ValueType = 'MultiString';
    }

    Registry 'RDSLicensingMode' {
        Key = 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server\RCM\Licensing Core';
        ValueName = 'LicensingMode';
        ValueData = '4'; # 2 = Per Device, 4 = Per User
        ValueType = 'Dword';
    }

} #end configuration XD7LabSessionHost
