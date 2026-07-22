`timescale 1ns/1ps

module tb_02_read_hit;

parameter ADDR_WIDTH    = 32;
parameter NUM_LINES     = 256;
parameter LINE_SIZE     = 2;
parameter ASSOCIATIVITY = 2;
parameter MEM_LATENCY   = 4;

reg clk;
reg rst;
reg cpu_req;
reg WE;
reg [7:0] WD;
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
    .cpu_req(cpu_req),
    .WE(WE),
    .WD(WD),
    .A(A),
    .stall(stall),
    .data_out(data_out)
);

always #5 clk = ~clk;

initial begin

    clk     = 0;
    rst     = 1;
    cpu_req = 0;
    WE      = 0;
    WD      = 8'h00;
    A       = 32'h00000010;

    // Reset
    #10 rst = 0;
    #20 rst = 1;
    @(posedge clk);

    //---------------------------------------------------
    // First Access (Read Miss)
    //---------------------------------------------------

    cpu_req = 1;

    wait(DUT.CC.fill);
    wait(!stall);

    @(posedge clk);

    //---------------------------------------------------
    // Second Access (Read Hit)
    //---------------------------------------------------

    $display("\n========== TB-02 READ HIT ==========");

    cpu_req = 1;

    @(posedge clk);

    if(DUT.CC.hit)
        $display("PASS : Cache Hit");
    else
        $display("FAIL : Cache Miss");

    if(!stall)
        $display("PASS : No Stall");
    else
        $display("FAIL : Stall Asserted");

    if(!DUT.CC.req)
        $display("PASS : No Memory Request");
    else
        $display("FAIL : Unexpected Memory Request");

    if(!DUT.CC.fill)
        $display("PASS : No Cache Fill");
    else
        $display("FAIL : Unexpected Cache Fill");

    if(data_out == 8'h10)
        $display("PASS : Correct Data Returned = %h", data_out);
    else
        $display("FAIL : Incorrect Data Returned = %h", data_out);

    $display("========== TB-02 COMPLETE ==========");

    #20;
    $finish;

end

endmodule