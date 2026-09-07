module APB_bus (
    input uart_sel, i2c_sel, addr_fault, PCLK, PRST_n, 
    input [31:0] core_addr,
    input PREADY_uart, PREADY_i2c, //from peripherals (slaves)
    input core_memread, core_memwrite, // coming from control unit
    input [31:0] PRDATA_UART, PRDATA_I2C, //data for reading 
    input [31:0] core_wdata, //reg file data for storing 
    output reg PSEL_uart, PSEL_i2c, //registered versions of i2c_sel, uart_sel, 
    output reg PEN, //Peripherals enable
    output reg PWRITE, //writing in peripherals
    output reg  [31:0] PADDR, PWDATA,
    output core_stall,
    output reg [31:0] core_rdata //data returned to memread mux 
);
parameter IDLE=2'b00, SETUP=2'b01, ACCESS=2'b10;
reg [1:0] current_state, next_state;

always @(posedge PCLK or negedge PRST_n) begin
        if (!PRST_n) 
            current_state <= IDLE;
        else current_state <= next_state;
    end
//Next state logic , also add mealy outputs 
always @(*) begin    
        case (current_state)
            IDLE: begin
                if ((core_memread | core_memwrite) && (uart_sel | i2c_sel | addr_fault)) begin
                    next_state = SETUP;
                end else 
                    next_state = IDLE;
                end
            SETUP: begin
                next_state= ACCESS;
                end
            ACCESS: begin
                if ((PSEL_uart && PREADY_uart) || (PSEL_i2c && PREADY_i2c) || (!PSEL_uart && !PSEL_i2c)) begin
                    next_state = IDLE;
                end else
                    next_state = ACCESS; 
            end
            default: next_state = IDLE; 
        endcase
    end
//moore outputs

always @(posedge PCLK or negedge PRST_n) begin
    if (!PRST_n) begin
        PSEL_uart  <= 1'b0;
            PSEL_i2c   <= 1'b0;  
            PEN        <= 1'b0;
            PADDR      <= 32'd0;
            PWDATA     <= 32'd0;
            PWRITE     <= 1'b0;
    end else begin
        case(current_state)
            IDLE: begin 
                PEN <= 1'b0;
                if ((core_memread | core_memwrite) && (uart_sel | i2c_sel| addr_fault)) begin
                        // Latching for transmission 
                        PSEL_uart  <= uart_sel;
                        PSEL_i2c   <= i2c_sel;
                        PADDR      <= core_addr;   
                        PWDATA     <= core_wdata;  
                        PWRITE     <= core_memwrite; 
                    end else begin
                        PSEL_uart  <= 1'b0;
                        PSEL_i2c   <= 1'b0;
                    end
            end
            SETUP: begin
                PEN<=1'b1; // to accomedate the 1 cycle delay
            end
            ACCESS: begin
                if ((PSEL_uart && PREADY_uart) || (PSEL_i2c && PREADY_i2c) || (!PSEL_uart && !PSEL_i2c)) begin
                    PEN<= 1'b0;
                    PSEL_uart <= 1'b0;
                    PSEL_i2c  <= 1'b0;
                    if (PSEL_uart && !PWRITE) core_rdata <= PRDATA_UART;
                    else if (PSEL_i2c && !PWRITE) core_rdata <= PRDATA_I2C;
                    else core_rdata <= 32'h0;   // fault case: no real data
                    end
            end
        endcase
    end
end

assign core_stall = 
    ((current_state == IDLE) && (core_memread | core_memwrite) && (uart_sel | i2c_sel | addr_fault)) |
    (current_state == SETUP) |
    ((current_state == ACCESS) && !((PSEL_uart & PREADY_uart) | (PSEL_i2c & PREADY_i2c) | (!PSEL_uart & !PSEL_i2c)));
endmodule