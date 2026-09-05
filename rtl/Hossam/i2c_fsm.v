module i2c_fsm (

 input wire scl,
 input wire rst,
 input wire rx_done,
 input wire tx_done,
 input wire [7:0] data_rx,


 output reg start,
 output reg direction,
 output reg enable,
 output reg load,
 output reg [7:0]data_tx,
 output reg [7:0]div_value,
 output reg ack,
 output reg nack
 
 
 
);

reg [3:0] current_state, next_state;

parameter IDLE        = 4'b0000;
parameter START       = 4'b0001;
parameter ADDRESS     = 4'b0010;
parameter ACK_ADDR    = 4'b0011;
parameter DATA_TX     = 4'b0100;
parameter ACK_DATA_TX = 4'b0101;
parameter DATA_RX     = 4'b0110;
parameter ACK_DATA_RX = 4'b0111;
parameter STOP        = 4'b1000;

always@(posedge scl or negedge rst)
begin
    if(!rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always@(*)
begin
    case(current_state)
        IDLE:
            if (start)
                next_state = START;
            else
                next_state = IDLE;

        START:
            next_state = ADDRESS;

        ADDRESS:
            if (tx_done)
                next_state = ACK_ADDR;
            else
                next_state = ADDRESS;

        ACK_ADDR:
            if (direction)          // write
                next_state = DATA_TX;
            else                    // read
                next_state = DATA_RX;

        DATA_TX:
            if (tx_done)
                next_state = ACK_DATA_TX;
            else
                next_state = DATA_TX;

        ACK_DATA_TX:
            next_state = STOP;

        DATA_RX:
            if (rx_done)
                next_state = ACK_DATA_RX;
            else
                next_state = DATA_RX;

        ACK_DATA_RX:
            next_state = STOP;

        STOP:
            next_state = IDLE;

        default:
            next_state = IDLE;
    endcase
end
endmodule 