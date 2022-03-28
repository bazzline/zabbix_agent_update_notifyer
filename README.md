# Zabbix Agent Update Notifyer

Free as in freedome zabbix agent installation to notify if updateable packges are available.

The main intention of this repository is to provide a refactored version of [theranger/zabbix-apt](https://github.com/theranger/zabbix-apt). Zabbix-apt is great.

The current change log can be found [here](CHANGELOG.md).

# Installation

For easy installation, git is mandatory.

```
WORKING_DIRECTORY=$(pwd)
TEMPORARY_DIRECTORY=$(mktemp -d)

cd ${TEMPORARY_DIRECTORY}
git clone https://github.com/bazzline/zabbix_agent_update_notifyer .

#call >>install.sh -h<< to display help and more information
#if needed, change the configuration by adapting >>data/configuration.sh<<
./bin/install.sh

#import the template in template/update_notifyer.xml
# in your zabbix server
#`Configuration` -> `Templates` -> `Import`

cd ${WORKING_DIRECTORY}

rm -fr ${TEMPORARY_DIRECTORY}
```

## Uninstallation

```
WORKING_DIRECTORY=$(pwd)
TEMPORARY_DIRECTORY=$(mktemp -d)

cd ${TEMPORARY_DIRECTORY}
git clone https://github.com/bazzline/zabbix_agent_update_notifyer .

#call >>uninstall.sh -h<< to display help and more information
#if needed, change the configuration by adapting >>data/configuration.sh<<
./bin/uninstall.sh

cd ${WORKING_DIRECTORY}

rm -fr ${TEMPORARY_DIRECTORY}
```

## Update

Basically do the uninstallation followed by the installation.

# Idea

Credit to the people where it belongs to, [theranger/zabbix-apt](https://github.com/theranger/zabbix-apt) showed me so much and gave me the base for my code. Thank you very much.

## In the short

The idea is to:

* Update local package database
* Fetch the package names where updates are available
* Read the amount of updateable packages and report them to zabbix

## The longer version

### Supported systems and mandatory packages

This package comes with "battery included"/support for the packagemanager `pacman` and `apt` which means, all [debian](https://www.debian.org/) and [arch linux](https://archlinux.org/) base systems are supported.

Right now, [systemd](https://systemd.io/) mandatory too, as well as an installed [zabbix agent](https://www.zabbix.com/zabbix_agent).

Feel free to create a pull request to extend the support of more package managers or init deamons.

### The process described in depth

Updating the local packages is triggered by a systemd timer file (`/etc/systemd/system/zabbix_agent-update_notifyer.timer` which is starting `/etc/systemd/system/zabbix_agent-update_notifyer.service`).

The package manager is used to update it's database. After that, the database is asked to fetch packages where updates are available.   
For `apt`, we are able to distinguish between security and regular packages. For `pacman`, because of the nature of arch linux, each package is security related.   
The informations of the packages are stored in the file paths `/var/local/zabbix_agent-update_notifyer_-_security_packages.txt` and `/var/local/zabbix_agent-update_notifyer_-_regular_packages.txt`.

The generated files with the information of the updateable packages are processed by the zabbix agent. A dedicated configuration file is created in `/usr/local/etc/zabbix_agentd.conf.d/zabbix_agent-update_notifyer.conf`. The file `/etc/zabbix/zabbix_agentd.conf` is enriched by the line `Include=/usr/local/etc/zabbix_agentd.conf.d/*.conf` to load the configuration file.   
The zabbix agent is counting the amount of lines in each of the packages files and reports that amount to your zabbix server.

The zabbix server can process the supported values. The template basically comes with two triggers. One for security packages and one for regular packages.   
All you need to do is to import the [template](template/update_notifyer.xml) and add them to the client where you've installed this software.

### Final note

Based on the idea of [theranger/zabbix-apt](https://github.com/theranger/zabbix-apt), this package is an evolution of his idea. I moved the logic into a dedicated script to enable the possibility to support multiple package manager and init scripts.
