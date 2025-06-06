// Generated by PeakRDL-regblock - A free and open-source SystemVerilog generator
//  https://github.com/SystemRDL/PeakRDL-regblock

module registers (
        input wire clk,
        input wire rst,

        output logic s_axil_awready,
        input wire s_axil_awvalid,
        input wire [4:0] s_axil_awaddr,
        input wire [2:0] s_axil_awprot,
        output logic s_axil_wready,
        input wire s_axil_wvalid,
        input wire [31:0] s_axil_wdata,
        input wire [3:0]s_axil_wstrb,
        input wire s_axil_bready,
        output logic s_axil_bvalid,
        output logic [1:0] s_axil_bresp,
        output logic s_axil_arready,
        input wire s_axil_arvalid,
        input wire [4:0] s_axil_araddr,
        input wire [2:0] s_axil_arprot,
        input wire s_axil_rready,
        output logic s_axil_rvalid,
        output logic [31:0] s_axil_rdata,
        output logic [1:0] s_axil_rresp,

        input registers_pkg::registers__in_t hwif_in,
        output registers_pkg::registers__out_t hwif_out
    );

    //--------------------------------------------------------------------------
    // CPU Bus interface logic
    //--------------------------------------------------------------------------
    logic cpuif_req;
    logic cpuif_req_is_wr;
    logic [4:0] cpuif_addr;
    logic [31:0] cpuif_wr_data;
    logic [31:0] cpuif_wr_biten;
    logic cpuif_req_stall_wr;
    logic cpuif_req_stall_rd;

    logic cpuif_rd_ack;
    logic cpuif_rd_err;
    logic [31:0] cpuif_rd_data;

    logic cpuif_wr_ack;
    logic cpuif_wr_err;

    // Max Outstanding Transactions: 2
    logic [1:0] axil_n_in_flight;
    logic axil_prev_was_rd;
    logic axil_arvalid;
    logic [4:0] axil_araddr;
    logic axil_ar_accept;
    logic axil_awvalid;
    logic [4:0] axil_awaddr;
    logic axil_wvalid;
    logic [31:0] axil_wdata;
    logic [3:0] axil_wstrb;
    logic axil_aw_accept;
    logic axil_resp_acked;

    // Transaction request accpetance
    always_ff @(posedge clk) begin
        if(rst) begin
            axil_prev_was_rd <= '0;
            axil_arvalid <= '0;
            axil_araddr <= '0;
            axil_awvalid <= '0;
            axil_awaddr <= '0;
            axil_wvalid <= '0;
            axil_wdata <= '0;
            axil_wstrb <= '0;
            axil_n_in_flight <= '0;
        end else begin
            // AR* acceptance register
            if(axil_ar_accept) begin
                axil_prev_was_rd <= '1;
                axil_arvalid <= '0;
            end
            if(s_axil_arvalid && s_axil_arready) begin
                axil_arvalid <= '1;
                axil_araddr <= s_axil_araddr;
            end

            // AW* & W* acceptance registers
            if(axil_aw_accept) begin
                axil_prev_was_rd <= '0;
                axil_awvalid <= '0;
                axil_wvalid <= '0;
            end
            if(s_axil_awvalid && s_axil_awready) begin
                axil_awvalid <= '1;
                axil_awaddr <= s_axil_awaddr;
            end
            if(s_axil_wvalid && s_axil_wready) begin
                axil_wvalid <= '1;
                axil_wdata <= s_axil_wdata;
                axil_wstrb <= s_axil_wstrb;
            end

            // Keep track of in-flight transactions
            if((axil_ar_accept || axil_aw_accept) && !axil_resp_acked) begin
                axil_n_in_flight <= axil_n_in_flight + 1'b1;
            end else if(!(axil_ar_accept || axil_aw_accept) && axil_resp_acked) begin
                axil_n_in_flight <= axil_n_in_flight - 1'b1;
            end
        end
    end

    always_comb begin
        s_axil_arready = (!axil_arvalid || axil_ar_accept);
        s_axil_awready = (!axil_awvalid || axil_aw_accept);
        s_axil_wready = (!axil_wvalid || axil_aw_accept);
    end

    // Request dispatch
    always_comb begin
        cpuif_wr_data = axil_wdata;
        for(int i=0; i<4; i++) begin
            cpuif_wr_biten[i*8 +: 8] = {8{axil_wstrb[i]}};
        end
        cpuif_req = '0;
        cpuif_req_is_wr = '0;
        cpuif_addr = '0;
        axil_ar_accept = '0;
        axil_aw_accept = '0;

        if(axil_n_in_flight < 2'd2) begin
            // Can safely issue more transactions without overwhelming response buffer
            if(axil_arvalid && !axil_prev_was_rd) begin
                cpuif_req = '1;
                cpuif_req_is_wr = '0;
                cpuif_addr = {axil_araddr[4:2], 2'b0};
                if(!cpuif_req_stall_rd) axil_ar_accept = '1;
            end else if(axil_awvalid && axil_wvalid) begin
                cpuif_req = '1;
                cpuif_req_is_wr = '1;
                cpuif_addr = {axil_awaddr[4:2], 2'b0};
                if(!cpuif_req_stall_wr) axil_aw_accept = '1;
            end else if(axil_arvalid) begin
                cpuif_req = '1;
                cpuif_req_is_wr = '0;
                cpuif_addr = {axil_araddr[4:2], 2'b0};
                if(!cpuif_req_stall_rd) axil_ar_accept = '1;
            end
        end
    end


    // AXI4-Lite Response Logic
    struct {
        logic is_wr;
        logic err;
        logic [31:0] rdata;
    } axil_resp_buffer[2];

    logic [1:0] axil_resp_wptr;
    logic [1:0] axil_resp_rptr;

    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i=0; i<2; i++) begin
                axil_resp_buffer[i].is_wr <= '0;
                axil_resp_buffer[i].err <= '0;
                axil_resp_buffer[i].rdata <= '0;
            end
            axil_resp_wptr <= '0;
            axil_resp_rptr <= '0;
        end else begin
            // Store responses in buffer until AXI response channel accepts them
            if(cpuif_rd_ack || cpuif_wr_ack) begin
                if(cpuif_rd_ack) begin
                    axil_resp_buffer[axil_resp_wptr[0:0]].is_wr <= '0;
                    axil_resp_buffer[axil_resp_wptr[0:0]].err <= cpuif_rd_err;
                    axil_resp_buffer[axil_resp_wptr[0:0]].rdata <= cpuif_rd_data;

                end else if(cpuif_wr_ack) begin
                    axil_resp_buffer[axil_resp_wptr[0:0]].is_wr <= '1;
                    axil_resp_buffer[axil_resp_wptr[0:0]].err <= cpuif_wr_err;
                end
                axil_resp_wptr <= axil_resp_wptr + 1'b1;
            end

            // Advance read pointer when acknowledged
            if(axil_resp_acked) begin
                axil_resp_rptr <= axil_resp_rptr + 1'b1;
            end
        end
    end

    always_comb begin
        axil_resp_acked = '0;
        s_axil_bvalid = '0;
        s_axil_rvalid = '0;
        if(axil_resp_rptr != axil_resp_wptr) begin
            if(axil_resp_buffer[axil_resp_rptr[0:0]].is_wr) begin
                s_axil_bvalid = '1;
                if(s_axil_bready) axil_resp_acked = '1;
            end else begin
                s_axil_rvalid = '1;
                if(s_axil_rready) axil_resp_acked = '1;
            end
        end

        s_axil_rdata = axil_resp_buffer[axil_resp_rptr[0:0]].rdata;
        if(axil_resp_buffer[axil_resp_rptr[0:0]].err) begin
            s_axil_bresp = 2'b10;
            s_axil_rresp = 2'b10;
        end else begin
            s_axil_bresp = 2'b00;
            s_axil_rresp = 2'b00;
        end
    end

    logic cpuif_req_masked;

    // Read & write latencies are balanced. Stalls not required
    assign cpuif_req_stall_rd = '0;
    assign cpuif_req_stall_wr = '0;
    assign cpuif_req_masked = cpuif_req
                            & !(!cpuif_req_is_wr & cpuif_req_stall_rd)
                            & !(cpuif_req_is_wr & cpuif_req_stall_wr);

    //--------------------------------------------------------------------------
    // Address Decode
    //--------------------------------------------------------------------------
    typedef struct {
        logic SYSTEM_ID;
        logic LEDS;
        logic DEBUG;
        logic INPUT_DATA;
        logic OUTPUT_DATA;
    } decoded_reg_strb_t;
    decoded_reg_strb_t decoded_reg_strb;
    logic decoded_req;
    logic decoded_req_is_wr;
    logic [31:0] decoded_wr_data;
    logic [31:0] decoded_wr_biten;

    always_comb begin
        decoded_reg_strb.SYSTEM_ID = cpuif_req_masked & (cpuif_addr == 5'h0);
        decoded_reg_strb.LEDS = cpuif_req_masked & (cpuif_addr == 5'h4);
        decoded_reg_strb.DEBUG = cpuif_req_masked & (cpuif_addr == 5'h8);
        decoded_reg_strb.INPUT_DATA = cpuif_req_masked & (cpuif_addr == 5'hc);
        decoded_reg_strb.OUTPUT_DATA = cpuif_req_masked & (cpuif_addr == 5'h10);
    end

    // Pass down signals to next stage
    assign decoded_req = cpuif_req_masked;
    assign decoded_req_is_wr = cpuif_req_is_wr;
    assign decoded_wr_data = cpuif_wr_data;
    assign decoded_wr_biten = cpuif_wr_biten;

    //--------------------------------------------------------------------------
    // Field logic
    //--------------------------------------------------------------------------
    typedef struct {
        struct {
            struct {
                logic [7:0] next;
                logic load_next;
            } LED;
        } LEDS;
        struct {
            struct {
                logic [7:0] next;
                logic load_next;
            } DataIN;
            struct {
                logic next;
                logic load_next;
            } BCH;
            struct {
                logic next;
                logic load_next;
            } FS;
            struct {
                logic next;
                logic load_next;
            } Gauss;
            struct {
                logic next;
                logic load_next;
            } BER;
            struct {
                logic [7:0] next;
                logic load_next;
            } density;
            struct {
                logic [7:0] next;
                logic load_next;
            } BERGen;
            struct {
                logic next;
                logic load_next;
            } DataINReady;
        } INPUT_DATA;
        struct {
            struct {
                logic [7:0] next;
                logic load_next;
            } DataOUT;
            struct {
                logic next;
                logic load_next;
            } DataOutputReady;
        } OUTPUT_DATA;
    } field_combo_t;
    field_combo_t field_combo;

    typedef struct {
        struct {
            struct {
                logic [7:0] value;
            } LED;
        } LEDS;
        struct {
            struct {
                logic [7:0] value;
            } DataIN;
            struct {
                logic value;
            } BCH;
            struct {
                logic value;
            } FS;
            struct {
                logic value;
            } Gauss;
            struct {
                logic value;
            } BER;
            struct {
                logic [7:0] value;
            } density;
            struct {
                logic [7:0] value;
            } BERGen;
            struct {
                logic value;
            } DataINReady;
        } INPUT_DATA;
        struct {
            struct {
                logic [7:0] value;
            } DataOUT;
            struct {
                logic value;
            } DataOutputReady;
        } OUTPUT_DATA;
    } field_storage_t;
    field_storage_t field_storage;

    // Field: registers.LEDS.LED
    always_comb begin
        automatic logic [7:0] next_c = field_storage.LEDS.LED.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.LEDS && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.LEDS.LED.value & ~decoded_wr_biten[7:0]) | (decoded_wr_data[7:0] & decoded_wr_biten[7:0]);
            load_next_c = '1;
        end
        field_combo.LEDS.LED.next = next_c;
        field_combo.LEDS.LED.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.LEDS.LED.value <= 8'h0;
        end else if(field_combo.LEDS.LED.load_next) begin
            field_storage.LEDS.LED.value <= field_combo.LEDS.LED.next;
        end
    end
    assign hwif_out.LEDS.LED.value = field_storage.LEDS.LED.value;
    // Field: registers.INPUT_DATA.DataIN
    always_comb begin
        automatic logic [7:0] next_c = field_storage.INPUT_DATA.DataIN.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.DataIN.value & ~decoded_wr_biten[7:0]) | (decoded_wr_data[7:0] & decoded_wr_biten[7:0]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.DataIN.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.DataIN.next = next_c;
        field_combo.INPUT_DATA.DataIN.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.DataIN.value <= 8'h0;
        end else if(field_combo.INPUT_DATA.DataIN.load_next) begin
            field_storage.INPUT_DATA.DataIN.value <= field_combo.INPUT_DATA.DataIN.next;
        end
    end
    assign hwif_out.INPUT_DATA.DataIN.value = field_storage.INPUT_DATA.DataIN.value;
    // Field: registers.INPUT_DATA.BCH
    always_comb begin
        automatic logic [0:0] next_c = field_storage.INPUT_DATA.BCH.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.BCH.value & ~decoded_wr_biten[8:8]) | (decoded_wr_data[8:8] & decoded_wr_biten[8:8]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.BCH.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.BCH.next = next_c;
        field_combo.INPUT_DATA.BCH.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.BCH.value <= 1'h0;
        end else if(field_combo.INPUT_DATA.BCH.load_next) begin
            field_storage.INPUT_DATA.BCH.value <= field_combo.INPUT_DATA.BCH.next;
        end
    end
    assign hwif_out.INPUT_DATA.BCH.value = field_storage.INPUT_DATA.BCH.value;
    // Field: registers.INPUT_DATA.FS
    always_comb begin
        automatic logic [0:0] next_c = field_storage.INPUT_DATA.FS.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.FS.value & ~decoded_wr_biten[9:9]) | (decoded_wr_data[9:9] & decoded_wr_biten[9:9]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.FS.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.FS.next = next_c;
        field_combo.INPUT_DATA.FS.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.FS.value <= 1'h0;
        end else if(field_combo.INPUT_DATA.FS.load_next) begin
            field_storage.INPUT_DATA.FS.value <= field_combo.INPUT_DATA.FS.next;
        end
    end
    assign hwif_out.INPUT_DATA.FS.value = field_storage.INPUT_DATA.FS.value;
    // Field: registers.INPUT_DATA.Gauss
    always_comb begin
        automatic logic [0:0] next_c = field_storage.INPUT_DATA.Gauss.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.Gauss.value & ~decoded_wr_biten[10:10]) | (decoded_wr_data[10:10] & decoded_wr_biten[10:10]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.Gauss.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.Gauss.next = next_c;
        field_combo.INPUT_DATA.Gauss.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.Gauss.value <= 1'h0;
        end else if(field_combo.INPUT_DATA.Gauss.load_next) begin
            field_storage.INPUT_DATA.Gauss.value <= field_combo.INPUT_DATA.Gauss.next;
        end
    end
    assign hwif_out.INPUT_DATA.Gauss.value = field_storage.INPUT_DATA.Gauss.value;
    // Field: registers.INPUT_DATA.BER
    always_comb begin
        automatic logic [0:0] next_c = field_storage.INPUT_DATA.BER.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.BER.value & ~decoded_wr_biten[11:11]) | (decoded_wr_data[11:11] & decoded_wr_biten[11:11]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.BER.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.BER.next = next_c;
        field_combo.INPUT_DATA.BER.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.BER.value <= 1'h0;
        end else if(field_combo.INPUT_DATA.BER.load_next) begin
            field_storage.INPUT_DATA.BER.value <= field_combo.INPUT_DATA.BER.next;
        end
    end
    assign hwif_out.INPUT_DATA.BER.value = field_storage.INPUT_DATA.BER.value;
    // Field: registers.INPUT_DATA.density
    always_comb begin
        automatic logic [7:0] next_c = field_storage.INPUT_DATA.density.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.density.value & ~decoded_wr_biten[19:12]) | (decoded_wr_data[19:12] & decoded_wr_biten[19:12]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.density.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.density.next = next_c;
        field_combo.INPUT_DATA.density.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.density.value <= 8'h0;
        end else if(field_combo.INPUT_DATA.density.load_next) begin
            field_storage.INPUT_DATA.density.value <= field_combo.INPUT_DATA.density.next;
        end
    end
    assign hwif_out.INPUT_DATA.density.value = field_storage.INPUT_DATA.density.value;
    // Field: registers.INPUT_DATA.BERGen
    always_comb begin
        automatic logic [7:0] next_c = field_storage.INPUT_DATA.BERGen.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.BERGen.value & ~decoded_wr_biten[27:20]) | (decoded_wr_data[27:20] & decoded_wr_biten[27:20]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.BERGen.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.BERGen.next = next_c;
        field_combo.INPUT_DATA.BERGen.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.BERGen.value <= 8'h0;
        end else if(field_combo.INPUT_DATA.BERGen.load_next) begin
            field_storage.INPUT_DATA.BERGen.value <= field_combo.INPUT_DATA.BERGen.next;
        end
    end
    assign hwif_out.INPUT_DATA.BERGen.value = field_storage.INPUT_DATA.BERGen.value;
    // Field: registers.INPUT_DATA.DataINReady
    always_comb begin
        automatic logic [0:0] next_c = field_storage.INPUT_DATA.DataINReady.value;
        automatic logic load_next_c = '0;
        if(decoded_reg_strb.INPUT_DATA && decoded_req_is_wr) begin // SW write
            next_c = (field_storage.INPUT_DATA.DataINReady.value & ~decoded_wr_biten[28:28]) | (decoded_wr_data[28:28] & decoded_wr_biten[28:28]);
            load_next_c = '1;
        end else begin // HW Write
            next_c = hwif_in.INPUT_DATA.DataINReady.next;
            load_next_c = '1;
        end
        field_combo.INPUT_DATA.DataINReady.next = next_c;
        field_combo.INPUT_DATA.DataINReady.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.INPUT_DATA.DataINReady.value <= 1'h0;
        end else if(field_combo.INPUT_DATA.DataINReady.load_next) begin
            field_storage.INPUT_DATA.DataINReady.value <= field_combo.INPUT_DATA.DataINReady.next;
        end
    end
    assign hwif_out.INPUT_DATA.DataINReady.value = field_storage.INPUT_DATA.DataINReady.value;
    // Field: registers.OUTPUT_DATA.DataOUT
    always_comb begin
        automatic logic [7:0] next_c = field_storage.OUTPUT_DATA.DataOUT.value;
        automatic logic load_next_c = '0;
        
        // HW Write
        next_c = hwif_in.OUTPUT_DATA.DataOUT.next;
        load_next_c = '1;
        field_combo.OUTPUT_DATA.DataOUT.next = next_c;
        field_combo.OUTPUT_DATA.DataOUT.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.OUTPUT_DATA.DataOUT.value <= 8'h0;
        end else if(field_combo.OUTPUT_DATA.DataOUT.load_next) begin
            field_storage.OUTPUT_DATA.DataOUT.value <= field_combo.OUTPUT_DATA.DataOUT.next;
        end
    end
    assign hwif_out.OUTPUT_DATA.DataOUT.value = field_storage.OUTPUT_DATA.DataOUT.value;
    // Field: registers.OUTPUT_DATA.DataOutputReady
    always_comb begin
        automatic logic [0:0] next_c = field_storage.OUTPUT_DATA.DataOutputReady.value;
        automatic logic load_next_c = '0;
        
        // HW Write
        next_c = hwif_in.OUTPUT_DATA.DataOutputReady.next;
        load_next_c = '1;
        field_combo.OUTPUT_DATA.DataOutputReady.next = next_c;
        field_combo.OUTPUT_DATA.DataOutputReady.load_next = load_next_c;
    end
    always_ff @(posedge clk) begin
        if(rst) begin
            field_storage.OUTPUT_DATA.DataOutputReady.value <= 1'h0;
        end else if(field_combo.OUTPUT_DATA.DataOutputReady.load_next) begin
            field_storage.OUTPUT_DATA.DataOutputReady.value <= field_combo.OUTPUT_DATA.DataOutputReady.next;
        end
    end
    assign hwif_out.OUTPUT_DATA.DataOutputReady.value = field_storage.OUTPUT_DATA.DataOutputReady.value;

    //--------------------------------------------------------------------------
    // Write response
    //--------------------------------------------------------------------------
    assign cpuif_wr_ack = decoded_req & decoded_req_is_wr;
    // Writes are always granted with no error response
    assign cpuif_wr_err = '0;

    //--------------------------------------------------------------------------
    // Readback
    //--------------------------------------------------------------------------

    logic readback_err;
    logic readback_done;
    logic [31:0] readback_data;
    
    // Assign readback values to a flattened array
    logic [31:0] readback_array[5];
    assign readback_array[0][15:0] = (decoded_reg_strb.SYSTEM_ID && !decoded_req_is_wr) ? 'h1234 : '0;
    assign readback_array[0][31:16] = (decoded_reg_strb.SYSTEM_ID && !decoded_req_is_wr) ? 'habcd : '0;
    assign readback_array[1][7:0] = (decoded_reg_strb.LEDS && !decoded_req_is_wr) ? field_storage.LEDS.LED.value : '0;
    assign readback_array[1][31:8] = '0;
    assign readback_array[2][0:0] = (decoded_reg_strb.DEBUG && !decoded_req_is_wr) ? hwif_in.DEBUG.DEBUGTESTSYSTEM.next : '0;
    assign readback_array[2][31:1] = '0;
    assign readback_array[3][7:0] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.DataIN.value : '0;
    assign readback_array[3][8:8] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.BCH.value : '0;
    assign readback_array[3][9:9] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.FS.value : '0;
    assign readback_array[3][10:10] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.Gauss.value : '0;
    assign readback_array[3][11:11] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.BER.value : '0;
    assign readback_array[3][19:12] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.density.value : '0;
    assign readback_array[3][27:20] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.BERGen.value : '0;
    assign readback_array[3][28:28] = (decoded_reg_strb.INPUT_DATA && !decoded_req_is_wr) ? field_storage.INPUT_DATA.DataINReady.value : '0;
    assign readback_array[3][31:29] = '0;
    assign readback_array[4][7:0] = (decoded_reg_strb.OUTPUT_DATA && !decoded_req_is_wr) ? field_storage.OUTPUT_DATA.DataOUT.value : '0;
    assign readback_array[4][8:8] = (decoded_reg_strb.OUTPUT_DATA && !decoded_req_is_wr) ? field_storage.OUTPUT_DATA.DataOutputReady.value : '0;
    assign readback_array[4][31:9] = '0;

    // Reduce the array
    always_comb begin
        automatic logic [31:0] readback_data_var;
        readback_done = decoded_req & ~decoded_req_is_wr;
        readback_err = '0;
        readback_data_var = '0;
        for(int i=0; i<5; i++) readback_data_var |= readback_array[i];
        readback_data = readback_data_var;
    end

    assign cpuif_rd_ack = readback_done;
    assign cpuif_rd_data = readback_data;
    assign cpuif_rd_err = readback_err;
endmodule