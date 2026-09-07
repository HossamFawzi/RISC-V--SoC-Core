module addr_decoder (
    input [31:0] core_addr_decoder,
    input access_req,
    output uart_sel, i2c_sel, addr_fault,//high when access_req is high but the addr is not in the range of neither uart nor i2c
    output [31:0] core_addr // or it can be deleted and recieved directly from the core
);

parameter [23:0] UART_BASE_24 = 24'h40_00_00;
parameter [23:0] I2C_BASE_24  = 24'h40_00_01;

assign uart_sel = (core_addr[31:8] == UART_BASE_24) & access_req;
assign i2c_sel  = (core_addr[31:8] == I2C_BASE_24)  & access_req;
assign addr_fault=access_req&(~uart_sel)&(~i2c_sel); 

assign core_addr= core_addr_decoder; //latching the addr to the APB
endmodule