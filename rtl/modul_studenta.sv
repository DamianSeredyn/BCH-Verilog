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
logic [104:0] syndrome_coding = 104'b1110101101011; // test value but variable used to pass data. Keep the length!
logic [104:0] decoded_syndrome [8:0]; // decoded syndromes for further calculations
logic [4:0] correcting_capability = 2;//Number of errors that decoding can correct. MAX = 4
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
                decode_syndromes(correcting_capability*2,syndrome_coding); // syndrome numbering starts from 1;
                matrix(decoded_syndrome, correcting_capability);
                BCH_decoded_finished <= 1'b1;

            end
        end
end

//zmienne do testów, później pewnie będzie można usunąć
logic [104:0] test_variable1 [3:0][3:0];
logic [104:0] test_variable2 [3:0];
logic [104:0] test_variable3;

task matrix;
logic [104:0] decoded_syndrome2 [8:0];
logic [104:0] first_matrix [3:0][3:0];// macierz z lewej strony równania
logic [104:0] second_matrix [3:0];// macierz z prawej strony równania
logic [104:0] second_matrix_sum [3:0];
logic [104:0] first_matrix_sum;
logic [104:0] first_matrix_trans [3:0][3:0];
logic [104:0] where_errors [3:0];// pokazuje na których miejscach są błędy
logic [4:0] i;
logic [4:0] j;
input [104:0] decoded_syndrome [8:0];
input [4:0] size;
begin
    decoded_syndrome2 = decoded_syndrome;
    first_matrix_sum = 105'b0;
    second_matrix_sum[0] = 105'b0;
    second_matrix_sum[1] = 105'b0;
    second_matrix_sum[2] = 105'b0;
    second_matrix_sum[3] = 105'b0;

    //create matrix
    for (i = 0; i < size ; i++ ) begin
        for (j = 0; j < size ; j++ ) begin
           first_matrix[i][j] = decoded_syndrome2[j+i]; 
        end
        second_matrix[i] = decoded_syndrome2[size+i];
    end

    first_matrix_determinant(first_matrix,size,first_matrix_sum); // determinant calculation
    syndromes(first_matrix_sum,first_matrix_sum); // syndrome from determinant
    //powyżej tego momentu wszystko na pewno działa a poniżej działa dla 2 błędów a nie działa dla 3 i 4 chyba
    minor(first_matrix,size,first_matrix); // z tym chyba jest problem

    for (i = 0; i < size ; i++ ) begin
        for (j = 0; j < size ; j++ ) begin
            first_matrix[i][j] = first_matrix[i][j] * (16'b1000000000000000/first_matrix_sum);
            second_matrix_sum[i] = second_matrix_sum[i] + second_matrix[j]*first_matrix[i][j];
        end
        syndromes(second_matrix_sum[i],second_matrix_sum[i]);
    end

    error_place(second_matrix_sum,size,where_errors);

    test_variable1 = first_matrix;
    test_variable2 = where_errors;
    test_variable3 = first_matrix_sum;
end
endtask

task error_place;// działa tylko dla macierzy 2x2, na pewno wynik zgadza się z tym  co jest w filmiku na yt
input [104:0] second_matrix_sum [3:0];
input [4:0] size;
output [104:0] where_errors [3:0];
logic [104:0] second_matrix_sum2 [3:0];
logic [104:0] possible_values [15:0];
logic [104:0] value_holder;
logic [5:0] i;
logic [5:0] j;
i = 0;
begin
    second_matrix_sum2 = second_matrix_sum;
    for (i = 6'b0; i < 16; i++)
    begin
        if (i == 0) possible_values[i] = 16'b10;
        else
        possible_values[i] = 16'b10 << i;
    end
    for (j = 0; j < 16; j++)
    begin
        for (i = 0; i < 16; i++)
        begin
            if ((possible_values[i] * possible_values[j]) == second_matrix_sum2[0]) begin
                syndromes((possible_values[i] ^ possible_values[j]),value_holder);
                if (value_holder == second_matrix_sum2[1]) begin
                    where_errors[0] = possible_values[i];
                    where_errors[1] = possible_values[j];
                    break;
                end
            end
        end
    end
end
endtask

task minor; // Nie pamiętam jak to się nazywa ale chodzi o to, jak chcemy wiedzieć co jest w danym miejscu w macierzy...
// to wykreślamy wiersz i kolumnę w której znajduje się nasza zmienna i liczymy resztę metodą sarrusa.
// Ta funckja sarrus co napisałem to w sumie podziała tylko do liczenia macierzy 3x3 i determinanty 4x4, do tego raczej coś nowego by trzeba było napisać
// Albo może o coś innego chodzi? idk nie mam siły, chodzi o adj(M), które widać w 9:23 w filmiki przypietym na dc
input [104:0] first_matrix [3:0][3:0];
input [4:0] size;
output [104:0] first_matrix_out [3:0][3:0];
logic [104:0] first_matrix2[3:0][3:0];
logic [4:0] i;
logic [4:0] j;
i = 5'b0;
j = 5'b0;
begin
    for (i = 0; i < size ; i++ ) begin
        for (j = 0; j < size ; j++ ) begin
            first_matrix2[i][j] = 105'b0;
        end
    end

    if (size == 2) begin
        first_matrix2[0][0] = first_matrix[1][1];
        first_matrix2[1][1] = first_matrix[0][0];
        first_matrix2[0][1] = first_matrix[1][0];
        first_matrix2[1][0] = first_matrix[0][1]; 
    // dla 3 i 4 nie mialem sily i to zbruteforcowałem i może nie działać
    end else if (size == 3) begin
        for (i = 0; i < size ; i++ ) begin
            for (j = 0; j < size ; j++ ) begin
                first_matrix2[0][0] = first_matrix[1][1] * first_matrix[2][2] ^ first_matrix[1][2] * first_matrix[2][1];
                first_matrix2[1][0] = first_matrix[0][1] * first_matrix[2][2] ^ first_matrix[0][2] * first_matrix[2][1];
                first_matrix2[2][0] = first_matrix[0][1] * first_matrix[1][2] ^ first_matrix[0][2] * first_matrix[1][1];

                first_matrix2[0][1] = first_matrix[1][0] * first_matrix[2][2] ^ first_matrix[1][2] * first_matrix[2][0];
                first_matrix2[1][1] = first_matrix[0][0] * first_matrix[2][2] ^ first_matrix[0][2] * first_matrix[2][0];
                first_matrix2[2][1] = first_matrix[0][0] * first_matrix[1][2] ^ first_matrix[0][2] * first_matrix[1][0];

                first_matrix2[0][2] = first_matrix[1][0] * first_matrix[2][1] ^ first_matrix[1][1] * first_matrix[2][0];
                first_matrix2[1][2] = first_matrix[0][0] * first_matrix[2][1] ^ first_matrix[0][1] * first_matrix[2][0];
                first_matrix2[2][2] = first_matrix[0][0] * first_matrix[1][1] ^ first_matrix[0][1] * first_matrix[1][0];
            end
        end
    end else if (size == 4) begin
        first_matrix2[0][0] = (first_matrix[1][1] * first_matrix[2][2] * first_matrix[3][3]) ^(first_matrix[1][2] * first_matrix[2][3] * first_matrix[3][1]) ^(first_matrix[1][3] * first_matrix[2][1] * first_matrix[3][2]) ^(first_matrix[1][3] * first_matrix[2][2] * first_matrix[3][1]) ^(first_matrix[1][2] * first_matrix[2][1] * first_matrix[3][3]) ^(first_matrix[1][1] * first_matrix[2][3] * first_matrix[3][2]);
        first_matrix2[0][1] = (first_matrix[1][0] * first_matrix[2][2] * first_matrix[3][3]) ^(first_matrix[1][2] * first_matrix[2][3] * first_matrix[3][0]) ^(first_matrix[1][3] * first_matrix[2][0] * first_matrix[3][2]) ^(first_matrix[1][3] * first_matrix[2][2] * first_matrix[3][0]) ^(first_matrix[1][2] * first_matrix[2][0] * first_matrix[3][3]) ^(first_matrix[1][0] * first_matrix[2][3] * first_matrix[3][2]);
        first_matrix2[0][2] = (first_matrix[1][0] * first_matrix[2][1] * first_matrix[3][3]) ^(first_matrix[1][1] * first_matrix[2][3] * first_matrix[3][0]) ^(first_matrix[1][3] * first_matrix[2][0] * first_matrix[3][1]) ^(first_matrix[1][3] * first_matrix[2][1] * first_matrix[3][0]) ^(first_matrix[1][1] * first_matrix[2][0] * first_matrix[3][3]) ^(first_matrix[1][0] * first_matrix[2][3] * first_matrix[3][1]);
        first_matrix2[0][3] = (first_matrix[1][0] * first_matrix[2][1] * first_matrix[3][2]) ^(first_matrix[1][1] * first_matrix[2][2] * first_matrix[3][0]) ^(first_matrix[1][2] * first_matrix[2][0] * first_matrix[3][1]) ^(first_matrix[1][2] * first_matrix[2][1] * first_matrix[3][0]) ^(first_matrix[1][1] * first_matrix[2][0] * first_matrix[3][2]) ^(first_matrix[1][0] * first_matrix[2][2] * first_matrix[3][1]);
        first_matrix2[1][0] = (first_matrix[0][1] * first_matrix[2][2] * first_matrix[3][3]) ^(first_matrix[0][2] * first_matrix[2][3] * first_matrix[3][1]) ^(first_matrix[0][3] * first_matrix[2][1] * first_matrix[3][2]) ^(first_matrix[0][3] * first_matrix[2][2] * first_matrix[3][1]) ^(first_matrix[0][2] * first_matrix[2][1] * first_matrix[3][3]) ^(first_matrix[0][1] * first_matrix[2][3] * first_matrix[3][2]);
        first_matrix2[1][1] = (first_matrix[0][0] * first_matrix[2][2] * first_matrix[3][3]) ^(first_matrix[0][2] * first_matrix[2][3] * first_matrix[3][0]) ^(first_matrix[0][3] * first_matrix[2][0] * first_matrix[3][2]) ^(first_matrix[0][3] * first_matrix[2][2] * first_matrix[3][0]) ^(first_matrix[0][2] * first_matrix[2][0] * first_matrix[3][3]) ^(first_matrix[0][0] * first_matrix[2][3] * first_matrix[3][2]);
        first_matrix2[1][2] = (first_matrix[0][0] * first_matrix[2][1] * first_matrix[3][3]) ^(first_matrix[0][1] * first_matrix[2][3] * first_matrix[3][0]) ^(first_matrix[0][3] * first_matrix[2][0] * first_matrix[3][1]) ^(first_matrix[0][3] * first_matrix[2][1] * first_matrix[3][0]) ^(first_matrix[0][1] * first_matrix[2][0] * first_matrix[3][3]) ^(first_matrix[0][0] * first_matrix[2][3] * first_matrix[3][1]);
        first_matrix2[1][3] = (first_matrix[0][0] * first_matrix[2][1] * first_matrix[3][2]) ^(first_matrix[0][1] * first_matrix[2][2] * first_matrix[3][0]) ^(first_matrix[0][2] * first_matrix[2][0] * first_matrix[3][1]) ^(first_matrix[0][2] * first_matrix[2][1] * first_matrix[3][0]) ^(first_matrix[0][1] * first_matrix[2][0] * first_matrix[3][2]) ^(first_matrix[0][0] * first_matrix[2][2] * first_matrix[3][1]);
        first_matrix2[2][0] = (first_matrix[0][1] * first_matrix[1][2] * first_matrix[3][3]) ^(first_matrix[0][2] * first_matrix[1][3] * first_matrix[3][1]) ^(first_matrix[0][3] * first_matrix[1][1] * first_matrix[3][2]) ^(first_matrix[0][3] * first_matrix[1][2] * first_matrix[3][1]) ^(first_matrix[0][2] * first_matrix[1][1] * first_matrix[3][3]) ^(first_matrix[0][1] * first_matrix[1][3] * first_matrix[3][2]);
        first_matrix2[2][1] = (first_matrix[0][0] * first_matrix[1][2] * first_matrix[3][3]) ^(first_matrix[0][2] * first_matrix[1][3] * first_matrix[3][0]) ^(first_matrix[0][3] * first_matrix[1][0] * first_matrix[3][2]) ^(first_matrix[0][3] * first_matrix[1][2] * first_matrix[3][0]) ^(first_matrix[0][2] * first_matrix[1][0] * first_matrix[3][3]) ^(first_matrix[0][0] * first_matrix[1][3] * first_matrix[3][2]);
        first_matrix2[2][2] = (first_matrix[0][0] * first_matrix[1][1] * first_matrix[3][3]) ^(first_matrix[0][1] * first_matrix[1][3] * first_matrix[3][0]) ^(first_matrix[0][3] * first_matrix[1][0] * first_matrix[3][1]) ^(first_matrix[0][3] * first_matrix[1][1] * first_matrix[3][0]) ^(first_matrix[0][1] * first_matrix[1][0] * first_matrix[3][3]) ^(first_matrix[0][0] * first_matrix[1][3] * first_matrix[3][1]);
        first_matrix2[2][3] = (first_matrix[0][0] * first_matrix[1][1] * first_matrix[3][2]) ^(first_matrix[0][1] * first_matrix[1][2] * first_matrix[3][0]) ^(first_matrix[0][2] * first_matrix[1][0] * first_matrix[3][1]) ^(first_matrix[0][2] * first_matrix[1][1] * first_matrix[3][0]) ^(first_matrix[0][1] * first_matrix[1][0] * first_matrix[3][2]) ^(first_matrix[0][0] * first_matrix[1][2] * first_matrix[3][1]);
        first_matrix2[3][0] = (first_matrix[0][1] * first_matrix[1][2] * first_matrix[2][3]) ^(first_matrix[0][2] * first_matrix[1][3] * first_matrix[2][1]) ^(first_matrix[0][3] * first_matrix[1][1] * first_matrix[2][2]) ^(first_matrix[0][3] * first_matrix[1][2] * first_matrix[2][1]) ^(first_matrix[0][2] * first_matrix[1][1] * first_matrix[2][3]) ^(first_matrix[0][1] * first_matrix[1][3] * first_matrix[2][2]);
        first_matrix2[3][1] = (first_matrix[0][0] * first_matrix[1][2] * first_matrix[2][3]) ^(first_matrix[0][2] * first_matrix[1][3] * first_matrix[2][0]) ^(first_matrix[0][3] * first_matrix[1][0] * first_matrix[2][2]) ^(first_matrix[0][3] * first_matrix[1][2] * first_matrix[2][0]) ^(first_matrix[0][2] * first_matrix[1][0] * first_matrix[2][3]) ^(first_matrix[0][0] * first_matrix[1][3] * first_matrix[2][2]);
        first_matrix2[3][2] = (first_matrix[0][0] * first_matrix[1][1] * first_matrix[2][3]) ^(first_matrix[0][1] * first_matrix[1][3] * first_matrix[2][0]) ^(first_matrix[0][3] * first_matrix[1][0] * first_matrix[2][1]) ^(first_matrix[0][3] * first_matrix[1][1] * first_matrix[2][0]) ^(first_matrix[0][1] * first_matrix[1][0] * first_matrix[2][3]) ^(first_matrix[0][0] * first_matrix[1][3] * first_matrix[2][1]);
        first_matrix2[3][3] = (first_matrix[0][0] * first_matrix[1][1] * first_matrix[2][2]) ^(first_matrix[0][1] * first_matrix[1][2] * first_matrix[2][0]) ^(first_matrix[0][2] * first_matrix[1][0] * first_matrix[2][1]) ^(first_matrix[0][2] * first_matrix[1][1] * first_matrix[2][0]) ^(first_matrix[0][1] * first_matrix[1][0] * first_matrix[2][2]) ^(first_matrix[0][0] * first_matrix[1][2] * first_matrix[2][1]);
    end
    first_matrix_out = first_matrix2;
end
endtask


task first_matrix_determinant;
input [104:0] first_matrix [3:0][3:0];
input [4:0] size;
output [104:0] first_matrix_sum;
logic [104:0] first_matrix_sum2;
logic [4:0] start_row;
logic [4:0] start_column;
start_row = 5'b0;
start_column = 5'b0;
begin
    first_matrix_sum2 = 105'b0;
    if (size == 2) begin
        first_matrix_sum2 = first_matrix[0][0] * first_matrix[1][1];
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][1] * first_matrix[1][0]);
    end
    else if(size == 3)begin
        first_matrix_sum2 = Sarrus(first_matrix,0,0,0);
    end
    else if(size == 4)begin
        first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,1);
        first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,2);
        first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,3);
        first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,4);
    end
    first_matrix_sum = first_matrix_sum2;
end
endtask

function [104:0] Sarrus;
input [104:0] first_matrix [3:0][3:0];
input [4:0] start_row;
input [4:0] start_column;
input [4:0] skip_column;
logic [104:0] first_matrix_sum2;
logic [2:0] add1;
logic [2:0] add2;
logic [2:0] add3;
first_matrix_sum2 = 105'b0;
begin
    if (skip_column == 0) begin
        add1 = 1;
        add2 = 2;
        add3 = 0;
    end else if (skip_column == 1) begin
        add1 = 2;
        add2 = 3;
        add3 = 1;
    end else if (skip_column == 2) begin
        add1 = 2;
        add2 = 3;
        add3 = 0;
    end else if (skip_column == 3) begin
        add1 = 1;
        add2 = 3;
        add3 = 0;
    end else if (skip_column == 4) begin
        add1 = 1;
        add2 = 2;
        add3 = 0;
    end
    if (skip_column == 0)begin
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add2]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add3]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add3]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add2]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add1]);
    end else begin
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add2] * first_matrix[0][skip_column-1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add3] * first_matrix[0][skip_column-1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add1] * first_matrix[0][skip_column-1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add3] * first_matrix[0][skip_column-1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add2] * first_matrix[0][skip_column-1]);
        first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add1] * first_matrix[0][skip_column-1]);
    end
    Sarrus = first_matrix_sum2;
end
endfunction

task decode_syndromes;
    input [3:0] syndrome_number; // Input number of syndromes to do(2*max number of errors)
    input [104:0] data;
    logic [3:0] loop;
    logic [104:0] input_data;
    begin
        input_data = 105'b0;
        for ( loop = 1; loop <= syndrome_number; loop++)
        begin
            for (integer i = 0; i < 105; i++)
            begin
                if (data[i])
                input_data[i*loop] = 1'b1;
            end
            syndromes(input_data, decoded_syndrome[loop-1]);
            input_data = 105'b0;
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
        data_2 = 105'b0;
        for (j = 0; j < 8; j++)
        begin
            for (i = 16; i < 105; i++)
            begin
                if (data[i])
                begin
                    data[i] = 1'b0;
                    data[i % 15] = 1'b1 ^ data[i % 15];
                end
            end
        end
        if (data[0])
            data_2 = data_2 ^ 105'b01;
        if (data[1])
            data_2 = data_2 ^ 105'b10;
        if (data[2])
            data_2 = data_2 ^ 105'b100;
        if (data[3])
            data_2 = data_2 ^ 105'b1000;
        if (data[4])
            data_2 = data_2 ^ 105'b11;
        if(data[5])
            data_2 = data_2 ^ 105'b110;
        if(data[6])
            data_2 = data_2 ^ 105'b1100;
        if(data[7])
            data_2 = data_2 ^ 105'b1011; 
        if(data[8])
            data_2 = data_2 ^ 105'b101;
        if(data[9])
            data_2 = data_2 ^ 105'b1010;
        if(data[10])
            data_2 = data_2 ^ 105'b111;
        if(data[11])
            data_2 = data_2 ^ 105'b1110;
        if(data[12])
            data_2 = data_2 ^ 105'b1111;
        if(data[13])
            data_2 = data_2 ^ 105'b1101;
        if(data[14])
            data_2 = data_2 ^ 105'b1001;
        if(data[15])
            data_2 = data_2 ^ 105'b01;
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