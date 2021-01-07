`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/17 10:18:09
// Design Name: 
// Module Name: exception
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module exception(
    input wire rst,
    input wire [7:0] except,
    input wire [31:0] cp0_status, cp0_cause,
    output reg [31:0] excepttype
    );
    always @(*) begin
        if(rst) begin
            excepttype <= 32'b0;
        end else begin
            excepttype <= 32'b0;
            if(((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) && (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1))
                excepttype <= 32'h00000001;
            else if (except[7] == 1'b1 || except[1])
                excepttype <= 32'h00000004;
            else if (except[0])//ades
                excepttype <= 32'h00000005;
            else if (except[6])//syscall
                excepttype <= 32'h00000008;
            else if (except[5])//break
                excepttype <= 32'h00000009;
            else if (except[4])//invalid_inst
                excepttype <= 32'h0000000a;
            else if (except[3])//overflow
                excepttype <= 32'h0000000c;
            else if (except[2])//eret
                excepttype <= 32'h0000000e;
        end
    end
endmodule
