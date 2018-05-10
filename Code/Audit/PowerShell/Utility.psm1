# Writes json status update to stdout
Function Write-StatusUpdate {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Counter
    )

    # Ok we need to get the average time of both probes and audits
    $AverageProbeSeconds = $Counter.ProbeTimeSpans | Measure -Property TotalSeconds -Average | Select -ExpandProperty Average;
    $AverageAuditSeconds = $Counter.AuditTimeSpans | Measure -Property TotalSeconds -Average | Select -ExpandProperty Average;
    
    # Work out how many are left of each (count)
    $ProbeRemainingCount = $Counter.ProbeQueueCount - $($Counter.ProbeSuccessCount + $Counter.ProbeFailedCount);
    $AuditRemainingCount = $Counter.AuditQueueCount - $($Counter.AuditSuccessCount + $Counter.AuditFailedCount);

    # Work out how many are left of each (seconds)
    $ProbeSecondsRemaining = $ProbeRemainingCount * $AverageProbeSeconds;
    $AuditSecondsRemaining = $AuditRemainingCount * $AverageAuditSeconds;

    # Calculate the estimated time remaining
    $EstimatedSecondsRemaining = [Math]::Round($($ProbeSecondsRemaining + $AuditSecondsRemaining));

    # Build the json output
    $JSON = @{
        EstimatedSecondsRemaining = $EstimatedSecondsRemaining;
        ProbeSuccessCount = $Counter.ProbeSuccessCount;
        ProbeFailedCount = $Counter.ProbeFailedCount;
        AuditQueueCount = $Counter.AuditQueueCount;
        AuditSuccessCount = $Counter.AuditSuccessCount;
        AuditFailedCount = $Counter.AuditFailedCount;
    } | ConvertTo-Json -Compress;

    # Build the status string
    $StatusString = "SCANUPDATE:$JSON";

    # And write out
    Write-Output $StatusString;
}

# Writes host update to stdout
Function Write-HostUpdate {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ID,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Int]$Status,
        [Parameter(Mandatory=$False)]
        [Array]$Errors
    )

    # Build the json output
    $JSON = @{
        ID = $ID;
        Status = $Status;
        Errors = $Errors;
    } | ConvertTo-Json -Compress;

    # Build the status string
    $StatusString = "HOSTUPDATE:$JSON";

    # And write out
    Write-Output $StatusString;
}

# Writes host update to stdout
Function Write-HostUpdate {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ID,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Int]$Status,
        [Parameter(Mandatory=$False)]
        [Array]$Errors
    )

    # Build the json output
    $JSON = @{
        ID = $ID;
        Status = $Status;
        Errors = $Errors;
    } | ConvertTo-Json -Compress;

    # Build the status string
    $StatusString = "HOSTUPDATE:$JSON";

    # And write out
    Write-Output $StatusString;
}

# Writes out a scan termination
Function Terminate-Scan {
    [Cmdletinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("Error","Success")]
        [String]$State,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Message
    )

    # Build the json output
    $JSON = @{
        State = $State;
        Message = $Message;
    } | ConvertTo-Json -Compress;

    # Build the status string
    $TerminationString = "SCANTERMINATE:$JSON";

    # And write out
    Write-Output $TerminationString;
}

# Writes host update to stdout
Function Write-HostUpdate {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ID,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Int]$Status,
        [Parameter(Mandatory=$False)]
        [Array]$Errors
    )

    # Build the json output
    $JSON = @{
        ID = $ID;
        Status = $Status;
        Errors = $Errors;
    } | ConvertTo-Json -Compress;

    # Build the status string
    $StatusString = "HOSTUPDATE:$JSON";

    # And write out
    Write-Output $StatusString;
}

# Unrolls an encoded json/base64 string
Function Unroll-EncodedJson {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Path
    )

    # Get the json string
    $Json = Get-Content $Path -Raw;

    # Return the json to an object
    $Object = $Json | ConvertFrom-Json;

    # And return the object
    return $Object;
}

# Returns a bool based on ICMP ping result
Function Test-IcmpPing {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Endpoint
    )

    # Set EAP
    $ErrorActionPreference = "Stop";

    # ICMP ping
    try {
        # Init ping object and hit it
        $Ping       = New-Object System.Net.NetworkInformation.Ping;
        $PingResult = $Ping.Send($Endpoint, 1000, $(New-Object Byte[] 32));

        # Test the result
        if($PingResult.Status -eq "Success") {
            return $True;
        } else {
            return $False;
        }
    }
    catch {
        return $False;
    }
}

# Recursive resolver for ip/dns/hostnames
Function Resolve-Endpoints {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Endpoint
    )

    # Build our output result so we can add properties easily
    $Result = $([PSCustomObject]@{
        Hostnames = $(New-Object System.Collections.ArrayList);
        DnsAliases = $(New-Object System.Collections.ArrayList);
        Ipv4Addresses = $(New-Object System.Collections.ArrayList);
        Ipv6Addresses = $(New-Object System.Collections.ArrayList);
    });

    # Declare an array to hold our resolving targets
    $Targets = New-Object System.Collections.ArrayList;

    # Init a loop controller and seed our resolvers array
    $Resolving = $True;
    [Void]($Targets.Add($([PSCustomObject]@{
        Target   = $Endpoint;
        Resolved = $False;
    })));

    # Recursive resolution until we find all the possible entries
    While($Resolving) {

        # Build some current counters
        $HostNamesCounter     = $Result.Hostnames.Count;
        $DnsAliasesCounter    = $Result.DnsAliases.Count;
        $Ipv4AddressesCounter = $Result.Ipv4Addresses.Count;
        $Ipv6AddressesCounter = $Result.Ipv6Addresses.Count;
        $TargetsCounter       = $Targets.Count;

        # Resolve all the current targets we have
        try {
            $ResolvedTargets = $($Targets.Where({!$_.Resolved}) | %{
                [System.Net.DNS]::GetHostEntry($_.Target);           
            });
        } catch {
            # If we've failed to resolve anything, break
            $Resolving = $False; Break;
        };

        # Update the targets collection now we're not using it
        $Targets | %{$_.Resolved = $True};

        # Process the results we've gathered
        $ResolvedTargets | %{

            # Grab the resolved target from the pipeline
            $ResolvedTarget = $_;
            
            # Add the primary DNS name to the store if !exists
            if (!($Result.DnsAliases.Contains($ResolvedTarget.HostName.ToLower()))) {
                [Void]($Result.DnsAliases.Add($ResolvedTarget.HostName.ToLower()));
            }

            # Add the primary DNS name to the targets if !exists
            if (!($Targets.Where({$_.Target -eq $ResolvedTarget.HostName}))) {
                [Void]($Targets.Add($([PSCustomObject]@{
                    Target   = $ResolvedTarget.HostName;
                    Resolved = $False;
                })));
            }

            # Split out the hostname from the DNS name
            $Hostname = $ResolvedTarget.HostName -split "\." | Select -First 1;

            # Add the hostname to the store if !exists
            if (!($Result.Hostnames.Contains($Hostname.ToUpper()))) {
                [Void]($Result.Hostnames.Add($Hostname.ToUpper()));
            }

            # Add the hostname to the targets if !exists
            if (!($Targets.Where({$_.Target -eq $Hostname}))) {
                [Void]($Targets.Add($([PSCustomObject]@{
                    Target   = $Hostname;
                    Resolved = $False;
                })));
            }

            # For each of the DNS aliases, add to the store/targets if !exists
            $ResolvedTarget.Aliases | %{
                
                # Grab the alias from the pipeline
                $Alias = $_;

                # DNS entries
                if (!($Result.DnsAliases.Contains($Alias.ToLower()))) {
                    [Void]($Result.DnsAliases.Add($Alias.ToLower()));
                }
                
                # Targets
                if (!($Targets.Where({$_.Target -eq $Alias}))) {
                    [Void]($Targets.Add($([PSCustomObject]@{
                        Target   = $Alias;
                        Resolved = $False;
                    })));
                }
            }

            # For each of the IP addresses, add to the store/targets if !exists
            $ResolvedTarget.AddressList | %{
                
                # Grab the IP from the pipeline
                $IP = $_.IPAddressToString;

                # IP Addresses
                if ($IP -match "^\d+.\d+.\d+.\d+$") {
                    if (!($Result.Ipv4Addresses.Contains($IP))) {
                        [Void]($Result.Ipv4Addresses.Add($IP));
                    }
                } else {
                    if (!($Result.Ipv6Addresses.Contains($IP))) {
                        [Void]($Result.Ipv6Addresses.Add($IP));
                    }
                }

                # Targets
                if (!($Targets.Where({$_.Target -eq $IP}))) {
                    [Void]($Targets.Add($([PSCustomObject]@{
                        Target   = $IP;
                        Resolved = $False;
                    })));
                }
            }

        }

        # Check the counts based on what we gathered at the start
        $FoundHostNames     = $Result.Hostnames.Count - $HostNamesCounter;
        $FoundDnsAliases    = $Result.DnsAliases.Count - $DnsAliasesCounter;
        $FoundIpv4Addresses = $Result.Ipv4Addresses.Count - $Ipv4AddressesCounter;
        $FoundIpv6Addresses = $Result.Ipv6Addresses.Count - $Ipv6AddressesCounter;
        $FoundTargets       = $Targets.Count - $TargetsCounter;

        # If none of our counters have incremented, break
        if (($FoundHostNames + $FoundDnsAliases + $FoundIpv4Addresses + $FoundIpv6Addresses + $FoundTargets) -eq 0) {
            $Resolving = $False; Break;
        }
    }

    # And return the result
    return $Result;
}

# Attempts to get remote host OS
Function Nmap-TargetOS {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Endpoint
    )

    # Set EAP
    $ErrorActionPreference = "Stop";

    # Try and get the target's OS
    try {
        # Do the nmap scan
        #$Nmap = Invoke-Expression "nmap -oX - --script smb-os-discovery.nse $Endpoint *>&1";
        #$OS = [Regex]::Match(([Xml]$Nmap).nmaprun.host.hostscript.script.output,'OS\:\s(.*?)\n').Value.Replace("OS: ","").Trim();
        
        # Check and see if we got a result
        #if ($OS) {
        #    return $OS;
        #} else {
            return "Unknown (Nmap)";
        #}
        
    } catch {
        return "Unknown (Nmap)";
    }
}

# Returns a probe object
Function New-Probe {

    return $([PSCustomObject][Ordered]@{
        IsDead = $Null;
        Info = [PSCustomObject][Ordered]@{
            TimeTaken          = $Null;
            NmapDiscoveredOS   = $Null;
            RemoteDiscoveredOS = $Null;
        };
        Networking = [PSCustomObject][Ordered]@{
            ICMP          = $Null;
            HostNames     = $Null;
            DnsAliases    = $Null;
            IPv4Addresses = $Null;
            IPv6Addresses = $Null;
        };
        Credentials = [PSCustomObject][Ordered]@{
            Tested     = @();
            Successful = $Null;
        };
        RemoteConnectivity = [PSCustomObject][Ordered]@{
            OK  = $Null;
            Wmi = [PSCustomObject][Ordered]@{
                Successful     = $Null;
                ErrorMessage   = $Null;
                Authentication = $Null;
            };
            Ssh = [PSCustomObject][Ordered]@{
                Successful     = $Null;
                ErrorMessage   = $Null;
                Authentication = $Null;
            };
        };
    });
}

# Returns a new audit object
Function New-Audit {

    return $([PSCustomObject][Ordered]@{
        Info = [PSCustomObject][Ordered]@{
            TimeTaken = $Null;
            Completed = $Null;
        };
        Sections = $Null;
    });
}

# Thin wrapper for Get-WmiObject with additional params
Function Invoke-Wmi {
    [Cmdletbinding()]
    Param(
        # The server we're targetting
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,
    
        # The credential we're using to connect
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential,
    
        # The script we're executing
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ScriptPath,
    
        # The Machine identifer we'll tag the result with
        [Parameter(Mandatory=$True)]
        [ValidateScript({$_ -Match "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"})]
        [String]$MachineIdentifier
    )
    
    # Set EAP
    $ErrorActionPreference = "Stop";
    
    # Invoke the script supplying the params
    $Result = & $ScriptPath $Target $Credential $MachineIdentifier;
    
    # And return
    return $Result;
}

# Fat wrapper around plink for secure shell
Function Invoke-Ssh {
    [Cmdletbinding()]
    Param(
        # The server we're targetting
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Target,
    
        # Username we'll use to connect
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Username,
    
        # Password we'll use to connect
        [Parameter(Mandatory=$False)]
        [String]$Password,
    
        # Private key file path 
        [Parameter(Mandatory=$False)]
        [String]$PrivateKeyFilePath,
    
        # Passphrase for the private key
        [Parameter(Mandatory=$False)]
        [String]$PrivateKeyPassphrase,
    
        # The script we're executing
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ScriptPath,
    
        # The Machine identifer we'll tag the result with
        [Parameter(Mandatory=$True)]
        [ValidateScript({$_ -Match "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"})]
        [String]$MachineIdentifier
    )
    
    # Set EAP
    $ErrorActionPreference = "Stop";
    
    # Work out the authentication mechansim
    $AuthenticationMethod = $(
        if ($Username -and $PrivateKeyFilePath -and $PrivateKeyPassphrase) {
            "PrivateKeyWithPassphrase";
        } elseif ($Username -and $PrivateKeyFilePath) {
            "PrivateKey";
        } else {
            "Password";
        }
    );

    # Wrap the ssh connection in a Process so we can write to stdin
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo;
    $Process = New-Object System.Diagnostics.Process;
    
    # Set the startinfo object properties and set the process to use this startinfo
    $ProcessStartInfo.FileName = $($env:windir + "\System32\cmd.exe");
    $ProcessStartInfo.CreateNoWindow = $True;
    $ProcessStartInfo.UseShellExecute = $False;
    $ProcessStartInfo.RedirectStandardOutput = $True;
    $ProcessStartInfo.RedirectStandardInput = $True;
    $ProcessStartInfo.RedirectStandardError = $True;
    $Process.StartInfo = $ProcessStartInfo;
    
    # Start the process
    [Void]($Process.Start());
    
    # We need to switch here dependent on the connection method
    Switch -Regex ($AuthenticationMethod) {
        "Password" {
            $Cmd = "plink -ssh $Target -P 22 -l $Username -pw $Password -m $ScriptPath";
        }
        "PrivateKey*" {
            $Cmd = "plink -ssh $Target -P 22 -l $Username -i $PrivateKeyFilePath -m $ScriptPath";
        }
    }

    # Exec the cmd
    $Process.StandardInput.Write($Cmd + [System.Environment]::NewLine);

    # Check and see whether stderr has asked for the host key
    if ($Process.StandardError.ReadLineAsync().Result -like "*The server's host key is not cached in the registry.*") {
        Start-Sleep -Seconds 1;
        $Process.StandardInput.Write("yes" + [System.Environment]::NewLine);
    }

    # Wait for 2 seconds and write the private key passphrase to stdin if required
    if ($AuthenticationMethod -eq "PrivateKeyWithPassphrase") {
        Start-Sleep -Seconds 2;
        $Process.StandardInput.Write($PrivateKeyPassphrase + [System.Environment]::NewLine);
    }

    # Close stdin now we're done with it
    $Process.StandardInput.Close();
    
    # Block the exit until completion
    $Process.WaitForExit();
    
    # Grab stderr, stdout and exit code in case we need to throw
    $Stderr = $Process.StandardError.ReadToEnd();
    $Stdout = $Process.StandardOutput.ReadToEnd();
    $Status = $Process.ExitCode;

    # Parse stderr and remove the trash
    $ParsedStderr = $($Stderr | ?{
        $_ -notlike "*The server's host key is not cached in the registry.*" -and
        $_ -notlike "*have no guarantee that the server is the computer you*" -and
        $_ -notlike "*think it is.*" -and
        $_ -notlike "*The server's ssh* key fingerprint is:*" -and
        $_ -notlike "*ssh-*" -and
        $_ -notlike "*If you trust this host, enter*" -and
        $_ -notlike "*PuTTY's cache and carry on connecting.*" -and
        $_ -notlike "*If you want to carry on connecting just once, without*" -and
        $_ -notlike "*adding the key to the cache, enter*" -and
        $_ -notlike "*If you do not trust this host, press Return to abandon the*" -and
        $_ -notlike "*connection.*" -and
        $_ -notlike "*Store key in cache? (y/n)*"
    }) -Join " ";
    
    # Check our results first
    if (![String]::IsNullOrEmpty($ParsedStderr) -or $Status -gt 0) {
        throw "SSH Connection failed with exception: $ParsedStderr";
    }
    
    # Process the result
    $StartIndex = $Stdout.IndexOf("{");
    $EndIndex = $Stdout.LastIndexOf("}") - $StartIndex + 1;
    $Result = $Stdout.Substring($StartIndex,$EndIndex);

    # Clear up the trash
    $Process.Close();
    $Process.Dispose();

    # Clean up the result
    try {
        $Parsed = $Result | ConvertFrom-Json;
    } catch {
        throw "Unable to deserialise Json from SSH target with exception: $($_.Exception.Message)";
    }
    
    # Add the machine identifier
    $Parsed.MachineIdentifier = $MachineIdentifier;
    
    # And return
    return $Parsed;
}

# Returns an array of audit sections based on params
Function Get-AuditScripts {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path $_})]
        [String]$RootDirectory,

        [Parameter(Mandatory=$True)]
        [ValidateSet("SSH","WMI")]
        [String]$ScriptType,

        [Parameter(Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$SemanticData
    )

    # Build the root directory to search
    $ScriptDirectory = "$RootDirectory\PowerShell\Collectors\$ScriptType";

    # Work out which script extension we're using
    $Extension = $(Switch($ScriptType){
        "WMI" {"*.ps1"}
        "SSH" {"*.sh"}
    });

    # Get an array to hold our audit sections
    $AuditSections = @();
    
    # Check here if we have semantic data to process
    if ($SemanticData) {
        
        # See if we can find distro:version specific scripting
        $DistroSpecific = Get-ChildItem $ScriptDirectory -Directory | ?{$_.Name.Contains($SemanticData.DISTRIB_ID.ToLower())};

        # Check to see if we found a folder
        if ($DistroSpecific) {
            
            # Let's split up the name and get some properties
            $Properties    = $DistroSpecific.Name.Split("#");
            $TargetVersion = [Version]($Properties[1]);
            $Modifier      = $Properties[2];
            $SourceVersion = [Version]($SemanticData.VERSION_ID);

            # Switch based on our modifier to determine if we should pull these
            if ($(Switch ($Modifier) {
                "-"  {$TargetVersion -lt $SourceVersion}
                "+"  {$TargetVersion -gt $SourceVersion}
                "="  {$TargetVersion -eq $SourceVersion}
                "+=" {$TargetVersion -ge $SourceVersion}
                "-=" {$TargetVersion -le $SourceVersion}
            })) {
                Get-SpecificAuditScripts -Directory $DistroSpecific.FullName -ScriptType $ScriptType | %{$AuditSections += $_};
            }
        } 
    } 
    
    # Switch here based on script type
    if ($ScriptType -eq "SSH") {
        
        # Get the Generic directory in scope
        $GenericFolder = "$ScriptDirectory\Generic";
        
        # Enumerate the generic scripts
        Get-SpecificAuditScripts -Directory $GenericFolder -ScriptType $ScriptType | %{

            # Grab the script segment from the pipeline
            $ScriptSegment = $_;

            # Make sure we don't overwrite semantic scripting here
            if (($AuditSections | ?{$_.Name -eq $ScriptSegment.Name}).Count -eq 0) {
                $AuditSections += $ScriptSegment;
            }
        }
    } else {
        # Return Windows PowerShell scripting
        $AuditSections = Get-SpecificAuditScripts -Directory $ScriptDirectory -ScriptType $ScriptType
    }

    # And return the data
    return $AuditSections;  
}

# Helper function to return an array of audit sections
Function Get-SpecificAuditScripts {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path $_})]
        [String]$Directory,

        [Parameter(Mandatory=$True)]
        [ValidateSet("SSH","WMI")]
        [String]$ScriptType
    )

    # Work out which script extension we're using
    $Extension = $(Switch($ScriptType){
        "WMI" {"*.ps1"}
        "SSH" {"*.sh"}
    });

    # Return the scripts we need
    return @($(Get-ChildItem $Directory -Recurse $Extension | %{
        # Exclude the connection check script
        if (!$_.Name.Contains("_ConnectionCheck")) {
            [PSCustomObject]@{
                Name        = $_.BaseName;
                Script      = $_.FullName;
                Completed   = $False;
                RetryCount  = 0;
                Errors      = @();
                Data        = $Null;
            }
        }
    }));
}