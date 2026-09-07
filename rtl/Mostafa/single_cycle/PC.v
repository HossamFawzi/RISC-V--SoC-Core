//RISCV 32bit  module : PC
// impelementation of program counter
module Program_Counter(
	input wire clk,
	input wire rst,
	input wire [31:0] pc_in,
	output reg [31:0]pc_out
);

always @(posedge clk or negedge rst) 
begin
	if(!rst) 
	begin
		pc_out <= 32'b0;
	end 
	else 
	begin
		pc_out <= pc_in;
    end
end
endmodule