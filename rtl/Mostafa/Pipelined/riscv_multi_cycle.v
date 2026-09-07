// RISC-V 32-bit Multi-Cycle Top Level Module
module riscv_multi_cycle (
    input wire clk,
    input wire rst
);
    // Control Wires
    wire        PCWrite, AdrSrc, MemWrite, IRWrite, RegWrite, Zero;
    wire [1:0]  ResultSrc, ALUSrcA, ALUSrcB, ImmSrc;
    wire [2:0]  ALUControl;

    // Datapath Wires and Non-Architectural Registers
    wire [31:0] PC, PCNext, Adr;
    wire [31:0] ReadData;
    wire [31:0] Instr, Data, RD1, RD2, A, B;
    wire [31:0] ImmExt;
    wire [31:0] SrcA, SrcB;
    wire [31:0] ALUResult, ALUOut, Result;
    
    reg  [31:0] OldPC;
    reg  [31:0] Instr_reg, Data_reg, A_reg, B_reg, ALUOut_reg;

    // --- PC Register ---
    always @(posedge clk or negedge rst)
     begin
        if (!rst) 
        begin
            OldPC <= 32'b0;
        end 
        else if (IRWrite) 
        begin
            OldPC <= PC;
        end
    end

    // Enable-controlled Program Counter
    always @(posedge clk or negedge rst)
     begin
        if (!rst)
            A_reg <= 32'b0; // Dummy reference
    end

    // Program Counter Module Reused with Enable
    wire [31:0] pc_in_mux = Result;
    reg  [31:0] pc_reg;
    always @(posedge clk or negedge rst)
     begin
        if (!rst)
            pc_reg <= 32'b0;
        else if (PCWrite)
            pc_reg <= pc_in_mux;
    end
    assign PC = pc_reg;

    // --- Memory Address Mux ---
    MUX_2x1 #(32) adr_mux (
        .d0(PC),
        .d1(Result),
        .s(AdrSrc),
        .y(Adr)
    );

    // --- Unified Memory ---
    Memory mem (
        .clk(clk),
        .rst(rst),
        .WE(MemWrite),
        .A(Adr),
        .WD(B),
        .RD(ReadData)
    );

    // --- Instruction & Data Registers ---
    always @(posedge clk or negedge rst) 
    begin
        if (!rst) 
        begin
            Instr_reg <= 32'b0;
            Data_reg  <= 32'b0;
        end 
        else 
        begin
            if (IRWrite) 
            Instr_reg <= ReadData;

            Data_reg <= ReadData;
        end
    end
    assign Instr = Instr_reg;
    assign Data  = Data_reg;

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

    // --- Datapath Pipeline Registers (A, B) ---
    always @(posedge clk or negedge rst) 
    begin
        if (!rst) begin
            A_reg <= 32'b0;
            B_reg <= 32'b0;
        end else begin
            A_reg <= RD1;
            B_reg <= RD2;
        end
    end
    assign A = A_reg;
    assign B = B_reg;

    // --- Immediate Generator ---
    Imme_Gen imm_gen (
        .instr(Instr),
        .ImmSrc(ImmSrc),
        .ImmExt(ImmExt)
    );

    // --- ALUSrcA Mux ---
    MUX_3x1 #(32) srca_mux (
        .d0(PC),
        .d1(OldPC),
        .d2(A),
        .s(ALUSrcA),
        .y(SrcA)
    );

    // --- ALUSrcB Mux ---
    MUX_3x1 #(32) srcb_mux (
        .d0(B),
        .d1(ImmExt),
        .d2(32'd4),
        .s(ALUSrcB),
        .y(SrcB)
    );

    // --- ALU ---
    ALU alu_inst (
        .SrcA(SrcA),
        .SrcB(SrcB),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // --- ALUOut Register ---
    always @(posedge clk or negedge rst)
     begin
        if (!rst)
            ALUOut_reg <= 32'b0;
        else
            ALUOut_reg <= ALUResult;
    end
    assign ALUOut = ALUOut_reg;

    // --- Result Mux ---
    MUX_3x1 #(32) result_mux (
        .d0(ALUOut),
        .d1(Data),
        .d2(ALUResult),
        .s(ResultSrc),
        .y(Result)
    );

    // --- Multi-Cycle Controller ---
    Control_Unit control (
        .clk(clk),
        .rst(rst),
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7_5(Instr[30]),
        .Zero(Zero),
        .PCWrite(PCWrite),
        .AdrSrc(AdrSrc),
        .MemWrite(MemWrite),
        .IRWrite(IRWrite),
        .ResultSrc(ResultSrc),
        .ALUControl(ALUControl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite)
    );

endmodule