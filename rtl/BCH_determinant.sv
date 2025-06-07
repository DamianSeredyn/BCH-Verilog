module determinant (
    input  logic        rst,
    input  logic        clk,
    input  logic [50:0] first_matrix [3:0][3:0],
    input  logic [4:0]  size,
    input  logic        start_determinant,
    output logic [50:0] first_matrix_sum,
    output logic        finished_determinant
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

    logic [101:0] first_matrix_sum2;
    logic [4:0] start_row;
    logic [4:0] start_column;
    logic [5:0] operation_counter = 6'b0;

    always_ff @( posedge clk or posedge rst ) begin : first_matrix_determinant
        if (rst == 1'b1) begin 
        
        end else begin
            if (start_determinant == 1'b1)begin
                if (operation_counter == 6'b0) begin
                    first_matrix_sum2 <= 102'b0;
                    operation_counter <= operation_counter + 1'b1;
                end else if (operation_counter == 1 && size == 2) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[1][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 2 && size == 2) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][1];
                        b <= first_matrix[1][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 3 && size == 2) begin
                        first_matrix_sum <= first_matrix_sum2[50:0];
                        a <= 51'b0;
                        b <= 51'b0;
                        operation_counter <= 6'b0;
                        finished_determinant <= 1'b1;
                end else if (operation_counter == 1 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[1][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 2 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][2];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 3 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][1];
                        b <= first_matrix[1][2];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 4 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 5 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][2];
                        b <= first_matrix[1][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 6 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 7 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][2];
                        b <= first_matrix[1][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 8 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 9 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][1];
                        b <= first_matrix[1][0];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 10 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][2];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 11 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= first_matrix[0][0];
                        b <= first_matrix[1][2];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 12 && size == 3) begin
                    if (multiply_delay_start == 1'b0 && multiply_delay_finished == 1'b0) begin
                        a <= wynik_mnozenia[50:0];
                        b <= first_matrix[2][1];
                        multiply_delay_start <= 1'b1;
                    end else if (multiply_delay_finished == 1'b1) begin
                        first_matrix_sum2 <= first_matrix_sum2 ^ wynik_mnozenia;
                        multiply_delay_finished <= 1'b0;
                        operation_counter <= operation_counter + 1'b1;
                    end
                end else if (operation_counter == 13 && size == 3) begin
                        a <= 51'b0;
                        b <= 51'b0;
                        operation_counter <= 6'b0;
                        finished_determinant <= 1'b1;
                        first_matrix_sum <= first_matrix_sum2[50:0];
                end
            end else if (start_determinant == 1'b0) begin
                finished_determinant <= 1'b0;
            end
        end
    end

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
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][0] * first_matrix[1][1] * first_matrix[2][2]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][1] * first_matrix[1][2] * first_matrix[2][0]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][2] * first_matrix[1][0] * first_matrix[2][1]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][2] * first_matrix[1][1] * first_matrix[2][0]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][1] * first_matrix[1][0] * first_matrix[2][2]);
    //         first_matrix_sum2 = first_matrix_sum2 ^ (first_matrix[0][0] * first_matrix[1][2] * first_matrix[2][1]);
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