# Returns a group of TimeZone display names that match a supplied UTC offset in minutes
Function Get-TimeZoneDisplayName {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [Int]$UTCOffsetMinutes
    )

    # Let's convert the UTC offset to a formatted hours string for comparison
    $UTCOffsetHours = "{0:D2}:00:00" -F $($UTCOffsetMinutes / 60);

    # Get a list of zones that match the formatted UTC offset
    $Zones = [System.TimeZoneInfo]::GetSystemTimeZones() | ?{$_.BaseUtcOffset -eq $UTCOffsetHours};

    # Return a pipe seperated list of matching zones
    return $Zones.DisplayName -join " | ";
}

# Returns a CultureInfo name from a supplied WMI locale code
Function Get-LocaleFromWMICode {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$WMILocaleCode # String to preserve leading zeroes
    )

    # Get our Hex number style and Invariant information
    $HexNumber  = [System.Globalization.NumberStyles]::HexNumber;
    $InvarInfo  = [System.Globalization.NumberFormatInfo]::InvariantInfo;

    # Declare our ref var and parse to int
    $LocaleCode = 0;
    [Void]([Int]::TryParse($WMILocaleCode, $HexNumber, $InvarInfo, [Ref]$LocaleCode));

    # Get and return our CultureInfo name
    return [CultureInfo]::GetCultureInfo($LocaleCode).Name;
}

# Returns a formatted date string diffing between a supplied datetime and now (or supplied datetime)
Function Get-DateTimeDifference {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$CompareDateTime,
        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$ReferenceDateTime = $(Get-Date)
    )

    # Get a timespan object we can base from
    $TimeSpan  = New-TimeSpan $CompareDateTime $ReferenceDateTime;

    # And return our formatted string
    return "{0} Days, {1} Hours, {2} Minutes ago" -f $TimeSpan.Days, $TimeSpan.Hours, $TimeSpan.Minutes;
}

# Returns a bool indicating whether the supplied string is an IPv4 address
Function Is-Ipv4Address {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [String]$Address
    )

    # Pattern, will match any 32 bit 4 octet number but we know our inputs are good
    $Pattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b";

    # Return based on match
    Switch -Regex ($Address) {
        $Pattern {return $True}
        default  {return $False}
    }
}

# Returns a bool indicating whether the supplied string is an IPv4 address
Function Is-Ipv6Address {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$False,ValueFromPipeline=$True)]
        [String]$Address
    )

    # Pattern chopped up combined with a -join for legibility
    $Pattern = @(
        "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|",
        "([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}",
        ":){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:)",
        "{1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1",
        ",4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA",
        "-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9",
        "a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[",
        "0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:(",
        "(:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F",
        "]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4})",
        "{0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1",
        "}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0",
        ",1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(",
        "2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]",
        "|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
    ) -Join "";

    # Return based on match
    Switch -Regex ($Address) {
        $Pattern {return $True}
        default  {return $False}
    } 
}

# Converts a Win32_LogicalDisk MediaType enum to a description string
Function ConvertTo-DiskMediaTypeString {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateRange(0, 22)]
        [Int]$MediaTypeEnum
    )

    Switch($MediaTypeEnum) {
        0  {"Unknown media type"}
        1  {"5¼ Inch Floppy Disk - 1.2 MB - 512 bytes/sector"}
        2  {"3½ Inch Floppy Disk - 1.44 MB - 512 bytes/sector"}
        3  {"3½ Inch Floppy Disk - 2.88 MB - 512 bytes/sector"}
        4  {"3½ Inch Floppy Disk - 20.8 MB - 512 bytes/sector"}
        5  {"3½ Inch Floppy Disk - 720 KB - 512 bytes/sector"}
        6  {"5¼ Inch Floppy Disk - 360 KB - 512 bytes/sector"}
        7  {"5¼ Inch Floppy Disk - 320 KB - 512 bytes/sector"}
        8  {"5¼ Inch Floppy Disk - 320 KB - 1024 bytes/sector"}
        9  {"5¼ Inch Floppy Disk - 180 KB - 512 bytes/sector"}
        10 {"5¼ Inch Floppy Disk - 160 KB - 512 bytes/sector"}
        11 {"Removable media other than floppy"}
        12 {"Fixed hard disk media"}
        13 {"3½ Inch Floppy Disk - 120 MB - 512 bytes/sector"}
        14 {"3½ Inch Floppy Disk - 640 KB - 512 bytes/sector"}
        15 {"5¼ -Inch Floppy Disk - 640 KB - 512 bytes/sector"}
        16 {"5¼ -Inch Floppy Disk - 720 KB - 512 bytes/sector"}
        17 {"3½ Inch Floppy Disk - 1.2 MB - 512 bytes/sector"}
        18 {"3½ Inch Floppy Disk - 1.23 MB - 1024 bytes/sector"}
        19 {"5¼ Inch Floppy Disk - 1.23 MB - 1024 bytes/sector"}
        20 {"3½ Inch Floppy Disk - 128 MB - 512 bytes/sector"}
        21 {"3½ Inch Floppy Disk - 230 MB - 512 bytes/sector"}
        22 {"8 Inch Floppy Disk - 256 KB - 128 bytes/sector"}
    }
}

# Converts a Win32_LogicalDisk DriveType enum to a description string
Function ConvertTo-DiskDriveTypeString {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateRange(0, 6)]
        [Int]$DriveTypeEnum
    )

    Switch($DriveTypeEnum) {
        0 {"Unknown media type"}
        1 {"No Root Directory"}
        2 {"Removable Disk"}
        3 {"Local Disk"}
        4 {"Network Drive"}
        5 {"Compact Disc"}
        6 {"RAM Disk"}
    }
}

# Returns a string indicating whether the machine is running on Azure or On-Prem
# Function (now modified) and C# were sourced here: https://gallery.technet.microsoft.com/scriptcenter/Detect-Windows-Azure-aed06d51
# Uses the DHCP options-set 245 trick to see if the machine is running on Azure
Function Locate-WindowsMachine { 
    
    # Let's add the custom type and required Assemblies
    $CSharpClass = Get-Content ".\Lib\Azure-Detection.cs" | Out-String;
    Add-Type -TypeDefinition $CSharpClass;
    Add-Type -AssemblyName "System.Serviceprocess";
    
    # Get the VMBus object
    $VMBus = [System.ServiceProcess.ServiceController]::GetDevices() | ?{$_.Name -eq "vmbus"};

    # Prepare our Location variable
    $Location = $Null;

    # Check if it's running, if not we know we're physical on prem
    if($VMBus.Status -eq "Running") {

        # Get the custom client object
        $DHCPClient = New-Object Microsoft.WindowsAzure.Internal.DhcpClient;

        # Trapped so we can take advantage of finally block
        try {
            # Enumerate the collection and get our answer
            [Microsoft.WindowsAzure.Internal.DhcpClient]::GetDhcpInterfaces() | % {  
                # Get the options set
                $Result = $DHCPClient.DhcpRequestParams($_.Id, 245); 

                # Work out if the options set is there
                if($Result -And $Result.Length -eq 4) { 
                    $Location = "Microsoft Azure"
                }
            }

            # Now check our answer and see if we're on prem virtual
            if ($Location -eq $Null) {
                $Location = "On-Premises"
            }
        } 
        finally { 
            $DHCPClient.Dispose();
        }
    }
    else {
        $Location = "On-Premises"
    }

    # And finally return our detected location
    return $Location;
} 