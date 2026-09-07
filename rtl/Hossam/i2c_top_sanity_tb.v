`timescale 1ns/1ps
module i2c_top_sanity_tb;

reg         PCLK, PRST_n;
reg         PSEL_i2c, PEN, PWRITE;
reg  [31:0] PADDR, PWDATA;
wire [31:0] PRDATA_I2C;
wire        PREADY_i2c;
reg         sda_in;
wire        sda_out;

i2c_top dut (
    .PCLK      (PCLK),
    .PRST_n    (PRST_n),
    .PSEL_i2c  (PSEL_i2c),
    .PEN       (PEN),
    .PWRITE    (PWRITE),
    .PADDR     (PADDR),
    .PWDATA    (PWDATA),
    .PRDATA_I2C(PRDATA_I2C),
    .PREADY_i2c(PREADY_i2c),
    .sda_in    (sda_in),
    .sda_out   (sda_out)
);

always #5 PCLK = ~PCLK;

// simple APB write task
task apb_write(input [7:0] addr, input [7:0] data);
begin
    @(posedge PCLK);
    PSEL_i2c = 1; PWRITE = 1; PADDR = addr; PWDATA = data; PEN = 0;
    @(posedge PCLK);
    PEN = 1;
    @(posedge PCLK);
    PSEL_i2c = 0; PEN = 0;
end
endtask

initial begin
    PCLK     = 0;
    PRST_n   = 0;
    PSEL_i2c = 0;
    PEN      = 0;
    PWRITE   = 0;
    PADDR    = 0;
    PWDATA   = 0;
    sda_in   = 0;

    #12 PRST_n = 1;

    
    apb_write(8'h00, 8'd8);     
    apb_write(8'h01, 8'hA5);    
    apb_write(8'h04, 8'h01);    
    apb_write(8'h03, 8'h01);    

    #2000 $finish;
end

initial begin
    $dumpfile("i2c_top_sanity.vcd");
    $dumpvars(0, i2c_top_sanity_tb);
end

endmodule
