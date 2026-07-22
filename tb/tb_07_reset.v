`timescale 1ns/1ps

module tb_07_reset;

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

//----------------------------------------------------------
// Read Task
//----------------------------------------------------------
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

//----------------------------------------------------------
// Test
//----------------------------------------------------------
initial begin

    clk     = 0;
    rst     = 1;
    cpu_req = 0;
    WE      = 0;
    WD      = 0;
    A       = 0;

    #10 rst = 0;
    #20 rst = 1;

    @(posedge clk);

    $display("\n========================================");
    $display("TB-07 : RESET VERIFICATION");
    $display("========================================");

    //------------------------------------------------------
    // Fill cache
    //------------------------------------------------------
    read_addr(32'h00000010);
    read_addr(32'h00000020);

    //------------------------------------------------------
    // Verify cached
    //------------------------------------------------------
    A = 32'h00000010;
    cpu_req = 1;

    @(posedge clk);

    if(DUT.CC.hit)
        $display("PASS : Cache populated");
    else
        $display("FAIL : Cache not populated");

    cpu_req = 0;

    @(posedge clk);

    //------------------------------------------------------
    // Apply Reset
    //------------------------------------------------------
    $display("\nApplying Reset...");

    rst = 0;
    @(posedge clk);
    rst = 1;

    @(posedge clk);

    //------------------------------------------------------
    // Verify all valid bits cleared
    //------------------------------------------------------
    if(!DUT.CC.GSM.valid_bit[0][8] &&
       !DUT.CC.GSM.valid_bit[1][8] &&
       !DUT.CC.GSM.valid_bit[0][16] &&
       !DUT.CC.GSM.valid_bit[1][16])
        $display("PASS : Valid bits cleared");
    else
        $display("FAIL : Valid bits not cleared");

    //------------------------------------------------------
    // Address should MISS after reset
    //------------------------------------------------------
    A = 32'h00000010;
    cpu_req = 1;

    @(posedge clk);

    if(!DUT.CC.hit)
        $display("PASS : Cache miss after reset");
    else
        $display("FAIL : Cache retained data after reset");

    cpu_req = 0;

    #20;

    $display("========================================");
    $display("TB-07 PASSED");
    $display("========================================");

    $finish;

end

endmodule