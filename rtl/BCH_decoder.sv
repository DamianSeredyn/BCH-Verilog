module BCH_decoder (

    input  logic        rst,
    input  logic        clk,
    input  logic [104:0] syndrome_coding2,
    //output logic [104:0] decoded_syndrome2 [8:0],
    input  logic        BCH_decoded_finished2,
    input  logic        state2,
    input  logic [4:0] correcting_capability2,
    output logic [104:0] decoded_signal2//,
    // output logic [104:0] test1 [3:0][3:0],
    // output logic [104:0] test2 [3:0],
    // output logic [104:0] test3

   );


    logic lower_correcting_capability2 = 1'b0;
    logic [104:0] error_correction2 [3:0];
    logic [4:0] correcting_capability3;
    logic [104:0] decoded_syndrome2 [8:0]; // zakomentowac do testowania

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst == 1'b1) 
        begin
            //to see decoded syndrome comment the lines below
            lower_correcting_capability2 = 1'b0;
            for (logic [3:0] i = 0; i < 4 ;i++ ) begin
                error_correction2[i] <= 105'b0;
            end
            for (logic [3:0] i = 0;i < 9 ;i++ ) begin
                decoded_syndrome2[i] <= 105'b0;
            end
        end
        else begin
            if(BCH_decoded_finished2 == 1'b0 && state2 == 1'b1)
            begin
                correcting_capability3 = correcting_capability2;
                decode_syndromes(8,syndrome_coding2,decoded_syndrome2);
                if (decoded_syndrome2[0] != 0)begin
                matrix(decoded_syndrome2, correcting_capability3, error_correction2);
                end

                if (decoded_syndrome2[0] != 0 && lower_correcting_capability2 == 1'b1)begin
                    correcting_capability3 = 2;
                    matrix(decoded_syndrome2, correcting_capability3, error_correction2);
                end
            

                decoded_signal2 = syndrome_coding2;
                for (logic [3:0] k = 0;k < 3 ;k++ ) begin
                    if (error_correction2[k] !== 105'bx)
                    decoded_signal2 = decoded_signal2 ^ error_correction2[k];
                end
                if (error_correction2[0] === 105'bx)begin
                   // dodać jakąś flagę, że mamy więcej błędów niż kodowanie przewiduje 
                end
                //to see decoded syndrome comment the lines below
                lower_correcting_capability2 = 1'b0;
                for (logic [3:0] i = 0; i < 4 ;i++ ) begin
                    error_correction2[i] <= 105'b0;
                end
                for (logic [3:0] i = 0;i < 9 ;i++ ) begin
                    decoded_syndrome2[i] <= 105'b0;
                end
                
            end
        
        end
    end

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
    output [104:0] data_o [3:0];
    begin
        decoded_syndrome2 = decoded_syndrome;
        first_matrix_sum = 105'b0;
        second_matrix_sum[0] = 105'b0;
        second_matrix_sum[1] = 105'b0;
        second_matrix_sum[2] = 105'b0;
        second_matrix_sum[3] = 105'b0;

        //create matrix
        for (i = 0; i < 4 ; i++ ) begin //changed size to 4
            for (j = 0; j < 4 ; j++ ) begin //changed size to 4
            first_matrix[i][j] = decoded_syndrome2[j+i]; 
            end
            second_matrix[i] = decoded_syndrome2[size+i];
        end

        first_matrix_determinant(first_matrix,size,first_matrix_sum); // determinant calculation. Jeżeli jest mniej niż założona liczba błędów to wyjdzie 0, i powinniśmy spróbować innego rozmiaru
        syndromes(first_matrix_sum,first_matrix_sum); // syndrome from determinant
        //powyżej tego momentu wszystko na pewno działa a poniżej działa dla równo 2 błędów. Nad wyzwoleniem matrix napisałem co trzeba jako tako zrobić
        minor(first_matrix,size,first_matrix); // To raczej trzeba zmodyfikować by działało dla 3 i 4 błędów

        for (i = 0; i < 4 ; i++ ) begin //changed size to 4
            for (j = 0; j < 4 ; j++ ) begin //changed size to 4
                first_matrix[i][j] = first_matrix[i][j] * (16'b1000000000000000/first_matrix_sum); // wymnożenie przez determinante
                second_matrix_sum[i] = second_matrix_sum[i] ^ second_matrix[j]*first_matrix[i][j]; // wymnożenie przez 2 macierz
            end
            data_o[i] = 105'b0;
            syndromes(second_matrix_sum[i],second_matrix_sum[i]);
        end

        if(size == 2 && first_matrix[0][0] === 105'bx)
            where_errors[0] = decoded_syndrome[0]; // tylko dla 1 błędu
        else if (size == 3 && first_matrix[0][0] === 105'bx) begin
            lower_correcting_capability2 = 1'b1;
        end
        else error_place(second_matrix_sum,size,where_errors); // znalezienie na których miejscach są błędy

        data_o = where_errors;

        // test1 = first_matrix;
        // test2 = where_errors;
        // test3 = first_matrix_sum;
    end
    endtask

    task error_place;// działa tylko dla macierzy 2x2 czyli do 2 błędów
    input [104:0] second_matrix_sum [3:0];
    input [4:0] size;
    output [104:0] where_errors [3:0];
    logic [104:0] second_matrix_sum2 [3:0];
    logic [104:0] possible_values [15:0];
    logic [104:0] value_holder;
    begin
        second_matrix_sum2 = second_matrix_sum;
        //tworzenie wartości kolejnych zmiennych
        for (logic [5:0] i = 6'b0; i < 16; i++)
        begin
            if (i == 0) possible_values[i] = 16'b10;
            else
            possible_values[i] = 16'b10 << i;
        end

        //Dla 2 błędów mnożymy 2 możliwe wartości i muszą wyjść second_matrix_sum2[0] i po ich skróceniu muszą być równe second_matrix_sum2[1]. Jest to pokazane w filmiku pod koniec
        if (size == 2)begin
            for (logic [5:0] j = 0; j < 16; j++) 
            begin
                for (logic [5:0] i = 0; i < 16; i++)
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
        end else if(size == 3)begin
            for (logic [5:0] j = 0; j < 16; j++) begin
                for (logic [5:0] i = 0; i < 16; i++)begin
                    for (logic [5:0] k = 0; k < 16;k++ ) begin
                        if ((possible_values[i] * possible_values[j] * possible_values[k]) == second_matrix_sum2[0]) begin
                            syndromes((possible_values[i] ^ possible_values[j] ^ possible_values[k]),value_holder);
                            if (value_holder == second_matrix_sum2[2]) begin
                                syndromes(((possible_values[i] * possible_values[j]) ^ (possible_values[i] * possible_values[k]) ^ (possible_values[j] * possible_values[k])),value_holder);
                                if (value_holder == second_matrix_sum2[1]) begin
                                    where_errors[0] = possible_values[i];
                                    where_errors[1] = possible_values[j];
                                    where_errors[2] = possible_values[k];
                                end 
                            end
                        end
                    end
                end
            end
        end
    end
    endtask

    task minor;
    input [104:0] first_matrix [3:0][3:0];
    input [4:0] size;
    output [104:0] first_matrix_out [3:0][3:0];
    logic [104:0] first_matrix2[3:0][3:0];
    begin
        for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
            for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
                first_matrix2[i][j] = 105'b0;
            end
        end

        if (size == 2) begin
            first_matrix2[0][0] = first_matrix[1][1];
            first_matrix2[1][1] = first_matrix[0][0];
            first_matrix2[0][1] = first_matrix[1][0];
            first_matrix2[1][0] = first_matrix[0][1]; 
        end else if (size == 3) begin
            //pierwszy wiersz
            first_matrix2[0][0] = (first_matrix[1][1] * first_matrix[2][2]) ^ (first_matrix[1][2] * first_matrix[2][1]);
            first_matrix2[0][1] = (first_matrix[1][0] * first_matrix[2][2]) ^ (first_matrix[1][2] * first_matrix[2][0]);
            first_matrix2[0][2] = (first_matrix[1][0] * first_matrix[2][1]) ^ (first_matrix[1][1] * first_matrix[2][0]);
            //drugi wiersz
            first_matrix2[1][0] = (first_matrix[0][1] * first_matrix[2][2]) ^ (first_matrix[0][2] * first_matrix[2][1]);
            first_matrix2[1][1] = (first_matrix[0][0] * first_matrix[2][2]) ^ (first_matrix[0][2] * first_matrix[2][0]);
            first_matrix2[1][2] = (first_matrix[0][0] * first_matrix[2][1]) ^ (first_matrix[0][1] * first_matrix[2][0]);
            //trzeci wiersz
            first_matrix2[2][0] = (first_matrix[0][1] * first_matrix[1][2]) ^ (first_matrix[0][2] * first_matrix[1][1]);
            first_matrix2[2][1] = (first_matrix[0][0] * first_matrix[1][2]) ^ (first_matrix[0][2] * first_matrix[1][0]);
            first_matrix2[2][2] = (first_matrix[0][0] * first_matrix[1][1]) ^ (first_matrix[0][1] * first_matrix[1][0]);
        for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
            for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
                    syndromes(first_matrix2[i][j],first_matrix2[i][j]);
                end
            end
        end else if (size == 4) begin
            // do zrobienia
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
    output [104:0] out [8:0];
    logic [3:0] loop;
    logic [104:0] input_data;
    logic [104:0] decoded_syndrome3 [8:0];
    begin
        input_data = 105'b0;
        for ( loop = 1; loop <= 8; loop++) // changed size(syndrome_number) to 8
        begin
            for (integer i = 0; i < 20; i++)
            begin
              if (data[i] && i*loop < 105)
                input_data[i*loop] = 1'b1;
            end
            if(loop < 10 && loop > 0)
            syndromes(input_data, decoded_syndrome3[loop-1]);
            input_data = 105'b0;
        end
        out = decoded_syndrome3;
    end
    endtask

    task syndromes;
        logic [104:0] data;
        logic [15:0] data_2;
        input [104:0] data_i;
        output[104:0] data_oo;
        begin
            data = data_i;
            data_2 = 105'b0;
            for (logic [4:0] j = 0; j < 8; j++)
            begin
                for (logic [9:0] i = 16; i < 105; i++)
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
                16'b0011:  data_2 = 16'b10000;
                16'b0110:  data_2 = 16'b100000;
                16'b1100:  data_2 = 16'b1000000;
                16'b1011:  data_2 = 16'b10000000;
                16'b0101:  data_2 = 16'b100000000;
                16'b1010:  data_2 = 16'b1000000000;
                16'b0111:  data_2 = 16'b10000000000;
                16'b1110:  data_2 = 16'b100000000000;
                16'b1111:  data_2 = 16'b1000000000000;
                16'b1101:  data_2 = 16'b10000000000000;
                16'b1001:  data_2 = 16'b100000000000000;
                16'b0001:  data_2 = 16'b1000000000000000;
                default: data_2 = data_2;
            endcase
            data_oo = data_2;
        end
    endtask

endmodule