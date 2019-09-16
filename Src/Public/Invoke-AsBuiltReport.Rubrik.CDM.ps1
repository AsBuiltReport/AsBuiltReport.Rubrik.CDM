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
                    Section -Style Heading2 'Rubrik Cluster' { 
                        Paragraph ("The following section provides information on the configuration of the Rubrik CDM Cluster $($ClusterInfo.Name)")
                        BlankLine
                        
                        #Cluster Summary for InfoLevel 1/2 (Summary/Informative)
                        $ClusterSummary = [PSCustomObject]@{
                            'Name' = $ClusterInfo.Name
                            'Number of Briks' = $ClusterInfo.BrikCount
                            'Number of Nodes' = $ClusterInfo.NodeCount
                            'Software Version' = $ClusterInfo.softwareVersion
                        }

                        # InfoLevel 3 (Detailed) adds disk/cpu/memory metrics
                        if ($InfoLevel.Cluster -ge 3) {
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name '# CPU Cores' -Value $ClusterInfo.CPUCoresCount
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Total Memory (GB)' -Value $ClusterInfo.MemoryCapacityinGB
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'HDD Capacity (TB)' -Value $ClusterInfo.DiskCapacityInTb
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Flash Capacity (TB)' -Value $ClusterInfo.FlashCapacityInTb
                        }
                        # InfoLevel 4 ( Advanced Detailed) adds Timezone/Geo/Encryption
                        if ($InfoLevel.Cluster -ge 4) {
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Timezone' -Value $ClusterInfo.timezone.timezone
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Geo Location' -Value $ClusterInfo.geolocation.address
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Software Encrypted' -Value $ClusterInfo.isEncrypted
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Hardware Encrypted' -Value $ClusterInfo.isHardwareEncrypted
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Cluster ID' -Value $ClusterInfo.id
                        }
                        # InfoLevel 5 (Comprehensive) adds the rest!
                        if ($InfoLevel.Cluster -eq 5) {
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Accepted EULA Version' -Value $ClusterInfo.acceptedEULAVersion
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Has TPM Support' -Value $ClusterInfo.hasTPM
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Connected to Polaris' -Value $ClusterInfo.ConnectedToPolaris
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Platform' -Value $ClusterInfo.Platform
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Running on Cloud' -Value $ClusterInfo.isOnCloud
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Only Azure Support' -Value $ClusterInfo.OnlyAzureSupport
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Is Single Node Appliance' -Value $ClusterInfo.isSingleNode
                            $ClusterSummary | Add-Member -MemberType NoteProperty -Name 'Registered' -Value $ClusterInfo.isRegistered
                        }
                        $ClusterSummary | Table -Name $ClusterSummary.Name -ColumnWidths 30,70 -List
                        if ($InfoLevel.Cluster -ge 3) {
                            Section -Style Heading3 'Node Information' { 
                                $NodeInfo = Get-RubrikNode
                                $NodeInfo | Table -Name "Cluster Node Information" -ColumnWidths 25,12,12,25,25
                            }

                            
                        } # End InfoLevel -ge 3     
                    } #End Heading 2
                }# end of Infolevel 1
  

            }
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function