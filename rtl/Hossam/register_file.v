module register_file (
    // APB interface side
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [7:0]  pwdata,
    output reg  [7:0]  prdata,

    // Hardware side - outputs to other modules
    output reg  [7:0]  div_value,
    output reg  [7:0]  data_tx,
    output reg         start,
    output reg         rw_mode,

    // Hardware side - inputs from other modules
    input  wire [7:0]  data_rx,
    input  wire        ack,
    input  wire        nack,
    input  wire        busy
);