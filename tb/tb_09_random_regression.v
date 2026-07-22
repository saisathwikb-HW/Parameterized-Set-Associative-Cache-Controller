`timescale 1ns/1ps

module tb_09_random_regression;

reg         clk;
reg         rst;
reg         cpu_req;
reg         WE;
reg [31:0]  A;
reg [7:0]   WD;
wire [7:0]  data_out;
wire        stall;

integer i;
integer timeout;

top_module DUT (
    .clk(clk),
    .rst(rst),
    .cpu_req(cpu_req),
    .WE(WE),
    .A(A),
    .WD(WD),
    .data_out(data_out),
    .stall(stall)
);

always #5 clk = ~clk;

task automatic read_addr;
    input [31:0] addr;
begin
    @(negedge clk);
    cpu_req = 1;
    WE      = 0;
    A       = addr;

    @(posedge clk);
    cpu_req = 0;

    timeout = 0;

    while (!(DUT.CC.fill || DUT.CC.hit) && timeout < 100)
    begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == 100)
    begin
        $display("\n========================================");
        $display("TIMEOUT at time %0t", $time);
        $display("Address = %h", addr);
        $display("FSM state = %0d", DUT.CC.cache_fsm.state);
        $display("req   = %b", DUT.req);
        $display("ready = %b", DUT.ready);
        $display("stall = %b", stall);
        $display("hit   = %b", DUT.CC.hit);
        $display("fill  = %b", DUT.CC.fill);
        $display("========================================\n");
        $finish;
    end

    @(posedge clk);
end
endtask

initial
begin
    clk     = 0;
    rst     = 0;
    cpu_req = 0;
    WE      = 0;
    A       = 0;
    WD      = 0;

    #20;
    rst = 1;

    $display("\n========================================");
    $display("TB-09 : RANDOM REGRESSION");
    $display("========================================");

    for(i = 0; i < 12; i = i + 1)
    begin
        read_addr($random);
    end

    $display("\n========================================");
    $display("TB-09 PASSED");
    $display("========================================");

    $finish;
end

endmodule

