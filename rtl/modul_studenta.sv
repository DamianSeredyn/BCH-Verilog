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

    input logic DebugTestSystem,
    input  logic [7:0] DataIN,
    output logic [7:0] DataOUT,
    input  logic BCH,
    input  logic Gauss,
    input  logic FS,
    input  logic BER,
    input  logic [7:0] density,
    input  logic [7:0] BERGen,
    input  logic DataSignalReady,

    output logic DataOutputReady
);

import registers_pkg::*;

localparam int MAX_WIDTH = 16; 

registers_pkg::registers__out_t hwif_out;
registers_pkg::registers__in_t hwif_in;

// Main signals
logic BCH_coding = 1'b0;
logic generateNoise = 1'b0;
logic randomGenerateErrors = 1'b0;
logic [7:0] numberOfGenerateErrors = 8'b0;
logic [7:0] densityPar = 8'b0;
logic transmition_Finished = 1'b0;
logic [7:0] signal_input_comboined; 

wire clk_state;

// BCH THINNNNNNNNNNGSSSSSSSSSSSSSSSSSSSSSSS! Encoder!
logic [4:0] signal_input1 = 5'b10011;
logic [4:0] signal_input2 = 5'b10011; //temp value for testing max 7 bits
// generator dla max 2 błędów 9'b111010001. Możemy przesłać max 7 bitów
// generator dla max 3 błędów 11'b10100110111 // Możemy przesłać maksymalnie 5 bitów
// dodać funkcję która po przesłaniu danych będzie zerować te wszystkie poniższe zmienne
logic [15:0] encoded_signal1;
logic [15:0] encoded_signal2;

logic startEncoding1;
logic startEncoding2;

logic EncoderReady1;
logic EncoderReady2;

// Decoding
logic [15:0] syndrome_coding; // test value but variable used to pass data. Keep the length!, If u want to test different value change in ...unit_test.sv
logic [15:0] decoded_syndrome [8:0]; // decoded syndromes for further calculations
logic [4:0] correcting_capability = 3;//Number of errors that decoding can correct. MAX = 4
logic [15:0] decoded_signal; // final decoded signal
logic [15:0] decoded_signal2;
logic [15:0] decoded_signal3; // final decoded signal
logic start_decoding = 1'b0;
logic finished_decoding;
logic [50:0] test_variable1 [3:0][3:0];
logic [15:0] test_variable2 [3:0];
logic [50:0] test_variable3;
logic [50:0] counter = 51'b0; //DELETE THIS, ONLY FOR TESTING
logic [5:0] decoding_counter = 2'b0;
logic test = 1'b0;


// flags ending
logic BCH_encoded_finished = 1'b0;
logic BCH_startNoise_finished = 1'b0;
logic BCH_startErrorGen_finished = 1'b0;
logic BCH_decoded_finished = 1'b0;

// GAUSSSS
  logic [7:0] noisedSignalWithoutBCH;
  logic [15:0] noisedSignalWithBCH1;
  logic [15:0] noisedSignalWithBCH2;
  wire [15:0] data_out;
  wire valid_ctg;
  wire [63:0]  rnd;
  wire valid_out;

  logic GaussReset = 1'b1;
  logic GaussInitSignal = 1'b0;
  
  // Random error generator
  localparam WIDTH = 13;
  logic [7:0] current_iteration;
  logic [15:0] encoded_signal_mask =16'b0;
  logic [7:0] signal_input_mask =8'b0;
  logic [3:0] rand_idx;
    logic [7:0] REG_noisedSignalWithoutBCH;
  logic [15:0] REG_noisedSignalWithBCH1;
  logic [15:0] REG_noisedSignalWithBCH2;
  assign rand_idx = rnd[3:0] ^ rnd[7:4];
  logic AssignBERData = 1'b0;

  // Handle data
  logic prevDataReady;
  logic prevDataOutputReady;

    // Generator liczb pseudolosowych (CTG)
gng_ctg #(
    .INIT_Z1(64'd5030521883283424767),
    .INIT_Z2(64'd18445829279364155008),
    .INIT_Z3(64'd18436106298727503359)
)prng (
        .clk(clk),
        .rstn(GaussReset),
        .ce(1'b1),
        .valid_out(valid_ctg),
        .data_out(rnd)
    );

    // Interpolator – przekształca losowe bity w rozkład normalny
    gng_interp interp (
        .clk(clk),
        .rstn(GaussReset),
        .valid_in(valid_ctg),
        .data_in(rnd),
        .valid_out(valid_out),
        .data_out(data_out)
    );

     // Clock divier - do Uarta

    clock_div #(
    .N(10)
    )cld_div (
        .clk_i(clk),
        .rst_i(rst),
        .clk_o(clk_state)
    );


    BCH_encoder enc1 (
        .clk(clk),
        .rst(rst),
         .startEncoding(startEncoding1),
        .signal_input(signal_input1),
        .encoded_signal(encoded_signal1),
        .EncoderReady(EncoderReady1)
    
    );

    BCH_encoder enc2 (
        .clk(clk),
        .rst(rst),
        .startEncoding(startEncoding2),
        .signal_input(signal_input2),
        .encoded_signal(encoded_signal2),
        .EncoderReady(EncoderReady2)
    );

    BCH_decoder dec (
        .clk(clk),
        .rst(rst),
        .syndrome_coding2(syndrome_coding),
        .decoded_syndrome2(decoded_syndrome),
        .BCH_decoded_finished2(BCH_decoded_finished),
        .state2(start_decoding),
        .correcting_capability2(correcting_capability),
        .decoded_signal2(decoded_signal3),
        .test1(test_variable1),
        .test2(test_variable2),
        .test3(test_variable3),
        .finished_decoding2(finished_decoding)
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
            prevDataReady <= 1'b0;
            BCH_coding <= 1'b0;
            generateNoise <= 1'b0;
            randomGenerateErrors <= 1'b0;
            numberOfGenerateErrors <= 8'b0;  
            densityPar <= 8'b0;
            transmition_Finished <= 1'b0;
            signal_input1 <= 5'b0;
            signal_input2 <= 5'b0;
            signal_input_comboined <= 8'b0;
	    end 
        else 
        begin
            if(DataOutputReady == 1'b1 && prevDataOutputReady == 1'b0) begin
                transmition_Finished <= 1'b0;
            end
            if(hwif_out.INPUT_DATA.DataINReady.value == 1'b1 &&  prevDataReady == 1'b0) begin
                BCH_coding <= hwif_out.INPUT_DATA.BCH.value;
                generateNoise <= hwif_out.INPUT_DATA.Gauss.value;
                randomGenerateErrors <= hwif_out.INPUT_DATA.BER.value;
                numberOfGenerateErrors <= hwif_out.INPUT_DATA.BERGen.value;      
                densityPar <= hwif_out.INPUT_DATA.density.value;
                transmition_Finished <= 1'b1;
                signal_input1 <= hwif_out.INPUT_DATA.DataIN.value[7:4];
                signal_input2 <= hwif_out.INPUT_DATA.DataIN.value[3:0];
                signal_input_comboined <= hwif_out.INPUT_DATA.DataIN.value;      
            end
            prevDataReady <= hwif_out.INPUT_DATA.DataINReady.value;
            prevDataOutputReady <= DataOutputReady;
        end
end 

     
//TESTING PROCESS!

/*
always_ff @(posedge clk or posedge rst)
begin
	if (rst == 1'b1) 
        begin
            prevDataReady <= 1'b0;
            BCH_coding <= 1'b0;
            generateNoise <= 1'b0;
            randomGenerateErrors <= 1'b0;
            numberOfGenerateErrors <= 8'b0;  
            densityPar <= 8'b0;
            transmition_Finished <= 1'b0;
            signal_input1 <= 5'b0;
            signal_input2 <= 5'b0;
            signal_input_comboined <= 8'b0;
	    end 
        else 
        begin
            if(DataOutputReady == 1'b1) begin
                transmition_Finished <= 1'b0;
            end
            if(DataSignalReady == 1'b1 &&  prevDataReady == 1'b0) begin
                BCH_coding <= BCH;
                generateNoise <= Gauss;
                randomGenerateErrors <= BER;
                numberOfGenerateErrors <= BERGen;  
                densityPar <= density;
                transmition_Finished <= 1'b1;
                signal_input1 <= DataIN[7:4];
                signal_input2 <= DataIN[3:0];
                signal_input_comboined <= DataIN;

            prevDataReady <= DataSignalReady;
        end
    end
end
*/


always_ff @(posedge clk_state or posedge rst)
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
                LED <= 8'b0000_0001;
            end
            else if(generateNoise == 1'b1 && BCH_startNoise_finished == 1'b0 )
            begin
                state <= GENERATE_NOISE;
                LED <= 8'b0000_0011;
            end
            else if(randomGenerateErrors == 1'b1 && BCH_startErrorGen_finished == 1'b0 )
            begin
                state <= GENERATE_ERRORS;
                LED <= 8'b0000_0111;
            end

            else if(BCH_coding == 1'b1 && BCH_decoded_finished == 1'b0)
            begin
                state <= DECODING_BCH;
                LED <= 8'b0000_1111;
            end
            else  //if(test == 1'b1  )
            begin
                state <= FINISHED;
                LED <= 8'b0001_1111;
            end                
	    end
        else
        begin
            state <= IDLE;
            LED <= 8'b1111_1111;
        end
	end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_encoded_finished <= 1'b0;
        end
     else if(DataOutputReady == 1'b1) begin
            BCH_encoded_finished <= 1'b0;
            
    end          
    else
        begin
        if (state == ENCODING_BCH && BCH_encoded_finished == 1'b0)
            begin
                startEncoding1 <= 1'b1;
                startEncoding2 <= 1'b1;
                
                if(EncoderReady1 == 1'b1 &&  EncoderReady2 == 1'b1) begin
                    BCH_encoded_finished <= 1'b1;
                    startEncoding1 <= 1'b0;
                    startEncoding2 <= 1'b0;                    
                end
            end
        end

end

always_ff @(posedge clk_state or posedge rst)
begin
    if (rst) begin
        GaussInitSignal <= 1'b0;
    end
    else begin
        if (GaussInitSignal == 1'b0) begin
            GaussReset <= 1'b0;               // aktywny reset (jeśli Reset aktywny w stanie niskim)
            GaussInitSignal <= 1'b1;     // zapamiętaj, że już resetowano
        end 
        else begin
            GaussReset <= 1'b1;               // już nie resetuj
        end
    end
end


always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            BCH_startNoise_finished <= 1'b0;
        end
     else if(DataOutputReady == 1'b1) begin
            BCH_startNoise_finished <= 1'b0;
    end   
    else
        begin
            if(state == GENERATE_NOISE && BCH_startNoise_finished == 1'b0)
            begin
                if (valid_out) begin
                    if(BCH_coding == 1'b1) begin
                        noisedSignalWithBCH1 <= encoded_signal1 ^ (data_out & {densityPar, densityPar}); 
                        noisedSignalWithBCH2 <= encoded_signal2 ^ (data_out & {densityPar, densityPar}); 
                    end
                    else begin
                        noisedSignalWithoutBCH <= signal_input_comboined ^ (data_out & {densityPar, densityPar}); 
                    end
                    BCH_startNoise_finished <= 1'b1; 
                end
                else begin
                    BCH_startNoise_finished <= 1'b0; 
                end
            end
        end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst == 1'b1) begin
        BCH_startErrorGen_finished <= 0;
        current_iteration <= 0;
        encoded_signal_mask <= 0;
        signal_input_mask <= 0;
        REG_noisedSignalWithBCH1 <= 0;
        REG_noisedSignalWithBCH2 <= 0;
        REG_noisedSignalWithoutBCH <= 0;
        AssignBERData <= 0;
    end 
    else if (DataOutputReady == 1'b1) begin
        BCH_startErrorGen_finished <= 0;
        current_iteration <= 0;

        encoded_signal_mask <= 0;
        signal_input_mask <= 0;

        AssignBERData <= 1'b0;
    end 
    else begin
        if (state == GENERATE_ERRORS && BCH_startErrorGen_finished == 1'b0) begin

            if (AssignBERData == 1'b0) begin
                if (BCH_coding == 1'b1) begin
                    REG_noisedSignalWithBCH1 <= encoded_signal1; 
                    REG_noisedSignalWithBCH2 <= encoded_signal2;              
                end else begin
                    REG_noisedSignalWithoutBCH <= signal_input_comboined;
                end
                AssignBERData <= 1'b1;
            end
            if(current_iteration >= numberOfGenerateErrors || numberOfGenerateErrors == 0) begin
                BCH_startErrorGen_finished <= 1'b1;
            end
            else begin
            if (BCH_coding) begin
                if (rand_idx > 7) begin
                    if(encoded_signal_mask[rand_idx[3:0]] == 1'b0) begin
                        REG_noisedSignalWithBCH1[rand_idx[3:0]]<= ~REG_noisedSignalWithBCH1[rand_idx[3:0]];
                        encoded_signal_mask[rand_idx[3:0]] <= 1'b1;
                        current_iteration <= current_iteration+1;
                    end                   
                end else begin
                    if(encoded_signal_mask[rand_idx[3:0]] == 1'b0) begin
                        REG_noisedSignalWithBCH2[rand_idx[3:0]]<= ~REG_noisedSignalWithBCH2[rand_idx[3:0]];
                        encoded_signal_mask[rand_idx[3:0]] <= 1'b1;
                        current_iteration <= current_iteration+1;
                    end                      
                end
            end else begin
               
                if(signal_input_mask[rand_idx[2:0]] == 1'b0) begin
                    REG_noisedSignalWithoutBCH[rand_idx[2:0]]<= ~REG_noisedSignalWithoutBCH[rand_idx[2:0]];
                    signal_input_mask[rand_idx[2:0]] <= 1'b1;
                    current_iteration <= current_iteration+1;
                end
            end
        end
        end
    end
end
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
            // BCH_decoded_finished <= 1'b0;
            // correcting_capability <= 3;
            // decoded_signal <= 105'b0;
        end
    else if(DataOutputReady == 1'b1) begin
        BCH_decoded_finished <= 1'b0;
    end
    else
        begin
            if(state == DECODING_BCH && BCH_decoded_finished == 1'b0)
            begin
                counter <= counter + 1;
                if (decoding_counter == 0) begin
                   start_decoding <= 1'b1;
                   syndrome_coding <= 16'b101110000111111; // tu podstawic wynik szumow //test value: 16'b101110000111111
                end

                if (decoding_counter == 0 && counter == 80000) begin
                    decoded_signal <= syndrome_coding;
                    decoding_counter <= decoding_counter + 1;
                    start_decoding <= 1'b0;
                end else if (decoding_counter == 2 && counter == 160000) begin
                    decoded_signal2 <= syndrome_coding;
                    //test <= 1'b1;
                    BCH_decoded_finished <= 1'b1;
                    start_decoding <= 1'b0;
                    decoding_counter <= 6'b0;
                    counter <= 51'b0;
                end

                if (finished_decoding == 1'b1 && decoding_counter == 0) begin
                    decoded_signal <= decoded_signal3;
                    decoding_counter <= decoding_counter + 1;
                    start_decoding <= 1'b0;
                end else if (finished_decoding == 1'b0 && decoding_counter == 1) begin
                    syndrome_coding <= 16'b100100011111110; // tu podstawic wynik szumow // test value: 16'b100100011111110
                    start_decoding <= 1'b1;
                    decoding_counter <= decoding_counter + 1;
                end else if (finished_decoding == 1'b1 && decoding_counter == 2) begin
                    decoded_signal2 <= decoded_signal3;
                    //test <= 1'b1;
                    BCH_decoded_finished <= 1'b1;
                    start_decoding <= 1'b0;
                    decoding_counter <= 6'b0;
                    counter <= 51'b0;
                end

            end 
        end
end


always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
        begin
             DataOutputReady <= 1'b0;
        end
    else
        begin
            if(transmition_Finished == 1'b1) begin
                DataOutputReady <= 1'b0;
            end
            if(state == FINISHED && DataOutputReady == 1'b0)
            begin
                if(generateNoise == 1'b1 || randomGenerateErrors == 1'b1) begin
                    if(BCH_coding == 1'b1) begin
                        DataOUT <= decoded_signal[7:0];
                    end
                    else begin
                        if(randomGenerateErrors == 1'b1) begin
                            DataOUT <= REG_noisedSignalWithoutBCH;
                        end
                        else begin
                           DataOUT <= noisedSignalWithoutBCH;     
                        end
                    end
                end
                else begin
                     if(BCH_coding == 1'b1) begin
                        DataOUT <= decoded_signal[7:0];
                    end
                    else begin
                        DataOUT <= signal_input_comboined;
                    end               
                end
                DataOutputReady <= 1'b1;
            end
        end
end
assign hwif_in.OUTPUT_DATA.DataOUT.next = DataOUT;
assign hwif_in.OUTPUT_DATA.DataOutputReady.next = DataOutputReady;






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

    .hwif_out           (hwif_out),
    .hwif_in           (hwif_in)
);

endmodule