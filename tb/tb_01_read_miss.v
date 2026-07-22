`timescale 1ns/1ps

module tb_01_read_miss;

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

    $display("\n========== TB-01 READ MISS ==========");

    // Issue read request
    cpu_req = 1;

    // Observe controller for 15 clock cycles
    repeat(15) begin
        @(posedge clk);
        $display("T=%0t  stall=%b req=%b ready=%b fill=%b hit=%b data=%h",
                 $time,
                 stall,
                 DUT.CC.req,
                 DUT.ready,
                 DUT.CC.fill,
                 DUT.CC.hit,
                 data_out);
    end

    // Final checks
    if (DUT.CC.hit)
        $display("PASS : Cache line loaded successfully");
    else
        $display("FAIL : Cache line not loaded");

    $display("Final Data = %h", data_out);

    cpu_req = 0;

    #20;
    $display("========== TB-01 COMPLETE ==========");
    $finish;

end

endmodule