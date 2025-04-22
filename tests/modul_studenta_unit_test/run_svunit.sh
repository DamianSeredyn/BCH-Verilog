#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Change to the script's directory
cd "$SCRIPT_DIR"
# Source the Setup.bsh script from the ../svunit/ directory
cd ../svunit/ && source Setup.bsh
# Change to the script's directory
cd "$SCRIPT_DIR"

# To run all unit test templates within a given parent directory
# runSVUnit -s questa -o tmp_svunit -r "-suppress 12003,8386" -r "-voptargs=+acc" -r "-sv_seed random" "$@"

# To run specific unit test template within a given parent directory
runSVUnit -s questa -o tmp_svunit -r "-suppress 12003,8386" -r "-voptargs=+acc" -r "-sv_seed random" -t modul_studenta_unit_test.sv -r "-do ../modul_studenta_unit_test.do" "$@"

# Example of run in GUI
# ./run_svunit.sh -r -gui

# Example of run and define set
# ./run_svunit.sh -d MY_DEFINE=1