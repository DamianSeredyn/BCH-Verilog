module error_place (
    input  logic        rst,
    input  logic        clk,
    input  logic [50:0] second_matrix_sum [3:0],
    input  logic [4:0]  size,
    input  logic        start_error_place,
    output logic [15:0] where_errors [3:0],
    output logic        finished_error_place
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

    logic [5:0] operation_counter = 6'b0;
    logic [15:0] possible_values [15:0];
    logic [15:0] value_holder;
    logic [5:0] k = 6'b0;
    logic [5:0] m = 6'b0;
    logic [5:0] n = 6'b0;


    always_ff @( posedge clk or posedge rst ) begin
        if (rst == 1'b1) begin
            
        end else begin
            if (start_error_place == 1'b1) begin
                if (operation_counter == 6'b0) begin
                    for (logic [5:0] i = 6'b0; i < 16; i++)
                    begin
                        if (i == 0) possible_values[i] = 16'b1;
                        else if (i == 1) possible_values[i] = 16'b10;
                        else possible_values[i] = 16'b10 << i-1;
                    end
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 1 && size == 2) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= possible_values[k];
                        b <= possible_values[m];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_start <= 1'b0;
                        if (wynik_mnozenia[50:0] == second_matrix_sum[0]) begin
                            syndromes((possible_values[k] ^ possible_values[m]),value_holder);
                            if (value_holder == second_matrix_sum[1]) begin
                                where_errors[0] <= possible_values[k];
                                where_errors[1] <= possible_values[m];
                                where_errors[2] <= 16'b0;
                                where_errors[3] <= 16'b0;
                                operation_counter <= operation_counter + 1'b1;
                            end else begin
                                if (m == 15) begin
                                    k <= k + 1;
                                    m <= 6'b0;
                                end else begin
                                    m <= m + 1;
                                end
                            end
                        end else begin
                            if (m == 15) begin
                                k <= k + 1;
                                m <= 6'b0;
                            end else begin
                                m <= m + 1;
                            end
                        end
                    end
                end else if (operation_counter == 2 && size == 2) begin
                    finished_error_place <= 1'b1;
                    k <= 6'b0;
                    m <= 6'b0;
                    operation_counter <= 6'b0;
                    value_holder <= 16'b0;
                end else if (operation_counter == 1 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= possible_values[k];
                        b <= possible_values[m];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_start <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 2 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia;
                        b <= possible_values[n];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_start <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 3 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        if (wynik_mnozenia[50:0] == second_matrix_sum[0]) begin
                            syndromes((possible_values[k] ^ possible_values[m] ^ possible_values[n]),value_holder);
                            if (value_holder == second_matrix_sum[2]) begin
                                a <= possible_values[m];
                                b <= possible_values[k];
                                a2 <= possible_values[m];
                                b2 <= possible_values[n];
                                a3 <= possible_values[k];
                                b3 <= possible_values[n];
                                multiply_delay_start <= 1'b1;
                            end else begin
                               if (n == 15) begin
                                m <= m + 1;
                                n <= 16'b0;
                               end else if (m == 15) begin
                                k <= k + 1;
                                m <= 16'b0;
                               end else begin
                                n <= n + 1;
                               end
                               operation_counter <= 6'b1;
                            end
                        end else begin
                            if (n == 15) begin
                            m <= m + 1;
                            n <= 16'b0;
                            end else if (m == 15) begin
                            k <= k + 1;
                            m <= 16'b0;
                            end else begin
                            n <= n + 1;
                            end
                            operation_counter <= 6'b1;
                        end
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_start <= 1'b0;
                        syndromes((wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0] ^ wynik_mnozenia3[50:0]),value_holder);
                        if (value_holder == second_matrix_sum[1]) begin
                            where_errors[0] <= possible_values[k];
                            where_errors[1] <= possible_values[m];
                            where_errors[2] <= possible_values[n];
                            where_errors[3] <= 16'b0;
                            operation_counter <= operation_counter + 1'b1;
                        end else begin
                            if (n == 15) begin
                            m <= m + 1;
                            n <= 16'b0;
                            end else if (m == 15) begin
                            k <= k + 1;
                            m <= 16'b0;
                            end else begin
                            n <= n + 1;
                            end
                            operation_counter <= 6'b1;
                        end
                    end
                end else if (operation_counter == 4 && size == 3) begin
                    finished_error_place <= 1'b1;
                    k <= 6'b0;
                    m <= 6'b0;
                    n <= 6'b0;
                    operation_counter <= 6'b0;
                    value_holder <= 16'b0;
                end
            end else begin
                finished_error_place <= 1'b0;
                operation_counter <= 6'b0;
                value_holder <= 16'b0;
                k <= 6'b0;
                m <= 6'b0;
                n <= 6'b0;
                where_errors[0] <= 16'b0;
                where_errors[1] <= 16'b0;
                where_errors[2] <= 16'b0;
                where_errors[3] <= 16'b0;
            end
        end 
    end

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

   

endmodule

    // task error_placee;// działa tylko dla macierzy 2x2 czyli do 2 błędów
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
    //         if (i == 0) possible_values[i] = 16'b10;
    //         else
    //         possible_values[i] = 16'b10 << i;
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