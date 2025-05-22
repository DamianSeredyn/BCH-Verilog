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
    input  logic        DebugTestSystem,

    input  wire  UART_RX,
    output logic UART_TX

);

import registers_pkg::*;

registers_pkg::registers__out_t hwif_out;

// Main signals
logic BCH_coding = 1'b0;
logic generateNoise = 1'b0;
logic randomGenerateErrors = 1'b0;
logic [7:0] numberOfGenerateErrors = 8'b0;
logic transmition_Finished = 1'b0;


// BCH THINNNNNNNNNNGSSSSSSSSSSSSSSSSSSSSSSS!
logic [7:0] signal_input = 8'b1010_1010; //temp value for testing
logic [5:0] generator_signal = 6'b100101; //generator for encoding bch
logic [13:0] encoded_signal =14'b0;
logic [104:0] syndrome_coding = 104'b1110101101011; // test value but variable used to pass data. Keep the length!
logic [20:0] decoded_syndrome [8:0]; // decoded syndromes for further calculations
logic [4:0] correcting_capability = 2; //Number of errors that decoding can correct. MAX = 4
// transmition signals



// flags ending
logic BCH_encoded_finished = 1'b0;
logic BCH_startNoise_finished = 1'b0;
logic BCH_startErrorGen_finished = 1'b0;
logic BCH_decoded_finished = 1'b0;

// GAUSSSS
  wire [15:0] data_out;
  wire valid_ctg;
  wire [63:0]  rnd;
  wire vld;
  wire valid_out;
  logic ena;
  
  // Random error generator
  localparam WIDTH = 13;
  logic [7:0] current_iteration;
  logic [13:0] encoded_signal_mask =14'b0;
  logic [3:0] rand_idx;
  assign rand_idx = rnd[3:0];

  // UART
    logic clk_u;
    logic[7:0] RX_buff = 8'b0;
    logic[7:0] TX_buff = 8'b0;

    // Generator liczb pseudolosowych (CTG)
gng_ctg #(
    .INIT_Z1(64'hA1B2C3D4E5F60789),
    .INIT_Z2(64'h1234DEADBEEF5678),
    .INIT_Z3(64'h9ABCDEF012345678)
)prng (
        .clk(clk),
        .rstn(~rst),
        .ce(ena),
        .valid_out(valid_ctg),
        .data_out(rnd)
    );

    // Interpolator – przekształca losowe bity w rozkład normalny
    gng_interp interp (
        .clk(clk),
        .rstn(~rst),
        .valid_in(valid_ctg),
        .data_in(rnd),
        .valid_out(valid_out),
        .data_out(data_out)
    );

     // Clock divier - do Uarta

    clock_div #(
    .N(5208)
    )cld_div (
        .clk_i(clk),
        .rst_i(rst),
        .clk_o(clk_u)
    );


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
                
                generateNoise <= 1'b0;
                randomGenerateErrors <= 1'b1;

                transmition_Finished <= 1'b1;

                if(generateNoise == 1'b1 ||randomGenerateErrors == 1'b1 )
                    begin
                        ena <= 1'b1;    
                    end
                else
                    begin
                        ena <= 1'b0;    
                    end
                if(randomGenerateErrors == 1'b1)
                    begin
                        numberOfGenerateErrors <= 3;    
                    end
                else
                    begin
                        numberOfGenerateErrors <= 0;    
                    end
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
                if (valid_out) begin
                    encoded_signal <= encoded_signal + data_out; 
                    BCH_startNoise_finished <= 1'b1; 
                end
                else begin
                    BCH_startNoise_finished <= 1'b0; 
                end
            end
        end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_startErrorGen_finished <= 1'b0;
            current_iteration <= 0;
            encoded_signal_mask <= 0;
        end
    else
        begin
            if(state == GENERATE_ERRORS && BCH_startErrorGen_finished == 1'b0)
            begin

                if (rand_idx < WIDTH && encoded_signal_mask[rand_idx] == 0) begin
                    encoded_signal[rand_idx] <= ~encoded_signal[rand_idx];
                    encoded_signal_mask[rand_idx] <= 1;
                    current_iteration <= current_iteration + 1;

                    if (current_iteration == numberOfGenerateErrors-1)
                        BCH_startErrorGen_finished <= 1;
                    end
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
                decode_syndromes(correcting_capability*2,syndrome_coding); // syndrome numbering starts from 1;
                BCH_decoded_finished <= 1'b1;

            end
        end
end

task decode_syndromes;
    input [3:0] syndrome_number; // Input number of syndromes to do(2*max number of errors)
    input [104:0] data;
    logic [3:0] loop;
    logic [104:0] input_data;
    begin
        input_data = 104'b0;
        for ( loop = 1; loop <= syndrome_number; loop++)
        begin
            for (integer i = 0; i < 104; i++)
            begin
                if (data[i])
                input_data[i*loop] = 1'b1;
            end
            syndromes(input_data, decoded_syndrome[loop-1]);
            input_data = 104'b0;
        end
    end
endtask

task syndromes;
    logic [9:0] i;
    logic [4:0] j;
    logic [104:0] data;
    logic [15:0] data_2;
    input [104:0] data_i;
    output[104:0] data_oo;
    begin
        data = data_i;
        data_2 = 104'b0;
        for (j = 0; j < 8; j++)
        begin
            for (i = 16; i < 104; i++)
            begin
                if (data[i])
                begin
                    data[i] = 1'b0;
                    data[i % 15] = 1'b1 ^ data[i % 15];
                end
            end
        end
        if (data[0])
            data_2 = data_2 ^ 104'b01;
        if (data[1])
            data_2 = data_2 ^ 104'b10;
        if (data[2])
            data_2 = data_2 ^ 104'b100;
        if (data[3])
            data_2 = data_2 ^ 104'b1000;
        if (data[4])
            data_2 = data_2 ^ 104'b11;
        if(data[5])
            data_2 = data_2 ^ 104'b110;
        if(data[6])
            data_2 = data_2 ^ 104'b1100;
        if(data[7])
            data_2 = data_2 ^ 104'b1011; 
        if(data[8])
            data_2 = data_2 ^ 104'b101;
        if(data[9])
            data_2 = data_2 ^ 104'b1010;
        if(data[10])
            data_2 = data_2 ^ 104'b111;
        if(data[11])
            data_2 = data_2 ^ 104'b1110;
        if(data[12])
            data_2 = data_2 ^ 104'b1111;
        if(data[13])
            data_2 = data_2 ^ 104'b1101;
        if(data[14])
            data_2 = data_2 ^ 104'b1001;
        if(data[15])
            data_2 = data_2 ^ 104'b01;
        case (data_2)
            15'b0011:  data_2 = 15'b10000;
            15'b0110:  data_2 = 15'b100000;
            15'b1100:  data_2 = 15'b1000000;
            15'b1011:  data_2 = 15'b10000000;
            15'b0101:  data_2 = 15'b100000000;
            15'b1010:  data_2 = 15'b1000000000;
            15'b0111:  data_2 = 15'b10000000000;
            15'b1110:  data_2 = 15'b100000000000;
            15'b1111:  data_2 = 15'b1000000000000;
            15'b1101:  data_2 = 15'b10000000000000;
            15'b1001:  data_2 = 15'b100000000000000;
            default: data_2 = data_2;
        endcase
        data_oo = data_2;
    end
endtask

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