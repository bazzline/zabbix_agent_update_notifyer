#!/bin/bash
####
# Configuration file
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

#we are expecting a defined variable called >>OPTIONAL_PATH_PREFIX<<
#it only exists to ease up the maintainability for dry run reasons

if [[ -f /usr/bin/pacman ]];
then
    local PACKAGE_MANAGER="pacman"
elif [[ -f /usr/bin/apt ]];
then
    local PACKAGE_MANAGER="apt"
else
    local PACKAGE_MANAGER=""
fi

local DIRECTORY_PATH_TO_PACKAGES="${OPTIONAL_PATH_PREFIX}/var/local"
local DIRECTORY_PATH_TO_THE_ZABBIX_AGENT_CONFIGURATION="${OPTIONAL_PATH_PREFIX}/usr/local/etc/zabbix_agentd.conf.d"
local PACKAGE_NAME="zabbix_agent-update_notifyer"
local PACKAGE_VERSION="1.0.0"

local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="${OPTIONAL_PATH_PREFIX}/opt/net_bazzline/${PACKAGE_NAME}"

local FILE_PATH_TO_PACKAGE_VERSION="${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}/current_version.txt"
local FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT="${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}/generate_package_files.sh"
local FILE_PATH_TO_REGULAR_PACKAGES="${DIRECTORY_PATH_TO_PACKAGES}/${PACKAGE_NAME}_-_regular_packages.txt"
local FILE_PATH_TO_SECURITY_PACKAGES="${DIRECTORY_PATH_TO_PACKAGES}/${PACKAGE_NAME}_-_security_packages.txt"
local FILE_PATH_TO_SYSTEMD_SERVICE_FILE="${OPTIONAL_PATH_PREFIX}/etc/systemd/system/${PACKAGE_NAME}.service"
local FILE_PATH_TO_SYSTEMD_TIMER_FILE="${OPTIONAL_PATH_PREFIX}/etc/systemd/system/${PACKAGE_NAME}.timer"
local ZABBIX_AGENT_CONFIGURATION_NAME="${PACKAGE_NAME}.conf"