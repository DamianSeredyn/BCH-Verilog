module BCH_encoder (

    input  logic        rst,
    input  logic        clk,

    input logic startEncoding,
    input logic [4:0] signal_input,
    output logic [15:0] encoded_signal,
    output logic EncoderReady);

    logic [10:0] generator_signal = 11'b10100110111; //DO NOT TOUCH :>

    always_ff @(posedge clk or posedge rst)
    begin
	if (rst == 1'b1) 
    begin
        
	end
    else if(startEncoding == 1'b1) begin
        encoded_signal <= 16'b0;
		encoded_signal <= encode_bch(signal_input, generator_signal);
        EncoderReady <= 1'b1;
	end
    else begin 
        EncoderReady <= 1'b0;
    end
end


    function [15:0] encode_bch;
    input [4:0] px;
    input [10:0] gx;
    logic [15:0] result;
    begin
        result = 16'b0;
        for (logic [5:0] i = 0; i < 5; i++) begin
            if (px[i])
                result = result ^ (gx << i);
        end
        encode_bch = result;
    end
    endfunction

endmodule