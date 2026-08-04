`timescale 1ns/1ps

module tb_01_read_miss;

parameter ADDR_WIDTH    = 32;
parameter NUM_LINES     = 256;
parameter LINE_SIZE     = 2;
parameter ASSOCIATIVITY = 2;
parameter MEM_LATENCY   = 4;

reg clk;
reg rst;

reg rd_req;
reg wr_req;
reg [7:0] cpu_data;
reg [ADDR_WIDTH-1:0] A;

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

always #5 clk = ~clk;

initial begin

    clk      = 0;
    rst      = 0;
    rd_req   = 0;
    wr_req   = 0;
    cpu_data = 8'h00;
    A        = 32'h00000010;

    //---------------- Reset ----------------

    #20;
    rst = 1;

    $display("\n========== TB-01 READ MISS ==========\n");

    //--------------------------------------------------
    // Issue Read Miss
    //--------------------------------------------------

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);

    @(negedge clk);
    rd_req = 0;

    //--------------------------------------------------
    // Observe controller until miss serviced
    //--------------------------------------------------

    repeat(15) begin
        @(posedge clk);

        $display("T=%0t Stall=%b Req=%b Ready=%b FillRead=%b FillWrite=%b Hit=%b Data=%h",
                 $time,
                 stall,
                 DUT.CC.req,
                 DUT.ready,
                 DUT.CC.fillread,
                 DUT.CC.fillwrite,
                 DUT.CC.hit,
                 data_out);
    end

    //--------------------------------------------------
    // Verify cache line loaded
    //--------------------------------------------------

    if (DUT.CC.hit)
        $display("\nPASS : Cache line loaded successfully\n");
    else
        $display("\nFAIL : Cache line not loaded\n");

    //--------------------------------------------------
    // Verify cache hit by re-reading
    //--------------------------------------------------

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);

    #1;

    if (!stall && DUT.CC.hit)
        $display("PASS : Read hit after refill");
    else
        $display("FAIL : Cache did not hit after refill");

    @(negedge clk);
    rd_req = 0;

    #20;

    $display("\n========== TB-01 COMPLETE ==========\n");

    $finish;

end

endmodule