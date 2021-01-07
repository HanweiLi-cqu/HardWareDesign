`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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
module datapath(
	input wire clk,rst,
	input [5:0] int_n_i,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,
	output wire equalD,
	output wire[5:0] opD,functD,
	input wire jalD,jrD,balD,
	output [4:0] rsD,rtD,
	input wire cp0_writeD,invalid_instD,
	output wire stallD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[7:0] alucontrolE,
	output wire flushE,stallE,
	input wire hilo_writeE,hilo_readE,hilo_selectE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] data_address,writedataM_out,
	input wire[31:0] readdataM,
	input wire memenM,
	output wire [3:0]we2M,
	output wire stallM,flushM,
	output wire [31:0] excepttypeM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire stallW,flushW,

	//debug
	output wire[31:0] pcW,
	output wire[3:0] regwrite3W,
	output wire [4:0] writeregW,
	output wire[31:0] resultW,

	input wire i_stall,
	input wire d_stall
    );
	wire regwrite2W;
	assign regwrite3W = {4{regwrite2W}};
	//assign regwrite2W={4{regwriteW}};
	wire[31:0] aluoutM;
	reg[31:0] newpc;
	//assign data_address = (aluoutM==32'h7fff_ffff)?32'h0000_0000:(aluoutM==32'h9fff_ffff)?32'h0000_0000:aluoutM;
	//assign data_address = (aluoutM[31:16] != 16'hbfaf) ? aluoutM : {16'h1faf,aluoutM[15:0]};
	assign data_address = (aluoutM[31:29]==3'b100 || aluoutM[31:29]==3'b101)?{3'b0,aluoutM[28:0]}:aluoutM;
	wire next_in_delayslot_o,is_in_delayslot_iD,is_in_delayslot_E,is_in_delayslot_M,is_in_delayslot_W;
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD1,pcnextFD2,pcnextbrFD,pcplus4F,pcbranchD;
	//decode stage
	wire [31:0] pcplus4D,instrD;
	wire [1:0]forwardaD,forwardbD;
	wire [4:0] rdD;
	wire flushD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire jalE,balE,jrE;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	//mem stage
	wire jalM,balM,jrM;
	wire [4:0] writeregM;
	//writeback stage
	wire [63:0] hilo_iW,hilo_oW;
	
	wire [31:0] aluoutW,readdataW;

	//hazard detection
	wire hilo_writeM;
	wire hilo_writeW;
	wire [1:0]forward_hilo;
	wire div_stallE;
	wire branchFlushD;
	wire[4:0] writeregE_al;
	//wire stallM,flushM;
	wire cp0_writeM;
	wire forwardcp0E;
	wire[4:0] rdM;
	//wire flushW;
	//wire stallE;
	hazard h(
		//fetch stage
		stallF,flushF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,flushD,jumpD,jalD,balD,jrD,
		branchFlushD,
		//execute stage
		rsE,rtE,
		writeregE_al,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,cp0_writeM,rdE,forwardcp0E,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		stallM,excepttypeM,flushM,rdM,
		//write back stage
		writeregW,
		regwriteW,
		stallW,flushW,
		//hilo
		hilo_readE,hilo_writeM,hilo_writeW,
		forward_hilo,
		div_stallE,
		stallE,

		i_stall,
		d_stall
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		(jumpD|jalD)&(!jrD),pcnextFD1);

	mux2 #(32) j_r_type(pcnextFD1,srca2D,jrD,pcnextFD2);//根据jr指令会将rs设置为pc值
	//regfile (operates in decode and writeback)
	assign regwrite2W = regwriteW;
	regfile rf(clk,regwrite2W,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,flushF,pcnextFD2,newpc,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	wire[7:0] exceptF;
	assign exceptF=(pcF[1:0]==2'b00)?8'b00000000:8'b10000000;
	wire[7:0]exceptD;
	flopenrc #(8) except_FD(clk,rst,~stallF,flushF,exceptF,exceptD);
	//decode stage
	wire[31:0]pcD;
	flopenrc #(32) pc_FD(clk,rst,~stallD,flushD,pcF,pcD);
	flopenr #(32) r1D(clk,rst,~stallD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) delaySlot_FD(clk,rst,~stallD,flushD,next_in_delayslot_o,is_in_delayslot_iD);
	signext se(instrD[15:0],instrD[29:28],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	// mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	// mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	wire[31:0] aluoutE_new;
	mux4 #(32) forwardamux(srcaD,aluoutE_new,aluoutM,resultW,forwardaD,srca2D);//前推来使得jal地址没有数据冒险
	mux4 #(32) forwardbmux(srcbD,aluoutE_new,aluoutM,resultW,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,rtD,opD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	wire [4:0] saD;
	assign saD = instrD[10:6];//移位指令的移位位数
	wire syscallD;
	wire breakD;
	wire eretD;
	assign syscallD = (opD == `EXE_NOP && functD == `EXE_SYSCALL) & (~stallD);
	assign breakD = (opD == `EXE_NOP && functD == `EXE_BREAK)&(~stallD);
	assign eretD = (instrD == `EXE_ERET)&(~stallD);
	assign next_in_delayslot_o =  branchD | jrD | jumpD | jalD;
	wire invalid_inst2D;
	mux2 #(1) invalideret(invalid_instD,1'b0,eretD,invalid_inst2D);//如果中断例外返回的话就不需要invalid


	//execute stage
	wire[4:0] saE;
	wire [31:0] pcplus8E;
	wire[31:0] pcE;
	wire cp0_writeE;
	//wire[31:0] pc_except_E;
	wire invalid_instE;
	wire[7:0] exceptE;
	flopenrc #(32) pc_DE(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(8) except_DE(clk,rst,~stallE,flushE,
	{exceptD[7],syscallD,breakD,invalid_inst2D,exceptD[3],eretD,exceptD[1:0]},
	exceptE);

	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srca2D,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcb2D,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(1) jr_DE(clk,rst,~stallE,flushE,jrD,jrE);
	flopenrc #(32) chose_pcpluse8(clk,rst,~stallE,flushE,pcplus4D+3'b100,pcplus8E);//为jalr类的指令服务
	flopenrc #(1) bal_DE(clk,rst,~stallE,flushE,balD,balE);
	flopenrc #(5) sa_DE(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(1) jal_DE(clk,rst,~stallE,flushE,jalD,jalE);//传递j，b
	flopenrc #(1) cp0_write_DE(clk,rst,~stallE,flushE,cp0_writeD,cp0_writeE);
	flopenrc #(1) delaySlot_DE(clk,rst,~stallE,flushE,is_in_delayslot_iD,is_in_delayslot_E);
	//flopenrc #(32) pc_except_FE(clk,rst,~stallE,flushE,pcF,pc_except_E);
	flopenrc #(1) invalid_inst_DE(clk,rst,~stallE,flushE,invalid_inst2D,invalid_instE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);

	wire [63:0] hilo_aluOutE;//hilo_aluOutE的输入
	wire [31:0] chosed_hi_lo;//被选择的hi或者lo
	wire [31:0] srcb4E;//最终ALU的b端的输入
	wire [63:0] hilo_aluIn;//选择到底哪个阶段的hilo作为读入的值
	wire[63:0] hilo_aluOutM;
	mux3 #(64) which_stage_hilo(hilo_oW,hilo_aluOutM,hilo_iW,forward_hilo,hilo_aluIn);
	mux2 #(32) hi_or_lo(hilo_aluIn[31:0],hilo_aluIn[63:32],hilo_selectE,chosed_hi_lo);
	mux2 #(32) hilo_or_b(srcb3E,chosed_hi_lo,hilo_readE,srcb4E);
	wire overflow;
	wire [31:0]cp0_iE,cp0_oW;
	
	mux2 #(32) foardcp0mux(cp0_oW,aluoutM,forwardcp0E,cp0_iE);
	alu alu(clk,rst,srca2E,srcb4E,alucontrolE,aluoutE,saE,hilo_oW,hilo_aluOutE,div_stallE,flushF,overflow,cp0_iE);//输入hilo_iW是因为如果要修改hi，就修改它就像，回写又会写回寄存器
	
	
	
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	mux2 #(5) jmux(writeregE,5'b11111,jalE|balE,writeregE_al);//al类型选择31号寄存器
	mux2 #(32) j_pc_mux(aluoutE,pcplus8E,jalE|balE|jrE,aluoutE_new);//al型，jr类型没regwrite所以可以写jrE

	//mem stage
	wire[31:0] pcM;
	
	flopenrc #(32) pc_EM(clk,rst,~stallM,flushM,pcE,pcM);

	wire[7:0] alucontrolM;
	
	
	
	wire[31:0]writedataM;
	
	wire[31:0] pc_except_M;
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE_new,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE_al,writeregM);
	flopenrc #(64) hilo_aluOut_EM(clk,rst,~stallM,flushM,hilo_aluOutE,hilo_aluOutM);
	flopenrc #(1) hilo_write_EM(clk,rst,~stallM,flushM,hilo_writeE,hilo_writeM);
	flopenrc #(8) alucontrol_EM(clk,rst,~stallM,flushM,alucontrolE,alucontrolM);
	flopenrc #(1) cp0_write_EM(clk,rst,~stallM,flushM,cp0_writeE,cp0_writeM);
	flopenrc #(5) rd_EM(clk,rst,~stallM,flushM,rdE,rdM);
	flopenrc #(1) delaySlot_EM(clk,rst,~stallM,flushM,is_in_delayslot_E,is_in_delayslot_M);
	//flopenrc #(32) pc_except_EM(clk,rst,~stallM,flushM,pc_except_E,pc_except_M);
	

	wire [3:0]weM;
	wire[7:0] exceptM;
	wire [31:0]data_outM;
	wire adel,ades;
	write_mem wm(alucontrolM,aluoutM,writedataM,weM,writedataM_out,ades);//写存储器
	read_mem rm(alucontrolM,aluoutM,readdataM,data_outM,adel);//读存储器
	mux2 #(4) writeable(weM,4'b0000,ades,we2M);//如果写触发例外了一个都不写
	mux2 #(32) res1mux(aluoutM,data_outM,memtoregM,resultM);
	flopenrc #(8) except_EM(clk,rst,~stallM,flushM,{exceptE[7:4],overflow,exceptE[2],adel,ades},exceptM);
	
	flopenrc #(32) pc_MW(clk,rst,~stallW,flushW,pcM,pcW);
	flopenrc #(1) hilo_write_MW(clk,rst,~stallW,flushW,hilo_writeM,hilo_writeW);
	flopenrc #(64) hilo_aluOut_MW(clk,rst,~stallW,flushW,hilo_aluOutM,hilo_iW);
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,data_outM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	//flopr #(1) delaySlot_MW(clk,rst,is_in_delayslot_M,is_in_delayslot_W);
	//flopr #(32) pc_except_MW(clk,rst,pc_except_M,pc_except_W);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);
	//flopr #(1) r13W(clk,rst,flushM,flushW);

	//write hilo 
	hilo_reg hilo(clk,rst,hilo_writeW,
		hilo_iW[63:32],hilo_iW[31:0],
		hilo_oW[63:32],hilo_oW[31:0]);

	//异常处理
	wire[31:0] bad_addr_i;
	mux3 #(32) badaddr(32'h00000000,pcM,aluoutM,{adel|ades,exceptM[7]},bad_addr_i);
	reg[31:0] status_i,cause_i,epc_i;
	wire[31:0] status_o,cause_o,epc_o;
	wire[31:0] count_o,compare_o,config_o,prid_o,badvaddr;
	always @(*)begin
	   if(rst == 1'b1) begin 
	       status_i = `ZeroWord;
		   cause_i = `ZeroWord;
		   epc_i = `ZeroWord;
	   end
	   else begin
	       epc_i = epc_o;
	       cause_i = cause_o;
	       status_i = status_o;
	   end
	end
	
	//wire [5:0] int_i = 6'b0;
	wire timer_int_o;
	exception exception0(rst,{exceptM[7:2],adel,ades},status_i,cause_i,excepttypeM);
	cp0_reg cp0(clk,rst,cp0_writeM,rdM,rdE,aluoutM,
	int_n_i,excepttypeM,pcM,is_in_delayslot_M,bad_addr_i,
	cp0_oW,count_o,compare_o,status_o,cause_o,epc_o,config_o,prid_o,badvaddr,timer_int_o);

	always @(*)begin
	   newpc = 32'b0;
	   if(excepttypeM != 0) begin
	       case(excepttypeM)
	           32'h00000001:newpc = 32'hbfc00380;
	           32'h00000004:newpc = 32'hbfc00380;
	           32'h00000005:newpc = 32'hbfc00380;
	           32'h00000008:newpc = 32'hbfc00380;
	           32'h00000009:newpc = 32'hbfc00380;
	           32'h0000000a:newpc = 32'hbfc00380;
	           32'h0000000c:newpc = 32'hbfc00380;
	           32'h0000000e:newpc = epc_i;
	       endcase
	   end
	end

	

endmodule
