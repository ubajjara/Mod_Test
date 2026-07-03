module RegisterFile (
	input [31:0] wd3, //Entrada
	input [4:0] wa3,	// selecionar os reg registro
	input we3, 			// habilita escrita
	input clk,
	input rst,
	input [4:0] ra1, //Selecinar reg saida
	input [4:0] ra2, //Seleciona saida reg
	
	output reg [31:0] rd1, // saida 1 reg
	output reg [31:0] rd2, //saida 2 regis
	
	output wire  [31:0] x0,
    output wire  [31:0] x1,
    output wire  [31:0] x2,
    output wire  [31:0] x3,
    output wire  [31:0] x4,
    output wire  [31:0] x5,
    output wire  [31:0] x6,
    output wire  [31:0] x7
);
	//32Registradores de 32bits
	reg [31:0] regs [31:0];
	integer i;
	
	always @(posedge clk or negedge rst) begin
	
		if(!rst) begin //Reset assincrono 
			for (i = 0; i < 32; i = i + 1) begin
				regs[i] <= 32'b0;
			
			end
		
		end else begin
			
			regs[0] <= 32'b0; //Reg $0 = 0
			
			if(we3 && (wa3 != 0))begin // Verifica se pode escrever e evita escrever no reg0
				regs[wa3] <= wd3;
			
			end
		end
	end

	always @(*) begin
        rd1 = regs[ra1];	
        rd2 = regs[ra2];
    end
	
	 assign x0 = regs[0];
    assign x1 = regs[1];
    assign x2 = regs[2];
    assign x3 = regs[3];
    assign x4 = regs[4];
    assign x5 = regs[5];
    assign x6 = regs[6];
    assign x7 = regs[7];


endmodule
