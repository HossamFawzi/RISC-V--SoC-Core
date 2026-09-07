module i2c_fsm (
    input  wire       sys_clk,   
    input  wire       scl,                     
    input  wire       rst,
    input  wire       rx_done,
    input  wire       tx_done,
    input  wire [7:0] data_rx,
    input  wire       start,
    input  wire       rw_mode,   

    output reg        direction,
    output reg        enable,
    output reg        load,
    output reg        ack,
    output reg        nack,
    output wire       busy       
);

reg [3:0] current_state, next_state;

localparam IDLE        = 4'b0000;
localparam START       = 4'b0001;
localparam ADDRESS     = 4'b0010;
localparam ACK_ADDR    = 4'b0011;
localparam DATA_TX     = 4'b0100;
localparam ACK_DATA_TX = 4'b0101;
localparam DATA_RX     = 4'b0110;
localparam ACK_DATA_RX = 4'b0111;
localparam STOP        = 4'b1000;
)
assign busy = (current_state != IDLE);


// State register
always @(posedge sys_clk or negedge rst) begin
    if (!rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

reg [3:0] state_scl_sync;

always @(posedge scl or negedge rst) begin
    if (!rst)
        state_scl_sync <= IDLE;
    else
        state_scl_sync <= current_state;
end

// Next-state logic
always @(*) begin
    case (current_state)
        IDLE        : next_state = start   ? START      : IDLE;
        START       : next_state = ADDRESS;
        ADDRESS     : next_state = tx_done ? ACK_ADDR    : ADDRESS;
        ACK_ADDR    : next_state = rw_mode ? DATA_TX     : DATA_RX;
        DATA_TX     : next_state = tx_done ? ACK_DATA_TX : DATA_TX;
        ACK_DATA_TX : next_state = STOP;
        DATA_RX     : next_state = rx_done ? ACK_DATA_RX : DATA_RX;
        ACK_DATA_RX : next_state = STOP;
        STOP        : next_state = IDLE;
        default     : next_state = IDLE;
    endcase
end

always @(*) begin
    direction = 0;
    enable    = 0;
    load      = 0;
    ack       = 0;
    nack      = 0;

    case (current_state)
        IDLE: enable = 0;

        START: enable = 1;

        ADDRESS: begin
            enable    = 1;
            direction = 1;
            if (state_scl_sync != ADDRESS)
                load = 1;
            else
                load = 0;
        end

        ACK_ADDR: begin
            enable    = 1;
            direction = 0;
        end

        DATA_TX: begin
            enable    = 1;
            direction = 1;
            if (state_scl_sync != DATA_TX)
                load = 1;
            else
                load = 0;
        end

        ACK_DATA_TX: begin
            enable    = 1;
            direction = 0;
        end

        DATA_RX: begin
            enable    = 1;
            direction = 0;
        end

        ACK_DATA_RX: begin
            enable    = 1;
            direction = 1;
            ack       = 1;
        end

        STOP: enable = 0;
    endcase
end

endmodule
