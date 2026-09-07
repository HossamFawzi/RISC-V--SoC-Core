// RISCV 32bit : module PCTarget_Adder
// implementation of PC target adder for RISCV 32bit architecture
module PCTarget_Adder (
    input  wire [31:0] pc_in,
    input  wire [31:0] imm_ext,
    output wire [31:0] pc_target
);
    assign pc_target = pc_in + imm_ext;
endmodule