#!/bin/bash
####
# Configuration file
####
# @since 2022-03-10
# @author stev leibelt <artodeto@bazzline.net>
####

FILE_PATH_TO_REGULAR_PACKAGES="/var/local/packagemanager-list_of_updateable_regular_packages.txt"
FILE_PATH_TO_SECURITY_PACKAGES="/var/local/packagemanager-list_of_updateable_security_packages.txt"
ROOT_PATH_TO_PACKAGE_CONFIGURATION="/etc/net.bazzline/zabbix_agent/update_notifyer"

FILE_PATH_TO_SYSTEMD_SERVICE_FILE="${ROOT_PATH_TO_PACKAGE_CONFIGURATION}/zabbix_agent-update_notifyer.service"
FILE_PATH_TO_SYSTEMD_TIMER_FILE="${ROOT_PATH_TO_PACKAGE_CONFIGURATION}/zabbix_agent-update_notifyer.timer"
FILE_PATH_TO_PACKAGE_FILES_GENERATION_SCRIPT="${ROOT_PATH_TO_PACKAGE_CONFIGURATION}/generate_package_files.sh"
