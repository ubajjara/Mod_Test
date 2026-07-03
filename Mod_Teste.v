`default_nettype none //Comando para desabilitar declaração automática de wires
module Mod_Teste (
//Clocks
input CLOCK_27, CLOCK_50,
//Chaves e Botoes
input [3:0] KEY,
input [17:0] SW,
//Displays de 7 seg e LEDs
output [0:6] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
output [8:0] LEDG,
output [17:0] LEDR,
//Serial
output UART_TXD,
input UART_RXD,
inout [7:0] LCD_DATA,
output LCD_ON, LCD_BLON, LCD_RW, LCD_EN, LCD_RS,
//GPIO
inout [35:0] GPIO_0, GPIO_1
);
assign GPIO_1 = 36'hzzzzzzzzz;
assign GPIO_0 = 36'hzzzzzzzzz;
assign LCD_ON = 1'b1;
assign LCD_BLON = 1'b1;
wire [7:0] w_d0x0, w_d0x1, w_d0x2, w_d0x3, w_d0x4, w_d0x5,
w_d1x0, w_d1x1, w_d1x2, w_d1x3, w_d1x4, w_d1x5;
LCD_TEST MyLCD (
.iCLK ( CLOCK_50 ),
.iRST_N ( KEY[0] ),
.d0x0(w_d0x0),.d0x1(w_d0x1),.d0x2(w_d0x2),.d0x3(w_d0x3),.d0x4(w_d0x4),.d0x5(w_d0x5),
.d1x0(w_d1x0),.d1x1(w_d1x1),.d1x2(w_d1x2),.d1x3(w_d1x3),.d1x4(w_d1x4),.d1x5(w_d1x5),
.LCD_DATA( LCD_DATA ),
.LCD_RW ( LCD_RW ),
.LCD_EN ( LCD_EN ),
.LCD_RS ( LCD_RS )
);
//---------- modifique a partir daqui --------
// Setando os fios

// Setando os fios
 
 wire [31:0] w_PC;         // Saída do registrador PC
 wire [31:0] w_PCp4;       // PC + 4
 wire [31:0] w_Inst;       // Instrução atual
 wire [31:0] w_rd1SrcA;    // Saída rd1 do banco → SrcA da ULA
 wire [31:0] w_rd2;        // Saída rd2 do banco
 wire [31:0] w_MImm;       // Imediato estendido (I ou S, conforme ImmSrc)
 wire [31:0] w_SrcB;       // Entrada SrcB da ULA (rd2 ou MImm)
 wire [31:0] w_ULAResult;  // Resultado da ULA
 wire        w_ULASrc;     // seleciona SrcB
 wire        w_RegWrite;   // habilita escrita no banco
 wire [2:0]  w_ULAControl; // operação da ULA
 wire        w_Zero;       // Flag Zero da ULA
 
 // Novos sinais da Sprint 7 (memória de dados)
 wire        w_ImmSrc;     // 0 = imediato tipo I | 1 = tipo S
 wire        w_MemWrite;   // habilita escrita na Data_Mem
 wire        w_ResultSrc;  // 0 = ULAResult | 1 = dado lido da memória
 wire [31:0] w_RData;      // dado lido da Data_Mem
 wire [31:0] w_Wd3;        // dado que realmente é escrito no banco de registradores
 wire        w_Clk1Hz;     // clock de 1Hz gerado pelo divisor de frequência
 
 //Registradores de debug
 wire [31:0] w_x0, w_x1, w_x2, w_x3;
 wire [31:0] w_x4, w_x5, w_x6, w_x7;
 
 //Divisor de frequência 50MHz -> 1Hz
 Div_Freq FreqDiv (
        .clk_in  (CLOCK_50),
        .clk_out (w_Clk1Hz)
 );
 assign LEDG[0] = w_Clk1Hz;
 
 reg_paralelo_4bits PC_reg (
        .clk     (w_Clk1Hz),   // antes: KEY[1] (clock manual) -> agora clock de 1Hz
        .rst_n   (KEY[2]),
        .data_in (w_PCp4),
        .q       (w_PC)
);
 
 //adder Pc + 4
 
 Adder PC_adder (
        .lcd (w_PC),
        .w_p (w_PCp4)
 );
 
 //Instrução de memoria
 Instr_Mem IMem (
        .A  (w_PC[9:0]),
        .RD (w_Inst)
 );
 
 //Unidade de controle
 
  Control_Unit CU (
        .OP         (w_Inst[6:0]),
        .Funct3     (w_Inst[14:12]),
        .Funct7     (w_Inst[31:25]),
        .ULAControl (w_ULAControl),
        .ULASrc     (w_ULASrc),
        .RegWrite   (w_RegWrite),
        .ImmSrc     (w_ImmSrc),
        .MemWrite   (w_MemWrite),
        .ResultSrc  (w_ResultSrc)
 );
 
  //banco de registradores
 RegisterFile RF (
        .wd3 (w_Wd3),          // antes: w_ULAResult -> agora vem do mux de resultado
        .wa3 (w_Inst[11:7]),
        .we3 (w_RegWrite),
        .clk (w_Clk1Hz),       // antes: KEY[1]
        .rst (KEY[2]),
        .ra1 (w_Inst[19:15]),
        .ra2 (w_Inst[24:20]),
        .rd1 (w_rd1SrcA),
        .rd2 (w_rd2),
        // Saídas de debug
        .x0  (w_x0), .x1 (w_x1), .x2 (w_x2), .x3 (w_x3),
        .x4  (w_x4), .x5 (w_x5), .x6 (w_x6), .x7 (w_x7)
 );
 
 //extensor de sinal (agora recebe a instrução inteira + ImmSrc)
  SignExtend SE (
        .instr   (w_Inst),
        .ImmSrc  (w_ImmSrc),
        .imm_out (w_MImm)
 );
 
 //mUX SrcB da ULA
 Mux MuxULASrc (
        .in0 (w_rd2),
        .in1 (w_MImm),
        .sel (w_ULASrc),
        .out (w_SrcB)
);
 
//Ula
ULA ula_inst (
        .SrcA      (w_rd1SrcA),
        .SrcB      (w_SrcB),
        .ULAControl(w_ULAControl),
        .ULAResult (w_ULAResult),
        .Zero      (w_Zero)
);
 
// Memória de dados (RAM 1024 x 32bits)
Data_Mem DMem (
        .clk (w_Clk1Hz),
        .rst (KEY[2]),
        .WE  (w_MemWrite),
        .A   (w_ULAResult[9:0]),
        .WD  (w_rd2),
        .RD  (w_RData)
);
 
// Mux de resultado: escolhe entre ULAResult (R/I) e RData (LW)
Mux MuxResult (
        .in0 (w_ULAResult),
        .in1 (w_RData),
        .sel (w_ResultSrc),
        .out (w_Wd3)
);
 
    assign w_d0x0 = w_x0[7:0];   // x0
    assign w_d0x1 = w_x1[7:0];   // x1
    assign w_d0x2 = w_x2[7:0];   // x2
    assign w_d0x3 = w_x3[7:0];   // x3
    assign w_d0x4 = w_PC[7:0];   // PC (posição w_d0x4)
 
	 
	 assign w_d1x0 = w_x4[7:0];   // x4
    assign w_d1x1 = w_x5[7:0];   // x5
    assign w_d1x2 = w_x6[7:0];   // x6
    assign w_d1x3 = w_x7[7:0];   // x7
 
	 
 // HEX0-HEX7: exibe w_Inst (instrução atual, 32 bits = 8 nibbles)
    decodificador dec0 (.hexa(w_Inst[3:0]),   .seg(HEX0));
    decodificador dec1 (.hexa(w_Inst[7:4]),   .seg(HEX1));
    decodificador dec2 (.hexa(w_Inst[11:8]),  .seg(HEX2));
    decodificador dec3 (.hexa(w_Inst[15:12]), .seg(HEX3));
    decodificador dec4 (.hexa(w_Inst[19:16]), .seg(HEX4));
    decodificador dec5 (.hexa(w_Inst[23:20]), .seg(HEX5));
    decodificador dec6 (.hexa(w_Inst[27:24]), .seg(HEX6));
    decodificador dec7 (.hexa(w_Inst[31:28]), .seg(HEX7));
	 
	 // Debug dos 6 sinais de controle nos LEDs vermelhos (LEDR[7:0])
	 assign LEDR[0]    = w_RegWrite;
    assign LEDR[1]    = w_ImmSrc;
    assign LEDR[2]    = w_ULASrc;
    assign LEDR[5:3]  = w_ULAControl;
    assign LEDR[6]    = w_MemWrite;
    assign LEDR[7]    = w_ResultSrc;
  
endmodule
  
