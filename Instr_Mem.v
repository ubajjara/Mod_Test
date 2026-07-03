module Instr_Mem(
    input  wire [9:0]  A,
    output reg  [31:0] RD
);

always @(*) begin
    case (A)

        10'h000 : RD = 32'h0AB00093; // addi x1, x0, 0xAB
        10'h004 : RD = 32'h00102523; // sw   x1, 0xA(x0)
        10'h008 : RD = 32'h00A02103; // lw   x2, 0xA(x0)
        10'h00C : RD = 32'h002025A3; // sw   x2, 0xB(x0)
        10'h010 : RD = 32'h00B02183; // lw   x3, 0xB(x0)
        10'h014 : RD = 32'h00302623; // sw   x3, 0xC(x0)
        10'h018 : RD = 32'h00C02203; // lw   x4, 0xC(x0)

        default : RD = 32'h00000000;

    endcase
end

endmodule
