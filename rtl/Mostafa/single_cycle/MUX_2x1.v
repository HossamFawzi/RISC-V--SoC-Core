// RISCV 32bit : module MUX_2x1
// implementation of 2-to-1 multiplexer for RISCV 32bit architecture
module MUX_2x1 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire             s,
    output wire [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule