module tb_RegisterFile;

    reg [31:0] wd3;
    reg [4:0] wa3, ra1, ra2;
    reg we3, clk, rst;

    wire [31:0] rd1, rd2;

    integer i;

    RegisterFile uut (
        .wd3(wd3),
        .wa3(wa3),
        .we3(we3),
        .clk(clk),
        .rst(rst),
        .ra1(ra1),
        .ra2(ra2),
        .rd1(rd1),
        .rd2(rd2)
    );

    // Clock 10ns
    always #5 clk = ~clk;

    initial begin

        clk = 0;
        rst = 0;
        we3 = 0;
        wa3 = 0;
        wd3 = 0;
        ra1 = 0;
        ra2 = 0;

        // Rst
        #10;
        rst = 1;

        // Escrita
        for(i = 1; i < 32; i = i + 1) begin

            wa3 = i; //localização do reg
            wd3 = i; // Valor no reg
            we3 = 1;

            @(posedge clk); // Pro for não tentar fazer tudo de uma vez

        end

        we3 = 0;

        // Leitura
        for(i = 1; i < 32; i = i + 1) begin

            ra1 = i; // Endereço do reg pra leitura

            #1;

            if(rd1 == i)
                $display("OK Reg[%0d] = %0d", i, rd1);
            else
                $display("ERRO Reg[%0d]", i);

        end

        // test reg 0
        ra1 = 0;

        #1;

        if(rd1 == 0)
            $display("OK Reg[0] = 0");
        else
            $display("ERRO Reg[0]");

        $stop;

    end

endmodule