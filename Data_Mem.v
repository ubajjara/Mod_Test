module Data_Mem(
    input         clk,
    input         rst,   // reset assíncrono, ativo em borda de descida
    input         WE,    // write enable
    input  [9:0]  A,     // endereço (10 bits -> 1024 posições)
    input  [31:0] WD,    // dado de escrita
    output [31:0] RD     // dado de leitura
);

    reg [31:0] mem [0:1023];
    integer i;

    // Leitura: combinacional, depende só do endereço
    assign RD = mem[A];

    // Escrita: sequencial, na subida do clk, se WE = 1
    // Reset: assíncrono, apaga tudo na borda de descida de rst
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 1024; i = i + 1)
                mem[i] <= 32'b0;
        end else begin
            if (WE)
                mem[A] <= WD;
        end
    end

endmodule
