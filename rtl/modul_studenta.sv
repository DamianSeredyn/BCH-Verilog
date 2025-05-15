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

    output logic [7:0]  LED,
    input  logic        DebugTestSystem
);

import registers_pkg::*;

registers_pkg::registers__out_t hwif_out;

// Main signals
logic BCH_coding = 1'b0;
logic generateNoise = 1'b0;
logic randomGenerateErrors = 1'b0;
logic [7:0] numberOfGenerateErrors = 8'b0;
logic [7:0] signal_input = 8'b1010_1010; //temp value for testing
logic [5:0] generator_signal = 6'b100101; //generator for encoding bch
logic [13:0] encoded_signal =14'b0;

// transmition signals
logic transmition_Finished = 1'b0;


// flags ending
logic BCH_encoded_finished = 1'b0;
logic BCH_startNoise_finished = 1'b0;
logic BCH_startErrorGen_finished = 1'b0;
logic BCH_decoded_finished = 1'b0;


typedef enum logic[2:0]{
	IDLE = 3'h0,
	ENCODING_BCH = 3'h1,
	GENERATE_NOISE = 3'h2,
	GENERATE_ERRORS = 3'h3,
	DECODING_BCH = 3'h4,
    FINISHED = 3'h5 
} appState;

appState state;


always_ff @(posedge clk or posedge rst)
begin
    	if (rst == 1'b1) 
        begin
                BCH_coding <= 1'b0;
                generateNoise <= 1'b0;
                transmition_Finished <= 1'b0;
                BCH_startErrorGen_finished <= 1'b0;
                BCH_decoded_finished <= 1'b0;
	    end 
        else
        begin
            if (DebugTestSystem == 1'b1)
            begin
                BCH_coding <= 1'b1;
                generateNoise <= 1'b1;

                transmition_Finished <= 1'b1;
            end 
        end

end

always_ff @(posedge clk or posedge rst)
begin
	if (rst == 1'b1) 
    begin
        state <= IDLE;
	end 
    else begin
		if (transmition_Finished == 1'b1) 
        begin
            if(BCH_coding == 1'b1 && BCH_encoded_finished == 1'b0)
            begin
                state <= ENCODING_BCH;
            end
            else if(generateNoise == 1'b1 && BCH_startNoise_finished == 1'b0 && (BCH_encoded_finished == 1'b1 || BCH_coding == 1'b0) )
            begin
                state <= GENERATE_NOISE;
            end
            else if(randomGenerateErrors == 1'b1 && BCH_startErrorGen_finished == 1'b0 )
            begin
                state <= GENERATE_ERRORS;
            end
            else if(BCH_coding == 1'b1 && BCH_decoded_finished == 1'b0)
            begin
                state <= DECODING_BCH;
            end
            else
            begin
                state <= FINISHED;
            end                
	    end
        else
        begin
            state <= IDLE;
        end
	end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_encoded_finished <= 1'b0;
        end
    else
        begin
        if (state == ENCODING_BCH && BCH_encoded_finished == 1'b0)
            begin
                encoded_signal <= encode_bch(signal_input, generator_signal);
                BCH_encoded_finished <= 1'b1;
            end
        end

end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_startNoise_finished <= 1'b0;
        end
    else
        begin
            if(state == GENERATE_NOISE && BCH_startNoise_finished == 1'b0)
            begin
                BCH_startNoise_finished <= 1'b1;

            end
        end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_startErrorGen_finished <= 1'b0;
        end
    else
        begin
            if(state == GENERATE_ERRORS && BCH_startErrorGen_finished == 1'b0)
            begin
                BCH_startErrorGen_finished <= 1'b1;

            end
        end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
             BCH_decoded_finished <= 1'b0;
        end
    else
        begin
            if(state == DECODING_BCH && BCH_decoded_finished == 1'b0)
            begin
                BCH_decoded_finished <= 1'b1;

            end
        end
end


function [13:0] encode_bch;
    input [7:0] px;
    input [5:0] gx;
    begin
        encode_bch = px * gx;
    end
endfunction



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