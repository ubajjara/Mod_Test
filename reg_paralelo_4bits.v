module reg_paralelo_4bits (
    input clk ,
    input rst_n,           
    input [31:0] data_in,  
    output reg [31:0] q    
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 31'b0;
        end 
        else  begin
            q <= data_in;
        end
    end

endmodule
