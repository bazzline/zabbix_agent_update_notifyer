#!/bin/bash
####
# Configuration file
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

local DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION="/opt/net_bazzline/zabbix_agent/update_notifyer"
local DIRECTORY_PATH_TO_PACKAGES="/var/local"
local PACKAGE_NAME="zabbix_agent-update_notifyer"

local FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT="${DIRECTORY_PATH_TO_PACKAGE_CONFIGURATION}/generate_package_files.sh"
local FILE_PATH_TO_REGULAR_PACKAGES="${DIRECTORY_PATH_FOR_PACKAGES_FILES}/${PACKAGE_NAME}_-_regular_packages.txt"
local FILE_PATH_TO_SECURITY_PACKAGES="${DIRECTORY_PATH_FOR_PACKAGES_FILES}/${PACKAGE_NAME}_-_security_packages.txt"
local FILE_PATH_TO_SYSTEMD_SERVICE_FILE="/etc/systemd/system/${PACKAGE_NAME}.service"
local FILE_PATH_TO_SYSTEMD_TIMER_FILE="/etc/systemd/system/${PACKAGE_NAME}.timer"
local ZABBIX_AGENT_CONFIGURATION_NAME="${PACKAGE_NAME}.conf"
