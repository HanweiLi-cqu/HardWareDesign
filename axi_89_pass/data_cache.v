`timescale 1ns / 1ps
module data_cache #(parameter A_WIDTH=32,parameter C_INDEX = 6)(
    input[A_WIDTH-1:0] p_a,//CPU地址
    input[31:0]        p_dout,//CPU输出数据
    output[31:0]       p_din,//Cache传输给CPU的数�?
    input              p_strobe,//�?1则可读写
    input              p_rw,//0:read,1:write
    output             p_ready,//通知CPU准备好了
    //input              flush_except,
    input[3:0]         p_wen,
    input[3:0]         p_ren,

    input              clk,
    input              clrn,

    output[A_WIDTH-1:0] m_a,//内存地址
    input[31:0]         m_dout,//内存返回数据
    output[31:0]        m_din,//输入内存数据
    output              m_strobe,
    output              m_rw,
    input               m_ready,
    output reg [1:0]         m_size
);
    localparam T_WIDTH =A_WIDTH - C_INDEX -2;
    reg  [3:0]            d_valid[0:(1<<C_INDEX)-1];
    reg  [T_WIDTH-1:0]    d_tags [0:(1<<C_INDEX)-1];
    reg  [31:0]           d_data [0:(1<<C_INDEX)-1];
    wire [C_INDEX-1:0]    index = p_a[C_INDEX+1:2];
    wire [T_WIDTH-1:0]    tag = p_a[A_WIDTH-1 : C_INDEX+2];

    //read from cache
    wire valid =((d_valid[index]&p_ren)==d_valid[index]);
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
    //cache准备好数�?
    //1.读，命中
    //2.缺失但是存储那边已经得到�?
    //3.因为是写直达�?以一旦写就是写mem，然后mem ready那cache就ready
    
    integer i;
    always @(posedge clk or negedge clrn)begin
      if(clrn == 0)begin
          m_size<=2'b10;
          for(i = 0;i<(1<<C_INDEX);i=i+1)begin
            d_valid[i] <= 4'b0;
          end
            
        end else if (c_write & (p_a[31:29]!=3'b101)) begin
            d_valid[index] <= p_wen;
            d_tags[index]  <= tag;
            case(p_wen)
                4'b0001:begin
                    d_data[index][7:0] <= c_din[7:0];
                    m_size<=2'b00;
                end
                4'b0010:begin
                    d_data[index][15:8]<= c_din[15:8];
                    m_size<=2'b00;
                end
                4'b0100:begin
                    d_data[index][23:16]<=c_din[23:16];
                    m_size<=2'b00;
                end
                4'b1000:begin
                    d_data[index][31:24]<=c_din[31:24];
                    m_size<=2'b00;
                end
                4'b0011:begin
                    d_data[index][15:0]<=c_din[15:0];
                    m_size<=2'b01;
                end
                4'b1100:begin
                    d_data[index][31:16]<=c_din[31:16];
                    m_size<=2'b01;
                end
                4'b1111:begin
                    d_data[index]<=c_din;
                    m_size<=2'b10;
                end
                default:begin
                    d_data[index]<=d_data[index];
                    m_size<=2'b10;
                end
            endcase
        end
    end

endmodule