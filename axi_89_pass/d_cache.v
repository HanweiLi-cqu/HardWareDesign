module d_cache (
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
//                                    root(used_block[index][0])
//                                              /   \
//                                           0 /     \ 1
//                                            /       \
//                    node1(used_block[index][1])    node2(used_block[index][2])
//                              /          \           /          \
//                          0 /            \ 1      0 /            \ 1
//                          /              \         /              \
//                       cache0         cache1     cache2          cache3
//            

//               | 使用的块 | used_block[index][0] | used_block[index][1] | used_block[index][2] |
//               | cache0  |        1             |         1            |                      |
//               | cache1  |        1             |         0            |                      |
//               | cache2  |        0             |                      |         1            |
//               | cache3  |        0             |                      |         0            |
//
//
    //Cache配置
    parameter  INDEX_WIDTH  = 8, OFFSET_WIDTH = 2;//这里使用的INDEX长度为8是因为把cache分成四个块，来达到相同容量下性能的比较
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
    //Cache存储单元
    reg                 cache_valid [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty [CACHE_DEEPTH - 1 : 0];//判断cache_line是否是脏位。

    reg                 cache_valid_1 [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_1   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_1 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_1 [CACHE_DEEPTH - 1 : 0];//判断cache_line是否是脏位。

    reg                 cache_valid_2 [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_2   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_2 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_2 [CACHE_DEEPTH - 1 : 0];//判断cache_line是否是脏位。

    reg                 cache_valid_3 [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag_3   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block_3 [CACHE_DEEPTH - 1 : 0];
    reg                 cache_dirty_3 [CACHE_DEEPTH - 1 : 0];//判断cache_line是否是脏位。

    wire[1:0]                 chose_block;//选择的块
    reg [2:0]            used_block [CACHE_DEEPTH - 1 : 0];//记录最近使用的块
    wire[2:0]            used_block_in;
    
    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    assign used_block_in=used_block[index];
    //访问Cache line
    wire c_valid;
    wire [TAG_WIDTH-1:0] c_tag;
    wire [31:0] c_block;
    wire c_dirty;

    wire c_valid_1;
    wire [TAG_WIDTH-1:0] c_tag_1;
    wire [31:0] c_block_1;
    wire c_dirty_1;

    wire c_valid_2;
    wire [TAG_WIDTH-1:0] c_tag_2;
    wire [31:0] c_block_2;
    wire c_dirty_2;

    wire c_valid_3;
    wire [TAG_WIDTH-1:0] c_tag_3;
    wire [31:0] c_block_3;
    wire c_dirty_3;

    wire c_valid_final;
    wire [TAG_WIDTH-1:0] c_tag_final;
    wire [31:0] c_block_final;
    wire c_dirty_final;

    assign c_valid = cache_valid[index];
    assign c_tag   = cache_tag  [index];
    assign c_block = cache_block[index];
    assign c_dirty = cache_dirty[index];

    assign c_valid_1 = cache_valid_1[index];
    assign c_tag_1   = cache_tag_1  [index];
    assign c_block_1 = cache_block_1[index];
    assign c_dirty_1 = cache_dirty_1[index];

    assign c_valid_2 = cache_valid_2[index];
    assign c_tag_2   = cache_tag_2  [index];
    assign c_block_2 = cache_block_2[index];
    assign c_dirty_2 = cache_dirty_2[index];

    assign c_valid_3 = cache_valid_3[index];
    assign c_tag_3   = cache_tag_3  [index];
    assign c_block_3 = cache_block_3[index];
    assign c_dirty_3 = cache_dirty_3[index];


    //判断是否命中
    wire hit, miss;
    assign hit = c_valid & (c_tag == tag);  //cache line的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;
    
    wire hit_1,miss_1;
    assign hit_1 = c_valid_1 & (c_tag_1 == tag);
    assign miss_1 = ~hit_1;

    wire hit_2,miss_2;
    assign hit_2 = c_valid_2 & (c_tag_2 == tag);
    assign miss_2 = ~hit_2;

    wire hit_3,miss_3;
    assign hit_3 = c_valid_3 & (c_tag_3 == tag);
    assign miss_3 = ~hit_3;

    wire hit_final;
    wire miss_final;
    wire all_valid;//判断是否都是有效的
    wire[1:0] invalid_cache;//如果不都是有效的，选取无效的块，这样的话，你就不会将原本读进来的数据替换掉以前的有效的块（即有数据）
                            //也就是说增加了cache的空间利用率，提高命中几率。
    assign all_valid = c_valid & c_valid_1 & c_valid_2 & c_valid_3;
    assign chose_block    =  hit?0:
                             hit_1?1:
                             hit_2?2:
                             hit_3?3:
                             all_valid?(used_block[index][0]?(used_block[index][2]?3:2):(used_block[index][1]?1:0)):
                             (c_valid?(c_valid_1?(c_valid_2?(c_valid_3?0:3):2):1):0);
                             
    assign hit_final      =  hit|hit_1|hit_2|hit_3;
    assign miss_final     =  ~hit_final;
    assign c_valid_final  =  (chose_block==0)?c_valid : ((chose_block==1) ? c_valid_1: ((chose_block==2) ?c_valid_2 : c_valid_3));
    assign c_tag_final    =  (chose_block==0)?c_tag :   ((chose_block==1) ? c_tag_1:   ((chose_block==2) ?c_tag_2   : c_tag_3));
    assign c_block_final  =  (chose_block==0)?c_block : ((chose_block==1) ? c_block_1: ((chose_block==2) ?c_block_2 : c_block_3));
    assign c_dirty_final  =  (chose_block==0)?c_dirty : ((chose_block==1) ? c_dirty_1: ((chose_block==2) ?c_dirty_2 : c_dirty_3));

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE:   state <= cpu_data_req & miss_final? c_dirty_final?WM:RM : IDLE;
                RM:     state <= cache_data_data_ok ? IDLE : RM;
                WM:     state <= cache_data_data_ok ? RM : WM;
            endcase
        end
    end

    //读内存
    //变量read_req, addr_rcv, read_finish用于构造类sram信号。
    wire read_req;      //一次完整的读事务，从发出读请求到结束
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    assign read_req = state==RM;
    assign read_finish = read_req & cache_data_data_ok;

    //写内存
    wire write_req;          
    wire write_finish;
    assign write_req = state==WM;
    assign write_finish = write_req & cache_data_data_ok;

    //output to mips core
    assign cpu_data_rdata   = hit_final ? c_block_final : cache_data_rdata;
    assign cpu_data_addr_ok = cpu_data_req & hit_final | read_req & cache_data_addr_ok;
    assign cpu_data_data_ok = cpu_data_req & hit_final | read_req & cache_data_data_ok;

    //锁存状态，接受地址后持续状态，如果不这样做可能会导致req这些只拉低一部分又弹回来继续发送请求。
    reg  addr_rcv;
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                     cache_data_req & cache_data_addr_ok ? 1'b1 :
                     cache_data_data_ok ? 1'b0 : addr_rcv;
    end

    //output to axi interface
    assign cache_data_req   = (read_req & ~addr_rcv) | (write_req & ~addr_rcv);//只要是RM、WM就涉及到对内存的访问，当然是在data_ok后要拉低req，因为数据握手成功
    assign cache_data_wr    = (state==WM) ;//只有WM才能写内存
    assign cache_data_size  = 2'b10;//因为涉及到cache写入内存都是将整块写进去，而不是只写一部分。
    assign cache_data_addr  = cache_data_wr?{c_tag_final,index,2'b00}:{cpu_data_addr[31:2], 2'b00};//选择写入的脏数据的地址还是cpu给的地址。这里选择2'b00是因为是为了写入四个字，直接将一个块写入
    assign cache_data_wdata = c_block_final;

    //缺失的情况，必须先把它们保存起来，即read_finish后改变的东西都是要进行保存的。
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    reg [31:0] wdata_save;
    reg wr_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
        wdata_save <= rst ? 0 :
                      cpu_data_req ? cpu_data_wdata : wdata_save;
        wr_save <= rst ? 0 :
                      cpu_data_req ? cpu_data_wr : wr_save;
    end

    wire [31:0] write_cache_data_miss;
    wire [31:0] write_cache_data_hit;
    wire [3:0] write_mask;

    //根据地址低两位和size，生成写掩码（针对sb，sh等不是写完整一个字的指令），4位对应1个字（4字节）中每个字的写使能
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //掩码的使用：位为1的代表需要更新的。
    //位拓展：{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data_miss = cache_data_rdata & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              wdata_save & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};
    
    assign write_cache_data_hit = c_block_final & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    integer t;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache置为无效
                cache_valid[t] <= 0;
                cache_dirty[t] <= 0;
                cache_valid_1[t] <= 0;
                cache_dirty_1[t] <= 0;
                cache_valid_2[t] <= 0;
                cache_dirty_2[t] <= 0;
                cache_valid_3[t] <= 0;
                cache_dirty_3[t] <= 0;
                used_block[t]    <= 0;
            end
            
        end
        else begin
            if(read_finish) begin
                if(chose_block==1)begin
                    cache_valid_1[index_save] <= 1'b1;             
                    cache_tag_1  [index_save] <= tag_save;
                    cache_block_1[index_save] <= wr_save? write_cache_data_miss : cache_data_rdata; //RM状态下，如果是WM传递过来的则将write_cache_data给他。如果本来就是RM，那就直接取cache_data_rdata
                    cache_dirty_1[index_save] <= wr_save? 1'b1 : 1'b0;
                    used_block [index_save][0] <= 1;
                    used_block [index_save][1] <= 0;
                end
                else if(chose_block==0)begin
                    cache_valid[index_save] <= 1'b1;             
                    cache_tag  [index_save] <= tag_save;
                    cache_block[index_save] <= wr_save? write_cache_data_miss : cache_data_rdata; //RM状态下，如果是WM传递过来的则将write_cache_data给他。如果本来就是RM，那就直接取cache_data_rdata
                    cache_dirty[index_save] <= wr_save? 1'b1 : 1'b0;
                    used_block [index_save][0] <= 1;
                    used_block [index_save][1] <= 1;
                end
                else if(chose_block==2)begin
                    cache_valid_2[index_save] <= 1'b1;             
                    cache_tag_2  [index_save] <= tag_save;
                    cache_block_2[index_save] <= wr_save? write_cache_data_miss : cache_data_rdata; //RM状态下，如果是WM传递过来的则将write_cache_data给他。如果本来就是RM，那就直接取cache_data_rdata
                    cache_dirty_2[index_save] <= wr_save? 1'b1 : 1'b0;
                    used_block [index_save][0] <= 0;
                    used_block [index_save][2] <= 1;
                end
                else if(chose_block==3)begin
                    cache_valid_3[index_save] <= 1'b1;             
                    cache_tag_3  [index_save] <= tag_save;
                    cache_block_3[index_save] <= wr_save? write_cache_data_miss : cache_data_rdata; //RM状态下，如果是WM传递过来的则将write_cache_data给他。如果本来就是RM，那就直接取cache_data_rdata
                    cache_dirty_3[index_save] <= wr_save? 1'b1 : 1'b0;
                    used_block [index_save][0] <= 0;
                    used_block [index_save][2] <= 0;
                end
            end
            if(cpu_data_req & hit_final) begin
                if (cpu_data_wr) begin
                    if(chose_block==1)begin
                        cache_block_1[index] <= write_cache_data_hit;
                        cache_dirty_1[index] <= 1'b1;
                        used_block [index][0] <= 1;
                        used_block [index][1] <= 0;
                    end
                    else if(chose_block==0)begin
                        cache_block[index] <= write_cache_data_hit;
                        cache_dirty[index] <= 1'b1;
                        used_block [index][0] <= 1;
                        used_block [index][1] <= 1;
                    end
                    else if(chose_block==2)begin
                        cache_block_2[index] <= write_cache_data_hit;
                        cache_dirty_2[index] <= 1'b1;
                        used_block [index][0] <= 0;
                        used_block [index][2] <= 1;
                    end
                    else if(chose_block==3)begin
                        cache_block_3[index] <= write_cache_data_hit;
                        cache_dirty_3[index] <= 1'b1;
                        used_block [index][0] <= 0;
                        used_block [index][2] <= 0;
                    end
                end
                else begin
                    if(chose_block==1)begin
                        used_block[index][0] <= 1;
                        used_block[index][1] <= 0;
                    end
                    else if(chose_block==0)begin
                        used_block[index][0] <= 1;
                        used_block[index][1] <= 1;
                    end
                    else if(chose_block==2)begin
                        used_block[index][0] <= 0;
                        used_block[index][2] <= 1;
                    end
                    else if(chose_block==3)begin
                        used_block[index][0] <= 0;
                        used_block[index][2] <= 0;
                    end
                end
            end
        end
    end
endmodule