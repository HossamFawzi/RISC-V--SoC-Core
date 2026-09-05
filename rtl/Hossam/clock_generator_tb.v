`timescale 1ns/1ps
module clock_generator_tb;
 reg sys_clk ;
 reg rst     ;
 reg enable  ;
 reg [7:0]div_value;
 wire scl;


clock_generator dut (
	.sys_clk(sys_clk),
	.rst(rst),
	.enable(enable),
	.div_value(div_value),
	.scl(scl)
);

always #5 sys_clk = ~sys_clk;

/*
initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0, clock_generator_tb);
end
*/

initial
begin

rst = 0;
sys_clk = 0;
enable =0 ;
div_value = 0;
#10 rst =1;
#20 enable = 1 ; div_value = 25;


#500 $finish;
end 
endmodule 