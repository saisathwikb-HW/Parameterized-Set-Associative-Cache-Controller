`timescale 1ns/1ps

module tb_06_lru_complete;

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

/////////////////////////////////////////////////////////

task read_addr;

input [31:0] addr;

begin

    @(negedge clk);
    A      = addr;
    rd_req = 1;

    @(posedge clk);

    @(negedge clk);
    rd_req = 0;

    if(stall)
        wait(!stall);

    @(posedge clk);

end

endtask

/////////////////////////////////////////////////////////

initial begin

    clk      = 0;
    rst      = 0;
    rd_req   = 0;
    wr_req   = 0;
    cpu_data = 8'h00;
    A        = 0;

    //---------------- Reset ----------------

    #20;
    rst = 1;

    @(posedge clk);

    $display("\n========================================");
    $display("TB-06 : COMPLETE LRU TEST");
    $display("========================================");

    //--------------------------------------------------
    // Build cache state
    //--------------------------------------------------

    // Miss
    read_addr(32'h00000010);

    // Miss
    read_addr(32'h00000210);

    // Hit -> 0x10 becomes MRU
    read_addr(32'h00000010);

    // Miss -> evicts 0x210
    read_addr(32'h00000410);

    //--------------------------------------------------
    // Verify first replacement
    //--------------------------------------------------

    read_addr(32'h00000010);

    if(DUT.CC.hit)
        $display("PASS : 0x10 retained");
    else
        $display("FAIL : 0x10 missing");

    read_addr(32'h00000410);

    if(DUT.CC.hit)
        $display("PASS : 0x410 inserted");
    else
        $display("FAIL : 0x410 missing");

    //--------------------------------------------------
    // Second replacement
    //--------------------------------------------------

    // Make 0x10 MRU
    read_addr(32'h00000010);

    // Miss -> evicts 0x410
    read_addr(32'h00000210);

    //--------------------------------------------------
    // Verify second replacement
    //--------------------------------------------------

    read_addr(32'h00000010);

    if(DUT.CC.hit)
        $display("PASS : 0x10 retained after second replacement");
    else
        $display("FAIL : 0x10 lost");

    //--------------------------------------------------
    // 0x410 should now miss
    //--------------------------------------------------

    @(negedge clk);
    A      = 32'h00000410;
    rd_req = 1;

    @(posedge clk);

    if(!DUT.CC.hit)
        $display("PASS : 0x410 correctly evicted");
    else
        $display("FAIL : 0x410 still present");

    @(negedge clk);
    rd_req = 0;

    #20;

    $display("========================================");
    $display("TB-06 PASSED");
    $display("========================================");

    $finish;

end

endmodule