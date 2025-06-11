module BCH_decoder (

    input  logic        rst,
    input  logic        clk,
    input  logic [15:0] syndrome_coding2,
    output logic [15:0] decoded_syndrome2 [8:0],
    input  logic        BCH_decoded_finished2,
    input  logic        state2,
    input  logic [4:0] correcting_capability2,
    output logic [15:0] decoded_signal2,
    output logic [50:0] test1 [3:0][3:0],
    output logic [15:0] test2 [3:0],
    output logic [50:0] test3,
    output logic finished_decoding2

   );


    logic lower_correcting_capability2 = 1'b0;
    logic [15:0] error_correction2 [3:0];
    logic [5:0] counter = 6'b0;
    logic [15:0] decoded_syndrome4 [8:0];
    logic [50:0] first_matrix3 [3:0][3:0];// macierz z lewej strony równania
    logic [50:0] first_matrix3_for_syndrome [3:0][3:0];
    logic [15:0] second_matrix [3:0];// macierz z prawej strony równania
    logic [50:0] second_matrix_sum3 [3:0];
    logic [50:0] second_matrix_sum3_for_syndrome [3:0];
    logic [50:0] first_matrix_sum3;
    logic [50:0] first_matrix_sum3_for_syndrome;
    logic [50:0] divided_signal;
    logic [15:0] where_errors2 [3:0];// pokazuje na których miejscach są błędy
    logic [4:0] size = 3; // changed to const because of errors
    logic matrix_finished = 1'b0;
    logic start_matrix = 1'b0;
    logic start_error_correction = 1'b0;
    logic lowered_correcting_capability = 1'b0;
    logic matrix_finished2 = 1'b0;
    logic blocker = 1'b0;
    logic [2:0] k = 0;
    //logic [15:0] decoded_syndrome2 [8:0]; // zakomentowac do testowania

    logic [50:0] det_first_matrix [3:0][3:0];
    logic        start_determinant = 1'b0;
    logic [50:0] det_first_matrix_sum;
    logic        finished_determinant;


    determinant det(
        .clk(clk),
        .rst(rst),
        .first_matrix(det_first_matrix),
        .size(size),
        .start_determinant(start_determinant),
        .first_matrix_sum(det_first_matrix_sum),
        .finished_determinant(finished_determinant)
    );

    logic [50:0] min_first_matrix [3:0][3:0];
    logic start_minor = 1'b0;
    logic [50:0] min_first_matrix_out [3:0][3:0];
    logic finished_minor;

    minor min(
        .clk(clk),
        .rst(rst),
        .first_matrix(min_first_matrix),
        .size(size),
        .start_minor(start_minor),
        .first_matrix_out(min_first_matrix_out),
        .finished_minor(finished_minor)
    );

    logic [50:0] err_second_matrix_sum [3:0];
    logic start_error_place = 1'b0;
    logic [15:0] err_where_errors [3:0];
    logic finished_error_place;
    
    error_place err(
        .clk(clk),
        .rst(rst),
        .second_matrix_sum(err_second_matrix_sum),
        .size(size),
        .start_error_place(start_error_place),
        .where_errors(err_where_errors),
        .finished_error_place(finished_error_place)
    );

    logic [50:0] a;
    logic [50:0] b;
    logic [101:0] wynik_mnozenia;
    mnozenie mno(
        .result(wynik_mnozenia),
        .dataa_0(a),
        .datab_0(b),
        .clock0(clk),
        .aclr0(rst)
    );

    logic [50:0] a2;
    logic [50:0] b2;
    logic [101:0] wynik_mnozenia2;
    mnozenie mno2(
        .result(wynik_mnozenia2),
        .dataa_0(a2),
        .datab_0(b2),
        .clock0(clk),
        .aclr0(rst)
    );

    logic [50:0] a3;
    logic [50:0] b3;
    logic [101:0] wynik_mnozenia3;
    mnozenie mno3(
        .result(wynik_mnozenia3),
        .dataa_0(a3),
        .datab_0(b3),
        .clock0(clk),
        .aclr0(rst)
    );

    logic [50:0] a4;
    logic [50:0] b4;
    logic [101:0] wynik_mnozenia4;
    mnozenie mno4(
        .result(wynik_mnozenia4),
        .dataa_0(a4),
        .datab_0(b4),
        .clock0(clk),
        .aclr0(rst)
    );


    logic multiply_delay_start = 1'b0;
    logic multiply_delay_finished = 1'b0;
    logic [3:0] multiply_delay = 4'b0;
    logic multiply_in_progress;

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst) begin
            multiply_in_progress <= 1'b0;
            multiply_delay <= 4'd0;
            multiply_delay_finished <= 1'b0;
        end else begin
            if (multiply_delay_start && !multiply_in_progress) begin
                multiply_in_progress <= 1'b1;
                multiply_delay <= 4'd1;  
                multiply_delay_finished <= 1'b0;
            end else if (multiply_in_progress) begin
                if (multiply_delay == 11) begin
                    multiply_in_progress <= 1'b0;
                    multiply_delay_finished <= 1'b1;
                    multiply_delay <= 4'd0;
                end else begin
                    multiply_delay <= multiply_delay + 1;
                end
            end else begin
                multiply_delay_finished <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst == 1'b1) 
        begin
            //to see decoded syndrome comment the lines below
            //lower_correcting_capability2 = 1'b0;
            // for (logic [3:0] i = 0; i < 4 ;i++ ) begin
            //     error_correction2[i] <= 105'b0;
            // end
            // for (logic [3:0] i = 0;i < 9 ;i++ ) begin
            //     decoded_syndrome2[i] <= 105'b0;
            // end
        end
        else begin
            if(BCH_decoded_finished2 == 1'b0 && state2 == 1'b1)
            begin
                decode_syndromes(8,syndrome_coding2,decoded_syndrome2);

                if (decoded_syndrome2[0] != 0 && finished_decoding2 == 1'b0)begin
                start_matrix <= 1'b1;
                end 

                if (decoded_syndrome2[0] != 0 && lower_correcting_capability2 == 1'b1 && matrix_finished == 1'b1 && lowered_correcting_capability == 1'b0)begin
                    size <= 2;
                    start_matrix <= 1'b0;
                    //matrix_finished = 1'b0;
                    lowered_correcting_capability <= 1'b1;
                end else if (decoded_syndrome2[0] != 0 && lower_correcting_capability2 == 1'b0 && matrix_finished == 1'b1) begin
                    start_error_correction = 1'b1;
                end

                if (decoded_syndrome2[0] != 0 && lower_correcting_capability2 == 1'b1 && matrix_finished == 1'b1 && size == 2 && blocker == 1'b1)begin
                    start_error_correction = 1'b1;
                end

            
                if (start_error_correction == 1'b1 || decoded_syndrome2[0] == 0)begin
                    decoded_signal2 = syndrome_coding2;
                    for (logic [3:0] k = 0;k < 3 ;k++ ) begin
                        if (error_correction2[k] !== 16'bx)
                        decoded_signal2 = decoded_signal2 ^ error_correction2[k];
                    end
                    if (error_correction2[0] === 16'bx)begin
                    // dodać jakąś flagę, że mamy więcej błędów niż kodowanie przewiduje 
                    end
                    lowered_correcting_capability <= 1'b0;
                    finished_decoding2 <= 1'b1;
                    start_error_correction = 1'b0;
                    start_matrix <= 1'b0;
                    size <= 3;
                end

                //to see decoded syndrome comment the lines below
                // lower_correcting_capability2 = 1'b0;
                // for (logic [3:0] i = 0; i < 4 ;i++ ) begin
                //     error_correction2[i] <= 105'b0;
                // end
                // for (logic [3:0] i = 0;i < 9 ;i++ ) begin
                //     decoded_syndrome2[i] <= 105'b0;
                // end
                //test3 = decoded_signal2;
                
            end else begin
                finished_decoding2 = 1'b0;
            end
        
        end
    end

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst == 1'b1) 
        begin

        end
        else if (BCH_decoded_finished2 == 1'b0 && state2 == 1'b1 && start_matrix == 1'b1) 
        begin
            if (lowered_correcting_capability == 1'b1 && blocker == 1'b0)begin
                blocker <= 1'b1;
                matrix_finished <= 1'b0;
            end

            if (counter == 6'b0)begin
                decoded_syndrome4 <= decoded_syndrome2;
                second_matrix_sum3[0] <= 51'b0;
                second_matrix_sum3[1] <= 51'b0;
                second_matrix_sum3[2] <= 51'b0;
                second_matrix_sum3[3] <= 51'b0;
                error_correction2[0] <= 16'b0;
                error_correction2[1] <= 16'b0;
                error_correction2[2] <= 16'b0;
                error_correction2[3] <= 16'b0;
                counter <= counter + 1;
            end

            if (counter == 1)begin
                for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                    for (logic [4:0] j = 0; j < 4 ; j++ ) begin //changed size to 4
                        first_matrix3[i][j] <= decoded_syndrome4[j+i]; 
                    end
                    second_matrix[i] <= decoded_syndrome4[size+i];
                end
                counter <= counter + 2;
            end

            //////////////////////create matrix
            if (counter == 3)begin
                det_first_matrix <= first_matrix3;
                start_determinant <= 1'b1;
                //first_matrix_determinant(first_matrix3,size,first_matrix_sum3); // determinant calculation. Jeżeli jest mniej niż założona liczba błędów to wyjdzie 0, i powinniśmy spróbować innego rozmiaru
                if (finished_determinant == 1'b1) begin
                    first_matrix_sum3 <= det_first_matrix_sum; 
                    start_determinant <= 1'b0;
                    counter <= counter + 1;
                    start_determinant <= 1'b0;
                end
            end
            
            if (counter == 4)begin
                syndromes(first_matrix_sum3,first_matrix_sum3_for_syndrome); // syndrome from determinant
                first_matrix_sum3 <= first_matrix_sum3_for_syndrome;
                counter <= counter + 1;
            end

            if (counter == 5)begin
                //minor(first_matrix3,size,first_matrix3); // działa do 3 błedów
                start_minor <= 1'b1;
                min_first_matrix <= first_matrix3;
                if (finished_minor == 1'b1) begin
                    first_matrix3 <= min_first_matrix_out;
                    start_minor <= 1'b0;
                    counter <= counter + 1;
                end
            end

            if (counter == 6)begin
                for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                    for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
                        syndromes(first_matrix3[i][j],first_matrix3_for_syndrome[i][j]);
                    end
                end
                first_matrix3 <= first_matrix3_for_syndrome;
                counter <= counter + 1;
            end

            if (counter == 7) begin
                //divided_signal <= 16'b1000000000000000/first_matrix_sum3[15:0];
            case (first_matrix_sum3[15:0])
                16'b1:                divided_signal <= 16'b1000000000000000;
                16'b10:               divided_signal <= 16'b100000000000000;
                16'b100:              divided_signal <= 16'b10000000000000;
                16'b1000:             divided_signal <= 16'b1000000000000;
                16'b10000:            divided_signal <= 16'b100000000000;
                16'b100000:           divided_signal <= 16'b10000000000;
                16'b1000000:          divided_signal <= 16'b1000000000;
                16'b10000000:         divided_signal <= 16'b100000000;
                16'b100000000:        divided_signal <= 16'b10000000;
                16'b1000000000:       divided_signal <= 16'b1000000;
                16'b10000000000:      divided_signal <= 16'b100000;
                16'b100000000000:     divided_signal <= 16'b10000;
                16'b1000000000000:    divided_signal <= 16'b1000;
                16'b10000000000000:   divided_signal <= 16'b100;
                16'b100000000000000:  divided_signal <= 16'b10;
                16'b1000000000000000: divided_signal <= 16'b1;
                default: divided_signal <= 16'b0;
            endcase
                counter <= counter + 1;
            end

            if (counter == 8)begin
                if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                    a <= divided_signal;
                    b <= first_matrix3[k][0];
                    a2 <= divided_signal;
                    b2 <= first_matrix3[k][1];
                    a3 <= divided_signal;
                    b3 <= first_matrix3[k][2];
                    a4 <= divided_signal;
                    b4 <= first_matrix3[k][3];
                    multiply_delay_start <= 1'b1;
                end else if (multiply_delay_finished == 1'b1) begin
                    multiply_delay_start <= 1'b0;
                    first_matrix3[k][0] <= wynik_mnozenia[50:0];
                    first_matrix3[k][1] <= wynik_mnozenia2[50:0];
                    first_matrix3[k][2] <= wynik_mnozenia3[50:0];
                    first_matrix3[k][3] <= wynik_mnozenia4[50:0];
                    k <= k+1;
                    if (k == 3) begin
                        k <= 3'b0;
                        counter <= counter + 1;
                    end 
                end
                // for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                //     for (logic [4:0] j = 0; j < 4 ; j++ ) begin //changed size to 4
                //         first_matrix3[i][j] <= first_matrix3[i][j] * (16'b1000000000000000/first_matrix_sum3);
                //     end
                // end
                // counter <= counter + 1;
                
            end

            if (counter == 9)begin
                if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                    a <= second_matrix[0];
                    b <= first_matrix3[k][0];
                    a2 <= second_matrix[1];
                    b2 <= first_matrix3[k][1];
                    a3 <= second_matrix[2];
                    b3 <= first_matrix3[k][2];
                    a4 <= second_matrix[3];
                    b4 <= first_matrix3[k][3];
                    multiply_delay_start <= 1'b1;
                end else if (multiply_delay_finished == 1'b1) begin
                    multiply_delay_start <= 1'b0;
                    second_matrix_sum3[k] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0] ^ wynik_mnozenia3[50:0] ^ wynik_mnozenia4[50:0];
                    k <= k+1;
                    if (k == 3) begin
                        k <= 3'b0;
                        counter <= counter + 1;
                    end 
                end
                // for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                //     for (logic [4:0] j = 0; j < 4 ; j++ ) begin //changed size to 4
                //     /////////////////////////////////////////////////////////////////////////////////////////////////
                //         second_matrix_sum3[i] = second_matrix_sum3[i] ^ second_matrix[j] * first_matrix3[i][j]; // wymnożenie przez 2 macierz DO NAPRAWY PRZEZ TO NIE DZIALA !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                //     ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //     end
                // end
                // counter <= counter + 1;
            end

            if (counter == 10)begin
                for (logic [4:0] i = 0; i < 4 ; i++ )
                syndromes(second_matrix_sum3[i],second_matrix_sum3_for_syndrome[i]);
                second_matrix_sum3 <= second_matrix_sum3_for_syndrome;
                counter <= counter + 1;
            end

            if (counter == 11)begin
                if(size == 2 && (first_matrix3[0][0] === 51'bx || first_matrix3[0][0] === 51'b0))begin
                    where_errors2[0] <= decoded_syndrome4[0]; // tylko dla 1 błędu
                    where_errors2[1] <= 16'b0;
                    where_errors2[2] <= 16'b0;
                    where_errors2[3] <= 16'b0;
                    counter <= counter + 1;
                end else if (size == 3 && first_matrix3[0][0] === 51'bx || first_matrix3[0][0] === 51'b0) begin
                    lower_correcting_capability2 <= 1'b1;
                    counter <= counter + 1;
                end else begin 
                //error_place(second_matrix_sum3,size,where_errors2); // znalezienie na których miejscach są błędy
                    start_error_place <= 1'b1;
                    err_second_matrix_sum <= second_matrix_sum3;
                    if (finished_error_place == 1'b1) begin
                        where_errors2 <= err_where_errors;
                        start_error_place <= 1'b0;
                        counter <= counter + 1;
                    end
                end
            end
            if (counter == 12)begin
                error_correction2 <= where_errors2;
                test1 <= first_matrix3;
                test2 <= where_errors2;
                test3 <= first_matrix_sum3;
                matrix_finished <= 1'b1;
                counter <= 6'b0;
            end
                // test1 <= first_matrix3;
                // test2 <= where_errors2;
                // test3 <= first_matrix_sum3;
        end else begin
            matrix_finished <= 1'b0;
            blocker <= 1'b0;
            counter <= 6'b0;
            lower_correcting_capability2 <= 1'b0;
        end
    end

    task decode_syndromes;
    input [3:0] syndrome_number; // Input number of syndromes to do(2*max number of errors)
    input [16:0] data;
    output [15:0] out [8:0];
    logic [3:0] loop;
    logic [104:0] input_data;
    logic [15:0] decoded_syndrome3 [8:0];
    begin
        input_data = 105'b0;
        for ( loop = 1; loop <= 8; loop++) // changed size(syndrome_number) to 8
        begin
            for (integer i = 0; i < 16; i++) // TRZEBA TO NAPRAWIĆ, KOD Z INTEGEREM SIE NIE ZSYTENZUJE A BEZ NIEGO NIE DZIALA
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
        output[15:0] data_oo;
        begin
            data = data_i;
            data_2 = 105'b0;
            for (logic [9:0] i = 16; i < 105; i++)
            begin
                if (data[i])
                begin
                    data[i] = 1'b0;
                    data[i % 15] = 1'b1 ^ data[i % 15];
                end
            end
            if (data[0])
                data_2 = data_2 ^ 16'b01;
            if (data[1])
                data_2 = data_2 ^ 16'b10;
            if (data[2])
                data_2 = data_2 ^ 16'b100;
            if (data[3])
                data_2 = data_2 ^ 16'b1000;
            if (data[4])
                data_2 = data_2 ^ 16'b11;
            if(data[5])
                data_2 = data_2 ^ 16'b110;
            if(data[6])
                data_2 = data_2 ^ 16'b1100;
            if(data[7])
                data_2 = data_2 ^ 16'b1011; 
            if(data[8])
                data_2 = data_2 ^ 16'b101;
            if(data[9])
                data_2 = data_2 ^ 16'b1010;
            if(data[10])
                data_2 = data_2 ^ 16'b111;
            if(data[11])
                data_2 = data_2 ^ 16'b1110;
            if(data[12])
                data_2 = data_2 ^ 16'b1111;
            if(data[13])
                data_2 = data_2 ^ 16'b1101;
            if(data[14])
                data_2 = data_2 ^ 16'b1001;
            if(data[15])
                data_2 = data_2 ^ 16'b01;
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

    // task error_place;// działa tylko dla macierzy 2x2 czyli do 2 błędów
    // input [50:0] second_matrix_sum [3:0];
    // input [4:0] size;
    // output [15:0] where_errors [3:0];
    // logic [50:0] second_matrix_sum2 [3:0];
    // logic [15:0] possible_values [15:0];
    // logic [15:0] value_holder;
    // begin
    //     second_matrix_sum2 = second_matrix_sum;
    //     //tworzenie wartości kolejnych zmiennych
    //     for (logic [5:0] i = 6'b0; i < 16; i++)
    //     begin
    //         if (i == 0) possible_values[i] = 16'b1;
    //         else if (i == 1) possible_values[i] = 16'b10;
    //         else possible_values[i] = 16'b10 << i-1;
    //     end

    //     //Dla 2 błędów mnożymy 2 możliwe wartości i muszą wyjść second_matrix_sum2[0] i po ich skróceniu muszą być równe second_matrix_sum2[1]. Jest to pokazane w filmiku pod koniec
    //     if (size == 2)begin
    //         for (logic [5:0] j = 0; j < 16; j++) 
    //         begin
    //             for (logic [5:0] i = 0; i < 16; i++)
    //             begin
    //                 if ((possible_values[i] * possible_values[j]) == second_matrix_sum2[0]) begin
    //                     syndromes((possible_values[i] ^ possible_values[j]),value_holder);
    //                     if (value_holder == second_matrix_sum2[1]) begin
    //                         where_errors[0] = possible_values[i];
    //                         where_errors[1] = possible_values[j];
    //                         break;
    //                     end
    //                 end
    //             end
    //         end
    //     end else if(size == 3)begin
    //         for (logic [5:0] j = 0; j < 16; j++) begin
    //             for (logic [5:0] i = 0; i < 16; i++)begin
    //                 for (logic [5:0] k = 0; k < 16;k++ ) begin
    //                     if ((possible_values[i] * possible_values[j] * possible_values[k]) == second_matrix_sum2[0]) begin
    //                         syndromes((possible_values[i] ^ possible_values[j] ^ possible_values[k]),value_holder);
    //                         if (value_holder == second_matrix_sum2[2]) begin
    //                             syndromes(((possible_values[i] * possible_values[j]) ^ (possible_values[i] * possible_values[k]) ^ (possible_values[j] * possible_values[k])),value_holder);
    //                             if (value_holder == second_matrix_sum2[1]) begin
    //                                 where_errors[0] = possible_values[i];
    //                                 where_errors[1] = possible_values[j];
    //                                 where_errors[2] = possible_values[k];
    //                             end 
    //                         end
    //                     end
    //                 end
    //             end
    //         end
    //     end
    // end
    // endtask

    // task minor;
    // input [50:0] first_matrix [3:0][3:0];
    // input [4:0] size;
    // output [50:0] first_matrix_out [3:0][3:0];
    // logic [50:0] first_matrix2[3:0][3:0];
    // begin
    //     for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
    //         for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
    //             first_matrix2[i][j] = 51'b0;
    //         end
    //     end

    //     if (size == 2) begin
    //         first_matrix2[0][0] = first_matrix[1][1];
    //         first_matrix2[1][1] = first_matrix[0][0];
    //         first_matrix2[0][1] = first_matrix[1][0];
    //         first_matrix2[1][0] = first_matrix[0][1]; 
    //     end else if (size == 3) begin
    //         //pierwszy wiersz
    //         first_matrix2[0][0] = (first_matrix[1][1] * first_matrix[2][2]) ^ (first_matrix[1][2] * first_matrix[2][1]);
    //         first_matrix2[0][1] = (first_matrix[1][0] * first_matrix[2][2]) ^ (first_matrix[1][2] * first_matrix[2][0]);
    //         first_matrix2[0][2] = (first_matrix[1][0] * first_matrix[2][1]) ^ (first_matrix[1][1] * first_matrix[2][0]);
    //         //drugi wiersz
    //         first_matrix2[1][0] = (first_matrix[0][1] * first_matrix[2][2]) ^ (first_matrix[0][2] * first_matrix[2][1]);
    //         first_matrix2[1][1] = (first_matrix[0][0] * first_matrix[2][2]) ^ (first_matrix[0][2] * first_matrix[2][0]);
    //         first_matrix2[1][2] = (first_matrix[0][0] * first_matrix[2][1]) ^ (first_matrix[0][1] * first_matrix[2][0]);
    //         //trzeci wiersz
    //         first_matrix2[2][0] = (first_matrix[0][1] * first_matrix[1][2]) ^ (first_matrix[0][2] * first_matrix[1][1]);
    //         first_matrix2[2][1] = (first_matrix[0][0] * first_matrix[1][2]) ^ (first_matrix[0][2] * first_matrix[1][0]);
    //         first_matrix2[2][2] = (first_matrix[0][0] * first_matrix[1][1]) ^ (first_matrix[0][1] * first_matrix[1][0]);
    //     for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
    //         for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
    //                 syndromes(first_matrix2[i][j],first_matrix2[i][j]);
    //             end
    //         end
    //     end else if (size == 4) begin
    //         // do zrobienia
    //     end
    //     first_matrix_out = first_matrix2;
    // end
    // endtask


    // task first_matrix_determinant;
    // input [50:0] first_matrix [3:0][3:0];
    // input [4:0] size;
    // output [50:0] first_matrix_sum;
    // logic [50:0] first_matrix_sum2;
    // begin
    //     first_matrix_sum2 = 51'b0;
    //     if (size == 2) begin
    //         first_matrix_sum2 = first_matrix[0][0] * first_matrix[1][1];
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][1] * first_matrix[1][0]);
    //     end
    //     else if(size == 3)begin
    //         first_matrix_sum2 = Sarrus(first_matrix,0,0,0);
    //     end
    //     else if(size == 4)begin
    //         first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,1);
    //         first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,2);
    //         first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,3);
    //         first_matrix_sum2 = first_matrix_sum2 ^ Sarrus(first_matrix,1,0,4);
    //     end
    //     first_matrix_sum = first_matrix_sum2;
    // end
    // endtask

    // function [50:0] Sarrus;
    // input [50:0] first_matrix [3:0][3:0];
    // input [4:0] start_row;
    // input [4:0] start_column;
    // input [4:0] skip_column;
    // logic [50:0] first_matrix_sum2;
    // logic [2:0] add1;
    // logic [2:0] add2;
    // logic [2:0] add3;
    // first_matrix_sum2 = 51'b0;
    // begin
    //     if (skip_column == 0) begin
    //         add1 = 1;
    //         add2 = 2;
    //         add3 = 0;
    //     end else if (skip_column == 1) begin
    //         add1 = 2;
    //         add2 = 3;
    //         add3 = 1;
    //     end else if (skip_column == 2) begin
    //         add1 = 2;
    //         add2 = 3;
    //         add3 = 0;
    //     end else if (skip_column == 3) begin
    //         add1 = 1;
    //         add2 = 3;
    //         add3 = 0;
    //     end else if (skip_column == 4) begin
    //         add1 = 1;
    //         add2 = 2;
    //         add3 = 0;
    //     end
    //     if (skip_column == 0)begin
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add2]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add3]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add3]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add2]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add1]);
    //     end else begin
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add2] * first_matrix[0][skip_column-1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add3] * first_matrix[0][skip_column-1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add1] * first_matrix[0][skip_column-1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add2] * first_matrix[start_row+1][start_column+add1] * first_matrix[start_row+2][start_column+add3] * first_matrix[0][skip_column-1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add1] * first_matrix[start_row+1][start_column+add3] * first_matrix[start_row+2][start_column+add2] * first_matrix[0][skip_column-1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[start_row][start_column+add3] * first_matrix[start_row+1][start_column+add2] * first_matrix[start_row+2][start_column+add1] * first_matrix[0][skip_column-1]);
    //     end
    //     Sarrus = first_matrix_sum2;
    // end
    // endfunction

endmodule