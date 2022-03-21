# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

* add check for `cat /etc/zabbix/zabbix_agentd.conf | grep -v '^#\|^$' | grep '^Include='`
    * if grep does not get a hit, we need to add the path to then end of the configuration file
* add `${ZABBIX_CONFIGURATION_FILE_NAME}`
    * `local ZABBIX_CONFIGURATION_FILE_NAME="update_notifyer.conf`
* add `README.md#Idea`

### To Change

* change zabbix configuration directory to `/usr/local/etc/zabbix_agentd.conf.d`

## [Unreleased]

### Added

### Changed

* Instead of stopping the script, we are now starting the same script with sudo prefix again

## [0.1.0](https://github.com/bazzline/zabbix_agent_update_notifyer/tree/0.1.0) - released at 20220317

### Added

* Added [install.sh](bin/install.sh)
* Added [uninstall.sh](bin/uninstall.sh)
* Added [configuration.sh](data/configuration.sh)
* Added [CHANGELOG.md](CHANGELOG.md)
