#!/bin/bash
####
# Contains the setup and installation routine
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

####
# @param: <string: PATH_TO_ZABBIX_AGENT_CONFIGURATION>
# @param: <string: path_to_the_regular_package_file>
# @param: <string: path_to_the_security_package_file>
####
function _add_zabbix_agent_configuration ()
{
    #bo: variable
    local PATH_TO_ZABBIX_AGENT_CONFIGURATION="${1}"
    local PATH_TO_THE_REGULAR_PACKAGES_FILE="${2}"
    local PATH_TO_THE_SECURITY_PACKAGES_FILE="${3}"
    #eo: variable

    #bo: prepare environment
    local DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION=$(dirname "${PATH_TO_ZABBIX_AGENT_CONFIGURATION}")

    if [[ ! -d "${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}" ]];
    then
        _echo_if_be_verbose ":: Creating path >>${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}<<."

        mkdir -p "${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}"

        if [[ $? -ne 0 ]];
        then
            echo ":: Could not create directory >>${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}<<."

            exit 1
        fi
    fi
    #eo: prepare environment

    #bo: creating configuration file
    cat > "${PATH_TO_THE_DESTINATION_DIRECTORY}/${ZABBIX_AGENT_CONFIGURATION_NAME}" <<DELIM
####
# @see: https://github.com/theranger/zabbix-apt/blob/master/zabbix_agentd.d/apt.conf
# @since: 2022-03-09
# @author: stev leibelt <artodeto@bazzline.net>
####
# Treat security and regular updates differently
####
UserParameter=update-notifyer.security,cat ${PATH_TO_THE_SECURITY_PACKAGES_FILE} | wc -l
UserParameter=update-notifyer.regular,cat ${PATH_TO_THE_REGULAR_PACKAGES_FILE} | wc -l
DELIM
    #eo: creating configuration file

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
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_regular_packages_file>
# @param: <string: path_to_security_packages_file>
####
function _create_script_for_apt ()
{
    #bo: variable
    local PATH_TO_SCRIPT_FILE="${1}"
    local PATH_TO_REGULAR_PACKAGES_FILE="${2}"
    local PATH_TO_SECURITY_PACKAGES_FILE="${3}"
    #eo: variable

    cat > "${PATH_TO_SCRIPT_FILE}" <<DELIM
#!/bin/bash
####
# Creates files containting updateable packages
####
# @since 20220312
# @author zabbix_agent-update_notifyer
####

logger -i -p cron.info ":: Starting updating of package files."
logger -i -p cron.info ":: Starting updating of package files."
logger -i -p cron.debug "   Updating package database."
apt update

logger -i -p cron.debug "   Creating file >>${PATH_TO_SECURITY_PACKAGES_FILE}<<."
apt upgrade --dry-run | grep -i ^inst.*security > "${PATH_TO_SECURITY_PACKAGES_FILE}"

logger -i -p cron.debug "   Creating file >>${PATH_TO_REGULAR_PACKAGES_FILE}<<."
apt full-upgrade --dry-run | 
apt upgrade --dry-run | grep -iP '^Inst((?!security).)*\$' > "${PATH_TO_REGULAR_PACKAGES_FILE}"

logger -i -p cron.info ":: Finished updating of package files."
DELIM

    chmod +x "${PATH_TO_SCRIPT_FILE}"
}

####
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_regular_packages_file>
# @param: <string: path_to_security_packages_file>
####
function _create_script_for_pacman ()
{
    #bo: variable
    local PATH_TO_SCRIPT_FILE="${1}"
    local PATH_TO_REGULAR_PACKAGES_FILE="${2}"
    local PATH_TO_SECURITY_PACKAGES_FILE="${3}"
    #eo: variable

    cat > "${PATH_TO_SCRIPT_FILE}" <<DELIM
#!/bin/bash
####
# Creates files containting updateable packages
####
# @since 20220312
# @author zabbix_agent-update_notifyer
####

logger -i -p cron.info ":: Starting updating of package files."
logger -i -p cron.debug "   Updating package database."
pacman -Sy

logger -i -p cron.debug "   Creating file >>${PATH_TO_SECURITY_PACKAGES_FILE}<<."
pacman -Qu > "${PATH_TO_SECURITY_PACKAGES_FILE}"

logger -i -p cron.debug "   Creating file >>${PATH_TO_REGULAR_PACKAGES_FILE}<<."
cp "${PATH_TO_SECURITY_PACKAGES_FILE}" "${PATH_TO_REGULAR_PACKAGES_FILE}"

logger -i -p cron.info ":: Finished updating of package files."
DELIM

    chmod +x "${PATH_TO_SCRIPT_FILE}"
}

####
# @param: <string: path_to_the_script_file>
# @param: <string: path_to_the_systemd_service_file>
# @param: <string: path_to_the_systemd_timer_file>
####
function _create_systemd_files ()
{
    #bo: variable
    local PATH_TO_THE_SCRIPT_FILE="${1}"
    local PATH_TO_THE_SYSTEMD_SERVICE_FILE="${2}"
    local PATH_TO_THE_SYSTEMD_TIMER_FILE="${3}"

    local SYSTEMD_TIMER=$(basename "${PATH_TO_THE_SYSTEMD_TIMER_FILE}")
    local SYSTEMD_SERVICE=$(basename "${PATH_TO_THE_SYSTEMD_SERVICE_FILE}")
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
    _echo_if_be_verbose "   Created >>${PATH_TO_THE_SYSTEMD_SERVICE_FILE}<<."

    if [[ ${?} -ne 0 ]];
    then
        _echo_an_error "   Failed with exit code >>${?}<<."
    fi
    #be: systemd service file

    #bo: systemd timer file
    cat > "${PATH_TO_THE_SYSTEMD_TIMER_FILE}" <<DELIM
[Unit]
Description=15 minute zabbix-agent update-notifier

[Timer]
OnCalendar=*:0/15
RandomizedDelaySec=42
Persistent=true
Unit=${SYSTEMD_SERVICE}

[Install]
WantedBy=timers.target
DELIM
    _echo_if_be_verbose "   Created >>${PATH_TO_THE_SYSTEMD_TIMER_FILE}<<."

    if [[ ${?} -ne 0 ]];
    then
        _echo_an_error "   Failed with exit code >>${?}<<."
    fi
    #eo: systemd timer file

    #bo: register and enable timer
    _echo_if_be_verbose "   Activating timer >>${SYSTEMD_TIMER}<<."

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        systemctl daemon-reload
        systemctl enable ${SYSTEMD_TIMER}
        systemctl start ${SYSTEMD_TIMER}
    fi
    #eo: register and enable timer
}

####
# @param <string: DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION>
####
function _check_and_setup_system_environment_or_exit ()
{
    #bo: variable
    local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="${1}"
    local WHO_AM_I=$(whoami)
    #eo: variable

    #bo: check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        _echo_an_error "   Script needs to be executed as root."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            #call this script (${0}) again with sudo with all provided arguments (${@})
            sudo "${0}" "${@}"

            exit ${?}
        fi
    fi
    #eo: check if we are root

    #bo: check if systemd installed
    if [[ ! -d /usr/lib/systemd ]];
    then
        _echo_an_error "   Directory >>/usr/lib/systemd<< does not exist."
        _echo_an_error "   Systemd is mandatory right now. Feel free to create a pull request to support multiple init systems."

        exit 2
    fi
    #bo: check if systemd installed

    #bo: check if zabbix-agent is installed
    local NUMBER_OF_ZABBIX_AGENT_SERVICE_FILES_FOUND=$(systemctl list-unit-files zabbix-agent.service | grep -c zabbix-agent.service)

    if [[ ${NUMBER_OF_ZABBIX_AGENT_SERVICE_FILES_FOUND} -eq 0 ]] ;
    then
        _echo_an_error "   Systemd service file >>zabbix-agent.service<< not found."
        _echo_an_error "   Please install zabbix agent first."

        exit 3
    fi
    #eo: check if zabbix-agent is installed

    #bo: check if this software is already installed
    if [[ -d "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}" ]];
    then
        _echo_an_error "   Directory >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<< does exist."
        _echo_an_error "   Looks like installation was already done."

        exit 4
    else
        _echo_if_be_verbose ":: Creating path >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<<."
        mkdir -p "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"

        if [[ "${?}" -gt 0 ]];
        then
            _echo_an_error "   Could not create it. mkdir return code was >>${?}<<."

            exit 5
        fi
    fi
    #eo: check if this software is already installed
}

function _echo_an_error ()
{
    echo ":: ERROR: ${1}"
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
        echo "   install.sh [-d|--dry-run] [-h|--help] [-v|--verbose]"

        exit 0
    fi

    _echo_if_be_verbose ":: Starting installation"

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
        local TEMPORARY_DIRECTORY=$(mktemp -d)

        echo ":: Dry run enabled."
        echo "   Every path variable will be prefixed with >>${TEMPORARY_DIRECTORY}<<."
        echo "   This directory won't be removed outomatically!"
        echo "   Please remove it after finishing the investigation."
        echo ""

        local FILE_PATH_TO_REGULAR_PACKAGES="${TEMPORARY_DIRECTORY}${FILE_PATH_TO_REGULAR_PACKAGES}"
        local FILE_PATH_TO_SECURITY_PACKAGES="${TEMPORARY_DIRECTORY}${FILE_PATH_TO_SECURITY_PACKAGES}"
        local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="${TEMPORARY_DIRECTORY}${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"
        local FILE_PATH_TO_SYSTEMD_SERVICE_FILE="${TEMPORARY_DIRECTORY}${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}"
        local FILE_PATH_TO_SYSTEMD_TIMER_FILE="${TEMPORARY_DIRECTORY}${FILE_PATH_TO_SYSTEMD_TIMER_FILE}"
        local FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT="${TEMPORARY_DIRECTORY}${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}"
        local DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION="${TEMPORARY_DIRECTORY}${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}"

        local DIRECTORY_PATH_FOR_PACKAGES_FILES=$(dirname "${FILE_PATH_TO_REGULAR_PACKAGES}")

        echo "   Creating path >>${DIRECTORY_PATH_FOR_PACKAGES_FILES}<<."
        mkdir -p "${DIRECTORY_PATH_FOR_PACKAGES_FILES}"

        echo "   Creating path >>${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}<<."
        mkdir -p "${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}"
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
        echo "   CURRENT_SCRIPT_PATH >>${CURRENT_SCRIPT_PATH}<<."
        echo "   PATH_TO_CONFIGURATION_FILE >>${PATH_TO_CONFIGURATION_FILE}<<"
        echo "   FILE_PATH_TO_REGULAR_PACKAGES >>${FILE_PATH_TO_REGULAR_PACKAGES}<<"
        echo "   FILE_PATH_TO_SECURITY_PACKAGES >>${FILE_PATH_TO_SECURITY_PACKAGES}<<"
        echo "   DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION >>${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}<<"
        echo "   FILE_PATH_TO_SYSTEMD_SERVICE_FILE >>${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}<<"
        echo "   FILE_PATH_TO_SYSTEMD_TIMER_FILE >>${FILE_PATH_TO_SYSTEMD_TIMER_FILE}<<"
        echo "   FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT >>${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}<<"
        echo "   DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION >>${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}<<"
        echo ""
    fi

    _check_and_setup_system_environment_or_exit "${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}"

    if [[ -f /usr/bin/pacman ]];
    then
        _create_script_for_pacman "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
    elif [[ -f /usr/bin/apt ]];
    then
        _create_script_for_apt "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"
    else
        _echo_if_be_verbose ":: No supported package manager found."
        _echo_if_be_verbose "   pacman or apt are mandatory right now. Feel free to create a pull request to support more package managers."

        exit 2
    fi

    chmod +x "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}"

    #take a look on zabbix_mysql_housekeeping/bin/install.sh
    _create_systemd_files "${FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT}" "${FILE_PATH_TO_SYSTEMD_SERVICE_FILE}" "${FILE_PATH_TO_SYSTEMD_TIMER_FILE}"

    _add_zabbix_agent_configuration "${DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION}/${ZABBIX_AGENT_CONFIGURATION_NAME}" "${FILE_PATH_TO_REGULAR_PACKAGES}" "${FILE_PATH_TO_SECURITY_PACKAGES}"

    _echo_if_be_verbose ":: Finished installation"
    _echo_if_be_verbose "   Please import the template file in path >>${CURRENT_SCRIPT_PATH}/../template/update_notifyer.xml<< in your zabbix server."
    #eo: code
}

_main ${*}
