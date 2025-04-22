`ifndef MODPORT_SVH
`define MODPORT_SVH

`ifndef MODPORT_DISABLED
    /* Define: MODPORT
     *
     * Define that helps to enable or disable modport feature. Useful only for Intel
     * Quartus Pro Prime that doesn't support modports properly.
     *
     * Parameters:
     *  _interface  - Interface name.
     *  _modport    - Modport name.
     */
    `define MODPORT(_interface, _modport) \
        _interface.``_modport
`else
    `define MODPORT(_interface, _modport) \
        _interface
`endif

`endif /* MODPORT_SVH */
