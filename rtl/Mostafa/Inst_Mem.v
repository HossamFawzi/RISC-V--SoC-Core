// RISCV 32bit : module  instruction memory
// impelementation of instruction memory
module Instruction_Memory(
	input wire clk,
	input wire rst,
	input wire [31:0] inst_mem_read_addr,
	output wire [31:0] inst_mem_out
);

reg [31:0] inst_mem [0:63]; // 64 words of 32-bit instruction memory
integer i;
always @(posedge clk or negedge rst) 
begin
	if(!rst) 
	begin
		for (i = 0; i < 63; i = i + 1)
			inst_mem[i] <= 32'b0; // Initialize instruction memory to zero
	end 	 
end

assign inst_mem_out = inst_mem[inst_mem_read_addr]; // Read instruction from memory

endmodule



/*
    1. Inputs and Outputsclk & rst: Clock signal and active-low reset signal. 
    inst_mem_read_addr: The 32-bit Program Counter (PC) address coming into memory.  
    inst_mem_out: The 32-bit instruction fetched and sent to the processor. 
   
    2. Internal Storagereg [31:0] inst_mem [0:63]: Creates an array of 64 memory registers,
    where each slot holds a 32-bit instruction.  
	
	3. Reset Action (if (!rst))When rst goes low (0), a for loop runs on the clock edge to 
	reset memory locations by clearing them to zero. (Note: It loops up to index 62, 
	so index 63 remains uninitialized). 
	
	4. Reading Instructions (else)inst_mem_read_addr[7:2]: Extracts bits 7 down to 2 
	 of the address to convert a byte-aligned PC address (which increases by 4: 0, 4, 8, 12...) 
	 into a word-aligned array index (0, 1, 2, 3...).  inst_mem_out <= ...: On the rising edge
	  of the clock, the instruction at that calculated memory index is registered to the output. 
*/