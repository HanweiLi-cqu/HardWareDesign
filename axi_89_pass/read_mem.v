`timescale 1ns / 1ps
`include "defines.vh"
module read_mem(
    input wire [7:0] alucontrol,//控制信号
    input [31:0] addr,//输入地址，根据地址判断读哪一位
    input [31:0] data_in,//data_mem的输出，表示读出的数据
    output reg [31:0] data_out,//处理后的数据
    output reg adel//是否触发例外
);
    always @(*) begin
        adel <= 1'b0;
        data_out <= data_in;
        case(alucontrol)
            `EXE_LB_OP:begin
                case (addr[1:0])
                    2'b00: data_out <= {{24{data_in[7]}},data_in[7:0]};
                    2'b01: data_out <= {{24{data_in[15]}},data_in[15:8]};
                    2'b10: data_out <= {{24{data_in[23]}},data_in[23:16]};
                    2'b11: data_out <= {{24{data_in[31]}},data_in[31:24]};
                endcase
            end
            `EXE_LBU_OP:begin
                case (addr[1:0])
                    2'b00: data_out <= {{24{1'b0}},data_in[7:0]};
                    2'b01: data_out <= {{24{1'b0}},data_in[15:8]};
                    2'b10: data_out <= {{24{1'b0}},data_in[23:16]};
                    2'b11: data_out <= {{24{1'b0}},data_in[31:24]};
                endcase
            end
            `EXE_LH_OP:begin
                adel <= addr[0];
                case (addr[1:0])
                    2'b00: data_out <= {{16{data_in[15]}},data_in[15:0]};
                    2'b10: data_out <= {{16{data_in[31]}},data_in[31:16]};
                endcase
            end
            `EXE_LHU_OP:begin
                adel <= addr[0];
                case (addr[1:0])
                    2'b00: data_out <= {{16{1'b0}},data_in[15:0]};
                    2'b10: data_out <= {{16{1'b0}},data_in[31:16]};
                endcase
            end
            `EXE_LW_OP:begin data_out <= data_in; adel <= (addr[1:0] == 2'b00) ? 0:1; end
        endcase
    end

endmodule