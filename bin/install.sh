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

function _main ()
{
    echo "foo"
}

_main ${*}
