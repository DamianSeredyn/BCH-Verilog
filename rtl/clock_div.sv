module clock_div #(parameter N = 100_000_000) (
    input wire clk_i,
    input wire rst_i,
    output logic clk_o
);
  reg [31:0] count = 0;

    always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i) begin
            count <= 0;
            clk_o <= 0;
        end else begin
                if (count == (N/2 - 1)) begin
                    clk_o <= ~clk_o;
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
        end
    end
endmodule
