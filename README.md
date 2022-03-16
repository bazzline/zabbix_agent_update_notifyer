# Zabbix Agent Update Notifyer

Free as in freedome zabbix agent installation to notify if updateable packges are available.

The main intention of this repository is to provide a refactored version of [theranger/zabbix-apt](https://github.com/theranger/zabbix-apt). Zabbix-apt is great.

The current change log can be found [here](CHANGELOG.md).

The current documentation can be found [here](documentation).

The main idea is currently written down [here](https://github.com/stevleibelt/General_Howtos/blob/master/network/monitoring/zabbix/howto.md#setup-updateable-packages-available).


# Installation

```
WORKING_DIRECTORY=$(pwd)
TEMPORARY_DIRECTORY=$(mktemp -d)

cd ${TEMPORARY_DIRECTORY}
git clone https://github.com/bazzline/zabbix_agent_update_notifyer .
#call >>install.sh -h<< to display help
#call >>install.sh -d<< for dry run usage
#call >>install.sh -v<< for verbose output
sudo bash bin/install.sh

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
#call >>uninstall.sh -h<< to display help
#call >>uninstall.sh -d<< for dry run usage
#call >>uninstall.sh -v<< for verbose output
sudo bash bin/uninstall.sh

cd ${WORKING_DIRECTORY}

rm -fr ${TEMPORARY_DIRECTORY}
```
