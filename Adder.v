module Adder(
    input  [31:0] lcd,
    output [31:0] w_p
);
    assign w_p = lcd + 32'd4;
endmodule
