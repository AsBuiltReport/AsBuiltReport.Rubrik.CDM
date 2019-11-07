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
                        } # End Heading 3 - Security Settings
                    } #End Heading 2
                }# end of Infolevel 1
  

            }
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function