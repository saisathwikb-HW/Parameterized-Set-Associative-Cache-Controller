module cache_controller #(
    parameter ADDR_WIDTH     = 32,
    parameter NUM_LINES      = 256,
    parameter LINE_SIZE      = 2,
    parameter ASSOCIATIVITY  = 2
)(
    input                       clk,
    input                       rst,

    input  [ADDR_WIDTH-1:0]     A,
    input                       rd_req,
    input                       wr_req,
    input  [7:0]                data_in,

    input                       ready,
    input  [LINE_SIZE*8-1:0]    DM_in,
    input  [ADDR_WIDTH-1:0]     DM_addr,

    output                      req,
    output                      stall,
    output [7:0]                data_out,
	
	output                      WE,
	output [LINE_SIZE*8-1:0]    victim_data,
	output [ADDR_WIDTH-1:0]     victim_addr
);

wire hit;

wire fillread;
wire fillwrite;
wire capture_req;
wire victim_dirty;

wire [ADDR_WIDTH-1:0] pending_addr;
wire [7:0]            pending_data;




general_set_mapping #(
    .ADDR_WIDTH    (ADDR_WIDTH),
    .NUM_LINES     (NUM_LINES),
    .ASSOCIATIVITY (ASSOCIATIVITY),
    .LINE_SIZE     (LINE_SIZE)
) GSM (
    .clk(clk),
    .rst(rst),

    .A(A),
    .hit(hit),

    .DM_in(DM_in),
    .DM_addr(DM_addr),

    .pending_addr(pending_addr),
    .pending_data(pending_data),

    .fillread(fillread),
    .fillwrite(fillwrite),

    .data_out(data_out),

    .rd_req(rd_req),
    .wr_req(wr_req),

    .data_in(data_in),

    .victim_dirty(victim_dirty),

    .victim_data(victim_data),
    .victim_addr(victim_addr)
);

fsm cache_fsm (
    .clk(clk),
    .rst(rst),

    .rd_req(rd_req),
    .wr_req(wr_req),

    .hit(hit),

    .req(req),
    .ready(ready),

    .fillwrite(fillwrite),
    .fillread(fillread),

    .stall(stall),

    .capture_req(capture_req),

    .victim_dirty(victim_dirty),

    .WE(WE)
);

pending_buffer PBUF (
    .clk(clk),
    .rst(rst),

    .capture_req(capture_req),

    .A(A),
    .data_in(data_in),

    .pending_addr(pending_addr),
    .pending_data(pending_data)
);

endmodule
