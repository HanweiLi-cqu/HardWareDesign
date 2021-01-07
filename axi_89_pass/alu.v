`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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

`include "defines.vh"
`include "F:\\HardwareDesign\\step_into_mips-lab_4\\step_into_mips-lab_4\\lab_4\\rtl\\ascii\\defines2.vh"
module alu(
	input clk,rst,
	input wire[31:0] a,b,
	//input wire[2:0] op,
	input wire[7:0]alucontrol,
	output reg[31:0] y,
	input wire[4:0] sa,//移位位数
	input wire[63:0] hilo_iW,
	output reg[63:0] hiloE,
	output reg div_stallE,
	input wire flush_except,
	output wire overflow,
	input [31:0] cp0_iE
	//output wire zero
    );
	wire [31:0] mult_a,mult_b;
	wire [63:0] hilo_temp;
	//处理乘法
	assign mult_a = ( (alucontrol == `EXE_MULT_OP) && (a[31] == 1'b1) )? ( ~a + 1 ): a ; 
    assign mult_b = ( (alucontrol == `EXE_MULT_OP) && (b[31] == 1'b1) )? ( ~b + 1 ): b ; 
    assign hilo_temp = ( (alucontrol == `EXE_MULT_OP) && (a[31] ^ b[31] == 1'b1) )?  ~(mult_a * mult_b) + 1 : mult_a * mult_b ; 

	//处理加法、减法、比较
	wire[31:0] b_mux;
	//如果是减法或者有符号的比较运算，那么b_mux等于第二个数的补码，否则就等于第二个数
	assign b_mux = ((alucontrol==`EXE_SUB_OP)||(alucontrol==`EXE_SUBU_OP)||(alucontrol==`EXE_SLT_OP))? ~b+1:b;
	//分为三种情况
	//（1）加法，此时就正常+就行
	//（2）减法，此时b_mux等于b的补码这就等效于减法
	//（3）有符号比较，此时b_mux也是补码，下面的式子也是属于减法运算，可以通过判断结果是不是小于0来判断第一个数是不是小于第二个数
	wire[31:0] y_mux;
	assign y_mux =a + b_mux;
	//计算溢出，产生溢出的运算就三种运算，sub,add,addi
	//wire overflow;
	assign overflow=((alucontrol==`EXE_SUB_OP)||(alucontrol==`EXE_ADD_OP)||(alucontrol==`EXE_ADDI_OP))?
						((!a[31] && !b_mux[31]) && (y_mux[31])) || ((a[31] && b_mux[31]) && (!y_mux[31])):0;
	//判断操作数1是否小于操作数2,有符号时
	//（1）a -，b +
	//（2）a +，b +，则进行减法，结果为负数则小于
	//（3）a -, b -，则进行减法，结果为负数则小于
	//无符号是直接比较
	wire lessThan;
	assign lessThan=((alucontrol==`EXE_SLT_OP)||(alucontrol==`EXE_SLTI_OP))?((a[31] && !b[31])||(!a[31] && !b[31] && y_mux[31])||(a[31] && b[31] && y_mux[31])):(a < b);

	// wire signed_div;
	// assign signed_div=(alucontrol==`EXE_DIV_OP)?1'b1:1'b0;
	// reg div_start = 0;
	// reg div_stop;
	// wire div_res_ready;
	// wire[63:0]div_res;
	reg signed_div,div_start;
    wire div_res_ready;
	wire[63:0]div_res;
	
	div div_reg(clk,rst,signed_div,a,b,div_start,0,div_res,div_res_ready);

	wire[31:0] a_not;
	assign a_not = ~a; 

	always@(*)begin
	  div_stallE <= 1'b0;
	  div_start <= 1'b0;
	  case (alucontrol)
		`EXE_AND_OP, `EXE_ANDI_OP : y <= a & b;
        `EXE_OR_OP,  `EXE_ORI_OP  : y <= a | b;
        `EXE_XOR_OP, `EXE_XORI_OP : y <= a ^ b;
        `EXE_NOR_OP : y <= ~(a | b);
        `EXE_LUI_OP : y <= { b[15:0],16'b0 };   

		//shift inst
        `EXE_SLL_OP     : y <= b << sa;
        `EXE_SRL_OP     : y <= b >> sa;
        `EXE_SRA_OP     : y <= ( {32{b[31]}} << (6'd32 - {1'b0,sa}) ) | b >> sa;
        
        `EXE_SLLV_OP    : y <= b << a[4:0]; 
        `EXE_SRLV_OP    : y <= b >> a[4:0];
        `EXE_SRAV_OP    : y <= ( {32{b[31]}} << (6'd32 - {1'b0,a[4:0]}) ) | b >> a[4:0];

		//move inst
		`EXE_MFHI_OP: y <= b;
		`EXE_MFLO_OP: y <= b;
		`EXE_MTHI_OP:begin
		  hiloE[63:32] <= a;
		  hiloE[31:0] <= hilo_iW[31:0];
		end 
		`EXE_MTLO_OP:begin
		  hiloE[31:0] <= a;
		  hiloE[63:32] <= hilo_iW[63:32];
		end 
		`EXE_MULT_OP,`EXE_MULTU_OP : hiloE <= hilo_temp;
		
		`EXE_ADD_OP,`EXE_ADDU_OP,`EXE_ADDI_OP,`EXE_ADDIU_OP : y <= y_mux; //加法运算
		`EXE_SUB_OP,`EXE_SUBU_OP: y <= y_mux; //减法运算
		`EXE_SLT_OP,`EXE_SLTI_OP: begin
		  if(a[31] == 1'b1 && b[31] == 1'b0) y = 1'b1;
          else if(a[31] == 1'b0 && b[31] == 1'b1) y = 1'b0;
          else  y = (a<b)?1'b1:1'b0;
		end
		`EXE_SLTU_OP,`EXE_SLTIU_OP:y=(a<b)?1:0;
		`EXE_DIV_OP,`EXE_DIVU_OP:begin
		  if(div_res_ready==`DivResultNotReady)begin
			div_start <= `DivStart;
			signed_div <= (alucontrol==`EXE_DIV_OP);
			div_stallE <= 1'b1;
			//div_stop <= 1'b0;
		  end else if(div_res_ready==`DivResultReady) begin
			div_start <= `DivStop;
			signed_div <= (alucontrol==`EXE_DIV_OP);
			div_stallE <= 1'b0;
			hiloE <= div_res;
		  end else begin
			div_start <= `DivStop;
			signed_div <= (alucontrol==`EXE_DIV_OP);
			div_stallE <= 1'b0;
		  end
		  //if(flush_except) div_stallE <= 1'b0;		  
		end
		`EXE_LB_OP,`EXE_LBU_OP,`EXE_LH_OP,`EXE_LH_OP,`EXE_LB_OP,`EXE_LHU_OP,`EXE_LW_OP,
                `EXE_SB_OP,`EXE_SH_OP,`EXE_SW_OP: y <= a + b;
		`EXE_MFC0_OP: y <= cp0_iE;
		`EXE_MTC0_OP: y <= b;
		default:hiloE <= hilo_iW;
	  endcase
	end

	//assign div_stallE=(div_start==`DivStart)?1'b1:1'b0;
endmodule
