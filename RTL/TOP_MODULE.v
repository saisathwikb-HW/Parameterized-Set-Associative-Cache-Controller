module top_module #(
    parameter ADDR_WIDTH     = 32,
    parameter NUM_LINES      = 256,
    parameter LINE_SIZE      = 2,
    parameter ASSOCIATIVITY  = 2,
    parameter MEM_LATENCY    = 4
)(
    input                       clk,
    input                       rst,

    // CPU Interface
    input  [ADDR_WIDTH-1:0]     A,
    input                       rd_req,
    input                       wr_req,
    input  [7:0]                cpu_data,

    // CPU Outputs
    output                      stall,
    output [7:0]                data_out
);


wire req;
wire ready;

wire [LINE_SIZE*8-1:0] DM_in;
wire [ADDR_WIDTH-1:0]  DM_addr;

wire WE;
wire [LINE_SIZE*8-1:0] victim_data;
wire [ADDR_WIDTH-1:0]  victim_addr;



cache_controller #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .NUM_LINES      (NUM_LINES),
    .LINE_SIZE      (LINE_SIZE),
    .ASSOCIATIVITY  (ASSOCIATIVITY)
) CC (
    .clk            (clk),
    .rst            (rst),

    .A              (A),
    .rd_req         (rd_req),
    .wr_req         (wr_req),
    .data_in        (cpu_data),

    .ready          (ready),
    .DM_in          (DM_in),
    .DM_addr        (DM_addr),

    .req            (req),
    .stall          (stall),
    .data_out       (data_out),

    .WE             (WE),
    .victim_data    (victim_data),
    .victim_addr    (victim_addr)
);


Data_Memory #(
    .ADDR_WIDTH     (ADDR_WIDTH),
    .LINE_SIZE      (LINE_SIZE),
    .MEM_LATENCY    (MEM_LATENCY)
) DM (
    .clk            (clk),
    .rst            (rst),

    .req            (req),
    .ready          (ready),

    .WE             (WE),
    .WD             (victim_data),
    .A              (WE ? victim_addr : A),

    .RD             (DM_in),
    .DM_addr        (DM_addr)
);


endmodule
