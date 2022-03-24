# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

* add check for `cat /etc/zabbix/zabbix_agentd.conf | grep -v '^#\|^$' | grep '^Include='`
    * if grep does not get a hit, we need to add the path to then end of the configuration file
* add `README.md#Idea`

### To Change

## [Unreleased]

### Added

* Added >>ZABBIX_AGENT_CONFIGURATION_NAME<<
* Added >>FILE_<< in front of >>PATH_TO_SYSTEMD_..<<

### Changed

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
