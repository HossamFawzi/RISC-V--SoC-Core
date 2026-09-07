

module register_file (
    input  wire       pclk,
    input  wire       presetn,
    input  wire       write_enable,
    input  wire       read_enable,
    input  wire [7:0] address,
    input  wire [7:0] wdata,
    output reg  [7:0] rdata,

  
    output reg  [7:0] div_value,
    output reg  [7:0] data_tx,
    output reg        start,
    output reg        rw_mode,


    input  wire [7:0] data_rx,
    input  wire       ack,
    input  wire       nack,
    input  wire       busy
);

localparam ADDR_DIV_VALUE = 8'h00;
localparam ADDR_DATA_TX   = 8'h01;
localparam ADDR_DATA_RX   = 8'h02;
localparam ADDR_START     = 8'h03;
localparam ADDR_RW_MODE   = 8'h04;
localparam ADDR_STATUS    = 8'h05;


always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        div_value <= 8'h00;
        data_tx   <= 8'h00;
        start     <= 1'b0;
        rw_mode   <= 1'b0;
    end
    else begin
       
        start <= 1'b0;

        if (write_enable) begin
            case (address)
                ADDR_DIV_VALUE: div_value <= wdata;
                ADDR_DATA_TX:   data_tx   <= wdata;
                ADDR_START:     start     <= wdata[0];
                ADDR_RW_MODE:   rw_mode   <= wdata[0];
                default: ; 
            endcase
        end
    end
end

// Read logic
always @(*) begin
    case (address)
        ADDR_DIV_VALUE: rdata = div_value;
        ADDR_DATA_TX:   rdata = data_tx;
        ADDR_DATA_RX:   rdata = data_rx;
        ADDR_RW_MODE:   rdata = {7'b0, rw_mode};
        ADDR_STATUS:    rdata = {5'b0, busy, nack, ack};
        default:        rdata = 8'h00;
    endcase
end

endmodule
