# Rubrik CDM As Built Report Changelog

### Modified

* Added count check on Snapshot retention
* Removed duplicate Object cmd on vCloud Director section
* Count checks now occur on both Filesets and NAS Shares before issuing -DetailedObject queries. Fixes [Issue 6](https://github.com/AsBuiltReport/AsBuiltReport.Rubrik.CDM/issues/6)

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
