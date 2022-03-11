#!/bin/bash
####
# Contains the setup and installation routine
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

####
# @param: <string: path_to_the_source_zabbix_agent_configuration_file>
# @param: <string: path_to_the_destination_directory>
# @param: <string: path_to_the_regular_package_file>
# @param: <string: path_to_the_security_package_file>
####
function _add_zabbix_agent_configuration ()
{
    #bo: variable
    local PATH_TO_THE_DESTINATION_DIRECTORY="${1}"
    local PATH_TO_THE_REGULAR_PACKAGES_FILE="${2}"
    local PATH_TO_THE_SECURITY_PACKAGES_FILE="${3}"
    local PATH_TO_THE_SOURCE_FILE="${0}"
    #eo: variable

    #bo: prepare environment
    if [[ ! -f "${PATH_TO_THE_SOURCE_FILE}" ]];
    then
        echo ":: File path >>${PATH_TO_THE_SOURCE_FILE}<< is invalid."
        echo "   File is mandatory to finish installation."

        exit 1
    fi

    if [[ ! -d "${PATH_TO_THE_DESTINATION_DIRECTORY}" ]];
    then
        echo ":: Creating path >>${PATH_TO_THE_DESTINATION_DIRECTORY}<<."
        mkdir -p "${PATH_TO_THE_DESTINATION_DIRECTORY}"
    fi
    #eo: prepare environment

    #bo: copying configuration file
    cat > "${PATH_TO_THE_DESTINATION_DIRECTORY}/update_notifyer.conf" <<DELIM
####
# @see: https://github.com/theranger/zabbix-apt/blob/master/zabbix_agentd.d/apt.conf
# @since: 2022-03-09
# @author: stev leibelt <artodeto@bazzline.net>
####
# Treat security and regular updates differently
####
UserParameter=update-notifyer.security,cat ${PATH_TO_THE_SECURITY_PACKAGES_FILE} | wc -l
UserParameter=update-notifyer.updates,cat ${PATH_TO_THE_REGULAR_PACKAGES_FILE} | wc -l
DELIM
    #eo: copying configuration file

    #bo: restart zabbix agent
    if systemctl is-active --quiet zabbix-agent.service;
    then
        echo ":: Restarting >>zabbix-agent.service<< to enable new configuration file."
        systemctl restart zabbix-agent.service
    fi
    #eo: restart zabbix agent
}

####
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_regular_packages_file>
# @param: <string: path_to_security_packages_file>
####
function _create_script_for_apt ()
{
    #bo: variable
    local PATH_TO_SCRIPT_FILE="${0}"
    local PATH_TO_REGULAR_PACKAGES_FILE="${1}"
    local PATH_TO_SECURITY_PACKAGES_FILE="${2}"
    #eo: variable

    cat > "${PATH_TO_SCRIPT_FILE}" <<DELIM
    logger -i -p cron.info ":: Starting updating of package files."
    logger -i -p cron.debug "   Updating package database."
    apt update

    logger -i -p cron.debug "   Creating file >>\${PATH_TO_SECURITY_PACKAGES_FILE}<<."
    apt upgrade --dry-run | grep -ci ^inst.*security > \"\${PATH_TO_SECURITY_PACKAGES_FILE}\"

    logger -i -p cron.debug "   Creating file >>\${PATH_TO_REGULAR_PACKAGES_FILE}<<."
    apt full-upgrade --dry-run | 
    apt upgrade --dry-run | grep -iP '^Inst((?!security).)*\$' > \"\${PATH_TO_REGULAR_PACKAGES_FILE}\"

    logger -i -p cron.info ":: Finished updating of package files."
DELIM
}

####
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_regular_packages_file>
# @param: <string: path_to_security_packages_file>
####
function _create_script_for_pacman ()
{
    #bo: variable
    local PATH_TO_SCRIPT_FILE="${0}"
    local PATH_TO_REGULAR_PACKAGES_FILE="${1}"
    local PATH_TO_SECURITY_PACKAGES_FILE="${2}"
    #eo: variable

    cat > "${PATH_TO_SCRIPT_FILE}" <<DELIM
    logger -i -p cron.info ":: Starting updating of package files."
    logger -i -p cron.debug "   Updating package database."
    pacman -Syu

    logger -i -p cron.debug "   Creating file >>\${PATH_TO_SECURITY_PACKAGES_FILE}<<."
    pacman -Qu > \"${PATH_TO_SECURITY_PACKAGES_FILE}\"

    logger -i -p cron.debug "   Creating file >>\${PATH_TO_REGULAR_PACKAGES_FILE}<<."
    cp \"${PATH_TO_SECURITY_PACKAGES_FILE}\" \"\${PATH_TO_REGULAR_PACKAGES_FILE}\"

    logger -i -p cron.info ":: Finished updating of package files."
DELIM
}

####
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_the_systemd_service_file>
# @param: <string: path_to_the_systemd_timer_file>
####
function _create_systemd_files ()
{
    #bo: variable
    local PATH_TO_THE_SCRIPT_FILE="${0}"
    local PATH_TO_THE_SYSTEMD_SERVICE_FILE="${0}"
    local PATH_TO_THE_SYSTEMD_TIMER_FILE="${0}"
    #eo: variable

    #bo: systemd service file
    cat > "${PATH_TO_THE_SYSTEMD_SERVICE_FILE}" <<DELIM
[Unit]
Description=zabbix-agent update-notifier service
ConditionACPower=true
After=network-online.target

[Service]
Type=oneshot
ExecStart=${PATH_TO_THE_SCRIPT_FILE}
KillMode=process
TimeoutStopSec=21600
DELIM
    #be: systemd service file

    #bo: systemd timer file
    cat > "${PATH_TO_THE_SYSTEMD_TIMER_FILE}" <<DELIM
[Unit]
Description=Hourly zabbix-agent update-notifier timer

[Timer]
OnCalendar=hourly
RandomizedDelaySec=42
Persistent=true
Unit=${PATH_TO_THE_SYSTEMD_SERVICE_FILE}

[Install]
WantedBy=timers.target
DELIM
    #be: systemd timer file
}

function _check_and_setup_system_environment_or_exit ()
{
    local ROOT_PATH_TO_PACKAGE_CONFIGURATION="${1}"

    #bo: check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        echo ":: Script needs to be executed as root."

        exit 1
    fi
    #eo: check if we are root

    #bo: check if systemd installed
    if [[ ! -d /usr/lib/systemd ]];
    then
        echo ":: Directory >>/usr/lib/systemd<< does not exist."
        echo "   Systemd is mandatory right now. Feel free to create a pull request to support multiple init systems."

        exit 2
    fi
    #bo: check if systemd installed

    #bo: check if zabbix-agent is installed
    local NUMBER_OF_ZABBIX_AGENT_SERVICE_FILES_FOUND=$(systemctl list-unit-files zabbix-agent.service | grep -c zabbix-agent.service)

    if [[ ${NUMBER_OF_ZABBIX_AGENT_SERVICE_FILES_FOUND} -eq 0 ]] ;
    then
        echo ":: Systemd servive file >>zabbix-agent.service<< not found."
        echo "   Please install zabbix agent first."

        exit 3
    fi

    #eo: check if zabbix-agent is installed

    #bo: check if this software is already installed
    if [[ -d "${ROOT_PATH_TO_PACKAGE_CONFIGURATION}" ]];
    then
        echo ":: Directory >>${ROOT_PATH_TO_PACKAGE_CONFIGURATION}<< does not exist."
        echo "   Systemd is mandatory right now. Feel free to create a pull request to support multiple init systems."

        exit 4
    else
        echo ":: Creating path >>${ROOT_PATH_TO_PACKAGE_CONFIGURATION}<<."
        sudo mkdir -p "${ROOT_PATH_TO_PACKAGE_CONFIGURATION}"

        if [[ "${?}" -gt 0 ]];
        then
            echo "   Could not create it. mkdir return code was >>${?}<<."

            exit 5
        fi
    fi
    #eo: check if this software is already installed
}

function _main ()
{
    #bo: variable
    local CURRENT_SCRIPT_PATH=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    local PATH_TO_CONFIGURATION_FILE="${CURRENT_SCRIPT_PATH}/../data/configuration.sh"
    local PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION_DIRECTORY=""   #will be filled up later
    #eo: variable

    #bo: code
    echo ":: Starting installation"

    if [[ ! -f ${FILE_PATH_TO_CONFIGURATION_FILE} ]];
    then
        echo ":: File >>${FILE_PATH_TO_CONFIGURATION_FILE}<< does not exist."

        exit 1
    else
        #loads the following variables.
        #   list below is just there to ease up auto completion
        #FILE_PATH_TO_REGULAR_PACKAGES
        #FILE_PATH_TO_SECURITY_PACKAGES
        #ROOT_PATH_TO_PACKAGE_CONFIGURATION

        #PATH_TO_SYSTEMD_SERVICE_FILE
        #PATH_TO_SYSTEMD_TIMER_FILE
        #FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT

        . "${FILE_PATH_TO_CONFIGURATION_FILE}"
    fi

    _check_and_setup_system_environment_or_exit "${ROOT_PATH_TO_PACKAGE_CONFIGURATION}"
    
    if [[ -f /usr/bin/pacman ]];
    then
        _create_script_for_pacman "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
        PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION_DIRECTORY="/etc/zabbix/zabbix_agentd.conf.d"

    elif [[ -f /usr/bin/apt ]];
    then
        _create_script_for_apt "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
        PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION_DIRECTORY="/etc/zabbix/zabbix_agentd.d"

    else
        echo ":: No supported package manager found."
        echo "   pacman or apt are mandatory right now. Feel free to create a pull request to support more package managers."

        exit 1
    fi

    #take a look on zabbix_mysql_housekeeping/bin/install.sh
    _create_systemd_files "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${PATH_TO_SYSTEMD_SERVICE_FILE}" "${PATH_TO_SYSTEMD_TIMER_FILE}"

    _add_zabbix_agent_configuration "${PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION_DIRECTORY}" "${PATH_TO_THE_DESTINATION_DIRECTORY}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"

    echo ":: Finished installation"
    echo "   Please import the template file in path >>${CURRENT_SCRIPT_PATH}/../template/update_notifyer.xml<< in your zabbix."
    #eo: code
}

_main ${*}