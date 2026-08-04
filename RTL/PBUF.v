module pending_buffer (capture_req,clk,rst,pending_addr,pending_data,A,data_in);

input   capture_req,clk,rst;
input  [31:0]A;
input [7:0]data_in;
output  reg [31:0]pending_addr;
output  reg [7:0]pending_data;

always @ (posedge clk or negedge rst )
begin
if(!rst)
begin
    pending_addr <= 32'd0;
    pending_data <= 8'd0;
end
else if(capture_req)
				begin
					pending_data  <= data_in;
					pending_addr  <= A;
					end
end
endmodule