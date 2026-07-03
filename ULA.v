module ULA (
    input  [31:0] SrcA,
    input  [31:0] SrcB,
    input  [2:0]  ULAControl,

    output reg [31:0] ULAResult,
    output Zero
);

    always @(*) begin
        case (ULAControl)

            // Soma
            3'b000: ULAResult = SrcA + SrcB;

            // Subtração
            3'b001: ULAResult = SrcA - SrcB;

            // AND
            3'b010: ULAResult = SrcA & SrcB;

            // OR
            3'b011: ULAResult = SrcA | SrcB;

            // Set Less Than
            3'b101: begin
                if (SrcA < SrcB)
                    ULAResult = 32'd1;
                else
                    ULAResult = 32'd0;
            end

            default: ULAResult = 32'd0;

        endcase
    end

    // Flag Zero
    assign Zero = (ULAResult == 32'd0);

endmodule
