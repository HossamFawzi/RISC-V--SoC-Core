// RISCV 32bit : module Data Memory
// implementation of data memory for RISCV 32bit architecture with RE/WE controls
module Data_Memory (
    input  wire        clk,
    input  wire        rst,
    input  wire        WE,        // Write Enable
    input  wire [31:0] A,         // Address
    input  wire [31:0] WD,        // Write Data
    output wire [31:0] RD         // Read Data  
);

    reg [31:0] reg_file [0:63]; // 64 words of 32-bit data memory
    integer i;

    always @(posedge clk or negedge rst) 
    begin
        if (!rst) 
        begin
            for (i = 0; i < 64; i = i + 1)
                reg_file[i] <= 32'b0; // Initialize data memory to zero
        end 
        else if (WE) // Write Operation
                reg_file[A] <= WD;
    end
assign RD = reg_file[A];
endmodule