`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output wire stallF,flushF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	output wire[1:0] forwardaD,forwardbD,
	output wire stallD,flushD,
	input wire jumpD,jalD,balD,jrD,
	output wire branchFlushD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushE,
	input wire cp0_writeM,
	input wire[4:0] rdE,
	output wire forwardcp0E,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire stallM,
	input wire[31:0] excepttypeM,
	output wire flushM,
	input wire[4:0] rdM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire stallW,flushW,

	//hilo
    wire hilo_readE,hilo_writeM,hilo_writeW,
	output wire[1:0] forward_hilo,

	//div
	input wire div_stallE,
	output wire stallE
    );

	wire lwstallD,branchstallD;

	//forwarding sources to D stage (branch equality)
	assign forwardaD =	(rsD==0)? 2'b00:
						(rsD == writeregE & regwriteE)?2'b01:
						(rsD == writeregM & regwriteM)?2'b10:
						(rsD == writeregW & regwriteW)?2'b11:2'b00;
    assign forwardbD =	(rtD==0)?2'b00:
						(rtD == writeregE & regwriteE)?2'b01:
						(rtD == writeregM & regwriteM)?2'b10:
						(rtD == writeregW & regwriteW)?2'b11:2'b00;
	// always @(*) begin
    //     forwardaD = (rsD !=0) & (rsD == writeregM) & regwriteM;
    //     forwardbD = (rtD !=0) & (rtD == writeregM) & regwriteM;
    // end
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end
	wire jrstall;
	//stalls
	assign  lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
	assign  branchstallD = branchD &
				(regwriteE & 
				(writeregE == rsD | writeregE == rtD) |
				memtoregM &
				(writeregM == rsD | writeregM == rtD));
	wire flush_except;
	assign flush_except = (excepttypeM != 32'b0);
	// wire div_stall;
	// assign div_stall=(div_stallE==1'b0 )?0:1;
	//assign #1 stallD = lwstallD | branchstallD | div_stallE;
	assign  stallF = lwstallD | div_stallE | branchstallD |jrstall;
	assign  stallD = lwstallD | div_stallE | branchstallD |jrstall;
	assign  stallE = div_stallE;
	assign  stallM = 0;
	assign  stallW = 0;

	assign flushF = flush_except;
	assign flushD = flush_except;
	assign flushE = flush_except|lwstallD|branchstallD|jumpD|jrstall;
	assign flushM = flush_except;
	assign flushW = flush_except;
	
	assign branchFlushD= branchD & (!balD);
	assign jrstall = (jrD && regwriteE && writeregE==rsD) || (jrD && memtoregM && writeregM==rsD);
	assign forward_hilo=(hilo_readE && hilo_writeM) ? 2'b01: (hilo_readE && hilo_writeW)? 2'b10:2'b00;
	assign forwardcp0E = ((cp0_writeM)&(rdE==rdM)&(rdE!=0))?1'b1:1'b0;

endmodule
