`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 13:50:53
// Design Name: 
// Module Name: top
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


module top(
	input wire clk,rst,
	output wire[31:0] writedata,dataadr,
	output wire memwrite,
	output wire [31:0]instr
    );

	wire[31:0] pc,readdata;
	wire memenM;

	mips mips(clk,rst,pc,instr,memwrite,memenM,dataadr,writedata,readdata);
	inst_mem imem(~clk,pc[7:2],instr);
	data_mem dmem(~clk,memenM,memwrite,dataadr,writedata,readdata);
endmodule
