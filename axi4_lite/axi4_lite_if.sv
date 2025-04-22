`include "modport.svh"

/* Interface: axi4_lite_if
 *
 * AXI4-Lite interface.
 *
 * Parameters:
 *  DATA_BYTES      - Number of bytes for wdata and rdata signals.
 *  ADDRESS_WIDTH   - Number of bits for awaddr and araddr signals.
 *
 * Ports:
 *  aclk        - Clock. Used only for internal checkers and assertions
 *  areset_n    - Asynchronous active-low reset. Used only for internal checkers
 *                and assertions
 */


interface axi4_lite_if #(
    int DATA_BYTES = 4,
    int ADDRESS_WIDTH = 1,
    int AWADDR_WIDTH = ADDRESS_WIDTH,
    int ARADDR_WIDTH = ADDRESS_WIDTH
) (
    input aclk,
    input areset_n
);
    import axi4_lite_pkg::*;

    typedef logic [ARADDR_WIDTH-1:0] araddr_t;
    typedef logic [AWADDR_WIDTH-1:0] awaddr_t;
    typedef logic [DATA_BYTES-1:0][7:0] wdata_t;
    typedef logic [DATA_BYTES-1:0][7:0] rdata_t;
    typedef logic [DATA_BYTES-1:0] wstrb_t;
    typedef axi4_lite_pkg::response_t rresp_t;
    typedef axi4_lite_pkg::response_t bresp_t;
    typedef axi4_lite_pkg::access_t awprot_t;
    typedef axi4_lite_pkg::access_t arprot_t;

`ifdef SYNTHESIS
    /* Write address channel */
    logic awvalid;
    logic awready;
    awaddr_t awaddr;
    awprot_t awprot;

    /* Write data channel */
    logic wvalid;
    logic wready;
    wdata_t wdata;
    wstrb_t wstrb;

    /* Write response channel */
    logic bvalid;
    logic bready;
    bresp_t bresp;

    /* Read address channel */
    logic arvalid;
    logic arready;
    araddr_t araddr;
    arprot_t arprot;

    /* Read data channel */
    logic rvalid;
    logic rready;
    rdata_t rdata;
    rresp_t rresp;
`else
    /* Write address channel */
    logic awvalid = 'X;
    logic awready = 'X;
    awaddr_t awaddr = 'X;
    awprot_t awprot = axi4_lite_pkg::access_t'('X);

    /* Write data channel */
    logic wvalid = 'X;
    logic wready = 'X;
    wdata_t wdata = 'X;
    wstrb_t wstrb = 'X;

    /* Write response channel */
    logic bvalid = 'X;
    logic bready = 'X;
    bresp_t bresp = axi4_lite_pkg::response_t'('X);

    /* Read address channel */
    logic arvalid = 'X;
    logic arready = 'X;
    araddr_t araddr = 'X;
    arprot_t arprot = axi4_lite_pkg::access_t'('X);

    /* Read data channel */
    logic rvalid = 'X;
    logic rready = 'X;
    rdata_t rdata = 'X;
    rresp_t rresp = axi4_lite_pkg::response_t'('X);
`endif

modport slave (
    /* Write address channel */
    input awvalid,
    output awready,
    input awaddr,
    input awprot,
    /* Write data channel */
    input wvalid,
    output wready,
    input wdata,
    input wstrb,
    /* Write response channel */
    output bvalid,
    input bready,
    output bresp,
    /* Read address channel */
    input arvalid,
    output arready,
    input araddr,
    input arprot,
    /* Read data channel */
    output rvalid,
    input rready,
    output rdata,
    output rresp
);

modport master (
    /* Write address channel */
    output awvalid,
    input awready,
    output awaddr,
    output awprot,
    /* Write data channel */
    output wvalid,
    input wready,
    output wdata,
    output wstrb,
    /* Write response channel */
    input bvalid,
    output bready,
    input bresp,
    /* Read address channel */
    output arvalid,
    input arready,
    output araddr,
    output arprot,
    /* Read data channel */
    input rvalid,
    output rready,
    input rdata,
    input rresp
);

modport monitor (
    /* Write address channel */
    input awvalid,
    input awready,
    input awaddr,
    input awprot,
    /* Write data channel */
    input wvalid,
    input wready,
    input wdata,
    input wstrb,
    /* Write response channel */
    input bvalid,
    input bready,
    input bresp,
    /* Read address channel */
    input arvalid,
    input arready,
    input araddr,
    input arprot,
    /* Read data channel */
    input rvalid,
    input rready,
    input rdata,
    input rresp
);

`ifndef SYNTHESIS
    clocking cb_slave @(posedge aclk);
        /* Write address channel */
        inout awvalid;
        input awready;
        inout awaddr;
        inout awprot;
        /* Write data channel */
        inout wvalid;
        input wready;
        inout wdata;
        inout wstrb;
        /* Write response channel */
        input bvalid;
        inout bready;
        input bresp;
        /* Read address channel */
        inout arvalid;
        input arready;
        inout araddr;
        inout arprot;
        /* Read data channel */
        input rvalid;
        inout rready;
        input rdata;
        input rresp;
    endclocking

    modport cb_slave_modport (
        input areset_n,
        clocking cb_slave
    );

    clocking cb_master @(posedge aclk);
        /* Write address channel */
        input awvalid;
        inout awready;
        input awaddr;
        input awprot;
        /* Write data channel */
        input wvalid;
        inout wready;
        input wdata;
        input wstrb;
        /* Write response channel */
        inout bvalid;
        input bready;
        inout bresp;
        /* Read address channel */
        input arvalid;
        inout arready;
        input araddr;
        input arprot;
        /* Read data channel */
        inout rvalid;
        input rready;
        inout rdata;
        inout rresp;
    endclocking

    modport cb_master_modport (
        input areset_n,
        clocking cb_master
    );

    clocking cb_monitor @(posedge aclk);
        /* Write address channel */
        input awvalid;
        input awready;
        input awaddr;
        input awprot;
        /* Write data channel */
        input wvalid;
        input wready;
        input wdata;
        input wstrb;
        /* Write response channel */
        input bvalid;
        input bready;
        input bresp;
        /* Read address channel */
        input arvalid;
        input arready;
        input araddr;
        input arprot;
        /* Read data channel */
        input rvalid;
        input rready;
        input rdata;
        input rresp;
    endclocking

    modport cb_monitor_modport (
        input areset_n,
        clocking cb_monitor
    );
`endif

endinterface