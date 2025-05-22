module UART_module #(parameter MAX_BITS = 8) (
    input wire clk_i,
    input wire rst_i,

    input  wire  UART_RX,
    output logic UART_TX,

    input logic[MAX_BITS-1:0] TX_buff,
    output logic[MAX_BITS-1:0] RX_buff
);
 

endmodule
