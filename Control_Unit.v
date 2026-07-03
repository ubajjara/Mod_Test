module Control_Unit(
    input  [6:0] OP,
    input  [2:0] Funct3,
    input  [6:0] Funct7,

    output reg [2:0] ULAControl,
    output reg       ULASrc,
    output reg       RegWrite,
    output reg       ImmSrc,
    output reg       MemWrite,
    output reg       ResultSrc
);

always @(*) begin
    // valores padrão (evita latches)
    RegWrite   = 0;
    ULASrc     = 0;
    ULAControl = 3'b000;
    ImmSrc     = 0;
    MemWrite   = 0;
    ResultSrc  = 0;

    case (OP)

        // Tipo R (add, sub, and, or, slt)
        7'b0110011: begin
            RegWrite = 1;
            ULASrc   = 0;

            case (Funct3)
                3'b000:
                    if (Funct7 == 7'b0000000)
                        ULAControl = 3'b000; // ADD
                    else
                        ULAControl = 3'b001; // SUB

                3'b111: ULAControl = 3'b010; // AND
                3'b110: ULAControl = 3'b011; // OR
                3'b010: ULAControl = 3'b101; // SLT
            endcase
        end

        // ADDI
        7'b0010011: begin
            RegWrite   = 1;
            ULASrc     = 1;
            ImmSrc     = 0;
            ULAControl = 3'b000;
            MemWrite   = 0;
            ResultSrc  = 0;
        end

        // LW
        7'b0000011: begin
            RegWrite   = 1;
            ULASrc     = 1;
            ImmSrc     = 0;
            ULAControl = 3'b000;
            MemWrite   = 0;
            ResultSrc  = 1;
        end

        // SW
        7'b0100011: begin
            RegWrite   = 0;
            ULASrc     = 1;
            ImmSrc     = 1;
            ULAControl = 3'b000;
            MemWrite   = 1;
            ResultSrc  = 0; // "x" na tabela, valor irrelevante
        end

    endcase
end

endmodule
