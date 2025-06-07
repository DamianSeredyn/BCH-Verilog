module minor (
    input  logic        rst,
    input  logic        clk,
    input  logic [50:0] first_matrix [3:0][3:0],
    input  logic [4:0]  size,
    input  logic        start_minor,
    output logic [50:0] first_matrix_out [3:0][3:0],
    output logic        finished_minor
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

    logic multiply_delay_start = 1'b0;
    logic multiply_delay_finished = 1'b0;
    logic [3:0] multiply_delay = 4'b0;

    always_ff @(posedge clk or posedge rst)
    begin
        if (rst == 1'b1) begin 
            multiply_delay_start <= 1'b0;
            multiply_delay_finished <= 1'b0;
            multiply_delay <= 4'b0;
        end else begin
            if (multiply_delay_start == 1'b1) begin
                multiply_delay <= multiply_delay + 1;
            end
            if (multiply_delay == 11) begin
                multiply_delay <= 4'b0;
                multiply_delay_start <= 1'b0;
                multiply_delay_finished <= 1'b1;
            end
        end
    end

    logic [50:0] first_matrix2[3:0][3:0];
    logic [5:0] operation_counter = 6'b0;

    always_ff @( posedge clk or posedge rst ) begin : minor
        if (rst == 1'b1) begin 
            for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
                    first_matrix2[i][j] <= 51'b0;
                    operation_counter = 6'b0;
                end
            end
        end else begin
            if (start_minor == 1'b1) begin
                if (operation_counter == 6'b0) begin
                    for (logic [4:0] i = 0; i < 4 ; i++ ) begin //changed size to 4
                        for (logic [4:0] j = 0; j < 4 ; j++ ) begin// changed size to 4
                            first_matrix2[i][j] <= 51'b0;
                        end
                    end
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 1 && size == 2) begin
                    first_matrix2[0][0] <= first_matrix[1][1];
                    first_matrix2[1][1] <= first_matrix[0][0];
                    first_matrix2[0][1] <= first_matrix[1][0];
                    first_matrix2[1][0] <= first_matrix[0][1];
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 2 && size == 2) begin
                    first_matrix_out <= first_matrix2;
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 3 && size == 2) begin
                    operation_counter <= 6'b0;
                    finished_minor <= 1'b1;
                end else if (operation_counter == 1 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[1][1];
                        b <= first_matrix[2][2];
                        a2 <= first_matrix[1][2];
                        b2 <= first_matrix[2][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[0][0] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 2 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[1][0];
                        b <= first_matrix[2][2];
                        a2 <= first_matrix[1][2];
                        b2 <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[0][1] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 3 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[1][0];
                        b <= first_matrix[2][1];
                        a2 <= first_matrix[1][1];
                        b2 <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[0][2] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 4 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][1];
                        b <= first_matrix[2][2];
                        a2 <= first_matrix[0][2];
                        b2 <= first_matrix[2][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[1][0] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 5 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[2][2];
                        a2 <= first_matrix[0][2];
                        b2 <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[1][1] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 6 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[2][1];
                        a2 <= first_matrix[0][1];
                        b2 <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[1][2] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 7 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][1];
                        b <= first_matrix[1][2];
                        a2 <= first_matrix[0][2];
                        b2 <= first_matrix[1][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[2][0] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 8 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[1][2];
                        a2 <= first_matrix[0][2];
                        b2 <= first_matrix[1][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[2][1] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 9 && size  == 3)begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[1][1];
                        a2 <= first_matrix[0][1];
                        b2 <= first_matrix[1][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix2[2][2] <= wynik_mnozenia[50:0] ^ wynik_mnozenia2[50:0];
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 10 && size  == 3)begin
                    first_matrix_out <= first_matrix2;
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 11 && size  == 3)begin
                    operation_counter <= 6'b0;
                    finished_minor <= 1'b1;
                end
            end else if (start_minor == 1'b0) begin
                finished_minor = 1'b0;
            end
        end
    end
    
    
endmodule

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