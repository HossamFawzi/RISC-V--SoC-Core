// RISCV 32bit : module Immediate Generator
// Implementation of Immediate Generator for RISCV 32bit architecture
module Imme_Gen (
    input  wire [31:0] instr,
    input  wire [1:0]  ImmSrc,
    output reg  [31:0] ImmExt
);

    always @(*) begin
        case (ImmSrc)
            // 2'b00: I-Type (e.g., lw, addi, jalr)
            2'b00: ImmExt = {{20{instr[31]}}, instr[31:20]};
            
            // 2'b01: S-Type (e.g., sw)
            2'b01: ImmExt = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            
            // 2'b10: B-Type (e.g., beq, bne)
            2'b10: ImmExt = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            
            // 2'b11: J-Type (e.g., jal)
            2'b11: ImmExt = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            
            default: ImmExt = 32'bx;
        endcase
    end

endmodule