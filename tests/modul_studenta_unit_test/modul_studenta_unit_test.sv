`timescale 1 ns / 1 ns

`include "../svunit/svunit_base/svunit_defines.svh"

module modul_studenta_unit_test;
    import svunit_pkg::svunit_testcase;
    import unit_test_pkg::*;
    import registers_pkg::*;
    import axi4_lite_pkg::*;

    string name = "modul_studenta_unit_test";
    svunit_testcase svunit_ut;

    parameter TDATA_BYTES   = 4;
    parameter ADDRESS_WIDTH = 21;

    typedef struct {
        bit [ADDRESS_WIDTH-1:0] address;
        bit [TDATA_BYTES-1:0][7:0] data;
        bit [3:0] byte_enable;
        axi4_lite_pkg::access_t access;
        axi4_lite_pkg::response_t response;
    } request_t;
/*
    function axi4_lite_pkg::access_t random_access();
        return axi4_lite_pkg::access_t'($urandom % $bits(axi4_lite_pkg::access_t));
    endfunction

    function axi4_lite_pkg::response_t random_response();
        return axi4_lite_pkg::response_t'($urandom % $bits(axi4_lite_pkg::response_t));
    endfunction
*/
    localparam real TIME_BASE = 1000.0;
    localparam real CLOCK_100 = (TIME_BASE / 100.00);

    logic reset_n    = 1'b0;
    logic clk_100mhz = 0;

    initial forever #(CLOCK_100/2) clk_100mhz = ~clk_100mhz;

    // ----------------------------------
    // ------ Interfaces & Drivers ------
    // ----------------------------------

    axi4_lite_if #(
        .DATA_BYTES     (TDATA_BYTES),
        .ADDRESS_WIDTH  (ADDRESS_WIDTH)
    ) axi_lite_slave (
        .aclk           (clk_100mhz),
        .areset_n       (reset_n)
    );

    axi4_lite_driver_slave #(
        .DATA_BYTES     (TDATA_BYTES),
        .ADDRESS_WIDTH  (ADDRESS_WIDTH)
    ) axi4_slave_drv = new (axi_lite_slave);

    // ----------------------------------
    // ------- DUT initialization -------
    // ----------------------------------
    
    logic [ 7:0] LED;
    logic DEBUGTESTSYSTEM;

    logic        s_axil_awready;
    logic        s_axil_awvalid;
    logic [20:0] s_axil_awaddr;
    logic [ 2:0] s_axil_awprot;

    logic        s_axil_wready;
    logic        s_axil_wvalid;
    logic [31:0] s_axil_wdata;
    logic [ 3:0] s_axil_wstrb;

    logic        s_axil_bready;
    logic        s_axil_bvalid;
    logic [ 1:0] s_axil_bresp;

    logic        s_axil_arready;
    logic        s_axil_arvalid;
    logic [20:0] s_axil_araddr;
    logic [ 2:0] s_axil_arprot;

    logic        s_axil_rready;
    logic        s_axil_rvalid;
    logic [31:0] s_axil_rdata;
    logic [ 1:0] s_axil_rresp;

    assign axi_lite_slave.awready = s_axil_awready;
    assign s_axil_awvalid = axi_lite_slave.awvalid;
    assign s_axil_awaddr  = axi_lite_slave.awaddr;
    assign s_axil_awprot  = axi_lite_slave.awprot;

    assign axi_lite_slave.wready = s_axil_wready;
    assign s_axil_wvalid = axi_lite_slave.wvalid;
    assign s_axil_wdata  = axi_lite_slave.wdata;
    assign s_axil_wstrb  = axi_lite_slave.wstrb;

    assign s_axil_bready = axi_lite_slave.bready;
    assign axi_lite_slave.bvalid = s_axil_bvalid;
    assign axi_lite_slave.bresp  = s_axil_bresp;

    assign axi_lite_slave.arready = s_axil_arready;
    assign s_axil_arvalid = axi_lite_slave.arvalid;
    assign s_axil_araddr  = axi_lite_slave.araddr;
    assign s_axil_arprot  = axi_lite_slave.arprot;

    assign s_axil_rready = axi_lite_slave.rready;
    assign axi_lite_slave.rvalid = s_axil_rvalid;
    assign axi_lite_slave.rdata  = s_axil_rdata;
    assign axi_lite_slave.rresp  = s_axil_rresp;


    modul_studenta dut (
        .rst             ( ~reset_n       ),
        .clk             ( clk_100mhz     ),
    
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
        .LED             ( LED            )
    );

    typedef enum logic[2:0]{
	IDLE = 3'h0,
	ENCODING_BCH = 3'h1,
	GENERATE_NOISE = 3'h2,
	GENERATE_ERRORS = 3'h3,
	DECODING_BCH = 3'h4,
    FINISHED = 3'h5 
} appState;

function string appStateToString(appState s);
    case (s)
        IDLE:            return "IDLE";
        ENCODING_BCH:    return "ENCODING_BCH";
        GENERATE_NOISE:  return "GENERATE_NOISE";
        GENERATE_ERRORS: return "GENERATE_ERRORS";
        DECODING_BCH:    return "DECODING_BCH";
        FINISHED:        return "FINISHED";
        default:         return "UNKNOWN";
    endcase
endfunction

    function void build();
        svunit_ut = new(name);
    endfunction

    task setup();
        svunit_ut.setup();
        reset_n = 1'b0;
        #120;
        axi4_slave_drv.aclk_posedge();
        axi4_slave_drv.reset();

        @(posedge clk_100mhz);
        reset_n = 1'b1;

        axi4_slave_drv.aclk_posedge();
    endtask

    task teardown();
        svunit_ut.teardown();
        reset_n = 1'b0;
        axi4_slave_drv.reset();
    endtask

`SVUNIT_TESTS_BEGIN
    // `SVTEST(simple_write)
    //     request_t request;
    //     axi4_lite_pkg::response_t expected_response = RESPONSE_OKAY;

    //     request.data[0] = 8'h01;
    //     request.data[1] = 8'h00;
    //     request.data[2] = 8'h00;
    //     request.data[3] = 8'h00;
    //     request.address = 21'h4;
    //     request.byte_enable = 4'b0001;
    //     request.access = axi4_lite_pkg::DEFAULT_DATA_ACCESS;

    //     $display("LED[0] = %0h", dut.LED[0]);
    //     $display("LED[0] = %0b", dut.generator_signal);

    //     axi4_slave_drv.aclk_posedge();
    //     axi4_slave_drv.write_request_address(request.address);

    //     axi4_slave_drv.aclk_posedge(3);
    //     axi4_slave_drv.write_request_data(request.data, request.byte_enable);


    //     axi4_slave_drv.write_response(request.response);
    //     `FAIL_UNLESS_EQUAL(expected_response, request.response);

    //     `FAIL_UNLESS_EQUAL(dut.LED[0], 1'b1);

    //      $display("LED[0] = %0h", dut.LED[0]); 

    //     repeat(10) axi4_slave_drv.aclk_posedge();
        
    //     `FAIL_UNLESS_EQUAL(dut.LED[0], 1'b1);

    //     repeat(100) axi4_slave_drv.aclk_posedge();
    // `SVTEST_END

    // `SVTEST(simple_read)
    //     request_t request;
    //     axi4_lite_pkg::response_t expected_response = RESPONSE_OKAY;

    //     request.address = 21'h0;
    //     request.access = axi4_lite_pkg::DEFAULT_DATA_ACCESS;

    //     fork
    //         begin
    //             axi4_slave_drv.read_request(request.address, request.access);
    //         end
    //         begin
    //             request_t captured;

    //             axi4_slave_drv.read_response(captured.data, captured.response);
    //             $display("Captured ID = 0x%0x%0x%0x%0x", captured.data[3], captured.data[2], captured.data[1], captured.data[0]);
    //             `FAIL_UNLESS_EQUAL(expected_response, captured.response)
    //             `FAIL_UNLESS_EQUAL(captured.data, 32'hABCD_1234)
    //         end
    //     join

    //     repeat(100) axi4_slave_drv.aclk_posedge();
    // `SVTEST_END

    
    `SVTEST(encoding_bch_test)
        logic [7:0] signal_input = 8'b10101010;
        logic [5:0] generator_signal = 6'b100101; 
        logic [14:0] expected_encoded_signal = signal_input * generator_signal; 
        int wait_cycles = 0;
       
        dut.state = dut.ENCODING_BCH;


        while (dut.BCH_encoded_finished !== 1'b1) 
        begin
            @(posedge clk_100mhz);
            wait_cycles++;
            if (wait_cycles > 1000) begin
                $display("Timeout waiting for BCH_encoded_finished");
                `FAIL_UNLESS(0)
            break;
            end
        end
        
        $display("state of BCH_encoded = %0b", dut.BCH_encoded_finished);
        $display("encoded signal = %0b", dut.encoded_signal);
        $display("expected signal = %0b", expected_encoded_signal);
        `FAIL_UNLESS_EQUAL(dut.encoded_signal, expected_encoded_signal);
        `FAIL_UNLESS_EQUAL(dut.BCH_encoded_finished, 1'b1);  


        reset_n = ~ reset_n;
        #5 reset_n = ~ reset_n;
        
    `SVTEST_END
    

    `SVTEST(process_test)


    appState prev_state;
    int transition_count = 0;


    $display("==============================");
    $display("     INIT PROCESS TEST        ");
    $display("==============================");

    dut.state = dut.IDLE;
    DEBUGTESTSYSTEM = 1'b1;
    prev_state = dut.state;

    for (int i = 0; i < 2000; i++) begin
        @(posedge clk_100mhz);
        if (dut.state !== prev_state) begin
            transition_count++;
            $display("State transition %0d: %0s -> %0s [TIME = %0d]", transition_count,
                appStateToString(prev_state), appStateToString(dut.state),i);
            prev_state = dut.state;
        end
    end

    $display("Total number of state transitions: %0d", transition_count);

    `SVTEST_END


    `SVTEST(syndrome_coding_bch_test)
        logic [104:0] signal_input = 104'b1110101101011;
        int wait_cycles = 0;

        dut.syndrome_coding = signal_input;

        dut.state = dut.DECODING_BCH;

        while (dut.BCH_encoded_finished !== 1'b1) 
        begin
            @(posedge clk_100mhz);
            wait_cycles++;
            if (wait_cycles > 1000) begin
                $display("Timeout waiting for BCH_encoded_finished");
                `FAIL_UNLESS(0)
            break;
            end
        end
        $display("state of BCH_decoded = %0b", dut.BCH_decoded_finished);
        $display("Input signal = %0b", dut.syndrome_coding);
        $display("syndrome decoding result = %0b", dut.decoded_syndrome[0], "  %0b",dut.decoded_syndrome[1],
        "  %0b",dut.decoded_syndrome[2],"  %0b",dut.decoded_syndrome[3],"  %0b",dut.decoded_syndrome[4],
        "  %0b",dut.decoded_syndrome[5],"  %0b",dut.decoded_syndrome[6],"  %0b",dut.decoded_syndrome[7]);
        `FAIL_UNLESS_EQUAL(dut.decoded_syndrome[0], 2'b10);
        `FAIL_UNLESS_EQUAL(dut.decoded_syndrome[1], 3'b100);
        `FAIL_UNLESS_EQUAL(dut.decoded_syndrome[2], 9'b100000000);
        `FAIL_UNLESS_EQUAL(dut.decoded_syndrome[3], 5'b10000);
        `FAIL_UNLESS_EQUAL(dut.BCH_decoded_finished, 1'b1);  
        
    `SVTEST_END

`SVUNIT_TESTS_END

endmodule