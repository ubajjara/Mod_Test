module SignExtend (
    input  [31:0] instr,     // instrução completa
    input         ImmSrc,    // 0 = tipo I (addi, lw) | 1 = tipo S (sw)
    output [31:0] imm_out
);

    // Tipo I: imm[11:0] = instr[31:20]
    // Tipo S: imm[11:0] = {instr[31:25], instr[11:7]}
    wire [11:0] imm12 = ImmSrc ? {instr[31:25], instr[11:7]} : instr[31:20];

    assign imm_out = {{20{imm12[11]}}, imm12};

endmodule
