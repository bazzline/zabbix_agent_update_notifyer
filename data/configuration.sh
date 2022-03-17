#!/bin/bash
####
# Configuration file
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

local FILE_PATH_TO_REGULAR_PACKAGES="/var/local/update_notifyer-list_of_updateable_regular_packages.txt"
local FILE_PATH_TO_SECURITY_PACKAGES="/var/local/update_notifyer-list_of_updateable_security_packages.txt"
local ROOT_PATH_TO_PACKAGE_CONFIGURATION="/opt/net_bazzline/zabbix_agent/update_notifyer"

local PATH_TO_SYSTEMD_SERVICE_FILE="/etc/systemd/system/zabbix_agent-update_notifyer.service"
local PATH_TO_SYSTEMD_TIMER_FILE="/etc/systemd/system/zabbix_agent-update_notifyer.timer"
local FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT="${ROOT_PATH_TO_PACKAGE_CONFIGURATION}/generate_package_files.sh"
