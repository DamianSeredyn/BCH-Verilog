module soc_system (
      input              FPGA_CLK1_50,
      input              FPGA_CLK2_50,
      input              FPGA_CLK3_50,

      input       [1:0]  KEY,
      output      [7:0]  LED,
      input              DEBUGTESTSYSTEM,
    input   [7:0] DataIN,
    output  [7:0] DataOUT,
    input   BCH,
    input   FS,
    input Gauss,
    input   BER,
    input   [7:0] density,
    input   [7:0] BERGen,
    output DataOutputReady,
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C0_SCLK,
      inout              HPS_I2C0_SDAT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_KEY,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP
);


wire hps_reset_n;
assign hps_reset_n = KEY[0];

logic        s_axil_awready;
logic        s_axil_awvalid;
logic [20:0] s_axil_awaddr;
logic [ 2:0] s_axil_awprot;

logic        s_axil_wready;
logic        s_axil_wvalid;
logic [31:0] s_axil_wdata;
logic [ 3:0] s_axil_wstrb;
logic [11:0] s_axil_awid;

logic        s_axil_bready;
logic        s_axil_bvalid;
logic [ 1:0] s_axil_bresp;

logic        s_axil_arready;
logic        s_axil_arvalid;
logic [20:0] s_axil_araddr;
logic [ 2:0] s_axil_arprot;

logic        s_axil_rready;
logic        s_axil_rvalid;
logic        s_axil_rlast;
logic [31:0] s_axil_rdata;
logic [ 1:0] s_axil_rresp;
logic [11:0] s_axil_arid;

//------------------------------------------
//------------- HPS ------------------------
//------------------------------------------
hps u_hps (
    // Resets & events
    .hps_f2h_cold_reset_req_reset_n        (hps_reset_n),
    .hps_f2h_debug_reset_req_reset_n       (hps_reset_n),
    .hps_f2h_warm_reset_req_reset_n        (hps_reset_n),
    .hps_f2h_stm_hw_events_stm_hwevents    ('0),
    .hps_h2f_reset_reset_n                 (  ),

    // IRQ
    .hps_f2h_irq0_irq                      ('0),
    .hps_f2h_irq1_irq                      ('0),

    //HPS ethernet	
    .hps_io_hps_io_emac1_inst_TX_CLK       (HPS_ENET_GTX_CLK),
    .hps_io_hps_io_emac1_inst_TXD0         (HPS_ENET_TX_DATA[0]),
    .hps_io_hps_io_emac1_inst_TXD1         (HPS_ENET_TX_DATA[1]),
    .hps_io_hps_io_emac1_inst_TXD2         (HPS_ENET_TX_DATA[2]),
    .hps_io_hps_io_emac1_inst_TXD3         (HPS_ENET_TX_DATA[3]),
    .hps_io_hps_io_emac1_inst_MDIO         (HPS_ENET_MDIO),
    .hps_io_hps_io_emac1_inst_MDC          (HPS_ENET_MDC),
    .hps_io_hps_io_emac1_inst_RX_CTL       (HPS_ENET_RX_DV),
    .hps_io_hps_io_emac1_inst_TX_CTL       (HPS_ENET_TX_EN),
    .hps_io_hps_io_emac1_inst_RX_CLK       (HPS_ENET_RX_CLK),
    .hps_io_hps_io_emac1_inst_RXD0         (HPS_ENET_RX_DATA[0]),
    .hps_io_hps_io_emac1_inst_RXD1         (HPS_ENET_RX_DATA[1]),
    .hps_io_hps_io_emac1_inst_RXD2         (HPS_ENET_RX_DATA[2]),
    .hps_io_hps_io_emac1_inst_RXD3         (HPS_ENET_RX_DATA[3]),
    //HPS SD card
    .hps_io_hps_io_sdio_inst_CLK           (HPS_SD_CLK),
    .hps_io_hps_io_sdio_inst_CMD           (HPS_SD_CMD),
    .hps_io_hps_io_sdio_inst_PWREN         (),
    .hps_io_hps_io_sdio_inst_D0            (HPS_SD_DATA[0]),
    .hps_io_hps_io_sdio_inst_D1            (HPS_SD_DATA[1]),
    .hps_io_hps_io_sdio_inst_D2            (HPS_SD_DATA[2]),
    .hps_io_hps_io_sdio_inst_D3            (HPS_SD_DATA[3]),
    //HPS USB
    .hps_io_hps_io_usb1_inst_D0            (HPS_USB_DATA[0]),
    .hps_io_hps_io_usb1_inst_D1            (HPS_USB_DATA[1]),
    .hps_io_hps_io_usb1_inst_D2            (HPS_USB_DATA[2]),
    .hps_io_hps_io_usb1_inst_D3            (HPS_USB_DATA[3]),
    .hps_io_hps_io_usb1_inst_D4            (HPS_USB_DATA[4]),
    .hps_io_hps_io_usb1_inst_D5            (HPS_USB_DATA[5]),
    .hps_io_hps_io_usb1_inst_D6            (HPS_USB_DATA[6]),
    .hps_io_hps_io_usb1_inst_D7            (HPS_USB_DATA[7]),
    .hps_io_hps_io_usb1_inst_CLK           (HPS_USB_CLKOUT),
    .hps_io_hps_io_usb1_inst_STP           (HPS_USB_STP),
    .hps_io_hps_io_usb1_inst_DIR           (HPS_USB_DIR),
    .hps_io_hps_io_usb1_inst_NXT           (HPS_USB_NXT),
    //HPS SPI 		  
    .hps_io_hps_io_spim1_inst_CLK          (HPS_SPIM_CLK),
    .hps_io_hps_io_spim1_inst_MOSI         (HPS_SPIM_MOSI),
    .hps_io_hps_io_spim1_inst_MISO         (HPS_SPIM_MISO),
    .hps_io_hps_io_spim1_inst_SS0          (HPS_SPIM_SS),
    //HPS UART
    .hps_io_hps_io_uart0_inst_RX           (HPS_UART_RX),
    .hps_io_hps_io_uart0_inst_TX           (HPS_UART_TX),
    //HPS I2C1
    .hps_io_hps_io_i2c0_inst_SDA           (HPS_I2C0_SDAT),
    .hps_io_hps_io_i2c0_inst_SCL           (HPS_I2C0_SCLK),
    //HPS I2C2
    .hps_io_hps_io_i2c1_inst_SDA           (HPS_I2C1_SDAT),
    .hps_io_hps_io_i2c1_inst_SCL           (HPS_I2C1_SCLK),
   
    //HPS ddr3
    .memory_mem_a                          (HPS_DDR3_ADDR),
    .memory_mem_ba                         (HPS_DDR3_BA),
    .memory_mem_ck                         (HPS_DDR3_CK_P),
    .memory_mem_ck_n                       (HPS_DDR3_CK_N),
    .memory_mem_cke                        (HPS_DDR3_CKE), 
    .memory_mem_cs_n                       (HPS_DDR3_CS_N),
    .memory_mem_ras_n                      (HPS_DDR3_RAS_N),
    .memory_mem_cas_n                      (HPS_DDR3_CAS_N),
    .memory_mem_we_n                       (HPS_DDR3_WE_N),
    .memory_mem_reset_n                    (HPS_DDR3_RESET_N),
    .memory_mem_dq                         (HPS_DDR3_DQ),
    .memory_mem_dqs                        (HPS_DDR3_DQS_P),
    .memory_mem_dqs_n                      (HPS_DDR3_DQS_N),
    .memory_mem_odt                        (HPS_DDR3_ODT),
    .memory_mem_dm                         (HPS_DDR3_DM),
    .memory_oct_rzqin                      (HPS_DDR3_RZQ),

    .rst_reset                             (~hps_reset_n),
    .clk_clk                               (FPGA_CLK1_50),

    .hps_h2f_lw_axi_master_awid            (s_axil_awid),
    .hps_h2f_lw_axi_master_awaddr          (s_axil_awaddr),
    .hps_h2f_lw_axi_master_awlen           (),
    .hps_h2f_lw_axi_master_awsize          (),
    .hps_h2f_lw_axi_master_awburst         (),
    .hps_h2f_lw_axi_master_awlock          (),
    .hps_h2f_lw_axi_master_awcache         (),
    .hps_h2f_lw_axi_master_awprot          (s_axil_awprot),
    .hps_h2f_lw_axi_master_awvalid         (s_axil_awvalid),
    .hps_h2f_lw_axi_master_awready         (s_axil_awready),

    .hps_h2f_lw_axi_master_wid             (),       
    .hps_h2f_lw_axi_master_wdata           (s_axil_wdata),
    .hps_h2f_lw_axi_master_wstrb           (s_axil_wstrb),
    .hps_h2f_lw_axi_master_wlast           (),
    .hps_h2f_lw_axi_master_wvalid          (s_axil_wvalid),
    .hps_h2f_lw_axi_master_wready          (s_axil_wready),

    .hps_h2f_lw_axi_master_bid             (s_axil_awid),          
    .hps_h2f_lw_axi_master_bresp           (s_axil_bresp),
    .hps_h2f_lw_axi_master_bvalid          (s_axil_bvalid),
    .hps_h2f_lw_axi_master_bready          (s_axil_bready),

    .hps_h2f_lw_axi_master_arid            (s_axil_arid),
    .hps_h2f_lw_axi_master_araddr          (s_axil_araddr),
    .hps_h2f_lw_axi_master_arlen           (),
    .hps_h2f_lw_axi_master_arsize          (),
    .hps_h2f_lw_axi_master_arburst         (),
    .hps_h2f_lw_axi_master_arlock          (),
    .hps_h2f_lw_axi_master_arcache         (),
    .hps_h2f_lw_axi_master_arprot          (s_axil_arprot),
    .hps_h2f_lw_axi_master_arvalid         (s_axil_arvalid),
    .hps_h2f_lw_axi_master_arready         (s_axil_arready),

    .hps_h2f_lw_axi_master_rid             (s_axil_arid),          
    .hps_h2f_lw_axi_master_rdata           (s_axil_rdata),
    .hps_h2f_lw_axi_master_rresp           (s_axil_rresp),
    .hps_h2f_lw_axi_master_rlast           (s_axil_rlast),
    .hps_h2f_lw_axi_master_rvalid          (s_axil_rvalid),
    .hps_h2f_lw_axi_master_rready          (s_axil_rready)
);

assign s_axil_rlast = (s_axil_rvalid & s_axil_rready);



`ifdef AXI_DEBUG

(* noprune *) logic        DEBUG_s_axil_awready;
(* noprune *) logic        DEBUG_s_axil_awvalid;
(* noprune *) logic [20:0] DEBUG_s_axil_awaddr;
(* noprune *) logic [ 2:0] DEBUG_s_axil_awprot;

(* noprune *) logic        DEBUG_s_axil_wready;
(* noprune *) logic        DEBUG_s_axil_wvalid;

(* noprune *) logic [31:0] DEBUG_s_axil_wdata;
(* noprune *) logic [ 3:0] DEBUG_s_axil_wstrb;
(* noprune *) logic [11:0] DEBUG_s_axil_awid;

(* noprune *) logic        DEBUG_s_axil_bready;
(* noprune *) logic        DEBUG_s_axil_bvalid;
(* noprune *) logic [ 1:0] DEBUG_s_axil_bresp;

(* noprune *) logic        DEBUG_s_axil_arready;
(* noprune *) logic        DEBUG_s_axil_arvalid;
(* noprune *) logic [20:0] DEBUG_s_axil_araddr;
(* noprune *) logic [ 2:0] DEBUG_s_axil_arprot;

(* noprune *) logic        DEBUG_s_axil_rready;
(* noprune *) logic        DEBUG_s_axil_rvalid;
(* noprune *) logic        DEBUG_s_axil_rlast;
(* noprune *) logic [31:0] DEBUG_s_axil_rdata;
(* noprune *) logic [ 1:0] DEBUG_s_axil_rresp;
(* noprune *) logic [11:0] DEBUG_s_axil_arid;

   always_ff @(posedge FPGA_CLK1_50) begin
      DEBUG_s_axil_awready <= s_axil_awready ;
      DEBUG_s_axil_awvalid <= s_axil_awvalid ;
      DEBUG_s_axil_awaddr  <= s_axil_awaddr  ;
      DEBUG_s_axil_awprot  <= s_axil_awprot  ;
      DEBUG_s_axil_wready  <= s_axil_wready  ;
      DEBUG_s_axil_wvalid  <= s_axil_wvalid  ;
      DEBUG_s_axil_wdata   <= s_axil_wdata   ;
      DEBUG_s_axil_wstrb   <= s_axil_wstrb   ;
      DEBUG_s_axil_awid    <= s_axil_awid    ;
      DEBUG_s_axil_bready  <= s_axil_bready  ;
      DEBUG_s_axil_bvalid  <= s_axil_bvalid  ;
      DEBUG_s_axil_bresp   <= s_axil_bresp   ;
      DEBUG_s_axil_arready <= s_axil_arready ;
      DEBUG_s_axil_arvalid <= s_axil_arvalid ;
      DEBUG_s_axil_araddr  <= s_axil_araddr  ;
      DEBUG_s_axil_arprot  <= s_axil_arprot  ;
      DEBUG_s_axil_rready  <= s_axil_rready  ;
      DEBUG_s_axil_rvalid  <= s_axil_rvalid  ;
      DEBUG_s_axil_rlast   <= s_axil_rlast   ;
      DEBUG_s_axil_rdata   <= s_axil_rdata   ;
      DEBUG_s_axil_rresp   <= s_axil_rresp   ;
      DEBUG_s_axil_arid    <= s_axil_arid    ;
   end
`endif


modul_studenta modul_studenta_u (
    .rst             ( ~hps_reset_n   ),
    .clk             ( FPGA_CLK1_50   ),

    .s_axil_awready  ( s_axil_awready ),
    .s_axil_awvalid  ( s_axil_awvalid ),
    .s_axil_awaddr   ( s_axil_awaddr  ),
    .s_axil_awprot   ( s_axil_awprot  ),
    .s_axil_wready   ( s_axil_wready  ),
    .s_axil_wvalid   ( s_axil_wvalid  ),
    .s_axil_wdata    ( s_axil_wdata   ),
    .s_axil_wstrb    ( s_axil_wstrb   ),
    .s_axil_bready   ( s_axil_bready  ),
    .s_axil_bvalid   ( s_axil_bvalid  ),
    .s_axil_bresp    ( s_axil_bresp   ),
    .s_axil_arready  ( s_axil_arready ),
    .s_axil_arvalid  ( s_axil_arvalid ),
    .s_axil_araddr   ( s_axil_araddr  ),
    .s_axil_arprot   ( s_axil_arprot  ),
    .s_axil_rready   ( s_axil_rready  ),
    .s_axil_rvalid   ( s_axil_rvalid  ),
    .s_axil_rdata    ( s_axil_rdata   ),
    .s_axil_rresp    ( s_axil_rresp   ),
    .DebugTestSystem ( DEBUGTESTSYSTEM),
    .LED             ( LED            ),
    .DataIN          ( DataIN         ),
    .DataOUT         ( DataOUT        ),
    .BCH             ( BCH            ),
    .Gauss            ( Gauss         ),
    .FS              ( FS             ),
    .BER             ( BER            ),
    .density         ( density        ),
    .BERGen          ( BERGen         ),
    .DataOutputReady ( DataOutputReady)
);


endmodule