module UART_module #(
 parameter MAX_BITS = 8,  
 parameter PARAMETERS = 6
 )

 (
    input wire clk_i,
    input wire clk_N,
    input wire rst_i,

    input  wire  UART_RX,
    output logic UART_TX,

    input logic[MAX_BITS-1:0] TX_buff,
    output logic[MAX_BITS*PARAMETERS-1:0] RX_buff,
    
    output logic Data_Ready);


    // RX
    logic TransimitonIncoming = 1'b0;
    logic TransimitonFinished = 1'b0;
    logic prevState = 1'b1;
    logic[3:0] current_Bit_RX;
    logic[7:0] temp_RX_buff = 0;

    // Data Handle
    logic prevTransimitonFinished = 1'b0;
    integer commandIndex = 0;
 
    //Odbiornikkkkk
    always @(posedge clk_N or posedge rst_i)
        begin
            if(rst_i == 1)
                begin
                        TransimitonFinished <= 1'b0; 
                        TransimitonIncoming <= 1'b0;
                        current_Bit_RX <= 0;
                        temp_RX_buff <= 0;
                end
            else
                begin
                    if(UART_RX == 0 && prevState == 1 && TransimitonIncoming == 0)
                        begin
                            TransimitonIncoming <= 1'b1;
                            TransimitonFinished <= 1'b0;
                            current_Bit_RX<= 0;
                        end
                    else if(TransimitonIncoming == 1'b1)
                        begin
                            if(current_Bit_RX == MAX_BITS && UART_RX == 1'b1)
                                begin
                                    TransimitonIncoming <= 1'b0;
                                    TransimitonFinished <= 1'b1;
                                end
                            else
                                begin
                                    temp_RX_buff[current_Bit_RX]<=UART_RX;
                                    current_Bit_RX<= current_Bit_RX+1;                
                                end
                            end
                    else
                        begin
                            prevState <= UART_RX;
                        end
                end
        end
    always @(posedge clk_i or posedge rst_i)
        begin
            if(rst_i == 1)
                begin
                   prevTransimitonFinished <=  1'b0; 
                   commandIndex <= 0;
                    RX_buff <= 0;
                    Data_Ready <= 1'b0;
                end
            else
                begin
                    if(prevTransimitonFinished == 1'b0 && TransimitonFinished == 1'b1) begin
                        if(commandIndex == 0) begin
                            if(temp_RX_buff == 8'b0000_0001 || temp_RX_buff == 8'b0000_0010) begin
                                RX_buff <= 48'b0;
                                RX_buff[47:40] <= temp_RX_buff;   
                                commandIndex <= commandIndex+1;
                                Data_Ready <= 1'b0;
                            end
                            else begin
                                RX_buff <= 48'b0;
                                commandIndex <= 0;
                                Data_Ready <= 1'b0;
                            end
                        end
                        else
                            begin
                                case (commandIndex)
                                    1: RX_buff[39:32] <= temp_RX_buff;
                                    2: RX_buff[31:24] <= temp_RX_buff;
                                    3: RX_buff[23:16] <= temp_RX_buff;
                                    4: RX_buff[15:8]  <= temp_RX_buff;
                                    5: RX_buff[7:0]   <= temp_RX_buff;
                                endcase
                                commandIndex <= commandIndex+1;
                                if(commandIndex > 5)    begin
                                    commandIndex <= 0;
                                    Data_Ready <= 1'b0; 
                                    RX_buff <= 48'b0;       
                                end                                 
                            end
                    end
                    if(RX_buff[7:0] == 8'b0000_1111)    begin
                                    commandIndex <= 0;
                                    Data_Ready <= 1'b1;        
                    end 
                    prevTransimitonFinished <= TransimitonFinished;
                end
        end


endmodule
