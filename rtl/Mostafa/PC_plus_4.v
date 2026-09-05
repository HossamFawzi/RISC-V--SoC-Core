// RISCV 32bit  module : PC+4
// impelementation of program counter plus 4
module PC_plus_4(
	input wire [31:0] pc_plus_4_in,
	output reg [31:0]pc_plus_4_out
);

assign pc_plus_4_out = pc_plus_4_in + 32'b100;

endmodule