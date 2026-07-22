module top_module #(			parameter ADDR_WIDTH = 32,

								parameter NUM_LINES = 256,

								parameter LINE_SIZE = 2,
								
								parameter ASSOCIATIVITY = 2,
								
								parameter MEM_LATENCY = 4)
								
(clk,rst,A,cpu_req,stall,WE,WD,data_out);


input clk ,rst ,cpu_req,WE;

input [7:0] WD;

input [ADDR_WIDTH-1:0]A;

output [7:0] data_out;

output stall;

wire req,ready,hit,fill;

wire [LINE_SIZE*8-1:0]DM_in;

wire [ADDR_WIDTH-1:0]DM_addr;


cache_controller #(
					.ADDR_WIDTH (ADDR_WIDTH),
					.NUM_LINES  (NUM_LINES),
					.LINE_SIZE  (LINE_SIZE),
					.ASSOCIATIVITY(ASSOCIATIVITY)
				) CC (
					.clk      (clk),
					.rst      (rst),
					.A        (A),
					.req      (req),
					.ready    (ready),
					.DM_in    (DM_in),
					.DM_addr  (DM_addr),
					.cpu_req  (cpu_req),
					.stall    (stall),
					.data_out (data_out)
				);

Data_Memory      #(	
					.ADDR_WIDTH (ADDR_WIDTH),
					.LINE_SIZE  (LINE_SIZE),
					.MEM_LATENCY(MEM_LATENCY)
					)DM(
					.clk(clk),.rst(rst),.WE(WE),.WD(WD),.A(A),.RD(DM_in),.req(req),.ready(ready),.DM_addr(DM_addr));


endmodule