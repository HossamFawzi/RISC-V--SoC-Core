module apb_interface (
    input  wire        PCLK,
    input  wire        PRST_n,
    input  wire        PSEL_i2c,
    input  wire        PEN,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA_I2C,
    output reg         PREADY_i2c,

    output reg         write_enable,
    output reg         read_enable,
    output reg  [7:0]  address,
    output reg  [7:0]  wdata,
    input  wire [7:0]  rdata
);

wire access = PSEL_i2c & PEN;

always @(*) begin
    write_enable = access & PWRITE;
    read_enable  = access & ~PWRITE;
    address      = PADDR[7:0];   
    wdata        = PWDATA[7:0];
end

always @(*) begin
    PREADY_i2c = access;
end

always @(*) begin
    PRDATA_I2C = {24'b0, rdata};
end

endmodule
