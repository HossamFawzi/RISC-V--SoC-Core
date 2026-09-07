//  RISCV 32bit : module  register files
// impelementation of register files for RISCV 32bit architecture
module Register_Files(
	input wire clk,
	input wire rst,
	input wire [4:0] reg_write_addr,  //instruction [11:7]
	input wire [4:0] reg_read_addr1,  //instruction [19:15]
	input wire [4:0] reg_read_addr2,  //instruction [24:20]
	input wire [31:0] reg_write_data,
	input wire reg_write_en,
	output wire [31:0] reg_read_data1,
	output wire [31:0] reg_read_data2
);

reg [31:0] reg_file [0:31]; // 32 registers of 32-bit each
integer i;
always @(posedge clk or negedge rst) 
begin
	if(!rst) 
	begin
		for (i = 0; i < 31; i = i + 1)
			reg_file[i] <= 32'b0; // Initialize register file to zero
	end 
	else 
		if (reg_write_en) 
			reg_file[reg_write_addr] <= reg_write_data; // Write data to register

end
assign  reg_read_data1 = reg_file[reg_read_addr1]; // Read data from register 1
assign	reg_read_data2 = reg_file[reg_read_addr2]; // Read data from register 2
	
endmodule