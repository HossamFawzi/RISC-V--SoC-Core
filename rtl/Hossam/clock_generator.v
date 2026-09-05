module clock_generator (
input wire sys_clk , 
input wire rst    ,
input wire enable ,
input wire [7:0]div_value,
output reg scl

);

reg [7:0]counter ;
always@(posedge sys_clk or negedge rst)begin

	if (!rst)
	begin
		counter <= 0;
		scl <= 0;
	end
	
	else if(enable == 1'b1)
	begin
			//counter <= 0;
			counter <= counter +1;	
		if (counter == (div_value/2)-1)
			begin
			scl <= ~scl ;
			counter <= 0;
			end
	end
end

endmodule 
