`timescale 1ns/1ps

module tb_11_dirty_eviction;

parameter ADDR_WIDTH     = 32;
parameter NUM_LINES      = 256;
parameter LINE_SIZE      = 2;
parameter ASSOCIATIVITY  = 2;
parameter MEM_LATENCY    = 4;

reg clk;
reg rst;

reg [ADDR_WIDTH-1:0] A;
reg rd_req;
reg wr_req;
reg [7:0] cpu_data;

wire stall;
wire [7:0] data_out;

top_module #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_LINES(NUM_LINES),
    .LINE_SIZE(LINE_SIZE),
    .ASSOCIATIVITY(ASSOCIATIVITY),
    .MEM_LATENCY(MEM_LATENCY)
) DUT (
    .clk(clk),
    .rst(rst),
    .A(A),
    .rd_req(rd_req),
    .wr_req(wr_req),
    .cpu_data(cpu_data),
    .stall(stall),
    .data_out(data_out)
);

///////////////////////////////////////////////////////

always #5 clk = ~clk;

///////////////////////////////////////////////////////

initial begin

    clk      = 0;
    rst      = 0;
    rd_req   = 0;
    wr_req   = 0;
    A        = 0;
    cpu_data = 8'h00;

    //---------------- Reset ----------------

    #20;
    rst = 1;

    //-------------------------------------------------
    // STEP 1 : Read 0x40 (Fill Way-0)
    //-------------------------------------------------

    @(negedge clk);
    A      = 32'h00000040;
    rd_req = 1;

    @(posedge clk);
    @(negedge clk);
    rd_req = 0;

    wait(stall);
    wait(!stall);

    //-------------------------------------------------
    // STEP 2 : Write AA (Make line dirty)
    //-------------------------------------------------

    @(negedge clk);
    A        = 32'h00000040;
    cpu_data = 8'hAA;
    wr_req   = 1;

    @(posedge clk);
    @(negedge clk);
    wr_req = 0;

    //-------------------------------------------------
    // STEP 3 : Read 0xC0 (Fill Way-1)
    //-------------------------------------------------

    @(negedge clk);
    A      = 32'h000000C0;
    rd_req = 1;

    @(posedge clk);
    @(negedge clk);
    rd_req = 0;

    wait(stall);
    wait(!stall);

    //-------------------------------------------------
    // STEP 4 : Read 0x140
    // Forces eviction (0x40 should be victim)
    //-------------------------------------------------

    @(negedge clk);
    A      = 32'h00000140;
    rd_req = 1;

    @(posedge clk);
    @(negedge clk);
    rd_req = 0;

    wait(stall);
    wait(!stall);

    //-------------------------------------------------
    // STEP 5 : Read 0x40 again
    // Should MISS and fetch AA from memory
    //-------------------------------------------------

    @(negedge clk);
    A      = 32'h00000040;
    rd_req = 1;

    @(posedge clk);

    wait(stall);
    wait(!stall);

    #1;

    if(data_out == 8'hAA)
        $display("\nPASS : DIRTY EVICTION VERIFIED\n");
    else
        $display("\nFAIL : Expected AA, Got %h\n", data_out);

    @(negedge clk);
    rd_req = 0;

    #20;
    $finish;

end

///////////////////////////////////////////////////////

initial begin

$monitor(
"T=%0t A=%h RD=%b WR=%b Stall=%b Data=%h",
$time,
A,
rd_req,
wr_req,
stall,
data_out
);

end