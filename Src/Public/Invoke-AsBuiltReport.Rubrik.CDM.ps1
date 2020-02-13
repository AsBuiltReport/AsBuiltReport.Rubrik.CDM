function Invoke-AsBuiltReport.Rubrik.CDM {
    <#
    .SYNOPSIS  
        PowerShell script to document the configuration of Rubrik CDM in Word/HTML/XML/Text formats
    .DESCRIPTION
        Documents the configuration of the Rubrik CDM in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        0.0.2
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
                                               
                        Section -Style Heading3 'Cluster Storage Details' {
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
                            [pscustomobject]$StorageSummary | Table -Name "Cluster Storage Details" -ColumnWidths 30,70 -List
                        }

                        # Node Overview Table
                        if ($InfoLevel.Cluster -ge 3) {
                            Section -Style Heading3 'Member Nodes' { 
                                $NodeInfo = Get-RubrikNode 
                                $NodeInfo | Table -Name "Cluster Node Information" -ColumnWidths 25,12,12,25,25 -Columns brikId,id,status,supportTunnel -Headers 'Brik ID','ID','Status','Support Tunnel'
                            }
                        } # End InfoLevel -ge 3     

                        # Cluster Info - Networking
                        Section -Style Heading3 'Network Settings' {
                            Paragraph "The following contains network related settings for the cluster"
                            
                            Section -Style Heading4 'Cluster Interfaces' { 
                                $NodeDetails = Get-RubrikClusterNetworkInterface | Select -Property @{N="Interface Name";E={$_.interfaceName}},
                                    @{N="Type";E={$_.interfaceType}},@{N="Node";E={$_.node}},
                                    @{N="IP Addresses";E={$_.ipAddresses}},@{N="Subnet Mask";E={$_.netmask}}
                                $NodeDetails | Table -Name 'Cluster Node Information' 
                            }


                            Section -Style Heading4 'DNS Configuration' { 
                                $DNSDetails = Get-RubrikDNSSetting
                                $DNSDetails = [ordered]@{
                                    'DNS Servers'       = ($DNSDetails.DNSServers | Out-String)
                                    'Search Domains'    = ($DNSDetails.DNSSearchDomain | Out-String)
                                }
                                [pscustomobject]$DNSDetails | Table -Name 'DNS Configuration' -List
                            }
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
                            Section -Style Heading4 'NTP Configuration' {  
                                $NTPDetails | Table -Name 'NTP Configuration'
                            }
                            Section -Style Heading4 'Network Throttling' {
                                $NetworkThrottleDetails | Table -Name 'Network Throttling'
                            }
                            Section -Style Heading4 'Proxy Server' {
                                $ProxyDetails = Get-RubrikProxySetting
                                if ($ProxyDetails.length -gt 0) { $ProxyDetails | Table -Name 'Proxy Configuration' }
                                else { Paragraph "There are currently no proxy servers configured on this cluster"}
                            }

                        } # End Heading 3 - Network Settings
                        Section -Style Heading3 'Notification Settings' {
                            Paragraph "The following contains notification settings configured on the cluster"
                           
                            Section -Style Heading4 'Email Settings' { 
                                $EmailDetails = Get-RubrikEmailSetting
                                if ($EmailDetails.Length -gt 0) { $EmailDetails | Table -Name 'Email Details' -Columns id,smtpHostname,smtpPort,smtpUsername,fromEmailId,smtpSecurity -Headers 'ID','SMTP Server','Port','Username','From Email','Security' }
                                else { Paragraph "There are currently no email settings configured on this cluster"}
                            }
                            Section -Style Heading4 'SNMP Settings' { 
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
                                $inObj.add('Receiver Configurations', $strTraps)
                                $SNMPDetails = [pscustomobject]$inObj
                                $SNMPDetails | Table -Name 'SNMP Settings' 
                            }
                            
                            Section -Style Heading4 'Notification Settings' { 
                                $NotificationDetails = Get-RubrikNotificationSetting | Select -Property @{N="ID";E={$_.id}}, 
                                    @{N="Event Types";E={$_.eventTypes | Out-String}},@{N="SNMP Addresses";E={$_.snmpAddresses}},
                                    @{N="Email Addresses";E={$_.emailAddresses}},@{N="Send to syslog";E={$_.shouldSendToSyslog}}
                                $NotificationDetails | Table -Name 'Notification Settings' 
                            }
                        } # End Heading 3 - NOtification Settings
                        Section -Style Heading3 'Security Settings' {
                            Paragraph "The following contains security related settings configured on the cluster"
                           
                            Section -Style Heading4 'IPMI Settings' { 
                                $IPMIInformation = Get-RubrikIPMI
                                $inObj =[ordered] @{
                                    'IPMI Available'        = $IPMIInformation.isAvailable
                                    'HTTPS Access'          = $IPMIInformation.access.https
                                    'iKVM Access'           = $IPMIInformation.access.iKvm
                                    'SSH Access'            = $IPMIInformation.access.ssh
                                    'Virtual Media Access'  = $IPMIInformation.access.virtualMedia
                                }
                                $IPMIDetails = [pscustomobject]$inObj
                                $IPMIDetails | Table -Name 'IPMI Settings' 
                            }
                            Section -Style Heading4 'SMB Domains' {
                                if ($InfoLevel.Cluster -in (1,2)){
                                    $SMBDomainInformation = Get-RubrikSMBDomain | Select @{Name="Name";Expression={$_.name}},
                                        @{Name="Status";Expression={$_.status}},
                                        @{Name="Service Account";Expression={$_.serviceAccount}}
                                }
                                else {
                                    $SMBSecurityInformation = Get-RubrikSMBSecurity
                                    $SMBDomainInformation = Get-RubrikSMBDomain | Select @{N="Name";E={$_.name}},
                                        @{N="Status";E={$_.status}},
                                        @{N="Service Account";E={$_.serviceAccount}},
                                        @{N="Sticky SMB Service";E={$_.isStickySmbService}},
                                        @{Name = 'Force SMB Security'; Expression = {$SMBSecurityInformation.enforceSmbSecurity}}
                                } 
                                $SMBDomainInformation | Table -Name 'SMB Domains' 
                            }
                            Section -Style Heading4 'Syslog Settings' { 
                                $SyslogInformation = Get-RubrikSyslogServer | Select -Property @{N="Hostname";E={$_.hostname}},
                                    @{N="Protocol";E={$_.protocol}},@{N="Port";E={$_.port}}
                                $SyslogInformation | Table -Name 'Syslog Settings'
                            }
                            Section -Style Heading4 'Security Classification Settings' {
                                $SecurityInformation = Get-RubrikSecurityClassification | Select -Property @{N="Color";E={$_.classificationColor}},
                                    @{N="Message";E={$_.classificationMessage}}
                                $SecurityInformation | Table -Name 'Security Classification Settings' -ColumnWidths 50,50
                            }

                            Section -Style Heading4 'User Details' { 
                                if ($InfoLevel.Cluster -in (1,2)){
                                    $UserDetails = Get-RubrikUser | Select -Property @{N="Username";E={$_.username}},
                                        @{N="First Name";E={$_.firstName}},@{N="Last Name";E={$_.lastName}},
                                        @{N="Email Address";E={$_.emailAddress}}
                                    $UserDetails | Sort-Object -Property Username | Table -Name 'User Details' 
                                }
                                else {
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
                                    $UserDetails | Table -Name 'User Details' -ColumnWidths 20,80 -List
                                }
                            }
                            Section -Style Heading4 'LDAP Settings' { 
                                if ($InfoLevel.Cluster -in (1,2)) {
                                    $LDAPDetails = Get-RubrikLDAP | Select -Property @{N="Name";E={$_.name}},
                                        @{N="Domain Type";E={$_.domainType}},@{N="Initial Refresh Status";E={$_.initialRefreshStatus}}
                                    $LDAPDetails | Table -Name 'LDAP Settings' 
                                }
                                else {
                                    $LDAPDetails = Get-RubrikLDAP | Select -Property @{N="Name";E={$_.name}},
                                        @{N="Domain Type";E={$_.domainType}},@{N="Initial Refresh Status";E={$_.initialRefreshStatus}},
                                        @{N="Dynamic DNS Name";E={$_.dynamicDnsName}},@{N="Service Account";E={$_.serviceAccount}},
                                        @{N="Bind Username";E={$_.bindUserName}},@{Name="Advanced Options"; Expression = {$_.advancedOptions | Out-String}}
                                    $LDAPDetails | Table -Name 'LDAP Settings' -ColumnWidths 20,80 -List 
                                }
                            }
                        } # End Heading 3 - Security Settings
                        Section -Style Heading3 'Backup Settings' {
                            Paragraph "The following contains backup related settings configured on the cluster"
                            
                            Section -Style Heading4 'Guest OS Credentials' { 
                                $GuestOSCredentials = Get-RubrikGuestOsCredential | Select -Property @{N="Username";E={$_.username}},
                                    @{N="Domain";E={$_.domain}}
                                $GuestOSCredentials | Table -Name 'Guest OS Credentials' -ColumnWidths 50,50 
                            }
                            Section -Style Heading4 'Miscellaneous Backup Configurations' { 
                                $BackupServiceDeployment = Get-RubrikBackupServiceDeployment | Select @{Name="Automatically Deploy RBS"; Expression = {$_.isAutomatic}}
                                $BackupServiceDeployment | Table -Name 'Miscellaneous Backup Configuration' -ColumnWidths 30,70 -List 
                            }
                        } # End Heading 3 - Backup Settings
                        Section -Style Heading3 'Backup Sources' {
                            Paragraph "The following contains information around the backup sources configured on the cluster"
                            
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


                            if (0 -ne ($VMwarevCenter | Measure-Object).count ) {
                                Section -Style Heading4 'VMware vCenter Servers' { 
                                    Paragraph "The following table outlines the VMware vCenter Servers which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) { $VMwarevCenter | Table -Name 'VMware vCenter Server'}
                                    else {$VMwarevCenter | Table -Name 'VMware vCenter Server' -ColumnWidths 30,70 -List}
                                } 
                            }
                            if (0 -ne ($VMwareVCD | Measure-Object).count ) {
                                Section -Style Heading4 'VMware vCloud Director Clusters' { 
                                    Paragraph "The following table outlines the VMware vCloud Director clusters which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) { $VMwareVCD | Table -Name 'VMware vCloud Director Clusters' }
                                    else {$VMwareVCD | Table -Name 'VMware vCloud Director Clusters' -ColumnWidths 30,70 -List}
                                }
                            } 
                            if (0 -ne ($SCVMMServers | Measure-Object).count ) {
                                Section -Style Heading4 'Hyper-V SCVMM Servers' { 
                                    Paragraph "The following table outlines the SCVMM Servers which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) { $SCVMMServers | Table -Name 'Hyper-V SCVMM Servers' }
                                    else {$SCVMMServers | Table -Name 'Hyper-V SCVMM Servers' -ColumnWidths 30,70 -List }
                                }
                            } 
                            if (0 -ne ($NutanixClusters | Measure-Object).count ) {
                                Section -Style Heading4 'Nutanix Clusters' { 
                                    Paragraph "The following table outlines the Nutanix clusters which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) {$NutanixClusters | Table -Name 'Nutanix Clusters' }
                                    else {$NutanixClusters | Table -Name 'Nutanix Clusters' -ColumnWidths 30,70 -List}
                                }
                            }
                            if (0 -ne ($WindowsHosts | Measure-Object).count ) {
                                Section -Style Heading4 'Windows Hosts' { 
                                    Paragraph "The following table outlines the Windows Hosts which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) { $WindowsHosts | Table -Name 'Windows Hosts' } 
                                    else { $WindowsHosts | Table -Name 'Windows Hosts' -ColumnWidths 30,70 -List }
                                }
                            }
                            if (0 -ne ($LinuxHosts | Measure-Object).count ) {
                                Section -Style Heading4 'Linux Hosts' { 
                                    Paragraph "The following table outlines the Linux Hosts which have been added to the Rubrik cluster"
                                    if ($InfoLevel.Cluster -lt 3) { $LinuxHosts | Table -Name 'Linux Hosts' } 
                                    else { $LinuxHosts | Table -Name 'Linux Hosts' -ColumnWidths 30,70 -List }
                                }
                            }
                        } # End Heading 3 Backup Sources
                        Section -Style Heading3 'Replication Configuration' {
                            Paragraph "The following contains information  around the replication configuration on the cluster"
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
                            $ArchiveTargets = Get-RubrikArchive | Select -Property @{N="Name";E={$_.name}},
                                @{N="Bucket";E={$_.bucket}},@{N="State";E={$_.currentState}},
                                @{N="LocationType";E={$_.locationType}}
                            if ($InfoLevel.Cluster -lt 3) {
                                Section -Style Heading4 'S3 Targets' {
                                    if ( ($ArchiveTargets | Where-Object {$_.locationType -eq 'S3'}  | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'S3'} | Table -Name 'S3 Archives'
                                    }
                                    else { Paragraph "There are currently no S3 targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Glacier Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Glacier'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Glacier'} | Table -Name 'Glacier Archives'
                                    }
                                    else { Paragraph "There are currently no Glacier targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Azure Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Azure'} | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Azure'} | Table -Name 'Azure Archives'
                                    }
                                    else { Paragraph "There are currently no Azure targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Google Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Table -Name 'Google Archives'
                                    }
                                    else { Paragraph "There are currently no Google Cloud targets configured on the cluster."}
                                }
                                Section -Style Heading4 'NFS Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Nfs'}  | Measure-Object ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'NFS'} | Table -Name 'NFS Archives'
                                    }
                                    else { Paragraph "There are currently no NFS targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Tape Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Qstar'} | Measure-Object  ).count -gt 0) {
                                        $ArchiveTargets | Where-Object {$_.locationType -eq 'QStar'} | Table -Name 'Tape Archives'
                                    }
                                    else { Paragraph "There are currently no tape targets configured on the cluster."}
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
                                    else { Paragraph "There are currently no S3 targets configured on the cluster."}
                                }
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
                                    else { Paragraph "There are currently no Glacier targets configured on the cluster."}
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
                                    else { Paragraph "There are currently no Azure targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Google Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Google'} | Measure-Object  ).count -gt 0) {
                                    }
                                    else { Paragraph "There are currently no Google Cloud targets configured on the cluster."}
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
                                    else { Paragraph "There are currently no NFS targets configured on the cluster."}
                                }
                                Section -Style Heading4 'Tape Targets' {
                                    if (($ArchiveTargets | Where-Object {$_.locationType -eq 'Qstar'} | Measure-Object  ).count -gt 0) {
                                    }
                                    else { Paragraph "There are currently no tape targets configured on the cluster."}
                                }

                            }
                        } # End Heading 3 Archive Targets
                    } #End Heading 2
                }# end of Infolevel 1
                if ($InfoLevel.SLADomains -ge 1) {
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
                                                        $Objects = Get-RubrikVM -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected VMware VMs" -ColumnWidths 50,50
                                                    }
                                                }
                                                if ($SLADomain.numHyperVvms -gt 0) {
                                                    Section -Style Heading5 "HyperV VMs" {
                                                        $Objects = Get-RubrikHyperVVM -SLAID $SLADomain.Id |Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected HyperV VMs" -ColumnWidths 50,50
                                                    }
                                                }
                                                if ($SLADomain.numNutanixvms -gt 0) {
                                                    Section -Style Heading5 "Nutanix VMs" {
                                                        $Objects = Get-RubrikNutanixVM -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}} |Sort-Object -Property Name 
                                                        $Objects | Table -Name "Protected Nutanix VMs" -ColumnWidths 50,50
                                                    }
                                                }
                                                if ($SLADomain.numVcdVapps -gt 0) {
                                                    Section -Style Heading5 "VCD vApps" {
                                                        $Objects = Get-RubrikvApp -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected VCD vApps"  -ColumnWidths 50,50
                                                    }
                                                }
                                                #-=MWP=- Reserve for EC2 Instances - need to create cmdlet -=MWP=-
                                                if ($SLADomain.numDbs -gt 0) {
                                                    Section -Style Heading5 "MSSQL Databases" {
                                                        $Objects = Get-RubrikDatabase -SLAID $SLADomain.Id  | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}},@{N="Parent Host";E={$_.rootProperties.rootName}} |Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected MSSQL Databases" -ColumnWidths 33,33,34
                                                    }
                                                }
                                                if ($SLADomain.numOracleDbs -gt 0) {
                                                    Section -Style Heading5 "Oracle Databases" {
                                                        $Objects = Get-RubrikOracleDB -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}},@{N="ParentHost";E={$_.instances.hostName}} |  Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected Oracle Databases" -ColumnWidths 33,33,34
                                                    }
                                                }
                                                if ($SLADomain.numFilesets -gt 0) {
                                                    Section -Style Heading5 "Filesets" {
                                                        $Objects = Get-RubrikFileset -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={"Direct"}},@{N="Attached to host";E={$_.hostname}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected Filesets" -ColumnWidths 33,33,34
                                                    }
                                                }
                                                if ($SLADomain.numWindowsVolumeGroups -gt 0) {
                                                    Section -Style Heading5 "Windows Volume Groups" {
                                                        $Objects = Get-RubrikVolumeGroup -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}},@{N="Attached to host";E={$_.hostname}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected Volume Groups"  -ColumnWidths 33,33,34
                                                    }
                                                }
                                                if ($SLADomain.numManagedVolumes -gt 0) {
                                                    Section -Style Heading5 "Managed Volumes" {
                                                        $Objects = Get-RubrikManagedVolume -SLAID $SLADomain.Id | Select-Object -Property @{N="Name";E={$_.name}},@{N="Assignment Type";E={$_.slaAssignment}} | Sort-Object -Property Name
                                                        $Objects | Table -Name "Protected Managed Volumes" -ColumnWidths 50,50
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
                }
                if ($InfoLevel.ProtectedObjects -ge 1) {
                    Section -Style Heading2 "Protected Objects" {
                        Paragraph("The following shows details around all protected objects configured within the Rubrik cluster")
                        if ($InfoLevel.ProtectedObjects -in (1,2)) {
                            $VMwareVMs = Get-RubrikVM -Relic:$false -PrimaryClusterID 'local' | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}}
                            $HyperVVMs = Get-RubrikHypervVM -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}}
                            $NutanixVMs = Get-RubrikNutanixVM -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}}
                            $MSSQLDatabases = Get-RubrikDatabase -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="Recovery Model";E={$_.recoveryModel}},@{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}
                            $OracleDatabases = Get-RubrikOracleDB -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="SID";E={$_.sid}},  @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}
                            $Filesets = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -eq $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Operating System";E={$_.operatingSystemType}},@{N="Fileset Name";E={$_.name}}, 
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}}
                            $NasShares = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -ne $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Fileset Name";E={$_.name}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}}
                            $VolumeGroups = Get-RubrikVolumeGroup -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Volume Group name";E={$_.name}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}
                            $ManagedVolumes = Get-RubrikManagedVolume -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="Volume Size";E={$_.volumeSize}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}
                        }
                        elseif ($InfoLevel.ProtectedObjects -in (3,4)) {
                            #first level if check on total is temporary 
                            #this must be in place for sending additional GETs or Foreach
                            #as we may bet back null results (but have data/hasmore/total stanza hidden)
                            #from the SDK. - This is temporary until code is properly handled within the 
                            #Rubrik PowerShell SDK
                            #Applies to HyperV,Nutanix, MSSQL, Oracle, VolumeGroups below
                            $VMwareVMs = Get-RubrikVM -Relic:$false -PrimaryClusterID 'local' | Select -Property @{N="Name";E={$_.name}},
                                @{N="IP Address";E={$_.ipAddress}},@{N="vCenterName";E={ ($_.infraPath | Where { $_.managedId -like 'vCenter::*' } ).name }},
                                @{N="RBSInstalled";E={$_.agentStatus.agentStatus}},@{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}} | where {$_.effectiveSlaDomainName -ne 'Unprotected' }
                            $HyperVVMs = Get-RubrikHypervVM -Relic:$false -PrimaryClusterID local
                            if (0 -ne $HypervVMs[0].total) {
                                $HyperVVMs = $HyperVVMs | where {$_.effectiveSlaDomainName -ne 'Unprotected' }  | ForEach { Get-RubrikHyperVVM -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="SCVMM Server";E={ ($_.infraPath | Where { $_.Id -like 'HypervScvmm::*' } ).name }},@{N="RBS Registered";E={$_.isAgentRegistered}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}} }
                            }
                            else {
                                $HyperVVMs = $null
                            }
                            $NutanixVMs = Get-RubrikNutanixVM -Relic:$false -PrimaryClusterID local
                            if (0 -ne $NutanixVMs[0].total) {
                                $NutanixVMs = $NutanixVMs | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | ForEach { Get-RubrikNutanixVM -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="Cluster Name";E={$_.nutanixClusterName}},@{N="RBS Registered";E={$_.isAgentRegistered}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}} }
                            }
                            else {
                                $NutanixVMs = $null
                            }
                            $MSSQLDatabases = Get-RubrikDatabase -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $MSSQLDatabases[0].total) {
                                $MSSQLDatabases = $MSSQLDatabases | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Foreach { Get-RubrikDatabase -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="Instance";E={if ($null -eq $_.instanceName) {"N/A"} else {$_.instanceName}  }},@{N="LocationName";E={$_.rootProperties.rootName }},
                                    @{N="Recovery Model";E={if ($null -eq $_.recoveryModel) {"N/A"} else {$_.recoveryModel}  }}, @{N="Log Backup Frequency (seconds)";E={$_.logBackupFrequencyInSeconds}},
                                    @{N="Log Retention (hours)";E={$_.logBackupRetentionHours}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                    @{N="Assignment Type";E={$_.slaAssignment}}}
                            }
                            else {
                                $MSSQLDatabases = $null
                            }
                            $OracleDatabases = Get-RubrikOracleDB -Relic:$false -PrimaryClusterID local
                            if (0 -ne $OracleDatabases[0].total) {
                                $OracleDatabases = $OracleDatabases | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Foreach { Get-RubrikOracleDb -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="SID";E={$_.sid}}, @{N="# Tablespaces";E={$_.numTablespaces}},
                                    @{N="Oracle Host";E={$_.standaloneHostName}}, @{N="Log Enabled";E={$_.isArchiveLogModeEnabled}},
                                    @{N="Log Backup Frequency (minutes)";E={$_.logBackupFrequencyInMinutes}},@{N="Log Retention (Hours)";E={$_.logRetentionHours}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}} }
                            }
                            else {
                                $OracleDatabases = $null
                            }
                            $Filesets = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -eq $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Operating System";E={$_.operatingSystemType}},@{N="Fileset Name";E={$_.name}},
                                @{N="Includes";E={$_.includes | Out-String }},@{N="Excludes";E={$_.excludes | Out-String}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}}
                            $NasShares = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -ne $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Operating System";E={$_.operatingSystemType}} ,@{N="Fileset Name";E={$_.name}},
                                @{N="Includes";E={$_.includes | Out-String }},@{N="Excludes";E={$_.excludes | Out-String}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}}
                            $VolumeGroups = Get-RubrikVolumeGroup -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $VolumeGroups[0].total) {
                                $VolumeGroups = $VolumeGroups | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | ForEach { Get-RubrikVolumeGroup -id $_.id | Select -Property @{N="Hostname";E={$_.hostname}},
                                    @{N="Volume Group name";E={$_.name}},@{N="Includes";E={$_.includes | Out-String }},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}}}
                            }
                            else {
                                $VolumeGroups = $null
                            }
                            $ManagedVolumes = Get-RubrikManagedVolume -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="Volume Size";E={$_.volumeSize}}, @{N="Used";E={$_.usedSize}},
                                @{N="Is Writable";E={$_.isWritable}}, @{N="State";E={$_.state}},
                                @{N="# Channels";E={$_.numChannels}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}
                            }
                        elseif ($InfoLevel.ProtectedObjects -ge 5) {
                            #first level if check on total is temporary 
                            #this must be in place for sending additional GETs or Foreach
                            #as we may bet back null results (but have data/hasmore/total stanza hidden)
                            #from the SDK. - This is temporary until code is properly handled within the 
                            #Rubrik PowerShell SDK
                            #Applies to VMware VMs, HyperV, Nutanix, MSSQL, Oracle, VolumeGroups below
                            $VMwareVMs = Get-RubrikVM -Relic:$false -PrimaryClusterID 'local' 
                            if (0 -ne $VMwareVMs[0].total) {
                                $VMwareVMs = $VMwareVMs | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | foreach {Get-RubrikVM -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="IP Address";E={$_.ipAddress}},@{N="Guest OS";E={$_.guestOsType}},
                                    @{N="ESXiHost";E={ ($_.infraPath | Where { $_.managedId -like 'VMwareHost::*' } ).name }},
                                    @{N="ComputeCluster";E={ ($_.infraPath | Where { $_.managedId -like 'ComputeCluster::*' } ).name }}, 
                                    @{N="Datacenter";E={ ($_.infraPath | Where { $_.managedId -like 'DataCenter::*' } ).name }},
                                    @{N="vCenterName";E={ ($_.infraPath | Where { $_.managedId -like 'vCenter::*' } ).name }},
                                    @{N="RBSInstalled";E={$_.agentStatus.agentStatus}},@{N="VMware Tools";E={$_.vmwareToolsInstalled}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}}, @{N="Snapshot Count";E={$_.snapshotCount}},
                                    @{N="Oldest Backup";E={ ($_.snapshots | sort-object -Property Date | Select -First 1).date }},
                                    @{N="Latest Backup";E={ ($_.snapshots | sort-object -Property Date | Select -Last 1).date }}  }
                                }
                            else {
                                $VMwareVMs = $null
                            }
                            $HyperVVMs = Get-RubrikHypervVM -Relic:$false -PrimaryClusterID local
                            if (0 -ne $HypervVMs[0].total) {
                                $HyperVVMs = $HyperVVMs | where {$_.effectiveSlaDomainName -ne 'Unprotected' }  | ForEach { Get-RubrikHyperVVM -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="HyperV Server";E={ ($_.infraPath | Where { $_.Id -like 'HypervServer::*' } ).name }},
                                    @{N="HyperV Cluster";E={ ($_.infraPath | Where { $_.Id -like 'HypervCluster::*' } ).name }},
                                    @{N="SCVMM Server";E={ ($_.infraPath | Where { $_.Id -like 'HypervScvmm::*' } ).name }},
                                    @{N="RBS Registered";E={$_.isAgentRegistered}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                    @{N="Assignment Type";E={$_.slaAssignment}},@{N="Snapshot Count";E={ ( Get-RubrikSnapshot -id $_.id).count }},
                                    @{N="Latest Backup";E={ ( Get-RubrikSnapshot -id $_.id -latest  ).date }},
                                    @{N="Oldest Backup";E={ (Get-RubrikSnapshot -id $_.id | Sort-Object -Property date | Select -First 1).date }} }
                            }
                            else {
                                $HyperVVMs = $null
                            }
                            $NutanixVMs = Get-RubrikNutanixVM -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $NutanixVMs[0].total) {
                                $NutanixVMs = $NutanixVMs | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | ForEach { Get-RubrikNutanixVM -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="Cluster Name";E={$_.nutanixClusterName}},@{N="RBS Registered";E={$_.isAgentRegistered}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}},
                                    @{N="Snapshot Count";E={ ( Get-RubrikSnapshot -id $_.id).count }},
                                    @{N="Latest Backup";E={ ( Get-RubrikSnapshot -id $_.id -latest  ).date }},
                                    @{N="Oldest Backup";E={ (Get-RubrikSnapshot -id $_.id | Sort-Object -Property date | Select -First 1).date }} }
                            }
                            else {
                                $NutanixVMs = $null
                            }
                            $MSSQLDatabases = Get-RubrikDatabase -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $MSSQLDatabases[0].total) {
                                $MSSQLDatabases = $MSSQLDatabases | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Foreach { Get-RubrikDatabase -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="Instance";E={if ($null -eq $_.instanceName) {"N/A"} else {$_.instanceName}  }},@{N="Location Name";E={$_.rootProperties.rootName }},
                                    @{N="Recovery Model";E={if ($null -eq $_.recoveryModel) {"N/A"} else {$_.recoveryModel}  }}, @{N="Log Backup Frequency (seconds)";E={$_.logBackupFrequencyInSeconds}},
                                    @{N="Log Retention (hours)";E={$_.logBackupRetentionHours}}, @{N="Secondary Log Shipping";E={$_.isLogShippingSecondary}},
                                    @{N="Is in Availability Group";E={$_.isInAvailabilityGroup}},@{N="Copy Only";E={$_.copyOnly}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}}, @{N="Assignment Type";E={$_.slaAssignment}},
                                    @{N="Snapshot Count";E={$_.snapshotCount}},@{N="Oldest Backup";E={$_.oldestRecoveryPoint}},
                                    @{N="Latest Backup";E={$_.latestRecoveryPoint}} }
                            }
                            else {
                                $MSSQLDatabases = $null
                            }
                            $OracleDatabases = Get-RubrikOracleDB -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $OracleDatabases[0].total) {
                                $OracleDatabases = $OracleDatabases | where {$_.effectiveSlaDomainName -ne 'Unprotected' } | Foreach { Get-RubrikOracleDb -id $_.id | Select -Property @{N="Name";E={$_.name}},
                                    @{N="SID";E={$_.sid}}, @{N="# Tablespaces";E={$_.numTablespaces}},
                                    @{N="Oracle Host";E={$_.standaloneHostName}}, @{N="Log Enabled";E={$_.isArchiveLogModeEnabled}},
                                    @{N="Log Backup Frequency (minutes)";E={$_.logBackupFrequencyInMinutes}},@{N="Log Retention (Hours)";E={$_.logRetentionHours}},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}},
                                    @{N="Snapshot Count";E={$_.snapshotCount}},@{N="Oldest Backup";E={$_.oldestRecoveryPoint}},
                                    @{N="Latest Backup";E={$_.latestRecoveryPoint}} }
                            }
                            else {
                                $OracleDatabases = $null
                            }
                            $Filesets = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -eq $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Operating System";E={$_.operatingSystemType}},@{N="Fileset Name";E={$_.name}},
                                @{N="Includes";E={$_.includes | Out-String }},@{N="Excludes";E={$_.excludes | Out-String}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Snapshot Count";E={$_.snapshotCount}},
                                @{N="Oldest Backup";E={(Get-RubrikSnapshot -id $_.id | Sort-Object -Property Date | Select -First 1).date}},
                                @{N="Latest Backup";E={(Get-RubrikSnapshot -id $_.id | Sort-Object -Property Date | Select -Last 1).date}}
                            $NasShares = Get-RubrikFileset -Relic:$false -PrimaryClusterID local -DetailedObject | where {$_.effectiveSlaDomainId -ne 'Unprotected' -and $null -ne $_.shareId } | Select -Property @{N="Hostname";E={$_.hostname}},
                                @{N="Operating System";E={$_.operatingSystemType}},@{N="Fileset Name";E={$_.name}},
                                @{N="Includes";E={$_.includes | Out-String }},@{N="Excludes";E={$_.excludes | Out-String}},
                                @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Snapshot Count";E={$_.snapshotCount}},
                                @{N="Oldest Backup";E={(Get-RubrikSnapshot -id $_.id | Sort-Object -Property Date | Select -First 1).date}},
                                @{N="Latest Backup";E={(Get-RubrikSnapshot -id $_.id | Sort-Object -Property Date | Select -Last 1).date}}                  
                            $VolumeGroups = Get-RubrikVolumeGroup -Relic:$false -PrimaryClusterID local 
                            if (0 -ne $VolumeGroups[0].total) {
                                $VolumeGroups = $VolumeGroups | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | ForEach { Get-RubrikVolumeGroup -id $_.id | Select -Property @{N="Hostname";E={$_.hostname}},
                                    @{N="Volume Group name";E={$_.name}},@{N="Includes";E={$_.includes | Out-String }},
                                    @{N="SLA Domain";E={$_.effectiveSlaDomainName}},@{N="Assignment Type";E={$_.slaAssignment}},
                                    @{N="SnapshotCount";E={ ( Get-RubrikSnapshot -id $_.id).count }},
                                    @{N="LatestBackup";E={ ( Get-RubrikSnapshot -id $_.id -latest  ).date }},
                                    @{N="OldestBackup";E={ (Get-RubrikSnapshot -id $_.id | Sort-Object -Property date | Select -First 1).date }} }
                            }
                            else {
                                $VolumeGroups = $null
                            }
                            $ManagedVolumes = Get-RubrikManagedVolume -Relic:$false -PrimaryClusterID local | where {$_.effectiveSlaDomainId -ne 'Unprotected' } | Select -Property @{N="Name";E={$_.name}},
                                @{N="Volume Size";E={$_.volumeSize}}, @{N="Used";E={$_.usedSize}},
                                @{N="Is Writable";E={$_.isWritable}}, @{N="State";E={$_.state}},
                                @{N="# Channels";E={$_.numChannels}}, @{N="SLA Domain";E={$_.effectiveSlaDomainName}},
                                @{N="Assignment Type";E={$_.slaAssignment}}, @{N="Snapshot Count";E={$_.snapshotCount}},
                                @{N="Latest Backup";E={ ( Get-RubrikSnapshot -id $_.id -latest  ).date }},
                                @{N="Oldest Backup";E={ (Get-RubrikSnapshot -id $_.id | Sort-Object -Property date | Select -First 1).date }}
                        }

                        if (0 -ne ($VMwareVMs | Measure-Object).count) {
                            Section -Style Heading3 "VMware Virtual Machines" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $VMwareVMs | Sort-Object -Property Name | Table -Name "Protected VMware VMs" -List -ColumnWidths 30,70
                                }
                                else {
                                    $VMwareVMs | Sort-Object -Property Name | Table -Name "Protected VMware VMs" 
                                }
                            }
                        }
                        if (0 -ne ($HyperVVMs | Measure-Object).count) {
                            Section -Style Heading3 "Hyper-V Virtual Machines" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $HyperVVMs | Sort-Object -Property Name | Table -Name "Protected HyperV VMs" -List -ColumnWidths 30,70
                                }
                                else {
                                    $HyperVVMs | Sort-Object -Property Name | Table -Name "Protected HyperV VMs"
                                }
                            }
                        }
                        if (0 -ne ($NutanixVMs | Measure-Object).count) {
                            Section -Style Heading3 "Nutanix Virtual Machines" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $NutanixVMs | Sort-Object -Property Name | Table -Name "Protected Nutanix VMs" -List -ColumnWidths 30,70
                                }
                                else {
                                    $NutanixVMs | Sort-Object -Property Name | Table -Name "Protected Nutanix VMs" 
                                }
                            }
                        }
                        if (0 -ne ($MSSQLDatabases | Measure-Object).count) {
                            Section -Style Heading3 "MSSQL Databases" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $MSSQLDatabases | Sort-Object -Property Name | Table -Name "Protected MSSQL Databases" -List -ColumnWidths 30,70
                                }
                                else {
                                    $MSSQLDatabases | Sort-Object -Property Name | Table -Name "Protected MSSQL Databases" 
                                }
                            }
                        }
                        if (0 -ne ($OracleDatabases | Measure-Object).count) {
                            Section -Style Heading3 "Oracle Databases" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $OracleDatabases | Sort-Object -Property Name | Table -Name "Protected Oracle Databases" -List -ColumnWidths 30,70
                                }
                                else {
                                    $OracleDatabases | Sort-Object -Property Name | Table -Name "Protected Oracle Databases" 
                                }
                            }
                        }
                        if (0 -ne ($Filesets | Measure-Object).count) {
                            Section -Style Heading3 "Filesets" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $Filesets | Sort-Object -Property operatingSystemType,Name | Table -Name "Protected Filesets" -List -ColumnWidths 30,70
                                }
                                else {
                                    $Filesets | Sort-Object -Property operatingSystemType,Name | Table -Name "Protected Filesets" 
                                }
                            }
                        }
                        if (0 -ne ($NasShares | Measure-Object).count) {
                            Section -Style Heading3 "NAS Shares" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $NasShares | Sort-Object -Property operatingSystemType,Name | Table -Name "Protected NAS Shares" -List -ColumnWidths 30,70
                                }
                                else {
                                    $NasShares | Sort-Object -Property operatingSystemType,Name | Table -Name "Protected NAS Shares" 
                                }
                            }
                        }
                        if (0 -ne ($VolumeGroups | Measure-Object).count) {
                            Section -Style Heading3 "Volume Groups" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $VolumeGroups | Sort-Object -Property hostName | Table -Name "Protected Volume Groups" -List -ColumnWidths 30,70
                                }
                                else {
                                    $VolumeGroups | Sort-Object -Property hostName | Table -Name "Protected Volume Groups" 
                                }
                            }
                        }
                        if (0 -ne ($ManagedVolumes | Measure-Object).count) {
                            Section -Style Heading3 "Managed Volumes" {
                                if ($InfoLevel.ProtectedObjects -ge 5) {
                                    $ManagedVolumes | Sort-Object -Property name | Table -Name "Protected Managed Volumes" -List -ColumnWidths 30,70
                                }
                                else {
                                    $ManagedVolumes | Sort-Object -Property name | Table -Name "Protected Managed Volumes"
                                }
                            }
                        }
                    } # end of Style Heading2 Protected Objects
                }
                if ($InfoLevel.SnapshotRetention -ge 1) {
                    Section -Style Heading2 "Snapshot Retention" {
                        Paragraph ("The following displays all relic, expired, and unmanaged objects within the Rubrik cluster")
                        $UnmanagedObjects = Get-RubrikUnmanagedObject
                        if ($InfoLevel.SnapshotRetention -in (1,2)) {
                            $UnmanagedObjects | sort-object -Property Name, objecttype | Table -Name "Unmanaged Objects" -Columns Name,objectType,retentionSlaDomainName -Headers 'Name','ObjectType','Retention SLA Domain'
                        }
                        elseif ($InfoLevel.SnapshotRetention -in (3,4,5)) {
                            $UnmanagedObjects | sort-object -Property Name, objecttype | Table -Name "Unmanaged Objects" -Columns Name,objectType,retentionSlaDomainName,autoSnapshotCount, manualSnapshotCount,localStorage,archiveStorage,unmanagedStatus -Headers 'Name','ObjectType','Retention SLA Domain','Automatic Snapshots','Manual Snapshots','Local Storage','Archival Storage','Unmanaged Status' -List -ColumnWidths 30,70
                        }
                    }
                } # end of Style Heading2 Snapshot Retention
            }
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function