// ============================================================================
// Module Name  : Control_Unit
// Description  : Multi-Cycle Control Unit FSM for a 32-bit RISC-V Processor.
//                Decodes instructions (op, funct3, funct7_5) across multiple
//                clock cycles to generate control signals for the datapath, 
//                ALU, and memory interface.
// ============================================================================

module Control_Unit (
    // --- Clock and Reset Signals ---
    input  wire        clk,        // System Clock signal
    input  wire        rst,        // Active-Low Asynchronous Reset signal

    // --- Instruction Decoder Inputs ---
    input  wire [6:0]  op,         // Opcode field: instruction[6:0]
    input  wire [2:0]  funct3,     // Function 3-bit field: instruction[14:12]
    input  wire        funct7_5,   // Function 7 bit 5: instruction[30] (distinguishes ADD/SUB)
    input  wire        Zero,       // Zero flag output from the ALU (used for branch execution)

    // --- Datapath Control Outputs ---
    output reg         PCWrite,    // Enable write to Program Counter (PC)
    output reg         AdrSrc,     // Select memory address source: 0 = PC, 1 = Result/ALUOut
    output reg         MemWrite,   // Enable write to unified memory
    output reg         IRWrite,    // Enable write to Instruction Register (IR)
    output reg  [1:0]  ResultSrc,  // Select result source: 00 = ALUOut, 01 = Data, 10 = ALUResult
    output reg  [2:0]  ALUControl, // Direct control signal sent to the ALU
    output reg  [1:0]  ALUSrcA,    // Select Operand A for ALU: 00 = PC, 01 = OldPC, 10 = Register A
    output reg  [1:0]  ALUSrcB,    // Select Operand B for ALU: 00 = Register B, 01 = ImmExt, 10 = Constant 4
    output reg  [1:0]  ImmSrc,     // Select Immediate Extension type: 00 = I-type, 01 = S-type, 10 = B-type, 11 = J-type
    output reg         RegWrite    // Enable write to the Register File
);

    // ========================================================================
    // FSM State Encoding
    // ========================================================================
    localparam FETCH     = 4'b0000; // State 0: Fetch instruction & increment PC (PC + 4)
    localparam DECODE    = 4'b0001; // State 1: Decode instruction & compute target address (OldPC + Imm)
    localparam MEMADR    = 4'b0010; // State 2: Calculate memory address for load/store (A + Imm)
    localparam MEMREAD   = 4'b0011; // State 3: Read data from memory for Load Word (lw)
    localparam MEMWB     = 4'b0100; // State 4: Write memory read data back to register file
    localparam MEMWRITE  = 4'b0101; // State 5: Write register data to memory for Store Word (sw)
    localparam EXECUTER  = 4'b0110; // State 6: Execute R-type instruction (A op B)
    localparam ALUWB     = 4'b0111; // State 7: Write ALU result back to register file (R-type / I-type / JAL)
    localparam EXECUTEI  = 4'b1000; // State 8: Execute I-type ALU instruction (A op Imm)
    localparam JAL       = 4'b1001; // State 9: Execute Jump and Link (update PC to target)
    localparam BRANCH    = 4'b1010; // State 10: Execute Branch Equal (evaluate condition A - B)

    // Internal State and Helper Registers
    reg [3:0] state, next_state; // FSM Current and Next State Registers
    reg [1:0] ALUOp;             // Internal signal to drive the ALU Decoder
    reg       Branch;            // Internal signal indicating a branch evaluation state

    // ========================================================================
    // 1. FSM Sequential State Register
    // ========================================================================
    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= FETCH;      // Synchronous/Asynchronous state reset to FETCH
        else
            state <= next_state; // Transition to next computed state
    end

    // ========================================================================
    // 2. Next State Logic (Combinational)
    // ========================================================================
    always @(*) begin
        case (state)
            // Fetch -> Move to Decode automatically
            FETCH: next_state = DECODE;

            // Decode -> Branch based on Opcode (`op`)
            DECODE: begin
                case (op)
                    7'b0000011, 7'b0100011: next_state = MEMADR;   // Load (lw) or Store (sw)
                    7'b0110011:             next_state = EXECUTER; // R-type instructions (add, sub, and, or, slt)
                    7'b0010011:             next_state = EXECUTEI; // I-type ALU instructions (addi)
                    7'b1101111:             next_state = JAL;      // Jump and Link (jal)
                    7'b1100011:             next_state = BRANCH;   // Branch on Equal (beq)
                    default:                next_state = FETCH;    // Default fallback to safe state
                endcase
            end

            // Memory Operations Path
            MEMADR: begin
                if (op == 7'b0000011) 
                    next_state = MEMREAD;  // Read cycle for 'lw'
                else 
                    next_state = MEMWRITE; // Write cycle for 'sw'
            end
            
            MEMREAD:  next_state = MEMWB;   // Go to Writeback after reading memory
            MEMWB:    next_state = FETCH;   // Complete 'lw' instruction
            MEMWRITE: next_state = FETCH;   // Complete 'sw' instruction

            // Register-Register and Immediate Execution Paths
            EXECUTER: next_state = ALUWB;   // Go to Writeback after R-type execution
            EXECUTEI: next_state = ALUWB;   // Go to Writeback after I-type execution
            ALUWB:    next_state = FETCH;   // Complete R-type/I-type writeback

            // Jump & Branch Paths
            JAL:      next_state = ALUWB;   // Save PC+4 to rd, then return to FETCH
            BRANCH:   next_state = FETCH;   // Complete branch evaluation

            default:  next_state = FETCH;
        endcase
    end

    // ========================================================================
    // 3. FSM Output Signal Logic (Combinational Main Decoder)
    // ========================================================================
    always @(*) begin
        // --- Default Control Signal Values (Prevent Latches) ---
        PCWrite   = 1'b0;
        AdrSrc    = 1'b0;
        MemWrite  = 1'b0;
        IRWrite   = 1'b0;
        ResultSrc = 2'b00;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        ImmSrc    = 2'b00;
        RegWrite  = 1'b0;
        ALUOp     = 2'b00;
        Branch    = 1'b0;

        case (state)
            // State 0: Fetch Instruction from Memory & Increment PC by 4
            FETCH: begin
                AdrSrc    = 1'b0;  // Read address from PC
                IRWrite   = 1'b1;  // Latch instruction into Instruction Register
                ALUSrcA   = 2'b00; // Operand A = PC
                ALUSrcB   = 2'b10; // Operand B = 4
                ALUOp     = 2'b00; // ALU operation = ADD
                ResultSrc = 2'b10; // Select immediate ALUResult (PC + 4)
                PCWrite   = 1'b1;  // Write updated PC back to PC Register
            end

            // State 1: Decode Instruction & Precompute Branch Target
            DECODE: begin
                ALUSrcA   = 2'b01; // Operand A = OldPC
                ALUSrcB   = 2'b01; // Operand B = ImmExt
                ALUOp     = 2'b00; // ALU operation = ADD (OldPC + ImmExt saved in ALUOut)
                
                // Select Immediate Generation format based on opcode
                case (op)
                    7'b0000011: ImmSrc = 2'b00; // I-type format (lw)
                    7'b0100011: ImmSrc = 2'b01; // S-type format (sw)
                    7'b1100011: ImmSrc = 2'b10; // B-type format (beq)
                    7'b1101111: ImmSrc = 2'b11; // J-type format (jal)
                    7'b0010011: ImmSrc = 2'b00; // I-type format (addi)
                    default:    ImmSrc = 2'b00;
                endcase
            end

            // State 2: Calculate Effective Address for Memory Operations (A + Imm)
            MEMADR: begin
                    ALUSrcA   = 2'b10; // Operand A = Register A
                    ALUSrcB   = 2'b01; // Operand B = ImmExt
                    ALUOp     = 2'b00; // ALU operation = ADD
                    end

            // State 3: Read Memory Word (Load Word)
            MEMREAD: begin
                     AdrSrc    = 1'b1;  // Read address from ALUOut (calculated in MEMADR)
                     ResultSrc = 2'b00; // Route ALUOut for address stability
                     end

            // State 4: Write Memory Data back to Register File (lw Writeback)
            MEMWB: begin
                   ResultSrc = 2'b01; // Select Data Register output
                   RegWrite  = 1'b1;  // Enable write to destination register (rd)
                   end

            // State 5: Write Register B data to Memory (Store Word)
            MEMWRITE: begin
                      AdrSrc    = 1'b1;  // Write address from ALUOut
                      MemWrite  = 1'b1;  // Enable Unified Memory Write
                      end

            // State 6: Execute R-type Register Operation (A op B)
            EXECUTER: begin
                      ALUSrcA   = 2'b10; // Operand A = Register A
                      ALUSrcB   = 2'b00; // Operand B = Register B
                      ALUOp     = 2'b10; // Look up operational code in ALU Decoder
            end

            // State 8: Execute I-type Immediate Operation (A op Imm)
            EXECUTEI: begin
                ALUSrcA   = 2'b10; // Operand A = Register A
                ALUSrcB   = 2'b01; // Operand B = ImmExt
                ALUOp     = 2'b10; // Look up operational code in ALU Decoder
            end

            // State 7: Write ALU Calculation back to Register File
            ALUWB: begin
                ResultSrc = 2'b00; // Select ALUOut register
                RegWrite  = 1'b1;  // Enable write to destination register (rd)
            end

            // State 9: Execute Jump and Link (jal)
            JAL: begin
                ALUSrcA   = 2'b01; // Operand A = OldPC
                ALUSrcB   = 2'b10; // Operand B = 4
                ALUOp     = 2'b00; // ALU operation = ADD (OldPC + 4)
                ResultSrc = 2'b00; // Output target saved in ALUOut during DECODE state
                PCWrite   = 1'b1;  // Write jump target into PC
            end

            // State 10: Evaluate Branch Condition (beq)
            BRANCH: begin
                ALUSrcA   = 2'b10; // Operand A = Register A
                ALUSrcB   = 2'b00; // Operand B = Register B
                ALUOp     = 2'b01; // ALU operation = SUB (Check if A - B == 0)
                ResultSrc = 2'b00; // Target PC calculated in DECODE stage stored in ALUOut
                Branch    = 1'b1;  // Assert Branch evaluation flag
            end
        endcase

        // --- Branch Condition Evaluation ---
        // If in BRANCH state AND the ALU Zero flag is asserted, update the PC with target address
        if (Branch && Zero)
            PCWrite = 1'b1;
    end

    // ========================================================================
    // 4. ALU Decoder Logic (Combinational)
    // ========================================================================
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000; // Force ADD (used for PC+4, Memory Addr, Target Addr)
            2'b01: ALUControl = 3'b001; // Force SUB (used for Branch comparison)
            
            // Decoded Operations (R-Type / I-Type)
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // Distinguish between ADD and SUB based on op[5] and funct7_5:
                        // R-type SUB has op[5]=1 and funct7_5=1, whereas ADD or ADDI have 0.
                        if ({op[5], funct7_5} == 2'b11)
                            ALUControl = 3'b001; // SUB operation
                        else
                            ALUControl = 3'b000; // ADD / ADDI operation
                    end
                    3'b010: ALUControl = 3'b101; // Set Less Than (SLT / SLTI)
                    3'b110: ALUControl = 3'b011; // Bitwise OR / ORI
                    3'b111: ALUControl = 3'b010; // Bitwise AND / ANDI
                    default: ALUControl = 3'b000; // Default fallback to ADD
                endcase
            end
            
            default: ALUControl = 3'b000;
        endcase
    end

endmodule
/*

// RISC-V 32-bit Multi-Cycle Control Unit FSM
module Control_Unit (
    input  wire        clk,
    input  wire        rst,
    input  wire [6:0]  op,
    input  wire [2:0]  funct3,
    input  wire        funct7_5,
    input  wire        Zero,
    output reg         PCWrite,
    output reg         AdrSrc,
    output reg         MemWrite,
    output reg         IRWrite,
    output reg  [1:0]  ResultSrc,
    output reg  [2:0]  ALUControl,
    output reg  [1:0]  ALUSrcA,
    output reg  [1:0]  ALUSrcB,
    output reg  [1:0]  ImmSrc,
    output reg         RegWrite
);

    // FSM State Encoding
    localparam FETCH     = 4'b0000;
    localparam DECODE    = 4'b0001;
    localparam MEMADR    = 4'b0010;
    localparam MEMREAD   = 4'b0011;
    localparam MEMWB     = 4'b0100;
    localparam MEMWRITE  = 4'b0101;
    localparam EXECUTER  = 4'b0110;
    localparam ALUWB     = 4'b0111;
    localparam EXECUTEI  = 4'b1000;
    localparam JAL       = 4'b1001;
    localparam BRANCH    = 4'b1010;

    reg [3:0] state, next_state;
    reg [1:0] ALUOp;
    reg       Branch;

    // State Register
    always @(posedge clk or negedge rst)
    begin
        if (!rst)
            state <= FETCH;
        else
            state <= next_state;
    end

    // Next State Logic
    always @(*) 
    begin
        case (state)
            FETCH:    next_state = DECODE;
            DECODE: begin
                 case (op)
                    7'b0000011, 7'b0100011: next_state = MEMADR;   // lw, sw
                    7'b0110011:             next_state = EXECUTER; // R-type
                    7'b0010011:             next_state = EXECUTEI; // I-type ALU
                    7'b1101111:             next_state = JAL;      // jal
                    7'b1100011:             next_state = BRANCH;   // beq
                    default:                next_state = FETCH;
                 endcase
                    end
            MEMADR: begin
                      if (op == 7'b0000011)     
                      next_state = MEMREAD;
                      else                      
                      next_state = MEMWRITE;
                    end
            MEMREAD:  next_state = MEMWB;
            MEMWB:    next_state = FETCH;
            MEMWRITE: next_state = FETCH;
            EXECUTER: next_state = ALUWB;
            EXECUTEI: next_state = ALUWB;
            ALUWB:    next_state = FETCH;
            JAL:      next_state = ALUWB;
            BRANCH:   next_state = FETCH;
            default:  next_state = FETCH;
        endcase
    end

    // Output Logic
    always @(*) begin
        // Default control signal assignments
        PCWrite   = 1'b0;
        AdrSrc    = 1'b0;
        MemWrite  = 1'b0;
        IRWrite   = 1'b0;
        ResultSrc = 2'b00;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        ImmSrc    = 2'b00;
        RegWrite  = 1'b0;
        ALUOp     = 2'b00;
        Branch    = 1'b0;

        case (state)
            FETCH:begin
                AdrSrc    = 1'b0;
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00; // PC
                ALUSrcB   = 2'b10; // 4
                ALUOp     = 2'b00; // ADD
                ResultSrc = 2'b10; // ALUResult
                PCWrite   = 1'b1;
            end
            DECODE:begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b01; // ImmExt
                ALUOp     = 2'b00; // ADD (Branch Target)
                case (op)
                    7'b0000011: ImmSrc = 2'b00; // lw
                    7'b0100011: ImmSrc = 2'b01; // sw
                    7'b1100011: ImmSrc = 2'b10; // beq
                    7'b1101111: ImmSrc = 2'b11; // jal
                    7'b0010011: ImmSrc = 2'b00; // addi
                    default:    ImmSrc = 2'b00;
                endcase
            end
            MEMADR:begin
                   ALUSrcA   = 2'b10; // A
                   ALUSrcB   = 2'b01; // ImmExt
                   ALUOp     = 2'b00; // ADD
                   end
            MEMREAD:begin
                    AdrSrc    = 1'b1;  // Result (ALUOut)
                    ResultSrc = 2'b00;
                    end
            MEMWB:begin
                  ResultSrc = 2'b01; // Data
                  RegWrite  = 1'b1;
                  end
            MEMWRITE:begin
                     AdrSrc    = 1'b1;  // Result (ALUOut)
                     MemWrite  = 1'b1;
                     end
            EXECUTER:begin
                     ALUSrcA   = 2'b10; // A
                     ALUSrcB   = 2'b00; // B
                     ALUOp     = 2'b10;
                     end
            EXECUTEI:begin
                     ALUSrcA   = 2'b10; // A
                     ALUSrcB   = 2'b01; // ImmExt
                     ALUOp     = 2'b10;
                     end
            ALUWB:begin
                  ResultSrc = 2'b00; // ALUOut
                  RegWrite  = 1'b1;
                  end
            JAL:begin
                ALUSrcA   = 2'b01; // OldPC
                ALUSrcB   = 2'b10; // 4
                ALUOp     = 2'b00;
                ResultSrc = 2'b00; // PC + 4
                PCWrite   = 1'b1;
                end
            BRANCH:begin
                   ALUSrcA   = 2'b10; // A
                   ALUSrcB   = 2'b00; // B
                   ALUOp     = 2'b01; // SUB
                   ResultSrc = 2'b00;
                   Branch    = 1'b1;
                   end
        endcase

        // Branch condition update
        if (Branch && Zero)
            PCWrite = 1'b1;
    end

    // ALU Decoder Logic
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000; // ADD
            2'b01: ALUControl = 3'b001; // SUB
            2'b10: 
            begin
                case (funct3)
                    3'b000: 
                    begin
                        if ({op[5], funct7_5} == 2'b11)
                            ALUControl = 3'b001; // SUB
                        else
                            ALUControl = 3'b000; // ADD
                    end
                    3'b010: ALUControl = 3'b101; // SLT
                    3'b110: ALUControl = 3'b011; // OR
                    3'b111: ALUControl = 3'b010; // AND
                    default: ALUControl = 3'b000;
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end

endmodule


*/