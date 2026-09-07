// RISCV 32bit : module MUX_3x1
// implementation of 3-to-1 multiplexer for RISCV 32bit architecture
module MUX_3x1 #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire [WIDTH-1:0] d2,
    input  wire [1:0]       s,
    output reg [WIDTH-1:0] y
);
    always @(*) begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = {WIDTH{1'bx}};
        endcase
    end
endmodule