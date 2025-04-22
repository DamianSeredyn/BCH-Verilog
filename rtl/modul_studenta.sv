module modul_studenta (
    input  logic        rst,
    input  logic        clk,

    output logic        s_axil_awready,
    input  wire         s_axil_awvalid,
    input  wire [20:0]  s_axil_awaddr,
    input  wire [2:0]   s_axil_awprot,
    output logic        s_axil_wready,
    input  wire         s_axil_wvalid,
    input  wire [31:0]  s_axil_wdata,
    input  wire [3:0]   s_axil_wstrb,
    input  wire         s_axil_bready,
    output logic        s_axil_bvalid,
    output logic [1:0]  s_axil_bresp,
    output logic        s_axil_arready,
    input  wire         s_axil_arvalid,
    input  wire [20:0]  s_axil_araddr,
    input  wire [2:0]   s_axil_arprot,
    input  wire         s_axil_rready,
    output logic        s_axil_rvalid,
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,

    output logic [7:0]  LED
);

import registers_pkg::*;

registers_pkg::registers__out_t hwif_out;


//------------------------------------------
//------------- Registers ------------------
//------------------------------------------
registers u_registers (
    .clk                (clk),
    .rst                (rst),

    .s_axil_awready     (s_axil_awready),
    .s_axil_awvalid     (s_axil_awvalid),
    .s_axil_awaddr      (s_axil_awaddr[REGISTERS_MIN_ADDR_WIDTH-1:0]),
    .s_axil_awprot      (s_axil_awprot),

    .s_axil_wready      (s_axil_wready),
    .s_axil_wvalid      (s_axil_wvalid),
    .s_axil_wdata       (s_axil_wdata),
    .s_axil_wstrb       (s_axil_wstrb),

    .s_axil_bready      (s_axil_bready),
    .s_axil_bvalid      (s_axil_bvalid),
    .s_axil_bresp       (s_axil_bresp),

    .s_axil_arready     (s_axil_arready),
    .s_axil_arvalid     (s_axil_arvalid),
    .s_axil_araddr      (s_axil_araddr[REGISTERS_MIN_ADDR_WIDTH-1:0]),
    .s_axil_arprot      (s_axil_arprot),

    .s_axil_rready      (s_axil_rready),
    .s_axil_rvalid      (s_axil_rvalid),
    .s_axil_rdata       (s_axil_rdata),
    .s_axil_rresp       (s_axil_rresp),

    .hwif_out           (hwif_out)
);

endmodule