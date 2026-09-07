`timescale 1ns/1ps

module riscv_single_cycle_tb;
    reg clk;
    reg rst;
    integer errors;
    integer checks;

    riscv_single_cycle dut (
        .clk(clk),
        .rst(rst)
    );

    initial clk = 1'b0; 
    always #5 clk = ~clk;   // Clock: 10ns period

    // ------------------------------------------------------------------
    // Self-check tasks
    // ------------------------------------------------------------------
    task check_reg;
        input [4:0]  idx;
        input [31:0] expected;
        input [255:0] name; // debug label
        begin
            checks = checks + 1;
            if (dut.rf.reg_file[idx] !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0t ns : %0s (x%0d) = 0x%08h, expected 0x%08h",
                          $time, name, idx, dut.rf.reg_file[idx], expected);
            end else begin
                $display("[PASS] %0t ns : %0s (x%0d) = 0x%08h",
                          $time, name, idx, dut.rf.reg_file[idx]);
            end
        end
    endtask

    task check_mem;
        input [5:0]  addr;
        input [31:0] expected;
        input [255:0] name;
        begin
            checks = checks + 1;
            if (dut.dmem.reg_file[addr] !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0t ns : %0s (mem[%0d]) = 0x%08h, expected 0x%08h",
                          $time, name, addr, dut.dmem.reg_file[addr], expected);
            end else begin
                $display("[PASS] %0t ns : %0s (mem[%0d]) = 0x%08h",
                          $time, name, addr, dut.dmem.reg_file[addr]);
            end
        end
    endtask

    task check_val;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] name;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0t ns : %0s = 0x%08h, expected 0x%08h",
                          $time, name, actual, expected);
            end else begin
                $display("[PASS] %0t ns : %0s = 0x%08h",
                          $time, name, actual);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Instruction preload
    //   addr  instr        meaning
    //   0     00c00093     addi x1, x0, 12
    //   4     00a00113     addi x2, x0, 10
    //   8     002081b3     add  x3, x1, x2      -> 22
    //   12    40208233     sub  x4, x1, x2      -> 2
    //   16    0020f2b3     and  x5, x1, x2      -> 8
    //   20    0020e333     or   x6, x1, x2      -> 14
    //   24    001123b3     slt  x7, x2, x1      -> 1  (10<12)
    //   28    00302023     sw   x3, 0(x0)       -> mem[0] = 22
    //   32    00002403     lw   x8, 0(x0)       -> x8 = 22
    //   36    00108463     beq  x1, x1, 8       -> TAKEN, skip addr 40
    //   40    06300493     addi x9, x0, 99      -> must be SKIPPED (x9 stays 0)
    //   44    01400513     addi x10, x0, 20     -> branch target, x10 = 20
    //   48    00208463     beq  x1, x2, 8       -> NOT TAKEN (12 != 10)
    //   52    02100593     addi x11, x0, 33     -> must execute, x11 = 33
    //   56    0040066f     jal  x12, 4          -> x12 = 60 (link = PC+4)
    //   60    03700693     addi x13, x0, 55     -> jal target, x13 = 55
    // ------------------------------------------------------------------
    task load_program;
        begin
            dut.imem.inst_mem[0]  = 32'h00c00093; // addi x1,x0,12
            dut.imem.inst_mem[4]  = 32'h00a00113; // addi x2,x0,10
            dut.imem.inst_mem[8]  = 32'h002081b3; // add  x3,x1,x2
            dut.imem.inst_mem[12] = 32'h40208233; // sub  x4,x1,x2
            dut.imem.inst_mem[16] = 32'h0020f2b3; // and  x5,x1,x2
            dut.imem.inst_mem[20] = 32'h0020e333; // or   x6,x1,x2
            dut.imem.inst_mem[24] = 32'h001123b3; // slt  x7,x2,x1
            dut.imem.inst_mem[28] = 32'h00302023; // sw   x3,0(x0)
            dut.imem.inst_mem[32] = 32'h00002403; // lw   x8,0(x0)
            dut.imem.inst_mem[36] = 32'h00108463; // beq  x1,x1,8
            dut.imem.inst_mem[40] = 32'h06300493; // addi x9,x0,99 (skip target)
            dut.imem.inst_mem[44] = 32'h01400513; // addi x10,x0,20
            dut.imem.inst_mem[48] = 32'h00208463; // beq  x1,x2,8
            dut.imem.inst_mem[52] = 32'h02100593; // addi x11,x0,33
            dut.imem.inst_mem[56] = 32'h0040066f; // jal  x12,4
            dut.imem.inst_mem[60] = 32'h03700693; // addi x13,x0,55
        end
    endtask

    // ------------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------------
    initial begin
        errors = 0;
        checks = 0;

        // -------------------------------------------------------------
        // Case 0: Reset behavior
        //   rst is active-low and edge-triggered (negedge rst clears
        //   state). Start high, then drive a falling edge to reset.
        // -------------------------------------------------------------
        rst = 1'b1;
        #2;
        rst = 1'b0;   // falling edge -> clears PC, reg file, instr mem, data mem
        #11;          // hold through at least one clk edge while rst==0

        // Check everything came out of reset at 0
        check_val(dut.PC, 32'h0, "PC after reset");
        check_reg(1, 32'h0, "x1 after reset");
        check_reg(5, 32'h0, "x5 after reset");
        check_mem(0, 32'h0, "mem[0] after reset");

        // -------------------------------------------------------------
        // Release reset and load the program before the next clk edge
        // -------------------------------------------------------------
        rst = 1'b1;
        load_program;

        // -------------------------------------------------------------
        // Run 16 instructions (16 clk edges after reset release)
        // -------------------------------------------------------------
        repeat (16) @(posedge clk);
        #1; // let combinational/writeback settle

        $display("\n---------------- Register/Memory checks ----------------");
        check_reg (1,  32'd12, "addi x1,x0,12");
        check_reg (2,  32'd10, "addi x2,x0,10");
        check_reg (3,  32'd22, "add  x3,x1,x2");
        check_reg (4,  32'd2,  "sub  x4,x1,x2");
        check_reg (5,  32'd8,  "and  x5,x1,x2");
        check_reg (6,  32'd14, "or   x6,x1,x2");
        check_reg (7,  32'd1,  "slt  x7,x2,x1");
        check_mem (0,  32'd22, "sw   x3,0(x0)");
        check_reg (8,  32'd22, "lw   x8,0(x0)");
        check_reg (9,  32'd0,  "addi x9 (must be skipped by taken beq)");
        check_reg (10, 32'd20, "addi x10 (beq-taken branch target)");
        check_reg (11, 32'd33, "addi x11 (beq NOT taken, must execute)");
        check_reg (12, 32'd60, "jal  x12 link = PC+4");
        check_reg (13, 32'd55, "addi x13 (jal target)");

        // -------------------------------------------------------------
        // Case: mid-simulation reset re-check (design must recover)
        // -------------------------------------------------------------
        rst = 1'b0;   // falling edge -> reset again
        #11;
        check_val(dut.PC, 32'h0, "PC after mid-sim reset");
        check_reg(3, 32'h0, "x3 cleared after mid-sim reset");
        check_mem(0, 32'h0, "mem[0] cleared after mid-sim reset");
        rst = 1'b1;

        // -------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------
        $display("\n==========================================================");
        if (errors == 0)
            $display("ALL %0d CHECKS PASSED", checks);
        else
            $display("%0d / %0d CHECKS FAILED", errors, checks);
        $display("==========================================================\n");

        $finish;
    end

    // ------------------------------------------------------------------
    // Optional per-cycle trace for debugging
    // ------------------------------------------------------------------
    initial begin
        $display(" time |    PC    |   Instr    | RegWrite MemWrite ALUSrc PCSrc ResultSrc ImmSrc ALUControl");
    end
    always @(posedge clk) begin
        $display("%0t | %08h | %08h |    %b        %b       %b      %b     %b        %b     %b",
                 $time, dut.PC, dut.Instr, dut.RegWrite, dut.MemWrite,
                 dut.ALUSrc, dut.PCSrc, dut.ResultSrc, dut.ImmSrc, dut.ALUControl);
    end

endmodule
