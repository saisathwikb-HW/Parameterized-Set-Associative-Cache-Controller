`timescale 1ns/1ps

module tb_02_read_hit;

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

    //--------------------------------------------------
    // FIRST ACCESS : Read Miss
    //--------------------------------------------------

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);

    @(negedge clk);
    rd_req = 0;

    wait(stall);
    wait(!stall);

    //--------------------------------------------------
    // SECOND ACCESS : Read Hit
    //--------------------------------------------------

    $display("\n========== TB-02 READ HIT ==========\n");

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);

    #1;

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

    if(!DUT.CC.fillread && !DUT.CC.fillwrite)
        $display("PASS : No Cache Fill");
    else
        $display("FAIL : Unexpected Cache Fill");

    $display("Returned Data = %h", data_out);

    @(negedge clk);
    rd_req = 0;

    #20;

    $display("\n========== TB-02 COMPLETE ==========\n");

    $finish;

end

endmodule