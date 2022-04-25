# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

### To Change

* Hardening the create systemd service by using [this guide](https://www.opensourcerers.org/2022/04/25/optimizing-a-systemd-service-for-security/)

## [Unreleased]

### Added

### Changed

## [1.0.0](https://github.com/bazzline/zabbix_agent_update_notifyer/tree/1.0.0) - released at 20220328

* Added `README.md#Idea`

### Changed

* Fixed issue in `bin/uninstall.sh` if it is not executed as root

## [0.2.1](https://github.com/bazzline/zabbix_agent_update_notifyer/tree/0.2.1) - released at 20220325

### Changed

* Fixed a major issue in the `zabbix_agentd.conf` change

## [0.2.0](https://github.com/bazzline/zabbix_agent_update_notifyer/tree/0.2.0) - released at 20220325

### Added

* Added .version file for possible future update mechanism
* Added >>ZABBIX_AGENT_CONFIGURATION_NAME<<
* Added >>FILE_<< in front of >>PATH_TO_SYSTEMD_..<<
* Added check for `cat /etc/zabbix/zabbix_agentd.conf | grep -v '^#\|^$' | grep '^Include='`
    * If grep does not get a hit, we are adding the path to then end of the configuration file

### Changed

* Moved package manager detection into a variable and with that into the configuration file
* Changed the way we are dealing with dry run
* Changed check if scribts are executed as root or not
* Changed zabbix agent configuration file
    * If pacman is detected, the value of `update-notifyer.regular` will always be 0
* Change zabbix configuration directory to `/usr/local/etc/zabbix_agentd.conf.d`
* Instead of stopping the script, we are now starting the same script with sudo prefix again
* Replaced >>PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION_DIRECTORY<< with >>DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION<<
* Replaced >>ROOT_PATH_TO_PACKAGE_CONFIGURATION<< with >>DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION<<

## [0.1.0](https://github.com/bazzline/zabbix_agent_update_notifyer/tree/0.1.0) - released at 20220317

### Added

* Added [install.sh](bin/install.sh)
* Added [uninstall.sh](bin/uninstall.sh)
* Added [configuration.sh](data/configuration.sh)
* Added [CHANGELOG.md](CHANGELOG.md)
