`timescale 1ns/1ps

module tb_08_boundary_address;

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

//////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////

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
    $display("TB-08 : BOUNDARY ADDRESS TEST");
    $display("========================================");

    //------------------------------------------------
    // Lowest Address
    //------------------------------------------------

    read_addr(32'h00000000);

    if(DUT.CC.hit && !stall)
        $display("PASS : Lowest address loaded");
    else
        $display("FAIL : Lowest address");

    //------------------------------------------------
    // Highest Address
    //------------------------------------------------

    read_addr(32'hFFFFFFFF);

    if(DUT.CC.hit && !stall)
        $display("PASS : Highest address loaded");
    else
        $display("FAIL : Highest address");

    //------------------------------------------------
    // Lowest Address Hit
    //------------------------------------------------

    @(negedge clk);
    A      = 32'h00000000;
    rd_req = 1;

    @(posedge clk);

    if(DUT.CC.hit && !stall)
        $display("PASS : Lowest address hit");
    else
        $display("FAIL : Lowest address hit");

    @(negedge clk);
    rd_req = 0;

    @(posedge clk);

    //------------------------------------------------
    // Highest Address Hit
    //------------------------------------------------

    @(negedge clk);
    A      = 32'hFFFFFFFF;
    rd_req = 1;

    @(posedge clk);

    if(DUT.CC.hit && !stall)
        $display("PASS : Highest address hit");
    else
        $display("FAIL : Highest address hit");

    @(negedge clk);
    rd_req = 0;

    #20;

    $display("========================================");
    $display("TB-08 PASSED");
    $display("========================================");

    $finish;

end

endmodule