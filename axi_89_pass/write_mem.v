`timescale 1ns / 1ps
`include "defines.vh"
module write_mem(
    input wire [7:0] alucontrol,
    input wire [31:0] addr,
    input wire [31:0] writedata_in,
    output reg [3:0] we,
    output reg [31:0] writedata_out,
    output reg ades
);
    always @(*) begin
        we <= 4'b0000;
        ades <= 1'b0;
        writedata_out <= writedata_in;
        case(alucontrol)
            `EXE_LW_OP,`EXE_LH_OP,`EXE_LHU_OP,`EXE_LB_OP,`EXE_LBU_OP:we <= 4'b0000;
            `EXE_SB_OP:begin
                writedata_out <= {writedata_in[7:0],writedata_in[7:0],writedata_in[7:0],writedata_in[7:0]};
                case(addr[1:0])
                    2'b11: we <= 4'b1000;
                    2'b10: we <= 4'b0100;
                    2'b01: we <= 4'b0010;
                    2'b00: we <= 4'b0001;
                endcase
            end
            `EXE_SH_OP:begin
                ades <= addr[0];
                writedata_out <= {writedata_in[15:0],writedata_in[15:0]};
                case(addr[1:0])
                    2'b10: we <= 4'b1100;
                    2'b00: we <= 4'b0011;
                endcase
            end
            `EXE_SW_OP:begin
                ades <= (addr[1:0] == 2'b00) ? 0:1;
                writedata_out <= writedata_in;
                we <= 4'b1111;
            end
        endcase
    end
endmodule