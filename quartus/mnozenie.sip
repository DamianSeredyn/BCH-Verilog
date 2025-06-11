set_global_assignment -entity "mnozenie" -library "lib_mnozenie" -name IP_TOOL_NAME "altera_mult_add"
set_global_assignment -entity "mnozenie" -library "lib_mnozenie" -name IP_TOOL_VERSION "22.1"
set_global_assignment -entity "mnozenie" -library "lib_mnozenie" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_mnozenie" -name SPD_FILE [file join $::quartus(sip_path) "mnozenie.spd"]

set_global_assignment -library "lib_mnozenie" -name MISC_FILE [file join $::quartus(sip_path) "mnozenie_sim/mnozenie.v"]
