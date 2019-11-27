function Invoke-AsBuiltReport.Rubrik.CDM {
    <#
    .SYNOPSIS  
        PowerShell script to document the configuration of Rubrik CDM in Word/HTML/XML/Text formats
    .DESCRIPTION
        Documents the configuration of the Rubrik CDM in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
        Author:         Mike Preston
        Twitter:        @mwpreston
        Github:         mwpreston
        Credits:        Iain Brighton (@iainbrighton) - PScribo module
                        
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Rubrik.CDM
    #>

    param (
        [String[]] $Target,
        [PSCredential] $Credential,
        [String]$StylePath
    )

    # Import JSON Configuration for Options and InfoLevel
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # If custom style not set, use default style
    if (!$StylePath) {
        & "$PSScriptRoot\..\..\AsBuiltReport.Rubrik.CDM.Style.ps1"
    }

    #region Script Functions
    #---------------------------------------------------------------------------------------------#
    #                                    SCRIPT FUNCTIONS                                         #
    #---------------------------------------------------------------------------------------------#

    #endregion Script Functions

    #region Script Body
    #---------------------------------------------------------------------------------------------#
    #                                         SCRIPT BODY                                         #
    #---------------------------------------------------------------------------------------------#

    foreach ($brik in $Target) { 
        try {
            $RubrikCluster = Connect-Rubrik -Server $brik -Credential $Credential -ErrorAction Stop
        }
        catch {
            Write-Error $_
        }
        if ($RubrikCluster) {
            $ClusterInfo = Get-RubrikClusterInfo
            
            Section -Style Heading1 $($ClusterInfo.Name) {
                if ($InfoLevel.Cluster -ge 1) {
                    Section -Style Heading2 'Cluster Settings' { 
                        Paragraph ("The following section provides information on the configuration of the Rubrik CDM Cluster $($ClusterInfo.Name)")
                        BlankLine
                        
                        #-=MWP=- - add some blank lines like the example abbove
                        #Cluster Summary for InfoLevel 1/2 (Summary/Informative)
                        $ClusterSummary = [ordered]@{
                            'Name' = $ClusterInfo.Name
                            'Number of Briks' = $ClusterInfo.BrikCount
                            'Number of Nodes' = $ClusterInfo.NodeCount
                            'Software Version' = $ClusterInfo.softwareVersion
                        }
                        
                        # InfoLevel 3 (Detailed) adds disk/cpu/memory metrics
                        if ($InfoLevel.Cluster -ge 3) {
                            $ClusterSummary.Add('# CPU Cores', $ClusterInfo.CPUCoresCount)
                            $ClusterSummary.Add('Total Memory (GB)', $ClusterInfo.MemoryCapacityinGB)
                            $ClusterSummary.Add('Timezone', $ClusterInfo.timezone.timezone)
                        }
                        # InfoLevel 5 (Comprehensive) adds the rest!
                        if ($InfoLevel.Cluster -eq 5) {
                            $ClusterSummary.Add('Geo Location', $ClusterInfo.geolocation.address)
                            $ClusterSummary.Add('Software Encrypted', $ClusterInfo.isEncrypted)
                            $ClusterSummary.Add('Hardware Encrypted', $ClusterInfo.isHardwareEncrypted)
                            $ClusterSummary.Add('Cluster ID', $ClusterInfo.id)
                            $ClusterSummary.Add('Accepted EULA Version', $ClusterInfo.acceptedEULAVersion)
                            $ClusterSummary.Add('Has TPM Support', $ClusterInfo.hasTPM)
                            $ClusterSummary.Add('Connected to Polaris', $ClusterInfo.ConnectedToPolaris)
                            $ClusterSummary.Add('Platform', $ClusterInfo.Platform)
                            $ClusterSummary.Add('Running on Cloud', $ClusterInfo.isOnCloud)
                            $ClusterSummary.Add('Only Azure Support', $ClusterInfo.OnlyAzureSupport)
                            $ClusterSummary.Add('Is Single Node Appliance', $ClusterInfo.isSingleNode)
                            $ClusterSummary.Add('Registered', $ClusterInfo.isRegistered)
                            # Get Login Banner Info
                            $banner = Get-RubrikLoginBanner
                            $ClusterSummary.Add('Login Banner', $banner.loginBanner)
                        }

                        # Cluster Information Table
                        [pscustomobject]$ClusterSummary | Table -Name $ClusterSummary.Name -ColumnWidths 30,70 -List
                        

                        $StorageInfo = Get-RubrikClusterStorage
                        
                        $StorageSummary = [ordered]@{
                            'Total Usable Storage (TB)' = $StorageInfo.TotalUsableStorageInTb
                            'Used Storage (TB)' = $StorageInfo.UsedStorageInTb
                            'Available Storage (TB)' = $StorageInfo.AvailableStorageInTb
                        }
                        if ($InfoLevel.Cluster -ge 3) {
                            $StorageSummary.Add('Archival Storage Used (TB)',$StorageInfo.ArchivalUsageInTb)
                            $StorageSummary.Add('Live Mount Storage Used (GB)', $StorageInfo.LiveMountStorageInGb)
                        }
                        if ($InfoLevel.Cluster -eq 5) {
                            $StorageSummary.Add('Local Data Reduction Percentage', $StorageInfo.LocalDataReductionPercent)
                            $StorageSummary.Add('Archival Data Reduction Percentage', $StorageInfo.ArchivalDataReductionPercent)
                            $StorageSummary.Add('Average Daily Growth (GB)', $StorageInfo.AverageGrowthPerDayInGb)
                            $StorageSummary.Add('Estimated Runway (days)', $StorageInfo.EstimatedRunwayInDays)
                        }

                        
                        Section -Style Heading3 'Cluster Storage Details' {
                            [pscustomobject]$StorageSummary | Table -Name "Cluster Storage Details" -ColumnWidths 30,70 -List
                        }



                        # Node Overview Table
                        if ($InfoLevel.Cluster -ge 3) {
                            Section -Style Heading3 'Member Nodes' { 
                                $NodeInfo = Get-RubrikNode | Select -Property @{Name="Brik ID";Expression={$_.brikId}},
                                    @{Name="ID";Expression={$_.id}},
                                    @{Name="Status";Expression={$_.status}},
                                    @{Name="Support Tunnel";Expression={$_.supportTunnel}}
                                $NodeInfo | Table -Name "Cluster Node Information" -ColumnWidths 25,12,12,25,25
                            }
                        } # End InfoLevel -ge 3     

                        # Cluster Info - Networking
                        Section -Style Heading3 'Network Settings' {
                            Paragraph "The following contains network related settings for the cluster"
                            # Gather Information for level 1-5
                            $NodeDetails = Get-RubrikClusterNetworkInterface | Select -Property @{Name="Interface Name";Expression={$_.interfaceName}},
                                @{Name="Type";Expression={$_.interfaceType}},
                                @{Name="Node";Expression={$_.node}},
                                @{Name="IP Addresses";Expression={$_.ipAddresses}},
                                @{Name="Subnet Mask";Expression={$_.netmask}}
                            $DNSDetails = Get-RubrikDNSSetting
                            $DNSDetails = [ordered]@{
                                'DNS Servers'       = ($DNSDetails.DNSServers | Sort-Object) -join ', '
                                'Search Domains'    = ($DNSDetails.DNSSearchDomain | Sort-Object) -join ', '
                            }
                            $ProxyDetails = Get-RubrikProxySetting

                            
                            if ($InfoLevel.Cluster -lt 3) {
                                $NTPDetails = Get-RubrikNTPServer | Select -Property @{Name="Server";Expression={$_.server}}
                                $NetworkThrottleDetails = Get-RubrikNetworkThrottle | Select -Property @{Name="Resource ID";Expression={$_.resourceId}}, 
                                    @{Name="Enabled";Expression={$_.isEnabled}},
                                    @{Name="Default Throttle Limit";Expression={$_.defaultthrottleLimit}} 
                            }
                            else {
                                $NTPServers = Get-RubrikNTPServer  
                                $NTPDetails = @()
                                foreach ($ntpserver in $NTPServers) {
                                    $inObj = [ordered]@{
                                        'Server' = $ntpserver.server
                                        'Symmetric Key ID'  = $ntpserver.symmetricKey.keyId
                                        'Symmetric Key'  = $ntpserver.symmetricKey.key
                                        'Key Type'  = $ntpserver.symmetricKey.keyType
                                    }
                                    $NTPDetails += [pscustomobject]$inObj
                                }
                                $NetworkThrottleDetails = @()
                                $NetworkThrottles = Get-RubrikNetworkThrottle
                                foreach ($throttle in $NetworkThrottles) {
                                    $inObj = [ordered]@{
                                        'Resource ID' = $throttle.resourceId
                                        'Enabled'  = $throttle.isEnabled
                                        'Default Throttle Limit' = $throttle.defaultThrottleLimit
                                    }
                                    if ($null -eq $throttle.scheduledThrottles) { $strSchedule = ''}
                                    else {
                                        $strSchedule = New-Object Text.StringBuilder 
                                        foreach ($schedule in $throttle.scheduledThrottles) {
                                            $strSchedule.Append("Start Time: $($schedule.startTime)")
                                            $strSchedule.Append(" | End Time: $($schedule.endTime)")
                                            $strSchedule.Append(" | Days Of Week: $($schedule.daysOfWeek -Join ', ')")
                                            $strSchedule.Append(" | Throttle Limit: $($schedule.throttleLimit)")
                                            $strSchedule.Append("`n")
                                        }
                                    }
                                    $inObj.add('Scheduled Throttles', $strSchedule)
                                    $NetworkThrottleDetails += [pscustomobject]$inObj
                                }
                            }
                            Section -Style Heading4 'Cluster Interfaces' { 
                                $NodeDetails | Table -Name 'Cluster Node Information' 
                            }
                            Section -Style Heading4 'DNS Configuration' { 
                                [pscustomobject]$DNSDetails | Table -Name 'DNS Configuration' -List
                            }
                            Section -Style Heading4 'NTP Configuration' {  
                                $NTPDetails | Table -Name 'NTP Configuration'
                            }
                            Section -Style Heading4 'Network Throttling' {
                                $NetworkThrottleDetails | Table -Name 'Network Throttling'
                            }
                            Section -Style Heading4 'Proxy Server' {
                                if ($ProxyDetails.length -gt 0) { $ProxyDetails | Table -Name 'Proxy Configuration' }
                                else { Paragraph "There are currently no proxy servers configured on this cluster"}
                            }
                        } # End Heading 3 - Network Settings
                        Section -Style Heading3 'Notification Settings' {
                            Paragraph "The following contains notification settings configured on the cluster"
                            # Gather Information
                            $EmailDetails = Get-RubrikEmailSetting | Select -Property id, smtpHostname, smtpPort, smtpUsername, fromEmailId, smtpSecurity
                            
                            $SNMPInfo = Get-RubrikSNMPSetting
                            $inObj = [ordered]@{
                                    'Community String' = $($SNMPInfo.communityString)
                                    'Port'  = $SNMPInfo.snmpAgentPort
                                    'Enabled'  = $SNMPInfo.isEnabled
                            }
                            $strTraps = New-Object Text.StringBuilder 
                            foreach ($trap in $SNMPInfo.trapReceiverConfigs) {
                                $strTraps.Append("Address: $($trap.address)")
                                $strTraps.Append(" | Port: $($trap.port)")
                                $strTraps.Append("`n")
                            }
                            $inObj.add('Reciever Configurations', $strTraps)
                            $SNMPDetails = [pscustomobject]$inObj

                            $NotificationDetails = Get-RubrikNotificationSetting | Select -Property @{Name="ID";Expression={$_.id}},
                                @{Name="Event Types";Expression={$_.eventTypes}},
                                @{Name="SNMP Addresses";Expression={$_.snmpAddresses}},
                                @{Name="Email Addresses";Expression={$_.emailAddresses}},
                                @{Name="Send to Syslog";Expression={$_.souldSendToSyslog}}
                                
                            
                            
                            Section -Style Heading4 'Email Settings' { 
                                if ($EmailDetails.Length -gt 0) { $EmailDetails | Table -Name 'SNMP Settings' }
                                else { Paragraph "There are currently no email settings configured on this cluster"}
                            }
                            Section -Style Heading4 'SNMP Settings' { 
                                $SNMPDetails | Table -Name 'SNMP Settings' 
                            }
                            Section -Style Heading4 'Notification Settings' { 
                                $NotificationDetails | Table -Name 'Notification Settings' 
                            }
                        } # End Heading 3 - NOtification Settings
                        Section -Style Heading3 'Security Settings' {
                            Paragraph "The following contains security related settings configured on the cluster"
                            # Gather Information
                            # Global Configs for all InfoLevels
                            $IPMIInformation = Get-RubrikIPMI
                            $inObj =[ordered] @{
                                'IPMI Available'        = $IPMIInformation.isAvailable
                                'HTTPS Access'          = $IPMIInformation.access.https
                                'iKVM Access'           = $IPMIInformation.access.iKvm
                                'SSH Access'            = $IPMIInformation.access.ssh
                                'Virtual Media Access'  = $IPMIInformation.access.virtualMedia
                            }
                            $IPMIDetails = [pscustomobject]$inObj
                            $SecurityInformation = Get-RubrikSecurityClassification | Select @{N="Color";E={$_.classificationColor}},
                                @{N="Message";E={$_.classificationMessage}}


                            #Individual configs for specifed InfoLevels
                            if ($InfoLevel.Cluster -lt 3) {
                                $SMBDomainInformation = Get-RubrikSMBDomain | Select @{Name="Name";Expression={$_.name}},
                                    @{Name="Status";Expression={$_.status}},
                                    @{Name="Service Account";Expression={$_.serviceAccount}}
                                $SyslogInformation = Get-RubrikSyslogServer | Select @{N="Hostname";E={$_.hostname}},
                                    @{N="Protocol";E={$_.protocol}} 
                                $UserDetails = Get-RubrikUser | Select @{N="Username";E={$_.username}},
                                    @{N="First Name";E={$_.firstName}},
                                    @{N="Last Name";E={$_.lastName}},
                                    @{N="Email Address";E={$_.emailAddress}} | Sort-Object -Property Username
                                $LDAPDetails = Get-RubrikLDAP | Select @{N="Name";E={$_.name}},
                                    @{N="Domain Type";E={$_.domainType}},
                                    @{N="Initial Refresh";E={$_.initialRefreshStatus}}
                            }
                            else {
                                $SMBSecurityInformation = Get-RubrikSMBSecurity
                                $SMBDomainInformation = Get-RubrikSMBDomain | Select @{N="Name";E={$_.name}},
                                    @{N="Status";E={$_.status}},
                                    @{N="Service Account";E={$_.serviceAccount}},
                                    @{N="Sticky SMB Service";E={$_.isStickySmbService}},
                                    @{Name = 'Force SMB Security'; Expression = {$SMBSecurityInformation.enforceSmbSecurity}}
                                $SyslogInformation = Get-RubrikSyslogServer | Select @{N="ID";E={$_.id}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Port";E={$_.port}}
                                $UserInformation = Get-RubrikUser | Select UserName, FirstName, LastName, emailAddress, AuthDomainID, ID, 
                                    @{ Name = 'Permissions';  Expression = {Get-RubrikUserRole -id $_.id | Select @{Name='Perms'; Expression = {"ReadOnlyAdmin = $($_.readOnlyAdmin)`nAdmin = $($_.admin)`nOrgAdmin = $($_.orgAdmin)`nManagedVolumeAdmin = $($_.managedVolumeAdmin)`nOrganization=$($_.organization)`nManagedVolumeUser = $($_.managedVolumeUser)`nendUser = $($_.endUser)"}}}} | Sort-Object -Property Username
                                $UserDetails = @()
                                foreach ($user in $UserInformation) {
                                    $inObj =[ordered] @{
                                        'Username'        = $user.Username
                                        'First Name'          = $user.FirstName
                                        'Last Name'           = $user.LastName
                                        'Email Address'   = $User.emailAddress
                                        'Auth Domain ID'  = $user.AuthDomainID
                                        'ID'                = $user.id
                                        'Permissions'   = $user.permissions.perms
                                    } 
                                    $UserDetails += [pscustomobject]$inObj
                                }
                                #-=MWP=- fix below
                                $LDAPDetails = Get-RubrikLDAP | Select Name, DomainType, InitialRefreshStatus, dynamicDnsName, serviceAccount, bindUserName, @{Name="AdvancedOptions"; Expression = {$_.advancedOptions | Out-String}}
                            }
                            
                            # Add User Permissions to $UserInformation                
                            Section -Style Heading4 'IPMI Settings' { 
                                $IPMIDetails | Table -Name 'IPMI Settings' 
                            }

                            Section -Style Heading4 'SMB Domains' { 
                                $SMBDomainInformation | Table -Name 'SMB Domains' 
                            }

                            Section -Style Heading4 'Syslog Settings' { 
                                $SyslogInformation | Table -Name 'Syslog Settings' 
                            }

                            Section -Style Heading4 'Security Classification Settings' { 
                                $SecurityInformation | Table -Name 'Security Classification Settings' 
                            }
                            
                            if ($InfoLevel.Cluster -lt 3) {
                                Section -Style Heading4 'User Details' { 
                                    $UserDetails | Table -Name 'User Details'
                                }

                                Section -Style Heading4 'LDAP Settings' { 
                                    $LDAPDetails | Table -Name 'LDAP Settings' 
                                }
                            }
                            else {
                                Section -Style Heading4 'User Details' { 
                                    $UserDetails | Table -Name 'User Details' -ColumnWidths 20,80 -List
                                }

                                Section -Style Heading4 'LDAP Settings' { 
                                    $LDAPDetails | Table -Name 'LDAP Settings' -ColumnWidths 20,80 -List
                                }
                            }                          
                        } # End Heading 3 - Security Settings
                        Section -Style Heading3 'Backup Settings' {
                            Paragraph "The following contains backup related settings configured on the cluster"
                            # Gather Information
                            # Global Configs for all InfoLevels
                            $GuestOSCredentials = Get-RubrikGuestOsCredential | Select @{N="Username";E={$_.username}}, @{N="Domain";E={$_.domain}}
                            $BackupServiceDeployment = Get-RubrikBackupServiceDeployment | Select @{Name="Automatically Deploy RBS"; Expression = {$_.isAutomatic}}

                            Section -Style Heading4 'Guest OS Credentials' { 
                                $GuestOSCredentials | Table -Name 'Guest OS Credentials' -ColumnWidths 50,50
                            }
                            Section -Style Heading4 'Miscellaneous Backup Configurations' { 
                                $BackupServiceDeployment | Table -Name 'Miscellaneous Backup Configuration' -ColumnWidths 30,70 -List
                            }
                        } # End Heading 3 - Backup Settings
                        Section -Style Heading3 'Backup Sources' {
                            Paragraph "The following contains information around the backup sources configured on the cluster"
                            # Gather Information
                            # Global Configs for all InfoLevels
                           
                            # Level based info gathering
                            if ($InfoLevel.Cluster -lt 3) {
                                $VMwarevCenter = Get-RubrikvCenter -PrimaryClusterId "local" | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Username";E={$_.username}}
                                $VMwareVCD = Get-RubrikVCD | where {$_.PrimaryClusterId -eq (Get-RubrikSetting).id} | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}}, 
                                    @{N="Username";E={$_.username}}, 
                                    @{Name="Connection Status"; Expression={$_.connectionStatus.status}}
                                $NutanixClusters = Get-RubrikNutanixCluster -PrimaryClusterId "local" -DetailedObject | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Username";E={$_.username}}, 
                                    @{Name="Connection Status"; Expression={$_.connectionStatus.status}}
                                $SCVMMServers = Get-RubrikScvmm -PrimaryClusterId "local" -DetailedObject | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Run As";E={$_.runAsAccount}},
                                    @{N="Connection Status";E={$_.status}}
                                $WindowsHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Windows" | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Operating System";E={$_.operatingSystem}},
                                    @{N="Connection Status";E={$_.status}} 
                                $LinuxHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Linux" | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Operating System";E={$_.operatingSystem}},
                                    @{N="Connection Status";E={$_.status}} 
                            }
                            else {
                                $VMwarevCenter = Get-RubrikvCenter -PrimaryClusterId "local" | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Username";E={$_.username}}, 
                                    @{Name="VM Linking"; Expression = {$_.conflictResolutionAuthz}}, 
                                    @{Name="Certificate";E={$_.caCerts}}
                                $VMwareVCD = Get-RubrikVCD | where {$_.PrimaryClusterId -eq (Get-RubrikSetting).id} | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}}, 
                                    @{N="Username";E={$_.username}}, 
                                    @{Name="Connection Status"; Expression={$_.connectionStatus.status}}, 
                                    @{Name="Connection Message"; Expression={$_.connectionStatus.message}}, 
                                    @{N="Certificate";E={$_.caCerts}}
                                $NutanixClusters = Get-RubrikNutanixCluster -PrimaryClusterId "local" -DetailedObject | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Username";E={$_.username}}, 
                                    @{Name="Connection Status"; Expression={$_.connectionStatus.status}},
                                    @{N="Certificate";E={$_.caCerts}}
                                $SCVMMServers = Get-RubrikScvmm -PrimaryClusterId "local" -DetailedObject | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Run As";E={$_.runAsAccount}},
                                    @{N="Connection Status";E={$_.status}},
                                    @{N="Deploy Agent";E={$_.shouldDeployAgent}}
                                $WindowsHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Windows" -DetailedObject  | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Operating System";E={$_.operatingSystem}},
                                    @{N="Connection Status";E={$_.status}},
                                    @{N="Compression Enabled";E={$_.compressionEnabled}},
                                    @{N="Agent ID";E={$_.agentId}},
                                    @{N="MSSQL CBT Driver Installed";E={$_.mssqlCbtDriverInstalled}},
                                    @{N="MSSQL CBT Enabled";E={$_.mssqlCbtEnabled}},
                                    @{N="MSSQL CBT Status";E={$_.mssqlCbtEffectiveStatus}},
                                    @{N="VFD Driver State";E={$_.hostVfdDriverState}},
                                    @{N="VFD Enabled";E={$_.hostVfdEnabled}},
                                    @{N="Is Relic";E={$_.isRelic}}
                                $LinuxHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Linux" -DetailedObject | Select @{N="Name";E={$_.name}},
                                    @{N="Hostname";E={$_.hostname}},
                                    @{N="Operating System";E={$_.operatingSystem}},
                                    @{N="Connection Status";E={$_.status}},
                                    @{N="Compression Enabled";E={$_.compressionEnabled}},
                                    @{N="Agent ID";E={$_.agentId}},
                                    @{N="MSSQL CBT Driver Installed";E={$_.mssqlCbtDriverInstalled}},
                                    @{N="MSSQL CBT Enabled";E={$_.mssqlCbtEnabled}},
                                    @{N="MSSQL CBT Status";E={$_.mssqlCbtEffectiveStatus}},
                                    @{N="VFD Driver State";E={$_.hostVfdDriverState}},
                                    @{N="VFD Enabled";E={$_.hostVfdEnabled}},
                                    @{N="Is Relic";E={$_.isRelic}}
                            }

                            
                            Section -Style Heading4 'VMware vCenter Servers' { 
                                Paragraph "The following table outlines the VMware vCenter Servers which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $VMwarevCenter | Table -Name 'VMware vCenter Server'}
                                else {$VMwarevCenter | Table -Name 'VMware vCenter Server' -ColumnWidths 30,70 -List}
                            } 
                            Section -Style Heading4 'VMware vCloud Director Clusters' { 
                                Paragraph "The following table outlines the VMware vCloud Director clusters which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $VMwareVCD | Table -Name 'VMware vCloud Director Clusters' }
                                else {$VMwareVCD | Table -Name 'VMware vCloud Director Clusters' -ColumnWidths 30,70 -List}
                            } 
                            Section -Style Heading4 'Hyper-V SCVMM Servers' { 
                                Paragraph "The following table outlines the SCVMM Servers which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $SCVMMServers | Table -Name 'Hyper-V SCVMM Servers' }
                                else {$SCVMMServers | Table -Name 'Hyper-V SCVMM Servers' -ColumnWidths 30,70 -List }
                            } 
                            Section -Style Heading4 'Nutanix Clusters' { 
                                Paragraph "The following table outlines the Nutanix clusters which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) {$NutanixClusters | Table -Name 'Nutanix Clusters' }
                                else {$NutanixClusters | Table -Name 'Nutanix Clusters' -ColumnWidths 30,70 -List}
                            }
                            Section -Style Heading4 'Windows Hosts' { 
                                Paragraph "The following table outlines the Windows Hosts which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $WindowsHosts | Table -Name 'Windows Hosts' } 
                                else { $WindowsHosts | Table -Name 'Windows Hosts' -ColumnWidths 30,70 -List }
                            }
                            Section -Style Heading4 'Linux Hosts' { 
                                Paragraph "The following table outlines the Windows Hosts which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $LinuxHosts | Table -Name 'Linux Hosts' } 
                                else { $LinuxHosts | Table -Name 'Linux Hosts' -ColumnWidths 30,70 -List }
                            }
                            
                            #-=MWP=- Could add the following to this section in a later version 
                            # - Storage Arrays
                            # - Cloud Sources (AWS Protection)

                        } # End Heading 3 Backup Sources
                        Section -Style Heading3 'Replication Configuration' {
                            Paragraph "The following contains information  around the replication configuration on the cluster"
                            # Gather Information
                            # Global Configs for all InfoLevels
                            #-=MWP=- create checks for 0 results on all items
                            $ReplicationSources = Get-RubrikReplicationSource | Select @{N="Cluster Name";E={$_.sourceClusterName}},
                                @{N="Cluster Address";E={$_.sourceClusterAddress}},
                                @{N="Cluster UUID";E={$_.sourceClusterUuid}},
                                @{N="Replication Network Setup";E={$_.replicationSetup}}
                            $ReplicationTargets = Get-RubrikReplicationTarget | Select @{N="Cluster Name";E={$_.targetClusterName}},
                            @{N="Cluster Address";E={$_.targetClusterAddress}},
                            @{N="Cluster UUID";E={$_.targetClusterUuid}},
                            @{N="Replication Network Setup";E={$_.replicationSetup}}

                            Section -Style Heading4 'Replication Sources' { 
                                Paragraph "The following table outlines locations which have been configured as a replication source to this cluster"
                                $ReplicationSources | Table -Name 'Replication Sources'
                            }
                            Section -Style Heading4 'Replication Targets' { 
                                Paragraph "The following table outlines locations which have been configured as a replication targets for this cluster"
                                $ReplicationTargets | Table -Name 'Replication Sources'
                            }
                        } # End Heading 3 Replication Configuration
                        Section -Style Heading3 'Archive Targets' {
                            Paragraph "The following contains information around configured archive targets on the cluster"
                            # Gather Information
                            # Global Configs for all InfoLevels
                            $ArchiveTargets = Get-RubrikArchive | Select name, bucket, currentState, locationType
                            if ($InfoLevel.Cluster -lt 3) {
                                Section -Style Heading4 'S3 Targets' {
                                    if ( ($ArchiveTargets | Where-Object {$_.locationType -eq 'S3'}  | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'S3'} | Table -Name 'S3 Archives'
                                    }
                                    else { Paragraph "There are currenly no S3 targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Glacier Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Glacier'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Glacier'} | Table -Name 'Glacier Archives'
                                    }
                                    else { Paragraph "There are currenly no Glacier targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Azure Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Azure'} | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Azure'} | Table -Name 'Azure Archives'
                                    }
                                    else { Paragraph "There are currenly no Azure targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Google Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Table -Name 'Google Archives'
                                    }
                                    else { Paragraph "There are currenly no Google targets configured on the cluster."}
                                }
                                Section -Style Heading4 'NFS Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Nfs'}  | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'NFS'} | Table -Name 'NFS Archives'
                                    }
                                    else { Paragraph "There are currenly no NFS targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Tape Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Qstar'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'QStar'} | Table -Name 'Tape Archives'
                                    }
                                    else { Paragraph "There are currenly no tape targets configured on the cluster."}
                                }
                            }
                            else {
                                Section -Style Heading4 'S3 Archive Targets' {
                                    if ( ($ArchiveTargets | Where-Object {$_.locationType -eq 'S3'}  | Measure-Object ).count -gt 0) {
                                        $S3Targets = Get-RubrikArchive -ArchiveType S3 -DetailedObject | Select @{Name="Name"; Expression={$_.definition.name}},
                                                                    @{Name="Bucket";Expression={$_.definition.bucket}},   
                                                                    @{Name="Region";Expression={$_.definition.defaultRegion}},
                                                                    @{Name="Storage Class";Expression={$_.definition.storageClass}},
                                                                    @{Name="Consolidation Enabled";Expression={$_.definition.isConsolidationEnabled}},
                                                                    @{Name="Encryption Type";Expression={$_.definition.encryptionType}},
                                                                    @{Name="Access Key";Expression={$_.definition.accessKey}},
                                                                    @{Name="Compute Enabled";Expression={$_.definition.isComputeEnabled}},
                                                                    @{Name="Security Group";Expression={$_.definition.defaultComputeNetworkConfig.securityGroupId}},
                                                                    @{Name="VPC";Expression={$_.definition.defaultComputeNetworkConfig.vNetId}},
                                                                    @{Name="Subnet";Expression={$_.definition.defaultComputeNetworkConfig.subnetId}}
                                        
                                        $S3Targets | Table -Name 'S3 Archives' -List -ColumnWidths 30,70
                                    }
                                    else { Paragraph "There are currenly no S3 targets configured on the cluster."}
                                }
                                #-=MWP=- need Gaia to figure out.
                                Section -Style Heading4 'Glacier Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Glacier'} | Measure-Object  ).count -gt 0) {
                                        $GlacierTargets = Get-RubrikARchive -ArchiveType Glacier -DetailedObject | Select @{Name="Name";Expression={$_.definition.name}},
                                            @{Name="Host";Expression={$_.definition.host}},
                                            @{Name="Export";Expression={$_.definition.exportDir}},
                                            @{Name="Available Space (TB)";Expression={$_.availableSpace/1TB}}
                                            @{Name="Auth Type";Expression={$_.definition.authType}},
                                            @{Name="Version";Expression={$_.definition.nfsVersion}},
                                            @{Name="Consolidation Enabled";Expression={$_.definition.isConsolidationEnabled}},
                                            @{Name="File Lock Period (seconds)";Expression={$_.definition.fileLockPeriodInSeconds}},
                                            @{Name="NFS Options";Expression={$_.definition.otherNfsOptions}}
                                    }
                                    else { Paragraph "There are currenly no Glacier targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Azure Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Azure'} | Measure-Object ).count -gt 0) {
                                        $AzureTargets = Get-RubrikArchive -ArchiveType Azure -DetailedObject | Select @{Name="Name";Expression={$_.definition.name}},
                                            @{Name="Bucket";Expression={$_.definition.bucket}},   
                                            @{Name="Region";Expression={$_.definition.azureComputeSummary.region}},
                                            @{Name="Storage Account";Expression={$_.definition.azureComputeSummary.generalPurposeStorageAccountName}},
                                            @{Name="Container Name";Expression={$_.definition.azureComputeSummary.containerName}},
                                            @{Name="Consolidation Enabled";Expression={$_.definition.isConsolidationEnabled}},
                                            @{Name="Encryption Type";Expression={$_.definition.encryptionType}},
                                            @{Name="Access Key";Expression={$_.definition.accessKey}},
                                            @{Name="Compute Enabled";Expression={$_.definition.isComputeEnabled}},
                                            @{Name="Security Group";Expression={$_.definition.defaultComputeNetworkConfig.securityGroupId}},
                                            @{Name="Network";Expression={$_.definition.defaultComputeNetworkConfig.vNetId}},
                                            @{Name="Subnet";Expression={$_.definition.defaultComputeNetworkConfig.subnetId}},
                                            @{Name="Resource Group";Expression={$_.definition.defaultComputeNetworkConfig.resourceGroupId}}
                                        
                                        $AzureTargets | Table -Name 'Azure Archive Targets' -List -ColumnWidths 30,70
                                    }
                                    else { Paragraph "There are currenly no Azure targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Google Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Measure-Object  ).count -gt 0) {
                                        #Need GAIA -=MWP=-
                                    }
                                    else { Paragraph "There are currenly no Google targets configured on the cluster."}
                                }
                                Section -Style Heading4 'NFS Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'NFS'} | Measure-Object  ).count -gt 0) {
                                        $NFSTargets = Get-RubrikARchive -ArchiveType Nfs -DetailedObject | Select @{Name="Name";Expression={$_.definition.name}},
                                            @{Name="Host";Expression={$_.definition.host}},
                                            @{Name="Bucket";Expression={$_.definition.bucket}},
                                            @{Name="Export";Expression={$_.definition.exportDir}},
                                            @{Name="Available Space (TB)";Expression={$_.availableSpace/1TB}}
                                            @{Name="Auth Type";Expression={$_.definition.authType}},
                                            @{Name="Version";Expression={$_.definition.nfsVersion}},
                                            @{Name="Consolidation Enabled";Expression={$_.definition.isConsolidationEnabled}},
                                            @{Name="File Lock Period (seconds)";Expression={$_.definition.fileLockPeriodInSeconds}},
                                            @{Name="NFS Options";Expression={$_.definition.otherNfsOptions}}
                                        
                                        $NFSTargets | Table -Name 'NFS Archive Targets' -List -ColumnWidths 30,70
                                    }
                                    else { Paragraph "There are currenly no NFS targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Tape Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Qstar'} | Measure-Object  ).count -gt 0) {
                                        #Need GAIA -=MWP=-
                                    }
                                    else { Paragraph "There are currenly no tape targets configured on the cluster."}
                                }

                            }
                        } # End Heading 3 Archive Targets
                    } #End Heading 2
                }# end of Infolevel 1

                Section -Style Heading2 "SLA Domains" {
                    Paragraph ("The following section provides information on the configured SLA Domains")
                    BlankLine
                    if ($InfoLevel.SLADomains -lt 3) {
                        $SLADomains = Get-RubrikSLA -PrimaryClusterId 'local' | Select @{N="Name";E={$_.name}},
                        @{N="Base Frequency";E={if ($_.frequencies.hourly) {'{0} Hours' -f $_.frequencies.hourly.frequency} elseif ($_.frequencies.daily) {'{0} Days' -f $_.frequencies.daily.frequency}}},
                        @{N="Object Count";E={$_.numProtectedObjects}},
                        @{N="Archival Location";E={(Get-RubrikArchive -id $_.archivalSpecs.locationId).Name}},
                        @{N="Replication Location";E={(Get-RubrikReplicationTarget -id $_.replicationSpecs.locationId).targetClusterName}}                       
                    
                        $SLADomains | Table -Name 'SLA Domain Summary' 
                    }
                    elseif ($InfoLevel.SLADomains -le 5) {
                        #-=MWP=- add checks for zero results
                        $SLADomains = Get-RubrikSLA -PrimaryClusterId 'local' 
                        foreach ($SLADomain in $SLADomains) {
                            Section -Style Heading3 $SLADomain.name {
                                Paragraph ("The following outlines the configuration options for $($sladomain.name)")

                                Section -Style Heading4 "General Settings" {
                                    $BaseFrequency = if ($SLADomain.frequencies.hourly) {
                                        '{0} Hours' -f $SLADomain.frequencies.hourly.frequency
                                    } 
                                    elseif ($SLADomain.frequencies.daily) {
                                        '{0} Days' -f $SLADomain.frequencies.daily.frequency
                                    }
                                    if ($null -ne $SLADomain.archivalSpecs.locationId) {
                                        $ArchiveLocationName = (Get-RubrikArchive -id $SLADomain.archivalSpecs.locationId).Name
                                    }
                                    else { $ArchiveLocationName = ""}
                                    if ($null -ne $SLADomain.replicationSpecs.locationId) {
                                        $ReplicationLocationName = (Get-RubrikReplicationTarget -id $SLADomain.replicationSpecs.locationId).targetClusterName
                                    }
                                    else { $ReplicationLocationName = ""}
                                    $SLAGeneral =[ordered] @{
                                        'ID'                    = $SLADomain.id
                                        'Name'                  = $SLADomain.name
                                        'Object Count'          = $SLADomain.numProtectedObjects
                                        'Base Frequency'        = $BaseFrequency
                                        'Archival Location'     = $ArchiveLocationName
                                        'Replication Target'    = $ReplicationLocationName
                                    } 
                                    [PSCustomObject]$SLAGeneral | Table -Name "General Settings" -ColumnWidths 30,70 -List
                                }
                                Section -Style Heading4 "SLA Frequency Settings" {
                                    if ($null -ne $SLADomain.advancedUiConfig) {
                                        $SLAFrequency = @()

                                        if ($null -ne $SLADomain.frequencies.hourly.retention) {
                                            $HourlyRetentionType = ($SLADomain.advancedUiConfig | where {$_.timeUnit -eq 'Hourly'}).retentionType
                                            switch ($HourlyRetentionType) {
                                                "Weekly" { $HourlyRetention = "$($SLADomain.frequencies.hourly.retention) Week(s)" }
                                                "Daily" { $HourlyRetention = "$($SLADomain.frequencies.hourly.retention) Day(s)" }
                                            }
    
                                            $hourly = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.hourly.frequency) hour(s)"
                                                'Retain backups for' = $HourlyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$hourly
                                        }
                                        if ($null -ne $SLADomain.frequencies.daily.retention) {
                                            $DailyRetentionType = ($SLADomain.advancedUiConfig | where {$_.timeUnit -eq 'Daily'}).retentionType
                                            switch ($DailyRetentionType) {
                                                "Weekly" { $DailyRetention = "$($SLADomain.frequencies.daily.retention) Week(s)" }
                                                "Daily" { $DailyRetention = "$($SLADomain.frequencies.daily.retention) Day(s)" }
                                            }
                                            $daily = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.daily.frequency) day(s)"
                                                'Retain backups for' = $DailyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$daily
                                        }
                                        if ($null -ne $SLADomain.frequencies.weekly.retention) {
                                            #Weekly Retention is always weeks
                                            $WeeklyRetention = "$($SLADomain.frequencies.weekly.retention) Week(s)"
                                            $weekly = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.weekly.frequency) Week(s) on $($SLADomain.frequencies.weekly.dayOfWeek)"
                                                'Retain backups for' = $WeeklyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$weekly
                                        }
                                        if ($null -ne $SLADomain.frequencies.monthly.retention) {
                                            $MonthlyBackupTime = $SLADomain.frequencies.monthly.dayofMonth
                                            switch ($MonthlyBackupTime) {
                                                "LastDay" { $MonthStart = "the last day of the month."}
                                                "Fifteenth" { $MonthStart = "the 15th day of the month."}
                                                "FirstDay"  { $MonthStart = "the first day of the month."}
                                            }
                                            $MonthlyRetentionType = ($SLADomain.advancedUiConfig | where {$_.timeUnit -eq 'Monthly'}).retentionType
                                            switch ($MonthlyRetentionType) {
                                                "Monthly" { $MonthlyRetention = "$($SLADomain.frequencies.monthly.retention) Month(s)" }
                                                "Quarterly" { $MonthlyRetention = "$($SLADomain.frequencies.monthly.retention) Quarter(s)" }
                                                "Yearly" { $MonthlyRetention = "$($SLADomain.frequencies.monthly.retention) Year(s)" }
                                            }
                                            $monthly = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.monthly.frequency) Month(s) on $MonthStart"
                                                'Retain backups for' = $MonthlyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$monthly
                                        }
                                        if ($null -ne $SLADomain.frequencies.quarterly.retention) {
                                            $QuarterlyBackupTime = $SLADomain.frequencies.quarterly.dayofQuarter
                                            switch ($QuarterlyBackupTime) {
                                                "LastDay" { $QuarterStart = "the last day of the quarter"}
                                                "FirstDay"  { $QuarterStart = "the first day of the quarter"}
                                            }
                                            $QuarterMonthStart = $SLADomain.frequencies.quarterly.firstQuarterStartMonth

                                            $QuarterRetentionType = ($SLADomain.advancedUiConfig | where {$_.timeUnit -eq 'Quarterly'}).retentionType
                                            switch ($QuarterRetentionType) {
                                                "Quarterly" { $QuarterRetention = "$($SLADomain.frequencies.quarterly.retention) Quarter(s)" }
                                                "Yearly" { $QuarterRetention = "$($SLADomain.frequencies.quarterly.retention) Year(s)" }
                                            }
                                            $quarterly = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.quarterly.frequency) Quarter(s) on $QuarterStart beggining in $QuarterMonthStart"
                                                'Retain backups for' = $QuarterRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$quarterly
                                        }
                                        if ($null -ne $SLADomain.frequencies.yearly.retention) {
                                            $YearlyBackupTime = $SLADomain.frequencies.yearly.dayOfYear
                                            switch ($YearlyBackupTime) {
                                                "LastDay" { $YearStart = "the last day of the year"}
                                                "FirstDay"  { $YearStart = "the first day of the year"}
                                            }
                                            $YearMonthStart = $SLADomain.frequencies.yearly.yearStartMonth

                                            #Yearly time unit is always years
                                            $YearlyRetention = "$($SLADomain.frequencies.yearly.retention) Year(s)"
                                            $yearly = [ordered]@{
                                                'Take backups every' = "$($SLADomain.frequencies.yearly.frequency) Year(s) on $YearStart beggining in $YearMonthStart"
                                                'Retain backups for' = $YearlyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$yearly
                                        }
                                    }
                                    else {
                                        $SLAFrequency = @()
                                        
                                        if ($null -ne $SLADomain.frequencies.hourly.retention) {
                                            if ($SLADomain.frequencies.hourly.retention -gt 23) {
                                                $HourlyRetention = "$($SLADomain.frequencies.hourly.retention/24) Day(s)"
                                            }
                                            else {$HourlyRetention = "$($SLADomain.frequencies.hourly.retention) Hour(s)" }
                                            $hourly = @{
                                                'Take backups every' = "$($SLADomain.frequencies.hourly.frequency) Hour(s)"
                                                'Retain backups for' = $HourlyRetention
                                            }
                                            $SLAFrequency += [pscustomobject]$hourly
                                        }
                                        if ($null -ne $SLADomain.frequencies.daily.retention) {
                                            $daily = @{
                                                'Take backups every' = "$($SLADomain.frequencies.daily.frequency) Day(s)"
                                                'Retain backups for' = "$($SLADomain.frequencies.daily.retention)  Day(s)"
                                            }
                                            $SLAFrequency += [pscustomobject]$daily
                                        }
                                        if ($null -ne $SLADomain.frequencies.monthly.retention) {
                                            $monthly = @{
                                                'Take backups every' = "$($SLADomain.frequencies.monthly.frequency) Month(s)"
                                                'Retain backups for' = "$($SLADomain.frequencies.monthly.retention)  Month(s)"
                                            }
                                            $SLAFrequency += [pscustomobject]$monthly
                                        }
                                        if ($null -ne $SLADomain.frequencies.yearly.retention) {
                                            $yearly = @{
                                                'Take backups every' = "$($SLADomain.frequencies.yearly.frequency) Year(s)"
                                                'Retain backups for' = "$($SLADomain.frequencies.yearly.retention)  Year(s)"
                                            }
                                            $SLAFrequency += [pscustomobject]$yearly
                                        }
                                    }
                                    $SLAFrequency | Table -Name "SLA Frequencies" -Columns 'Take backups every','Retain backups for'
                                }
                                Section -Style Heading4 "SLA Archival Settings" {
                                    if ($null -ne $SLADomain.archivalSpecs.locationId) {
                                        $ArchiveInformation = Get-RubrikArchive -id $SLADomain.archivalSpecs.locationId -DetailedObject

                                        $Archive = [ordered] @{
                                            'Name'  = $ArchiveInformation.definition.name
                                            'Archive Location Type' = $ArchiveInformation.locationType
                                            'Archive data after' = "$($SLADomain.archivalSpecs.archivalThreshold/60/60/24) Day(s)"
                                        }

                                        [pscustomobject]$Archive | Table -Name "Archival Information" -List -ColumnWidths 30,70
                                    }
                                    else {
                                        Paragraph ("SLA Domain is not configured for archival")
                                    }
                                }
                                Section -Style Heading4 "SLA Replication Settings" {
                                    if ($null -ne $SLADomain.replicationSpecs.locationId) {
                                        $ReplicationInformation = Get-RubrikReplicationTarget -id $SLADomain.replicationSpecs.locationId 

                                        $Replication = [ordered] @{
                                            'Name'  = $ReplicationInformation.targetClusterName
                                            'Target Replication Cluster Address' = $ReplicationInformation.targetClusterAddress
                                            'Keep Replica on target cluster for' = "$($SLADomain.replicationSpecs.retentionLimit/60/60/24) Day(s)"
                                        }

                                        [pscustomobject]$Replication | Table -Name "Replication Information" -List -ColumnWidths 30,70
                                    }
                                    else {
                                        Paragraph ("SLA Domain is not configured for replication")
                                    }
                                }
                                
                                Section -Style Heading4 "SLA Protected Object Count" {
                                    if ($SLADomain.numProtectedObjects -gt 0) {
                                        #-=MWP=- may be able to use this strategy below to display columns above, rather than all the N= E=
                                        $SLADomain | Table -Name "Protected Object Summary" -Columns numVms,numHypervVms,numNutanixVms,numVcdVapps,numEc2Instances,numDbs,numOracleDbs,numFilesets,numWindowsVolumeGroups,numManagedVolumes,numShares,numStorageArrayVolumeGroups -Headers 'VMware VMs','HyperV VMs','Nutanix VMs','VCD vApps','EC2 Instances','MSSQL DBs','Oracle DBs','Filesets','Windows Volume Groups','Managed Volumes','NAS Shares','Storage Array Volumes' -List -ColumnWidths 30,70
                                    }
                                    else {
                                        Paragraph ("There are no objects assigned to this SLA Domain")
                                    }
                                     
                                }
                                
                                if ($InfoLevel.SLADomains -eq 5){
                                    Section -Style Heading4 "SLA Protected Objects Details" {
                                        Paragraph ("The following displays details about the objects protected by this SLA Domain")
                                        if ($SLADomain.numProtectedObjects -gt 0) {
                                            if ($SLADomain.numVms -gt 0) {
                                                Section -Style Heading5 "VMware VMs" {
                                                    $Objects = Get-RubrikVM -SLAID $SLADomain.Id | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected VMware VMs" -Columns Name,slaAssignment -Headers 'VM Name','Assignment Type' -ColumnWidths 50,50
                                                }
                                            }
                                            if ($SLADomain.numHyperVvms -gt 0) {
                                                Section -Style Heading5 "HyperV VMs" {
                                                    $Objects = Get-RubrikHyperVVM -SLAID $SLADomain.Id | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected HyperV VMs" -Columns Name,slaAssignment -Headers 'VM Name','Assignment Type' -ColumnWidths 50,50
                                                }
                                            }
                                            if ($SLADomain.numNutanixvms -gt 0) {
                                                Section -Style Heading5 "Nutanix VMs" {
                                                    $Objects = Get-RubrikNutanixVM -SLAID $SLADomain.Id | Sort-Object -Property Name 
                                                    $Objects | Table -Name "Protected Nutanix VMs" -Columns Name,slaAssignment -Headers 'VM Name','Assignment Type' -ColumnWidths 50,50
                                                }
                                            }
                                            if ($SLADomain.numVcdVapps -gt 0) {
                                                Section -Style Heading5 "VCD vApps" {
                                                    $Objects = Get-RubrikvApp -SLAID $SLADomain.Id | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected VCD vApps" -Columns Name,slaAssignment -Headers 'vApp Name','Assignment Type' -ColumnWidths 50,50
                                                }
                                            }
                                            #-=MWP=- Reserve for EC2 Instances - need to create cmdlet -=MWP=-
                                            if ($SLADomain.numDbs -gt 0) {
                                                Section -Style Heading5 "MSSQL Databases" {
                                                    $Objects = Get-RubrikDatabase -SLAID $SLADomain.Id  | Select -Property *,@{N="ParentHost";E={$_.rootProperties.rootName}} |Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected MSSQL Databases" -Columns Name,slaAssignment,ParentHost -Headers 'Database Name','Assignment Type','SQL Server/Availability Group' -ColumnWidths 33,33,34
                                                }
                                            }
                                            if ($SLADomain.numOracleDbs -gt 0) {
                                                Section -Style Heading5 "Oracle Databases" {
                                                    $Objects = Get-RubrikOracleDB -SLAID $SLADomain.Id | Select -Property *,@{N="ParentHost";E={$_.instances.hostName}} |  Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected Oracle Databases" -Columns Name,slaAssignment,ParentHost -Headers 'Database Name','Assignment Type','Oracle Server' -ColumnWidths 33,33,34
                                                }
                                            }
                                            #-=MWP=- add more information to this - fix all column widths to be the same
                                            if ($SLADomain.numFilesets -gt 0) {
                                                Section -Style Heading5 "Filesets" {
                                                    $Objects = Get-RubrikFileset -SLAID $SLADomain.Id | Select -Property *,@{N="slaAssignment";E={"Direct"}} | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected Filesets" -Columns Name,slaAssignment,hostname -Headers 'Fileset Name','Assignment Type','Attached to host' -ColumnWidths 33,33,34
                                                }
                                            }
                                            if ($SLADomain.numWindowsVolumeGroups -gt 0) {
                                                Section -Style Heading5 "Windows Volume Groups" {
                                                    $Objects = Get-RubrikVolumeGroup -SLAID $SLADomain.Id | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected Volume Groups" -Columns Name,slaAssignment,hostname -Headers 'Volume Group Name','Assignment Type','Attached to Host' -ColumnWidths 33,33,34
                                                }
                                            }
                                            if ($SLADomain.numManagedVolumes -gt 0) {
                                                Section -Style Heading5 "Managed Volumes" {
                                                    $Objects = Get-RubrikManagedVolume -SLAID $SLADomain.Id | Sort-Object -Property Name
                                                    $Objects | Table -Name "Protected Managed Volumes" -Columns Name,slaAssignment -Headers 'Managed Volume Name','Assignment Type' -ColumnWidths 50,50
                                                }
                                            }
                                            #-=MWP=- reserve for NAS Shares /internal/host_fileset/share
                                            # reserve for storage volume group protection
                                        }
                                        else {
                                            Paragraph ("There are no objects assigned to this SLA Domain")
                                        }
                                    }
                                }
                            }
                        }
                    } # End of ForEach SLA Domain
                } # End of Style Heading2 SLA Domains
                Section -Style Heading2 "Protected Objects" {
                    Paragraph("The following shows details around all protected objects configured within the Rubrik cluster")
                } # end of Style Heading2 Protected Objects
                Section -Style Heading2 "Snapshot Retention" {
                    Paragraph ("The following displays all relic, expired, and unmanaged objects within the Rubrik cluster")
                } # end of Style Heading2 Snapshot Retention
                Section -Style Heading2 "Custom Reports" {
                    Paragraph ("The following outlines any custom reports created within Rubrik.")
                } # end of Style Heading2 Custom Reports
            }
            
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function