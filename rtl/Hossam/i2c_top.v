
module i2c_top (
  
    input  wire        PCLK,
    input  wire        PRST_n,
    input  wire        PSEL_i2c,
    input  wire        PEN,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output wire [31:0] PRDATA_I2C,
    output wire        PREADY_i2c,

   
    input  wire         sda_in,
    output wire          sda_out
);


wire        write_enable, read_enable;
wire [7:0]  reg_address, reg_wdata, reg_rdata;

wire [7:0]  div_value;
wire [7:0]  data_tx;
wire        start;
wire        rw_mode;
wire [7:0]  data_rx;
wire        ack, nack, busy;

wire        direction, enable, load;
wire        scl;
wire        tx_done, rx_done;

// --- APB interface ---
apb_interface u_apb_interface (
    .PCLK        (PCLK),
    .PRST_n      (PRST_n),
    .PSEL_i2c    (PSEL_i2c),
    .PEN         (PEN),
    .PWRITE      (PWRITE),
    .PADDR       (PADDR),
    .PWDATA      (PWDATA),
    .PRDATA_I2C  (PRDATA_I2C),
    .PREADY_i2c  (PREADY_i2c),
    .write_enable(write_enable),
    .read_enable (read_enable),
    .address     (reg_address),
    .wdata       (reg_wdata),
    .rdata       (reg_rdata)
);

// --- Register file ---
register_file u_register_file (
    .pclk        (PCLK),
    .presetn     (PRST_n),
    .write_enable(write_enable),
    .read_enable (read_enable),
    .address     (reg_address),
    .wdata       (reg_wdata),
    .rdata       (reg_rdata),
    .div_value   (div_value),
    .data_tx     (data_tx),
    .start       (start),
    .rw_mode     (rw_mode),
    .data_rx     (data_rx),
    .ack         (ack),
    .nack        (nack),
    .busy        (busy)
);

// --- FSM controller (main logic on PCLK; load pulse synced via scl) ---
i2c_fsm u_i2c_fsm (
    .sys_clk   (PCLK),
    .scl       (scl),
    .rst       (PRST_n),
    .rx_done   (rx_done),
    .tx_done   (tx_done),
    .data_rx   (data_rx),
    .start     (start),
    .rw_mode   (rw_mode),
    .direction (direction),
    .enable    (enable),
    .load      (load),
    .ack       (ack),
    .nack      (nack),
    .busy      (busy)
);

// --- Clock generator (drives SCL) ---
clock_generator u_clock_generator (
    .sys_clk  (PCLK),
    .rst      (PRST_n),
    .enable   (enable),
    .div_value(div_value),
    .scl      (scl)
);

// --- Shift register (drives/samples SDA) ---
shift_reg u_shift_reg (
    .scl      (scl),
    .rst      (PRST_n),
    .data_in  (data_tx),
    .sda_in   (sda_in),
    .direction(direction),
    .enable   (enable),
    .load     (load),
    .data_out (data_rx),
    .rx_done  (rx_done),
    .tx_done  (tx_done),
    .sda_out  (sda_out)
);

endmodule
