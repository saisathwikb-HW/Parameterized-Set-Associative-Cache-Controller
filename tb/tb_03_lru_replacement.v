`timescale 1ns/1ps

module tb_03_lru_replacement;

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

task read_addr;
input [31:0] addr;
begin
    A = addr;
    cpu_req = 1;

    wait(DUT.CC.fill || DUT.CC.hit);
    wait(!stall);

    @(posedge clk);

    cpu_req = 0;

    @(posedge clk);
end
endtask

initial begin

    clk = 0;
    rst = 1;
    cpu_req = 0;
    WE = 0;
    WD = 0;

    #10 rst = 0;
    #20 rst = 1;

    @(posedge clk);

    $display("\n========== TB-03 LRU REPLACEMENT ==========");

    // Load A
    read_addr(32'h00000010);

    // Load B
    read_addr(32'h00000210);

    // Access A again
    read_addr(32'h00000010);

    // Load C (should evict B)
    read_addr(32'h00000410);

    // Access B again
    A = 32'h00000210;
    cpu_req = 1;

    @(posedge clk);

    if(!DUT.CC.hit)
        $display("PASS : LRU Replacement Verified (B Evicted)");
    else
        $display("FAIL : B Still Present");

    cpu_req = 0;

    #30;

    $display("========== TB-03 COMPLETE ==========");

    $finish;

end

endmodule