// RISCV 32bit : module riscv_single_cycle (Top level module)
// implementation of single-cycle RISCV processor for RISCV 32bit architecture
module riscv_single_cycle (
    input wire clk,
    input wire rst
);
    // Interconnect wires matching standard single-cycle datapath
    wire [31:0] PC, PCNext, PCPlus4, PCTarget;
    wire [31:0] Instr;
    wire [31:0] RD1, RD2, WriteData, SrcA, SrcB;
    wire [31:0] ImmExt;
    wire [31:0] ALUResult, ReadData, Result;
    
    // Control Wires
    wire       PCSrc, MemWrite, ALUSrc, RegWrite, Zero;
    wire [1:0] ResultSrc, ImmSrc;
    wire [2:0] ALUControl;

    // --- PC Mux & Program Counter ---
    MUX_2x1 #(32) pc_mux (
        .d0(PCPlus4),
        .d1(PCTarget),
        .s(PCSrc),
        .y(PCNext)
    );

    Program_Counter pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(PCNext),
        .pc_out(PC)
    );

    // --- PC Increment & Target Adders ---
    PC_plus_4 pc_add4 (
        .pc_plus_4_in(PC),
        .pc_plus_4_out(PCPlus4)
    );

    PCTarget_Adder pc_target_add (
        .pc_in(PC),
        .imm_ext(ImmExt),
        .pc_target(PCTarget)
    );

    // --- Instruction Memory ---
    Instruction_Memory imem (
        .clk(clk),
        .rst(rst),
        .inst_mem_read_addr(PC), // Word-aligned indexing
        .inst_mem_out(Instr)
    );

    // --- Register File ---
    Register_Files rf (
        .clk(clk),
        .rst(rst),
        .reg_write_addr(Instr[11:7]),
        .reg_read_addr1(Instr[19:15]),
        .reg_read_addr2(Instr[24:20]),
        .reg_write_data(Result),
        .reg_write_en(RegWrite),
        .reg_read_data1(RD1),
        .reg_read_data2(RD2)
    );

    assign SrcA = RD1;
    assign WriteData = RD2;

    // --- Immediate Generator ---
    Imme_Gen imm_gen (
        .instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    // --- ALU SrcB Mux & ALU ---
    MUX_2x1 #(32) srcb_mux (
        .d0(WriteData),
        .d1(ImmExt),
        .s(ALUSrc),
        .y(SrcB)
    );

    ALU alu_inst (
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // --- Data Memory ---
    Data_Memory dmem (
        .clk(clk),
        .rst(rst),
        .WE(MemWrite),
        .A(ALUResult), // Word-aligned indexing
        .WD(WriteData),
        .RD(ReadData)
    );

    // --- Result Mux ---
    MUX_3x1 #(32) result_mux (
        .d0(ALUResult),
        .d1(ReadData),
        .d2(PCPlus4),
        .s(ResultSrc),
        .y(Result)
    );

    // --- Control Unit ---
    Control_Unit control (
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7_5(Instr[30]),
        .Zero(Zero),
        .PCSrc(PCSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite),
        .ALUControl(ALUControl)
    );

endmodule