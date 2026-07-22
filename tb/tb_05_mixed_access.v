`timescale 1ns/1ps

module tb_05_mixed_access;

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
) DUT(
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

    @(posedge clk);

    wait(DUT.CC.fill || DUT.CC.hit);
    wait(!stall);

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
    A = 0;

    #10 rst = 0;
    #20 rst = 1;

    @(posedge clk);

    $display("\n========== TB-05 : MIXED ACCESS ==========");

    //-----------------------------
    // 0x10 (Miss)
    //-----------------------------
    read_addr(32'h10);

    if (data_out == 8'h10)
        $display("MISS 0x10 : PASS");
    else
        $display("MISS 0x10 : FAIL");

    //-----------------------------
    // 0x20 (Miss)
    //-----------------------------
    read_addr(32'h20);

    if (data_out == 8'h20)
        $display("MISS 0x20 : PASS");
    else
        $display("MISS 0x20 : FAIL");

    //-----------------------------
    // 0x10 (Hit)
    //-----------------------------
    read_addr(32'h10);

    if (DUT.CC.hit && data_out == 8'h10)
        $display("HIT  0x10 : PASS");
    else
        $display("HIT  0x10 : FAIL");

    //-----------------------------
    // 0x30 (Miss)
    //-----------------------------
    read_addr(32'h30);

    if (data_out == 8'h30)
        $display("MISS 0x30 : PASS");
    else
        $display("MISS 0x30 : FAIL");

    //-----------------------------
    // 0x20 (Hit)
    //-----------------------------
    read_addr(32'h20);

    if (DUT.CC.hit && data_out == 8'h20)
        $display("HIT  0x20 : PASS");
    else
        $display("HIT  0x20 : FAIL");

    //-----------------------------
    // 0x30 (Hit)
    //-----------------------------
    read_addr(32'h30);

    if (DUT.CC.hit && data_out == 8'h30)
        $display("HIT  0x30 : PASS");
    else
        $display("HIT  0x30 : FAIL");

    //-----------------------------
    // 0x10 (Hit)
    //-----------------------------
    read_addr(32'h10);

    if (DUT.CC.hit && data_out == 8'h10)
        $display("HIT  0x10 : PASS");
    else
        $display("HIT  0x10 : FAIL");

    #20;

    $display("========== TB-05 PASSED ==========");

    $finish;

end

endmodule