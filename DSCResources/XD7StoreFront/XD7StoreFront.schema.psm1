Configuration XD7StoreFront {
    param (
        ## Citrix XenDesktop installation source root
        [Parameter(Mandatory)]
        [System.String] $XenDesktopMediaPath
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration, XenDesktop7;

    XD7Feature 'XD7StoreFront' {
        Role = 'Storefront';
        SourcePath = $XenDesktopMediaPath;
    }

    XD7Feature 'XD7Director' {
        Role = 'Director';
        SourcePath = $XenDesktopMediaPath;
    }

    XD7Feature 'XD7Studio' {
        Role = 'Studio';
        SourcePath = $XenDesktopMediaPath;
    }

}