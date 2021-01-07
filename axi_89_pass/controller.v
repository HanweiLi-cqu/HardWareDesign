`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,jumpD,
	input wire equalD,
	output wire jalD,jrD,balD,
	input wire[4:0] rsD,rtD,
	output wire cp0_writeD,invalid_instD,
	input wire stallD,
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[7:0] alucontrolE,
	output wire hilo_writeE,hilo_readE,hilo_selectE,

	//mem stage
	input wire stallM,flushM,
	output wire memtoregM,memwriteM,
				regwriteM,memenM,
	//write back stage
	output wire memtoregW,regwriteW,
	input wire stallW,flushW

    );
	
	//decode stage
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD,memenD;
	wire[7:0] alucontrolD;
	wire hilo_writeD,hilo_readD,hilo_selectD;

	//execute stage
	wire memwriteE,memenE;

	maindec md(
		.op(opD),
		.funct(functD),
		.rsD(rsD),.rtD(rtD),
		.memtoreg(memtoregD),.memen(memenD),.memwrite(memwriteD),
		.branch(branchD),.alusrc(alusrcD),
		.regdst(regdstD),.regwrite(regwriteD),
		.jump(jumpD),.jal(jalD),.jr(jrD),.bal(balD),
		.hilo_write(hilo_writeD),.hilo_read(hilo_readD),.hilo_select(hilo_selectD),
		.cp0_write(cp0_writeD),.stallD(stallD)
		);
	aludec ad(opD,functD,rsD,rtD,alucontrolD,invalid_instD,stallD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(17) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,memenD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_writeD,hilo_readD,hilo_selectD},
		{memtoregE,memwriteE,memenE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_writeE,hilo_readE,hilo_selectE}
		);
	flopenrc #(4) regM(
		clk,rst,
		~stallM,
		flushM,
		{memtoregE,memwriteE,memenE,regwriteE},
		{memtoregM,memwriteM,memenM,regwriteM}
		);
	floprc #(2) regW(
		clk,rst,flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule
