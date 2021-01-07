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
`include "F:\\HardwareDesign\\axi_test\\rtl\\myCPU\\defines.vh"

module mycpu_top(
	input wire[5:0] int,
	input wire aclk,aresetn,
	
	 // axi port
    //ar
    output wire[3:0] arid,      //read request id, fixed 4'b0
    output wire[31:0] araddr,   //read request address
    output wire[7:0] arlen,     //read request transfer length(beats), fixed 4'b0
    output wire[2:0] arsize,    //read request transfer size(bytes per beats)
    output wire[1:0] arburst,   //transfer type, fixed 2'b01
    output wire[1:0] arlock,    //atomic lock, fixed 2'b0
    output wire[3:0] arcache,   //cache property, fixed 4'b0
    output wire[2:0] arprot,    //protect property, fixed 3'b0
    output wire arvalid,        //read request address valid
    input wire arready,         //slave end ready to receive address transfer
    //r              
    input wire[3:0] rid,        //equal to arid, can be ignored
    input wire[31:0] rdata,     //read data
    input wire[1:0] rresp,      //this read request finished successfully, can be ignored
    input wire rlast,           //the last beat data for this request, can be ignored
    input wire rvalid,          //read data valid
    output wire rready,         //master end ready to receive data transfer
    //aw           
    output wire[3:0] awid,      //write request id, fixed 4'b0
    output wire[31:0] awaddr,   //write request address
    output wire[3:0] awlen,     //write request transfer length(beats), fixed 4'b0
    output wire[2:0] awsize,    //write request transfer size(bytes per beats)
    output wire[1:0] awburst,   //transfer type, fixed 2'b01
    output wire[1:0] awlock,    //atomic lock, fixed 2'b01
    output wire[3:0] awcache,   //cache property, fixed 4'b01
    output wire[2:0] awprot,    //protect property, fixed 3'b01
    output wire awvalid,        //write request address valid
    input wire awready,         //slave end ready to receive address transfer
    //w          
    output wire[3:0] wid,       //equal to awid, fixed 4'b0
    output wire[31:0] wdata,    //write data
    output wire[3:0] wstrb,     //write data strobe select bit
    output wire wlast,          //the last beat data signal, fixed 1'b1
    output wire wvalid,         //write data valid
    input wire wready,          //slave end ready to receive data transfer
    //b              
    input  wire[3:0] bid,       //equal to wid,awid, can be ignored
    input  wire[1:0] bresp,     //this write request finished successfully, can be ignored
    input wire bvalid,          //write data valid
    output wire bready,          //master end ready to receive write response

	//debug signals
	output wire [31:0] debug_wb_pc,
	output wire [3 :0] debug_wb_rf_wen,
	output wire [4 :0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata

    );

	//sram signal
	//cpu inst sram
	wire        inst_sram_en;
	wire [3 :0] inst_sram_wen;
	wire [31:0] inst_sram_addr;
	wire [31:0] inst_sram_wdata;
	wire [31:0] inst_sram_rdata;
	//cpu data sram
	wire        data_sram_en,data_sram_write;
	wire [1 :0] data_sram_size;
	wire [3 :0] data_sram_wen;
	wire [31:0] data_sram_addr;
	wire [31:0] data_sram_wdata;
	wire [31:0] data_sram_rdata;

	// the follow definitions are between controller and datapath.
	// also use some of them  link the IPcores
	wire rst,clk;
	assign clk = aclk;
	assign rst = aresetn;
	// fetch stage
	wire[31:0] pcF;
	wire[31:0] instrF;

	// decode stage
	wire [31:0] instrD;
	wire pcsrcD,jumpD,jalD,jrD,balD,jalrD,branchD,equalD,invalidD;
	wire [1:0] hilo_weD;
	wire [4:0] alucontrolD;
	wire [4:0]rsD,rtD;
	wire cp0_writeD;
	wire [7:0] alucontrolE;
	wire [5:0] opD,functD;

	// execute stage
	wire regdstE,alusrcE;
	wire memtoregE,regwriteE;
	wire flushE,stallE;
	wire hilo_writeE,hilo_readE,hilo_selectE;

	// mem stage
	wire memwriteM,memenM;
	wire[31:0] aluoutM,writedata2M,excepttypeM;
	wire cp0weM;
	wire[31:0] readdataM;
	wire [3:0] sel;
	wire memtoregM,regwriteM;
	wire stallM,flushM;
	wire[31:0] data_address,writedataM_out;
	wire [3:0]we2M;

	// writeback stage
	wire memtoregW,regwriteW;
	wire [31:0] pcW;
	wire [4:0] writeregW;
	wire [31:0] resultW;
	wire flushW,stallW;
	wire[3:0] regwrite3W;


	//cache mux signal
	wire cache_miss,sel_i;
	wire[31:0] i_addr,d_addr,m_addr;
	wire m_fetch,m_ld_st,mem_access;
	wire mem_write,m_st;
	wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
	wire[31:0] mem_st_data,mem_data;
	wire[1:0] mem_size,d_size;// size not use
	wire[3:0] m_sel,d_wen;
	wire stallreq_from_if,stallreq_from_mem;


	// //inst_sram_like
	// wire i_stall;
	// wire inst_req;
	// wire inst_wr;
	// wire [1:0] inst_size;
	// wire [31:0] inst_addr;
	// wire [31:0] inst_wdata;
	// wire inst_addr_ok;
	// wire inst_data_ok;
	// wire [31:0] inst_rdata;
	// wire longest_stall;
	// assign the inst_sram_parameters
	assign inst_sram_en = 1'b1; //always strobe
	assign inst_sram_wen = 4'b0; // always read
	assign inst_sram_addr = pcF; // pc
	assign inst_sram_wdata = 32'b0; // do not need write operation
	assign instrF = inst_sram_rdata; // use your own signal from F stage

	// i_sram_to_sram_like i_sram(
	// 	.clk(clk),.rst(rst),
	// 	.inst_sram_en(inst_sram_en),
	// 	.inst_sram_addr(inst_sram_addr),
	// 	.inst_sram_rdata(inst_sram_rdata),
	// 	.i_stall(i_stall),
	// 	.inst_req(inst_req),
	// 	.inst_wr(inst_wr),
	// 	.inst_size(inst_size),
	// 	.inst_addr(inst_addr),
	// 	.inst_wdata(inst_wdata),
	// 	.inst_addr_ok(inst_addr_ok),
	// 	.inst_data_ok(inst_data_ok),
	// 	.inst_rdata(inst_rdata),
	// 	.longest_stall(longest_stall)
	// );

	// //data_sram_like
	// wire d_stall;
	// wire data_req;
	// wire data_wr;
	// wire [1:0] data_size;
	// wire [31:0] data_addr;
	// wire [31:0] data_wdata;
	// wire [31:0] data_rdata;
	// wire data_addr_ok;
	// wire data_data_ok;
	//assign the data_sram_parameters
	assign data_sram_en = (excepttypeM==32'b0)?memenM:1'b0;// notice: disable the data strobe when exceptions occur
	assign data_sram_write = memwriteM; // 0 read, 1 write
	assign data_sram_wen = we2M;
	assign data_sram_addr = dp.aluoutM;
	assign data_sram_wdata = writedataM_out;
	assign readdataM = data_sram_rdata; // use your own signal from M stage

	// d_sram_to_sram_like d_sram(
	// 	.clk(clk),.rst(rst),
	// 	.data_sram_en(data_sram_en),
	// 	.data_sram_addr(data_sram_addr),
	// 	.data_sram_rdata(data_sram_rdata),
	// 	.data_sram_wen(data_sram_wen),
	// 	.data_sram_wdata(data_sram_wdata),
	// 	.d_stall(d_stall),
	// 	.data_req(data_req),
	// 	.data_wr(data_wr),
	// 	.data_size(data_size),
	// 	.data_addr(data_addr),
	// 	.data_wdata(data_wdata),
	// 	.data_rdata(data_rdata),
	// 	.data_addr_ok(data_addr_ok),
	// 	.data_data_ok(data_data_ok),
	// 	.longest_stall(longest_stall)
	// );


	

	

	//assign the trace parameters
	assign debug_wb_pc = pcW;
	assign debug_wb_rf_wen = regwrite3W;
	assign debug_wb_rf_wnum = writeregW;
	assign debug_wb_rf_wdata = resultW;


	wire[39:0] ascii;
    instdec transfer(inst_sram_rdata,ascii);
	wire stallD;
	// these modules use your own
	controller c(
		.clk(clk),.rst(~rst),
		.opD(opD),.functD(functD),
		.pcsrcD(pcsrcD),.branchD(branchD),.jumpD(jumpD),
		.equalD(equalD),.jalD(jalD),.jrD(jrD),.balD(balD),
		.rsD(rsD),.rtD(rtD),
		.cp0_writeD(cp0_writeD),.invalid_instD(invalidD),
		.stallD(stallD),
		//execute stage
		.flushE(flushE),.stallE(stallE),
		.memtoregE(memtoregE),.alusrcE(alusrcE),
		.regdstE(regdstE),.regwriteE(regwriteE),
		.alucontrolE(alucontrolE),
		.hilo_writeE(hilo_writeE),.hilo_readE(hilo_readE),.hilo_selectE(hilo_selectE),
		//mem stage
		.stallM(stallM),.flushM(flushM),
		.memtoregM(memtoregM),.memwriteM(memwriteM),
		.regwriteM(regwriteM),.memenM(memenM),
		//write back stage
		.memtoregW(memtoregW),.regwriteW(regwriteW),
		.stallW(stallW),.flushW(flushW)
	);
	datapath dp(
		.clk(clk),.rst(~rst),
		.int_n_i(6'b000000),.pcF(pcF),
		.instrF(instrF),.pcsrcD(pcsrcD),.branchD(branchD),
		.jumpD(jumpD),.equalD(equalD),.opD(opD),.functD(functD),
		.jalD(jalD),.jrD(jrD),.balD(balD),.rsD(rsD),.rtD(rtD),
		.cp0_writeD(cp0_writeD),.invalid_instD(invalidD),
		.stallD(stallD),
		//execute stage
		.memtoregE(memtoregE),.alusrcE(alusrcE),.regdstE(regdstE),
		.regwriteE(regwriteE),.alucontrolE(alucontrolE),
		.flushE(flushE),.stallE(stallE),
		.hilo_writeE(hilo_writeE),.hilo_readE(hilo_readE),.hilo_selectE(hilo_selectE),
		//mem stage
		.memtoregM(memtoregM),.regwriteM(regwriteM),
		.data_address(data_address),.writedataM_out(writedataM_out),
		.readdataM(readdataM),.memenM(memenM),
		.we2M(we2M),.stallM(stallM),.flushM(flushM),
		//write back stage
		.memtoregW(memtoregW),.regwriteW(regwriteW),
		.stallW(stallW),.flushW(flushW),
		//debug
		.pcW(pcW),.regwrite3W(regwrite3W),.writeregW(writeregW),.resultW(resultW),

		//excepttypeM
		.excepttypeM(excepttypeM),
		.i_stall(stallreq_from_if),
		.d_stall(stallreq_from_mem)
	);
	wire[31:0] m_i_addr;
	reg[3:0] p_ren;
	always @(*) begin
		p_ren<=4'b0000;
		case(alucontrolE)
			`EXE_LB_OP,`EXE_LBU_OP:begin
			  case(data_address[1:0])
			  	2'b00:p_ren<=4'b0001;
			  	2'b01:p_ren<=4'b0010;
			  	2'b10:p_ren<=4'b0100;
			  	2'b11:p_ren<=4'b1000;
			  endcase
			end
			`EXE_LH_OP,`EXE_LHU_OP:begin
			  case(data_address[1:0])
			  	2'b00:p_ren<=4'b0011;
				2'b10:p_ren<=4'b1100;
			  endcase
			end
			`EXE_LW_OP:p_ren<=4'b1111;
			default:p_ren <= 4'b1111;
		endcase
	end
	wire m_i_rw;
	wire[31:0] m_i_din;
	inst_cache#(32,15) i_cache(
		.clk(clk),.clrn(rst),
		.p_a(inst_sram_addr),
		.p_din(inst_sram_rdata),
		.p_strobe(inst_sram_en),
		.p_rw(1'b0),
		.p_ready(i_ready),
		.m_a(m_i_addr),
		.m_dout(mem_data),
		.m_din(m_i_din),
		.m_strobe(m_fetch),
		.m_rw(m_i_rw),
		.m_ready(m_i_ready)
	);
	wire[31:0] m_d_addr;
	wire m_rw;
	wire [1:0]m_d_size;
	//记得No cache
	data_cache#(32,15) d_cache(
		.clk(clk),.clrn(rst),
		.p_a(data_sram_addr),
		.p_din(data_sram_rdata),
		.p_dout(data_sram_wdata),
		.p_strobe(data_sram_en),
		.p_rw(data_sram_write),
		.p_ready(d_ready),
		.p_wen(data_sram_wen),
		.p_ren(p_ren),
		.m_a(m_d_addr),
		.m_dout(mem_data),
		.m_din(mem_st_data),
		.m_strobe(m_ld_st),
		.m_rw(m_rw),
		.m_ready(m_d_ready),
		.m_size(m_d_size)
	);

	// // use a inst_miss signal to denote that the instruction is not loadssss
	// reg inst_miss;
	// always @(posedge clk) begin
	// 	if (~aresetn) begin
	// 		inst_miss <= 1'b1;
	// 	end
	// 	if (m_i_ready & inst_miss) begin // fetch instruction ready
	// 		inst_miss <= 1'b0;
	// 	end else if (~inst_miss & data_sram_en) begin // fetch instruction ready, but need load data, so inst_miss maintain 0
	// 		inst_miss <= 1'b0;
	// 	end else if (~inst_miss & data_sram_en & m_d_ready) begin //load data ready, set inst_miss to 1
	// 		inst_miss <= 1'b1;
	// 	end else begin // other conditions, set inst_miss to 1
	// 		inst_miss <= 1'b1;
	// 	end
	// end

	assign sel_i  = data_sram_en?0:1;	// use inst_miss to select access memory(for load/store) or fetch(each instruction)
	assign d_addr = ((m_d_addr[31:29] != 3'b100)||(m_d_addr!=3'b101)) ?
						 m_d_addr : {3'b000,m_d_addr[28:0]}; // modify data address, to get the data from confreg
	assign i_addr = m_i_addr;
	assign m_addr = sel_i ? i_addr : d_addr;
	// 
	// assign m_fetch = inst_sram_en & inst_miss; //if inst_miss equals 0, disable the fetch strobe
	// assign m_ld_st = data_sram_en;

	// assign inst_sram_rdata = mem_data;
	// assign data_sram_rdata = mem_data;
	// assign mem_st_data = data_sram_wdata;
	// use select signal
	assign mem_access = sel_i ? m_fetch : m_ld_st; 
	assign mem_size = sel_i ? 2'b10 : m_d_size;
	assign m_sel = sel_i ? 4'b1111 : data_sram_wen;
	assign mem_write = sel_i ? 1'b0 : m_rw;

	//demux
	assign m_i_ready = mem_ready &  sel_i;
	assign m_d_ready = mem_ready & ~sel_i;

	//
	assign stallreq_from_if = ~m_i_ready;
	assign stallreq_from_mem = data_sram_en & ~m_d_ready;


	axi_interface interface(
		.clk(aclk),
		.resetn(aresetn),
		
		 //cache/cpu_core port
		.mem_a(m_addr),
		.mem_access(mem_access),
		.mem_write(mem_write),
		.mem_size(mem_size),
		.mem_sel(m_sel),
		.mem_ready(mem_ready),
		.mem_st_data(mem_st_data),
		.mem_data(mem_data),
		// add a input signal 'flush', cancel the memory accessing operation in axi_interface, do not need any extra design. 
		.flush(|excepttypeM), // use excepetion type

		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),
					
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),
				
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    )
	);
endmodule
