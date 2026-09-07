// RISC-V 32-bit Multi-Cycle Unified Memory
module Memory (
    input  wire        clk,
    input  wire        rst,
    input  wire        WE,        // Write Enable
    input  wire [31:0] A,         // Address (Word-aligned or direct index)
    input  wire [31:0] WD,        // Write Data
    output wire [31:0] RD         // Read Data
);
    reg [31:0] mem [0:63];
    integer i;

    always @(posedge clk or negedge rst) 
    begin
        if (!rst)
        begin
            for (i = 0; i < 64; i = i + 1)
                mem[i] <= 32'b0;
        end 
        else if (WE) 
        begin
            mem[A[7:2]] <= WD; // Indexing by word address (A / 4)
        end
    end

    assign RD = mem[A[7:2]];
endmodule