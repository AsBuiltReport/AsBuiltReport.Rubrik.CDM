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
                                $NodeInfo = Get-RubrikNode | Select -Property brikId, id, status, supportTunnel
                                $NodeInfo | Table -Name "Cluster Node Information" -ColumnWidths 25,12,12,25,25
                            }
                        } # End InfoLevel -ge 3     

                        # Cluster Info - Networking
                        Section -Style Heading3 'Network Settings' {
                            Paragraph "The following contains network related settings for the cluster"
                            # Gather Information for level 1-5
                            $NodeDetails = Get-RubrikClusterNetworkInterface | Select -Property interfaceName, interfaceType, node, ipAddresses, netmask
                            $DNSDetails = Get-RubrikDNSSetting
                            $DNSDetails = [ordered]@{
                                'DNS Servers'       = ($DNSDetails.DNSServers | Sort-Object) -join ', '
                                'Search Domains'    = ($DNSDetails.DNSSearchDomain | Sort-Object) -join ', '
                            }
                            $ProxyDetails = Get-RubrikProxySetting

                            # Information for Level 3 and above
                            if ($InfoLevel.Cluster -lt 3) {
                                $NTPDetails = Get-RubrikNTPServer | Select -Property server
                                $NetworkThrottleDetails = Get-RubrikNetworkThrottle | Select -Property resourceId, isEnabled, defaultthrottleLimit
                            }
                            else {
                                $NTPServers = Get-RubrikNTPServer 
                                $NTPDetails = @()
                                foreach ($ntpserver in $NTPServers) {
                                    $inObj = [ordered]@{
                                        'server' = $ntpserver.server
                                        'symmetricKeyId'  = $ntpserver.symmetricKey.keyId
                                        'symmetricKey'  = $ntpserver.symmetricKey.key
                                        'symmetricKeyType'  = $ntpserver.symmetricKey.keyType
                                    }
                                    $NTPDetails += [pscustomobject]$inObj
                                }
                                $NetworkThrottleDetails = @()
                                $NetworkThrottles = Get-RubrikNetworkThrottle
                                foreach ($throttle in $NetworkThrottles) {
                                    $inObj = [ordered]@{
                                        'resourceId' = $throttle.resourceId
                                        'isEnabled'  = $throttle.isEnabled
                                        'defaultThrottleLimit' = $throttle.defaultThrottleLimit
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
                                    $inObj.add('scheduledThrottles', $strSchedule)
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
                                    'communityString' = $($SNMPInfo.communityString)
                                    'snmpAgentPort'  = $SNMPInfo.snmpAgentPort
                                    'isEnabled'  = $SNMPInfo.isEnabled
                            }
                            $strTraps = New-Object Text.StringBuilder 
                            foreach ($trap in $SNMPInfo.trapReceiverConfigs) {
                                $strTraps.Append("Address: $($trap.address)")
                                $strTraps.Append(" | Port: $($trap.port)")
                                $strTraps.Append("`n")
                            }
                            $inObj.add('trapReceiverConfigs', $strTraps)
                            $SNMPDetails = [pscustomobject]$inObj

                            $NotificationDetails = Get-RubrikNotificationSetting | Select -Property id,eventTypes, snmpAddresses, emailAddresses,shouldSendToSyslog
                            
                            
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
                            $SecurityInformation = Get-RubrikSecurityClassification | Select classificationColor, classificationMessage
                            
                            

                            #Individual configs for specifed InfoLevels
                            if ($InfoLevel.Cluster -lt 3) {
                                $SMBDomainInformation = Get-RubrikSMBDomain | Select Name, Status, ServiceAccount
                                $SyslogInformation = Get-RubrikSyslogServer | Select hostname, protocol
                                $UserDetails = Get-RubrikUser | Select Username, FirstName, LastName, emailAddress
                                $LDAPDetails = Get-RubrikLDAP | Select Name, DomainType, IntialRefreshStatus
                            }
                            else {
                                $SMBSecurityInformation = Get-RubrikSMBSecurity
                                $SMBDomainInformation = Get-RubrikSMBDomain | Select Name, Status, ServiceAccount, isStickySmbService, @{Name = 'Force SMB Security'; Expression = {$SMBSecurityInformation.enforceSmbSecurity}}
                                $SyslogInformation = Get-RubrikSyslogServer | Select id, hostname, port, protocol
                                $UserInformation = Get-RubrikUser | Select UserName, FirstName, LastName, emailAddress, AuthDomainID, ID, @{ Name = 'Permissions';  Expression = {Get-RubrikUserRole -id $_.id | Select @{Name='Perms'; Expression = {"ReadOnlyAdmin = $($_.readOnlyAdmin)`nAdmin = $($_.admin)`nOrgAdmin = $($_.orgAdmin)`nManagedVolumeAdmin = $($_.managedVolumeAdmin)`nOrganization=$($_.organization)`nManagedVolumeUser = $($_.managedVolumeUser)`nendUser = $($_.endUser)"}}}}
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
                            $GuestOSCredentials = Get-RubrikGuestOsCredential | Select username, domain
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
                                $VMwarevCenter = Get-RubrikvCenter -PrimaryClusterId "local" | Select name, hostname, username
                                $VMwareVCD = Get-RubrikVCD | where {$_.PrimaryClusterId -eq (Get-RubrikSetting).id} | Select name, hostname, username, @{Name="ConnectionStatus"; Expression={$_.connectionStatus.status}}
                                $NutanixClusters = Get-RubrikNutanixCluster -PrimaryClusterId "local" | Select name, hostname, username,  @{Name="ConnectionStatus"; Expression={$_.connectionStatus.status}}
                                $SCVMMServers = Get-RubrikScvmm -PrimaryClusterId "local" -DetailedObject | Select name, hostname, runAsAccount, status
                                $WindowsHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Windows" | Select name, hostname, operatingSystem, status
                                $LinuxHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Linux" | Select name, hostname, operatingSystem, status
                            }
                            else {
                                $VMwarevCenter = Get-RubrikvCenter -PrimaryClusterId "local" | Select name, hostname, username, @{Name="VM Linking"; Expression = {$_.conflictResolutionAuthz}}, caCerts
                                $VMwareVCD = Get-RubrikVCD | where {$_.PrimaryClusterId -eq (Get-RubrikSetting).id} | Select name, hostname, username, @{Name="ConnectionStatus"; Expression={$_.connectionStatus.status}}, @{Name="ConnectionMessage"; Expression={$_.connectionStatus.message}}, caCerts
                                $NutanixClusters = Get-RubrikNutanixCluster -PrimaryClusterId "local" | Select name, hostname, username,  @{Name="ConnectionStatus"; Expression={$_.connectionStatus.status}}, caCerts
                                $SCVMMServers = Get-RubrikScvmm -PrimaryClusterId "local" -DetailedObject | Select name, hostname, runAsAccount, status, shouldDeployAgent
                                $WindowsHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Windows" -DetailedObject | Select name, hostname, operatingSystem, status, compressionEnabled, agentId, mssqlCbtDriverInstalled, mssqlCbtEnabled, mmsqlCbtEffectiveStatus, hostVfdDriverState, hostVfdEnabled, isRelic
                                $LinuxHosts = Get-RubrikHost -PrimaryClusterId "local" -Type "Linux" -DetailedObject | Select name, hostname, operatingSystem, status, compressionEnabled, agentId, mssqlCbtDriverInstalled, mssqlCbtEnabled, mmsqlCbtEffectiveStatus, hostVfdDriverState, hostVfdEnabled, isRelic
                            }

                            
                            Section -Style Heading4 'VMware vCenter Servers' { 
                                Paragraph "The following table outlines the VMware vCenter Servers which have been added to the Rubrik cluster"
                                $VMwarevCenter | Table -Name 'VMware vCenter Server' -ColumnWidths 30,70 -List
                            } 
                            Section -Style Heading4 'VMware vCloud Director Clusters' { 
                                Paragraph "The following table outlines the VMware vCloud Director clusters which have been added to the Rubrik cluster"
                                $VMwareVCD | Table -Name 'VMware vCloud Director Clusters' -ColumnWidths 30,70 -List
                            } 
                            Section -Style Heading4 'Hyper-V SCVMM Servers' { 
                                Paragraph "The following table outlines the SCVMM Servers which have been added to the Rubrik cluster"
                                $SCVMMServers | Table -Name 'Hyper-V SCVMM Servers' -ColumnWidths 30,70 -List
                            } 
                            Section -Style Heading4 'Nutanix Clusters' { 
                                Paragraph "The following table outlines the Nutanix clusters which have been added to the Rubrik cluster"
                                $NutanixClusters | Table -Name 'Nutanix Clusters' -ColumnWidths 30,70 -List
                            }
                            #-=MWP=- - could try converting params to splats to reduce code here.  Also, add the same logic of tables for < 3 and lists for > 3 to sections above
                            Section -Style Heading4 'Windows Hosts' { 
                                Paragraph "The following table outlines the Windows Hosts which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $WindowsHosts | Table -Name 'Windows Hosts' -Table } 
                                else { $WindowsHosts | Table -Name 'Windows Hosts' -ColumnWidths 30,70 -List }
                            }
                            Section -Style Heading4 'Linux Hosts' { 
                                Paragraph "The following table outlines the Windows Hosts which have been added to the Rubrik cluster"
                                if ($InfoLevel.Cluster -lt 3) { $LinuxHosts | Table -Name 'Linux Hosts' -Table } 
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
                            #-=MWP=- also ensure all column names are in plain english - both below and above. - also, check for 0 results
                            $ReplicationSources = Get-RubrikReplicationSource | Select sourceClusterName, sourceClusterAddress, sourceClusterUuid, replicationSetup
                            $ReplicationTargets = Get-RubrikReplicationTarget | Select targetClusterName, targetClusterAddress, targetClusterUuid, replicationSetup
                            
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
  

            }
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function