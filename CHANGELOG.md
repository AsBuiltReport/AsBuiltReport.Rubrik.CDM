# Rubrik CDM As Built Report Changelog

## Unreleased

## Changed
* Added new `Token` parameter to support the ability to connect with an API Token

## [1.0.1]

### Added

* Added null check on SMB Domain information
* Added null check on Syslog Information
* Added null check on Guest OS Credentials Information

### Modified

* Modified null check on VMware VMs protected objects section as it was trying to index a null array

## [1.0.0] - 2021-01-29

### Added
* Added report style options to report configuration JSON

### Modified

* Modified default style to include headers, footers, table captions and cover page logo
* Removed and replaced references of `Write-Verbose` with `Write-PScriboMessage`
* Increased version in changelog and manifest

## [0.0.9] - 2020-09-04

### Modified

* Added null checks to replication source and targets before outputing as per [Issue 10](https://github.com/AsBuiltReport/AsBuiltReport.Rubrik.CDM/issues/10)
* Added S3Compatible as archive type as per [Issue 11](https://github.com/AsBuiltReport/AsBuiltReport.Rubrik.CDM/issues/11)
* Increases version in changelog and manifest.

## [0.0.8] - 2020-07-30

### Modified

* Added count check on Snapshot retention
* Removed duplicate Object cmd on vCloud Director section
* Count checks now occur on both Filesets and NAS Shares before issuing -DetailedObject queries. Fixes [Issue 6](https://github.com/AsBuiltReport/AsBuiltReport.Rubrik.CDM/issues/6)
* Added more verbose logging around what versions of modules are installed

## [0.0.7] - 2020-04-17

### Modified

* Null checks on backup sources
* Increased and made version consistent across files

## [0.0.6] - 2020-03-28

### Modified

* Added SLA Backup Windows and fixed SLA Frequency detection of advancedUiConfig
* Added more null checks around level 3 and 5 protected objects
* Updated readme to reflect verbose logging
* Fixed version numbering to reflect more dev
* Fixed changelog formatting
* Increase version

## [0.0.5] 2020-03-05

### Added

* Null/Count/Total checks to many outputs
* Verbose logging capabilities

## [0.0.2] 2020-01-16

### Modified

* replaced a number of incorrect references to point to the Rubrik CDM repository
* modified all colors to fall in line with Rubrik branding

## [0.0.1] 2019-12-09

### Added

* initial codebase for Rubrik As Built Report
