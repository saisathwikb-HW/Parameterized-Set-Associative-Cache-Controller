`timescale 1ns/1ps

module tb_01_1_memory_check;

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

/////////////////////////////////////////////////////////

always #5 clk = ~clk;

/////////////////////////////////////////////////////////

initial begin

    clk      = 0;
    rst      = 0;
    rd_req   = 0;
    wr_req   = 0;
    cpu_data = 8'h00;
    A        = 32'h00000010;

    //---------------- Reset ----------------

    #20;
    rst = 1;

    //--------------------------------------------------
    // Generate one read request
    //--------------------------------------------------

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);

    @(negedge clk);
    rd_req = 0;

    //--------------------------------------------------
    // Observe controller for 15 cycles
    //--------------------------------------------------

    repeat(15) begin
        @(posedge clk);

        $display("--------------------------------");
        $display("Time      : %0t",$time);
        $display("stall     : %b",stall);
        $display("req       : %b",DUT.CC.req);
        $display("ready     : %b",DUT.ready);
        $display("fillread  : %b",DUT.CC.fillread);
        $display("fillwrite : %b",DUT.CC.fillwrite);
        $display("hit       : %b",DUT.CC.hit);
        $display("DM_in     : %h",DUT.DM_in);
        $display("data_out  : %h",data_out);
    end

    $finish;

end

endmodule