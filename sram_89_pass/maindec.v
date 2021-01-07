`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
module maindec(
	input wire[5:0] op,
	input wire[5:0] funct,
	input wire[4:0] rsD,rtD,

	output wire memtoreg,memen,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jal,jr,bal,
	output wire hilo_write,hilo_read,hilo_select,
	output reg cp0_write
	//output wire[1:0] aluop
    );
	reg[10:0] controls;
	assign { regwrite,regdst,alusrc,branch,memen,memtoreg,jump,jal,jr,bal,memwrite } = controls;
	// initial begin controls=11'b0_0_0_0_0_0_0_0_0_0_0; end
	reg[2:0] hilo;
	assign {hilo_write,hilo_read,hilo_select}=hilo;
	// initial begin hilo=3'b000; end
	always @(*) begin
		hilo <= 3'b000;
		controls <= 11'b0_0_0_0_0_0_0_0_0_0_0;
		cp0_write <= 1'b0;
		case (op)
			 //logic inst
			 `EXE_ANDI,`EXE_ORI,`EXE_XORI,`EXE_LUI : controls <= 11'b1_0_1_0_0_0_0_0_0_0_0;
			 
			 //arithmetic inst
			 `EXE_SLTI,`EXE_SLTIU,`EXE_ADDI,`EXE_ADDIU : controls <= 11'b1_0_1_0_0_0_0_0_0_0_0;  
			 //J inst
			 `EXE_J: controls <= 11'b0_0_0_0_0_0_1_0_0_0_0;
             `EXE_JAL: controls <= 11'b1_0_0_0_0_0_0_1_0_0_0;

			 //branch inst
			//  `EXE_BEQ: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
            //  `EXE_BGTZ: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
            //  `EXE_BLEZ: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
             `EXE_BEQ,`EXE_BGTZ,`EXE_BLEZ,`EXE_BNE: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
             `EXE_REGIMM_INST:begin
                case(rtD)
                    `EXE_BLTZ,`EXE_BGEZ: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
                    `EXE_BLTZAL,`EXE_BGEZAL: controls <= 11'b1_0_0_1_0_0_0_0_0_1_0;
                    //`EXE_BGEZ: controls <= 11'b0_0_0_1_0_0_0_0_0_0_0;
                    //`EXE_BGEZAL: controls <= 11'b1_0_1_1_0_0_0_0_0_1_0;
                endcase
             end

			 `EXE_LB,`EXE_LBU,`EXE_LH,`EXE_LHU,`EXE_LW: controls <= 11'b1_0_1_0_1_1_0_0_0_0_0;
            //  `EXE_LBU: controls <= 11'b1_0_1_0_1_1_0_0_0_0_0;
            //  `EXE_LH: controls <=  11'b1_0_1_0_1_1_0_0_0_0_0;
            //  `EXE_LHU: controls <= 11'b1_0_1_0_1_1_0_0_0_0_0;
            //  `EXE_LW: controls <=  11'b1_0_1_0_1_1_0_0_0_0_0;
             `EXE_SB,`EXE_SH,`EXE_SW: controls <= 11'b0_0_1_0_1_0_0_0_0_0_1;
            //  `EXE_SH: controls <= 11'b0_0_1_0_1_0_0_0_0_0_1;
            //  `EXE_SW: controls <= 11'b0_0_1_0_1_0_0_0_0_0_1;

			 `EXE_NOP:begin
			   case (funct)
			   		//logic inst
				    `EXE_AND,`EXE_OR,`EXE_XOR,`EXE_NOR:controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;

					//shift inst
            		`EXE_SLL,`EXE_SLLV,`EXE_SRA,`EXE_SRAV,`EXE_SRL,`EXE_SRLV : controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;    

					//move inst
					`EXE_MFHI:begin
					  controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;
					  hilo <= 3'b0_1_1;
					end

					`EXE_MFLO:begin
					  controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;
					  hilo <= 3'b0_1_0;
					end		

					`EXE_MTHI:begin
					  controls <= 11'b0_0_0_0_0_0_0_0_0_0_0;
					  hilo <= 3'b1_0_1; 
					end			

					`EXE_MTLO:begin
					  controls <= 11'b0_0_0_0_0_0_0_0_0_0_0;
					  hilo <= 3'b1_0_0;
					end

					//arithmetic inst
					`EXE_ADD,`EXE_ADDU,`EXE_SUB,`EXE_SUBU,`EXE_SLT,`EXE_SLTU : controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;
			
                    `EXE_MULT,`EXE_MULTU,`EXE_DIV,`EXE_DIVU : begin 
                      controls <= 11'b1_1_0_0_0_0_0_0_0_0_0;
                      hilo <= 3'b1_0_0;   
                    end

					//J inst
					`EXE_JR     : controls <= 11'b0_0_0_0_0_0_1_0_1_0_0;
                    `EXE_JALR   : controls <= 11'b1_1_0_0_0_0_0_0_1_0_0;

			   endcase
			 end
			 6'b010000:case(rsD)
			 	//MFC0
				5'b00000:begin
				  controls <= 11'b1_0_0_0_0_0_0_0_0_0_0;
				  cp0_write <= 1'b0;
				end
				//MTC0
				5'b00100:begin
				  controls <= 11'b0_0_0_0_0_0_0_0_0_0_0;
				  cp0_write <= 1'b1;
				end
			 endcase
		endcase
	end
endmodule
