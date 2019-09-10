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
        } catch {
            Write-Error $_
        }
        if ($RubrikCluster) {
            # Get Cluster information - Name, number of nodes, etc..
            $ClusterSettings = Get-RubrikSetting
            $ClusterNodes = (Invoke-RubrikRESTCall -Endpoint 'cluster/me/node' -api 'internal' -Method GET).data

            Section -Style Heading1 $ClusterSettings.name {
                $ClusterNodes | Table -Name $ClusterSettings.name -ColumnWidths 20, 20, 20, 20, 20 
            }
        } # End of if $RubrikCluster
    } # End of foreach $cluster


    #endregion Script Body

} # End Invoke-AsBuiltReport.Rubrik.CDM function