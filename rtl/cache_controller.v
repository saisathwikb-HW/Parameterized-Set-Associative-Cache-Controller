module cache_controller #(	parameter ADDR_WIDTH = 32,

								parameter NUM_LINES = 256,

								parameter LINE_SIZE = 2,
								
								parameter ASSOCIATIVITY = 2)

(clk,rst,A,req,ready,DM_in,DM_addr,cpu_req,stall,data_out);

input clk,rst,cpu_req;
input[31:0]A;
input [LINE_SIZE*8-1:0] DM_in;
input [31:0] DM_addr;
input ready;

output req,stall;
output [7:0]data_out;

wire hit,fill;

general_set_mapping  #(
			.ADDR_WIDTH (ADDR_WIDTH),
			.NUM_LINES  (NUM_LINES),
			.LINE_SIZE  (LINE_SIZE) ,
			.ASSOCIATIVITY(ASSOCIATIVITY)
						) GSM (
			.clk      (clk),
			.rst      (rst),
			.A        (A),
			.hit      (hit),
			.DM_in    (DM_in),
			.DM_addr  (DM_addr),
			.fill     (fill),
			.data_out (data_out)
			);

fsm         cache_fsm (.clk(clk),.rst(rst),.cpu_req(cpu_req),.hit(hit),.req(req),.ready(ready),.fill(fill),.stall(stall));

endmodule

