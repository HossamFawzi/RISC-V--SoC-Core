module apb_interface (

    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [7:0]  pwdata,
    output reg  [7:0]  prdata,

   
    output reg         write_enable,
    output reg         read_enable,
    output reg  [7:0]  address,
    output reg  [7:0]  wdata,
    input  wire [7:0]  rdata
);

//reg


always@(posedge pclk or negedge presetn)
begin
	if(!presetn)
	begin
	
	end
	else
	begin
	
	end
end




endmodule