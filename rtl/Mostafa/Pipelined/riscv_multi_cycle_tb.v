`timescale 1ns/1ps

module riscv_multi_cycle_tb;

    reg clk;
    reg rst;

    integer errors;
    integer checks;

    // DUT
    riscv_multi_cycle dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock: 10ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Checking Tasks
    task check_reg;
        input [4:0]   idx;
        input [31:0]  expected;
        input [255:0] name;
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
        input [5:0]   addr;
        input [31:0]  expected;
        input [255:0] name;
        begin
            checks = checks + 1;
            if (dut.mem.mem[addr] !== expected) begin
                errors = errors + 1;
                $display("[FAIL] %0t ns : %0s (mem[%0d]) = 0x%08h, expected 0x%08h",
                          $time, name, addr, dut.mem.mem[addr], expected);
            end else begin
                $display("[PASS] %0t ns : %0s (mem[%0d]) = 0x%08h",
                          $time, name, addr, dut.mem.mem[addr]);
            end
        end
    endtask

    // Program Preload into Unified Memory
    task load_program;
        begin
            dut.mem.mem[0]  = 32'h00c00093; // addi x1,x0,12
            dut.mem.mem[1]  = 32'h00a00113; // addi x2,x0,10
            dut.mem.mem[2]  = 32'h002081b3; // add  x3,x1,x2
            dut.mem.mem[3]  = 32'h40208233; // sub  x4,x1,x2
            dut.mem.mem[4]  = 32'h0020f2b3; // and  x5,x1,x2
            dut.mem.mem[5]  = 32'h0020e333; // or   x6,x1,x2
            dut.mem.mem[6]  = 32'h001123b3; // slt  x7,x2,x1
            dut.mem.mem[7]  = 32'h00302023; // sw   x3,0(x0)
            dut.mem.mem[8]  = 32'h00002403; // lw   x8,0(x0)
            dut.mem.mem[9]  = 32'h00108463; // beq  x1,x1,8 (Target PC=44 -> index 11)
            dut.mem.mem[10] = 32'h06300493; // addi x9,x0,99 (SKIPPED)
            dut.mem.mem[11] = 32'h01400513; // addi x10,x0,20
            dut.mem.mem[12] = 32'h00208463; // beq  x1,x2,8 (NOT TAKEN)
            dut.mem.mem[13] = 32'h02100593; // addi x11,x0,33
            dut.mem.mem[14] = 32'h0040066f; // jal  x12,4 (Target PC=60 -> index 15)
            dut.mem.mem[15] = 32'h03700693; // addi x13,x0,55
        end
    endtask

    // Main Stimulus
    initial begin
        errors = 0;
        checks = 0;

        rst = 1'b1;
        #2;
        rst = 1'b0; // Reset active
        #11;
        rst = 1'b1;

        load_program;

        // Allow ~80 clock cycles for multi-cycle execution across all instructions
        repeat (80) @(posedge clk);
        #1;

        $display("\n---------------- Multi-Cycle Check Results ----------------");
        check_reg (1,  32'd12, "addi x1,x0,12");
        check_reg (2,  32'd10, "addi x2,x0,10");
        check_reg (3,  32'd22, "add  x3,x1,x2");
        check_reg (4,  32'd2,  "sub  x4,x1,x2");
        check_reg (5,  32'd8,  "and  x5,x1,x2");
        check_reg (6,  32'd14, "or   x6,x1,x2");
        check_reg (7,  32'd1,  "slt  x7,x2,x1");
        check_mem (0,  32'd22, "sw   x3,0(x0)");
        check_reg (8,  32'd22, "lw   x8,0(x0)");
        check_reg (9,  32'd0,  "addi x9 (skipped by beq)");
        check_reg (10, 32'd20, "addi x10 (branch target)");
        check_reg (11, 32'd33, "addi x11 (beq not taken)");
        check_reg (12, 32'd60, "jal  x12 link = PC+4");
        check_reg (13, 32'd55, "addi x13 (jal target)");

        $display("\n==========================================================");
        if (errors == 0)
            $display("ALL %0d CHECKS PASSED", checks);
        else
            $display("%0d / %0d CHECKS FAILED", errors, checks);
        $display("==========================================================\n");

        $finish;
    end

endmodule