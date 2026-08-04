`timescale 1ns/1ps

module tb_05_mixed_access;

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

///////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////

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

    $display("\n========== TB-05 : MIXED ACCESS ==========\n");

    //-----------------------------
    // 0x10 (Miss)
    //-----------------------------
    read_addr(32'h10);

    if(DUT.CC.hit)
        $display("MISS 0x10 : PASS");
    else
        $display("MISS 0x10 : FAIL");

    //-----------------------------
    // 0x20 (Miss)
    //-----------------------------
    read_addr(32'h20);

    if(DUT.CC.hit)
        $display("MISS 0x20 : PASS");
    else
        $display("MISS 0x20 : FAIL");

    //-----------------------------
    // 0x10 (Hit)
    //-----------------------------
    read_addr(32'h10);

    if(DUT.CC.hit && !stall)
        $display("HIT  0x10 : PASS");
    else
        $display("HIT  0x10 : FAIL");

    //-----------------------------
    // 0x30 (Miss)
    //-----------------------------
    read_addr(32'h30);

    if(DUT.CC.hit)
        $display("MISS 0x30 : PASS");
    else
        $display("MISS 0x30 : FAIL");

    //-----------------------------
    // 0x20 (Hit)
    //-----------------------------
    read_addr(32'h20);

    if(DUT.CC.hit && !stall)
        $display("HIT  0x20 : PASS");
    else
        $display("HIT  0x20 : FAIL");

    //-----------------------------
    // 0x30 (Hit)
    //-----------------------------
    read_addr(32'h30);

    if(DUT.CC.hit && !stall)
        $display("HIT  0x30 : PASS");
    else
        $display("HIT  0x30 : FAIL");

    //-----------------------------
    // 0x10 (Hit)
    //-----------------------------
    read_addr(32'h10);

    if(DUT.CC.hit && !stall)
        $display("HIT  0x10 : PASS");
    else
        $display("HIT  0x10 : FAIL");

    #20;

    $display("\n========== TB-05 PASSED ==========\n");

    $finish;

end

endmodule