#!/bin/bash
####
# Contains the setup and installation routine
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

function _create_pacman_script ()
{
    #bo: variable
    local PATH_TO_SCRIPT_FILE="${0}"
    local PATH_TO_NON_SECUITY="${1}"
    local PATH_TO_SECURITY="${2}"
    #eo: variable

    cat > "${PATH_TO_SCRIPT_FILE}" <<DELIM
#logging
pacman -Syu

pacman -Qu > \"${PATH_TO_SECURITY}\"

cp \"${PATH_TO_SECURITY}\" \"${PATH_TO_NON_SECUITY}\"
DELIM
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

function _create_systemd_files ()
{
}

function _main ()
{
    local CURRENT_SCRIPT_PATH=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    local FILE_PATH_TO_CONFIGURATION_FILE="${CURRENT_SCRIPT_PATH}/../data/configuration.sh"

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

        #FILE_PATH_TO_SYSTEMD_SERVICE_FILE
        #FILE_PATH_TO_SYSTEMD_TIMER_FILE
        #FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT

        . "${FILE_PATH_TO_CONFIGURATION_FILE}"
    fi

    _check_and_setup_system_environment_or_exit "${ROOT_PATH_TO_PACKAGE_CONFIGURATION}"
    
    if [[ -f /usr/bin/pacman ]];
    then
        _create_script_for_pacman "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
    elif [[ -f /usr/bin/apt ]];
    then
        _create_script_for_apt "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
    else
        echo ":: No supported package manager found."
        echo "   pacman or apt are mandatory right now. Feel free to create a pull request to support more package managers."

        exit 1
    fi

    #take a look on zabbix_mysql_housekeeping/bin/install.sh
    _create_systemd_files "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}" "${FILE_PATH_TO_SYSTEMD_TIMER_FILE}"

    _add_zabbix_agent_configuration

    #bo: restart zabbix agent
    if systemctl is-active --quiet zabbix-agent.service;
    then
        systemctl restart zabbix-agent.service
    fi
    #eo: restart zabbix agent
}

_main ${*}
