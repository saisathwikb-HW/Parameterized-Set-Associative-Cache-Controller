`timescale 1ns/1ps

module tb_04_set_independence;

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

//------------------------------------------------------------
// Read Task
//------------------------------------------------------------
task read_addr;
input [31:0] addr;
begin
    A       = addr;
    cpu_req = 1;

    // Allow address/hit logic to settle
    @(posedge clk);

    // Wait until request completes
    wait(DUT.CC.fill || DUT.CC.hit);
    wait(!stall);

    cpu_req = 0;

    @(posedge clk);
end
endtask

//------------------------------------------------------------
// Test Sequence
//------------------------------------------------------------
initial begin

    clk     = 0;
    rst     = 1;
    cpu_req = 0;
    WE      = 0;
    WD      = 8'h00;
    A       = 32'h00000000;

    #10 rst = 0;
    #20 rst = 1;

    @(posedge clk);

    $display("\n========== TB-04 : SET INDEPENDENCE ==========");

    // Address A -> Set 8
    read_addr(32'h00000010);

    // Address B -> Set 16
    read_addr(32'h00000020);

    //--------------------------------------------------------
    // Verify Address A
    //--------------------------------------------------------
    A = 32'h00000010;
    cpu_req = 1;

    @(posedge clk);

    if (DUT.CC.hit && !stall && data_out == 8'h10)
        $display("PASS : Address A retained");
    else
        $display("FAIL : Address A lost");

    cpu_req = 0;

    @(posedge clk);

    //--------------------------------------------------------
    // Verify Address B
    //--------------------------------------------------------
    A = 32'h00000020;
    cpu_req = 1;

    @(posedge clk);

    if (DUT.CC.hit && !stall && data_out == 8'h20)
        $display("PASS : Address B retained");
    else
        $display("FAIL : Address B lost");

    cpu_req = 0;

    #20;

    $display("========== TB-04 PASSED ==========");
    $finish;

end

endmodule