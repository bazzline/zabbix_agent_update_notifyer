#!/bin/bash
####
# Contains deinstallation routine
####
# @since 2022-03-16
# @author stev leibelt <artodeto@bazzline.net>
####

####
# @param: <string: path_to_the_file>
####
function __remove_file ()
{
    #bo: variable
    local CURRENT_FILE_PATH="${1}"
    #eo: variable

    #bo: code
    if [[ -f "${CURRENT_FILE_PATH}" ]];
    then
        _echo_if_be_verbose "   Removing file >>${CURRENT_FILE_PATH}<<."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            rm "${CURRENT_FILE_PATH}"

            if [[ ${?} -ne 0 ]];
            then
                _echo_an_error "   Failed with exit code >>${?}<<."
            fi
        fi
    else
        _echo_an_error "   Expected file >>${CURRENT_FILE_PATH}<< does not exist."
    fi
    #bo: code
}

####
# @param: <string: path_to_the_systemd_service_file>
# @param: <string: path_to_the_systemd_timer_file>
####
function _remove_systemd_files ()
{
    #bo: variable
    local PATH_TO_THE_SYSTEMD_SERVICE_FILE="${1}"
    local PATH_TO_THE_SYSTEMD_TIMER_FILE="${2}"

    local SYSTEMD_TIMER=$(basename "${PATH_TO_THE_SYSTEMD_TIMER_FILE}")
    local SYSTEMD_SERVICE=$(basename "${PATH_TO_THE_SYSTEMD_SERVICE_FILE}")
    #eo: variable

    #bo: code
    _echo_if_be_verbose "   Deactivating timer >>${SYSTEMD_TIMER}<<."

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        systemctl stop ${SYSTEMD_TIMER}
        systemctl disable ${SYSTEMD_TIMER}
        systemctl daemon-reload
    fi

    __remove_file "${PATH_TO_THE_SYSTEMD_TIMER_FILE}"

    __remove_file "${PATH_TO_THE_SYSTEMD_SERVICE_FILE}"
    #eo: code
}

####
# @param: <string: file_path_to_regular_packages>
# @param: <string: file_path_to_security_packages>
####
function _remove_packages_files ()
{
    #bo: variable
    local FILE_PATH_TO_REGULAR_PACKAGES="${1}"
    local FILE_PATH_TO_SECURITY_PACKAGES="${2}"
    #eo: variable

    #bo: code
    __remove_file "${FILE_PATH_TO_REGULAR_PACKAGES}"

    __remove_file "${FILE_PATH_TO_SECURITY_PACKAGES}"
    #eo: code
}

####
# @param: <string: PATH_TO_ZABBIX_AGENT_CONFIGURATION>
####
function _remove_zabbix_agent_configuration ()
{
    #bo: variable
    local PATH_TO_ZABBIX_AGENT_CONFIGURATION="${1}"
    #eo: variable

    #bo: remove configuration file
    __remove_file "${PATH_TO_ZABBIX_AGENT_CONFIGURATION}"
    #eo: remove configuration file

    #bo: restart zabbix agent
    if systemctl is-active --quiet zabbix-agent.service;
    then
        _echo_if_be_verbose ":: Restarting >>zabbix-agent.service<< to enable new configuration file."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            systemctl restart zabbix-agent.service
        fi
    fi
    #eo: restart zabbix agent
}

####
# @param: <string: DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION>
####
function _remove_configuration ()
{
    #bo: variable
    local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="${1}"
    #eo: variable

    #bo: code
    if [[ -d "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}" ]];
    then
        _echo_if_be_verbose "   Removing directory >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<<."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            rm -fr "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"

            if [[ ${?} -ne 0 ]];
            then
                _echo_an_error "   Failed with exit code >>${?}<<."
            fi
        fi
    else
        _echo_an_error "   Expected directory >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<< does not exist."
    fi
    #eo: code
}

####
# @param <string: DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION>
####
function _check_and_setup_system_environment_or_exit ()
{
    #bo: variable
    local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="${1}"
    #eo: variable

    #bo: check if systemd installed
    if [[ ! -d /usr/lib/systemd ]];
    then
        _echo_an_error "   Directory >>/usr/lib/systemd<< does not exist."
        _echo_an_error "   Systemd is mandatory right now. Feel free to create a pull request to support multiple init systems."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            exit 2
        fi
    fi
    #bo: check if systemd installed

    #bo: check if this software is already installed
    if [[ ! -d "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}" ]];
    then
        _echo_an_error "   Directory >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<< does not exist."
        _echo_an_error "   Looks like deinstallation is not needed."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            exit 3
        fi
    fi
    #eo: check if this software is already installed
}

function _echo_an_error ()
{
    echo ":: ERROR!"
    echo "${1}"
}

function _echo_if_be_verbose ()
{
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo "${1}"
    fi
}

function _main ()
{
    #bo: variable
    local BE_VERBOSE=0
    local CURRENT_SCRIPT_PATH=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
    local IS_DRY_RUN=0
    local SHOW_HELP=0
    local WHO_AM_I=$(whoami)

    local PATH_TO_CONFIGURATION_FILE="${CURRENT_SCRIPT_PATH}/../data/configuration.sh"

    while true;
    do
        case "${1}" in
            "-d" | "--dry-run" )
                IS_DRY_RUN=1
                shift 1
                ;;
            "-h" | "--help" )
                SHOW_HELP=1
                shift 1
                ;;
            "-v" | "--verbose" )
                BE_VERBOSE=1
                shift 1
                ;;
            *)
                break
                ;;
        esac
    done
    #eo: variable

    #bo: code
    if [[ ${SHOW_HELP} -eq 1 ]];
    then
        echo ":: Usage"
        echo "   uninstall.sh [-d|--dry-run] [-h|--help] [-v|--verbose]"

        exit 0
    fi

    #begin of check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            #call this script (${0}) again with sudo with all provided arguments (${@})
            sudo "${0}" "${@}"

            exit ${?}
        fi
    fi
    #end of check if we are root

    _echo_if_be_verbose ":: Starting deinstallation"

    if [[ ! -f ${PATH_TO_CONFIGURATION_FILE} ]];
    then
        _echo_an_error "   File >>${PATH_TO_CONFIGURATION_FILE}<< does not exist."
        _echo_an_error "   Configuration file is mandatory."

        exit 1
    else
        #loads the following variables.
        #   list below is just there to ease up auto completion
        #FILE_PATH_TO_REGULAR_PACKAGES
        #FILE_PATH_TO_SECURITY_PACKAGES
        #DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION

        #FILE_PATH_TO_SYSTEMD_SERVICE_FILE
        #FILE_PATH_TO_SYSTEMD_TIMER_FILE
        #FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT

        _echo_if_be_verbose ":: Sourcing file >>${PATH_TO_CONFIGURATION_FILE}<<."
        . "${PATH_TO_CONFIGURATION_FILE}"
    fi
    
    if [[ ${IS_DRY_RUN} -eq 1 ]];
    then
        echo ":: Dry run enabled."
    fi

    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Dumping used variables"
        echo ""
        echo "   ==== FLAGS ===="
        echo "   BE_VERBOSE >>${BE_VERBOSE}<<."
        echo "   IS_DRY_RUN >>${IS_DRY_RUN}<<."
        echo "   SHOW_HELP >>${SHOW_HELP}<<."
        echo ""
        echo "   ==== VARIABLES ===="
        echo "   DIRECTORY_PATH_TO_PACKAGES=${DIRECTORY_PATH_TO_PACKAGES}"
        echo "   DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION=${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}"
        echo "   PACKAGE_NAME=${PACKAGE_NAME}"
        echo "   PACKAGE_MANAGER=${PACKAGE_MANAGER}"
        echo "   PACKAGE_VERSION=${PACKAGE_VERSION}"
        echo "   DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION=${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"
        echo "   FILE_PATH_TO_PACKAGE_VERSION=${FILE_PATH_TO_PACKAGE_VERSION}"
        echo "   FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT=${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}"
        echo "   FILE_PATH_TO_REGULAR_PACKAGES=${FILE_PATH_TO_REGULAR_PACKAGES}"
        echo "   FILE_PATH_TO_SECURITY_PACKAGES=${FILE_PATH_TO_SECURITY_PACKAGES}"
        echo "   FILE_PATH_TO_SYSTEMD_SERVICE_FILE=${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}"
        echo "   FILE_PATH_TO_SYSTEMD_TIMER_FILE=${FILE_PATH_TO_SYSTEMD_TIMER_FILE}"
        echo "   FILE_PATH_TO_ZABBIX_AGENT_CONFIGURATION=${FILE_PATH_TO_ZABBIX_AGENT_CONFIGURATION}"
        echo "   ZABBIX_AGENT_CONFIGURATION_NAME=${ZABBIX_AGENT_CONFIGURATION_NAME}"
        echo ""
    fi

    _check_and_setup_system_environment_or_exit "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"

    _remove_systemd_files "${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}" "${FILE_PATH_TO_SYSTEMD_TIMER_FILE}"

    _remove_packages_files "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"

    _remove_configuration "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"

    _remove_zabbix_agent_configuration "${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}/${ZABBIX_AGENT_CONFIGURATION_NAME}"

    _echo_if_be_verbose ":: Finished deinstallation"
    _echo_if_be_verbose "   Please remove the template file in path >>${CURRENT_SCRIPT_PATH}/../template/update_notifyer.xml<< from your zabbix server (if needed)."
    #eo: code
}

_main ${*}
