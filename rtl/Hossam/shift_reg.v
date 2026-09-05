module shift_reg(
input  wire scl, rst,
input  wire [7:0] data_in,
input  wire sda_in,
input  wire direction,
input  wire enable ,
input  wire load,
output reg [7:0] data_out ,
output reg rx_done,
output reg tx_done,

output reg sda_out
);
reg [7:0] tx_buffer; 
reg [2:0] bit_count;

always@(posedge scl or negedge rst)begin

	if(!rst)
	begin
		data_out <=0;	 
		sda_out  <=0;
		tx_buffer <= 0;
		rx_done <= 0;
		tx_done <= 0 ;
		bit_count <= 0 ;
	end
	else if (enable)
	begin
		rx_done <= 0;
		tx_done <= 0;
		if(!direction) // recive
		begin
			data_out <= {data_out[6:0],{sda_in}};
			if (bit_count == 3'b111)
			begin
				rx_done <= 1 ;
				bit_count <= 0 ;
			end
			else 
			begin
				bit_count <= bit_count+1;
			end
		end
		else // transmit
		begin
			if (load)
			begin
				tx_buffer <= data_in;
				bit_count <= 0;
			end
			else
            begin
                sda_out   <= tx_buffer[7];  
				//bit_count <= bit_count +1 ;
                tx_buffer <= {tx_buffer[6:0], 1'b0};     
				if (bit_count == 3'b111)
				begin
					tx_done <= 1 ;
					bit_count <= 0 ;
				end
				else 
				begin
					bit_count <= bit_count +1 ;
				end
			end
		end
	end

end
endmodule