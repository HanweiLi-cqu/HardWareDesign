`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,resetn,
	input wire [5:0] int,
	//inst_mem
	output wire inst_sram_en,
	output wire [3:0]inst_sram_wen,
	output wire[31:0] inst_sram_addr,//pcF->inst_sram_addr
	output wire[31:0] inst_sram_wdata,
	input wire[31:0] inst_sram_rdata,//instrF->inst_sram_rdata

	//data_mem
	output wire data_sram_en,//memen
	output wire[3:0] data_sram_wen, //we2M
	output wire[31:0] data_sram_addr,
	output wire[31:0] data_sram_wdata,//aluoutM,writedataM
	input wire[31:0] data_sram_rdata, //readdataM

	//debug 
	output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );
	assign inst_sram_en=1'b1;
	assign inst_sram_wen=4'b0000;
	assign inst_sram_wdata=32'h00000000;
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,regwriteW;
	wire [7:0] alucontrolE;
	wire flushE,equalD;
	wire memwriteM;
	wire [4:0]rsD,rtD;
	wire cp0_writeD,invalid_instD;
	wire stallM,flushM;
	wire stallW,flushW;

	controller c(
		clk,~resetn,
		//decode stage
		opD,functD,
		pcsrcD,branchD,jumpD,equalD,
		jalD,jrD,balD,
		rsD,rtD,
		cp0_writeD,invalid_instD,
		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,
		hilo_writeE,hilo_readE,hilo_selectE,
		//mem stage
		stallM,flushM,
		memtoregM,memwriteM,
		regwriteM,data_sram_en,
		//write back stage
		memtoregW,regwriteW,
		stallW,flushW
		);
	datapath dp(
		clk,~resetn,
		int,
		//fetch stage
		inst_sram_addr,
		inst_sram_rdata,
		//decode stage
		pcsrcD,branchD,
		jumpD,
		equalD,
		opD,functD,
		jalD,jrD,balD,
		rsD,rtD,
		cp0_writeD,invalid_instD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		flushE,stallE,
		hilo_writeE,hilo_readE,hilo_selectE,
		//mem stage
		memtoregM,
		regwriteM,
		data_sram_addr,data_sram_wdata,
		data_sram_rdata,data_sram_en,
		data_sram_wen,
		stallM,flushM,
		//writeback stage
		memtoregW,
		regwriteW,
		stallW,flushW,
		//debug
		debug_wb_pc,
		debug_wb_rf_wen,
		debug_wb_rf_wnum,
		debug_wb_rf_wdata
	    );
	
endmodule
