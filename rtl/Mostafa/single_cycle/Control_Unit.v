// RISCV 32bit : module Control unit
// implementation of Control unit for RISCV 32bit architecture
module Control_Unit (
    input  wire [6:0] op,// instruction[6:0] for R-type instructions
    input  wire [2:0] funct3,// instruction[14:12] for R-type instructions
    input  wire       funct7_5,// instruction[30] for R-type instructions
    input  wire       Zero,// Zero flag from ALU
    output wire       PCSrc,// PCSrc signal for branch instructions
    output reg  [1:0] ResultSrc,// ResultSrc signal for selecting the result to write back to the register file
    output reg        MemWrite,// MemWrite signal for data memory write operation
    output reg       ALUSrc,// ALUSrc signal for selecting the second operand for the ALU
    output reg  [1:0] ImmSrc,// ImmSrc signal for selecting the immediate value to be used in the instruction
    output reg        RegWrite,// RegWrite signal for enabling write operation to the register file
    output reg  [2:0] ALUControl// ALUControl signal for selecting the operation to be performed by the ALU
);

    reg [1:0] ALUOp;
    reg       Branch;

    // -------------------------------------------------------------------------
    // Main Decoder
    // -------------------------------------------------------------------------
    always @(*) begin
        case (op)
            // lw (Load Word)
            7'b0000011: begin
                RegWrite  = 1'b1;// Enable write to register file
                ImmSrc    = 2'b00;// Select I-type immediate
                ALUSrc    = 1'b1;// Select immediate as second operand for ALU
                MemWrite  = 1'b0;// Disable write to data memory
                ResultSrc = 2'b01;// Write data from memory to register
                Branch    = 1'b0;// Disable branch
                ALUOp     = 2'b00;// ALU operation for lw is addition
            end
            
            // sw (Store Word)
            7'b0100011: begin
                RegWrite  = 1'b0;// Disable write to register file
                ImmSrc    = 2'b01;// Select S-type immediate
                ALUSrc    = 1'b1;// Select immediate as second operand for ALU
                MemWrite  = 1'b1;// Enable write to data memory
                ResultSrc = 2'bxx;// No result to write back to register
                Branch    = 1'b0;// Disable branch
                ALUOp     = 2'b00;// ALU operation for sw is addition
            end
            
            // R-type (add, sub, and, or, slt)
            7'b0110011: begin
                RegWrite  = 1'b1;// Enable write to register file
                ImmSrc    = 2'bxx;// No immediate value
                ALUSrc    = 1'b0;// Select register as second operand for ALU
                MemWrite  = 1'b0;// Disable write to data memory
                ResultSrc = 2'b00;// Write result to register
                Branch    = 1'b0;// Disable branch
                ALUOp     = 2'b10;
            end
            
            // beq (Branch Equal)
            7'b1100011: begin
                RegWrite  = 1'b0;// Disable write to register file
                ImmSrc    = 2'b10;// Select B-type immediate
                ALUSrc    = 1'b0;// Select register as second operand for ALU
                MemWrite  = 1'b0;// Disable write to data memory
                ResultSrc = 2'bxx;// No result to write back to register
                Branch    = 1'b1;// Enable branch
                ALUOp     = 2'b01;
            end
            
            // I-type ALU (addi)
            7'b0010011: begin
                RegWrite  = 1'b1;
                ImmSrc    = 2'b00;
                ALUSrc    = 1'b1;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                ALUOp     = 2'b10;
            end
            
            // jal (Jump and Link)
            7'b1101111: begin
                RegWrite  = 1'b1;
                ImmSrc    = 2'b11;
                ALUSrc    = 1'bx;
                MemWrite  = 1'b0;
                ResultSrc = 2'b10;// Write PC+4 to register
                Branch    = 1'b1; // Direct branch taken or handled via PCSrc jump logic
                ALUOp     = 2'bxx;
            end

            default: begin
                RegWrite  = 1'b0;
                ImmSrc    = 2'b00;
                ALUSrc    = 1'b0;
                MemWrite  = 1'b0;
                ResultSrc = 2'b00;
                Branch    = 1'b0;
                ALUOp     = 2'b00;
            end
        endcase
    end

    // PCSrc calculation for Branch instructions (e.g., beq)
    assign PCSrc = Branch & Zero;

    // -------------------------------------------------------------------------
    // ALU Decoder
    // -------------------------------------------------------------------------
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000; // Addition (lw, sw)
            2'b01: ALUControl = 3'b001; // Subtraction (beq)
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // Check sub vs add (R-type sub uses funct7[5] == 1)
                        if ({op[5], funct7_5} == 2'b11)  
                        /* op[5] distinguishes R-type instructions (op = 7'b0110011, so op[5] = 1) 
                        from I-type instructions like addi (op = 7'b0010011, so op[5] = 0).  
                        funct7_5 (bit 30 of the instruction) distinguishes sub (funct7[5] = 1) 
                        from add (funct7[5] = 0). */
                            ALUControl = 3'b001; // sub
                        else
                            ALUControl = 3'b000; // add / addi
                    end
                    3'b010: ALUControl = 3'b101; // slt / slti
                    3'b110: ALUControl = 3'b011; // or / ori
                    3'b111: ALUControl = 3'b010; // and / andi
                    default: ALUControl = 3'bxxx;
                endcase
            end
            default: ALUControl = 3'bxxx;
        endcase
    end

endmodule