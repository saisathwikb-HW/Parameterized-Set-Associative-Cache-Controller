`timescale 1ns/1ps

module tb_06_lru_complete;

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

//--------------------------------------------------
// Read Task
//--------------------------------------------------
task read_addr;
input [31:0] addr;
begin
    A = addr;
    cpu_req = 1;

    @(posedge clk);

    wait(DUT.CC.fill || DUT.CC.hit);
    wait(!stall);

    cpu_req = 0;

    @(posedge clk);
end
endtask

//--------------------------------------------------
// Test
//--------------------------------------------------
initial begin

    clk     = 0;
    rst     = 1;
    cpu_req = 0;
    WE      = 0;
    WD      = 8'h00;
    A       = 32'h0;

    #10 rst = 0;
    #20 rst = 1;

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

    // Hit -> 0x210 becomes LRU
    read_addr(32'h00000010);

    // Miss -> evicts 0x210
    read_addr(32'h00000410);

    //--------------------------------------------------
    // Verify first replacement
    //--------------------------------------------------

    A = 32'h00000010;
    cpu_req = 1;
    @(posedge clk);

    if (DUT.CC.hit && data_out==8'h10)
        $display("PASS : 0x10 retained");
    else
        $display("FAIL : 0x10 missing");

    cpu_req = 0;
    @(posedge clk);

    A = 32'h00000410;
    cpu_req = 1;
    @(posedge clk);

    if (DUT.CC.hit && data_out==8'h10)
        $display("PASS : 0x410 inserted");
    else
        $display("FAIL : 0x410 missing");

    cpu_req = 0;
    @(posedge clk);

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

    A = 32'h00000010;
    cpu_req = 1;
    @(posedge clk);

    if (DUT.CC.hit && data_out==8'h10)
        $display("PASS : 0x10 retained after second replacement");
    else
        $display("FAIL : 0x10 lost");

    cpu_req = 0;
    @(posedge clk);

    A = 32'h00000410;
    cpu_req = 1;
    @(posedge clk);

    if (!DUT.CC.hit)
        $display("PASS : 0x410 correctly evicted");
    else
        $display("FAIL : 0x410 still present");

    cpu_req = 0;

    #20;

    $display("========================================");
    $display("TB-06 PASSED");
    $display("========================================");

    $finish;

end

endmodule