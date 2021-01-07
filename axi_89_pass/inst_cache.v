`timescale 1ns / 1ps
module inst_cache #(parameter A_WIDTH=32,parameter C_INDEX = 6)(
    input[A_WIDTH-1:0] p_a,//CPU数据
    input[31:0]        p_dout,//CPU输出数据
    output[31:0]       p_din,//Cache传输给CPU的数据
    input              p_strobe,//为1则可读写
    input              p_rw,//0:read,1:write
    output             p_ready,//通知CPU准备好了
    //input              flush_except,

    input              clk,
    input              clrn,

    output[A_WIDTH-1:0] m_a,//内存地址
    input[31:0]         m_dout,//内存返回数据
    output[31:0]        m_din,//输入内存数据
    output              m_strobe,
    output              m_rw,
    input               m_ready
);
    localparam T_WIDTH =A_WIDTH - C_INDEX -2;
    reg                   d_valid[0:(1<<C_INDEX)-1];
    reg  [T_WIDTH-1:0]    d_tags [0:(1<<C_INDEX)-1];
    reg  [31:0]           d_data [0:(1<<C_INDEX)-1];
    wire [C_INDEX-1:0]    index = p_a[C_INDEX+1:2];
    wire [T_WIDTH-1:0]    tag = p_a[A_WIDTH-1 : C_INDEX+2];

    //read from cache
    wire valid =d_valid[index];
    wire[T_WIDTH-1:0] tagout=d_tags[index];
    wire[31:0] c_dout=d_data[index];

    //cache control
    wire cache_hit  = valid & (tagout == tag);//hit
    wire cache_miss = ~cache_hit;
    wire c_write    = p_rw | cache_miss&m_ready;
    wire sel_in     = p_rw;
    wire sel_out    = cache_hit;
    wire[31:0]c_din = sel_in ?p_dout : m_dout;
    assign p_din    = sel_out?c_dout : m_dout;
    assign m_din    = p_dout;
    assign m_a      = p_a;
    assign m_rw     = p_strobe & p_rw;//write through
    assign m_strobe = p_strobe & (p_rw | cache_miss);
    assign p_ready  = ~p_rw & cache_hit | ((cache_miss | p_rw) & m_ready);
    //cache准备好数据
    //1.读，命中
    //2.缺失但是存储那边已经得到了
    //3.因为是写直达所以一旦写就是写mem，然后mem ready那cache就ready
    
    integer i;
    always @(posedge clk or negedge clrn)begin
      if(clrn == 0)begin
          for(i = 0;i<(1<<C_INDEX);i=i+1)
            d_valid[i] <= 1'b0;
        end else if (c_write) begin
            d_valid[index] <= 1'b1;
        end
    end

    always @(posedge clk ) begin
        d_tags[index] <= tag;
        d_data[index] <= c_din;
    end

endmodule