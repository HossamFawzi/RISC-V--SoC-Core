`timescale 1ns/1ps
module shift_reg_tb;

 reg scl , rst;
 reg [7:0] data_in;
 reg sda_in;
 reg direction;
 reg enable ;
 reg load;
 wire  [7:0] data_out ;
 wire  sda_out;


shift_reg dut (

 .scl(scl) ,
 .rst(rst),
 .data_in(data_in),
 .sda_in(sda_in),
 .direction(direction),
 .enable(enable),
 .load(load),
 .data_out(data_out),
 .sda_out(sda_out),
 .tx_done(tx_done),
 .rx_done(done)
);

always #5 scl = ~scl;

initial begin
    scl       = 0;
    rst       = 0;
    data_in   = 8'b10101010;
    sda_in    = 0;
    direction = 0;
    enable    = 0;
    load      = 0;

    #10 rst = 1;

    #10 enable = 1;

    // Parallel load
    #10 direction = 1;
    load = 1;

    // Shift out
    #10 load = 0;

    #80 direction = 0;

    // Shift in
    sda_in = 1;
    #10 sda_in = 1;
    #10 sda_in = 0;
    #10 sda_in = 0;
    #10 sda_in = 1;
    #10 sda_in = 1;
    #10 sda_in = 0;
    #10 sda_in = 0;

    #100 $finish;
end
endmodule 