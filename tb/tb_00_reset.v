`timescale 1ns/1ps

module tb_00_reset;

parameter ADDR_WIDTH    = 32;
parameter NUM_LINES     = 256;
parameter LINE_SIZE     = 2;
parameter ASSOCIATIVITY = 2;
parameter MEM_LATENCY   = 4;

localparam NUM_SETS = NUM_LINES/(ASSOCIATIVITY*LINE_SIZE);

reg                     clk;
reg                     rst;
reg                     cpu_req;
reg                     WE;
reg [7:0]               WD;
reg [ADDR_WIDTH-1:0]    A;

wire                    stall;
wire [7:0]              data_out;

integer i,j;

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
    rst     = 1;      // inactive (active-low reset)
    cpu_req = 0;
    WE      = 0;
    WD      = 8'h00;
    A       = 32'h0;

    // Assert reset
    #10;
    rst = 0;

    #20;

    // Release reset
    rst = 1;

    @(posedge clk);

    $display("\n========== TB-00 RESET ==========");

    //-----------------------------
    // Controller outputs
    //-----------------------------

    if(DUT.cc.hit == 0)
        $display("PASS : hit reset");
    else
        $display("FAIL : hit reset");

    if(DUT.cc.req == 0)
        $display("PASS : req reset");
    else
        $display("FAIL : req reset");

    if(DUT.cc.fill == 0)
        $display("PASS : fill reset");
    else
        $display("FAIL : fill reset");

    if(stall == 0)
        $display("PASS : stall reset");
    else
        $display("FAIL : stall reset");

    if(data_out == 8'h00)
        $display("PASS : data_out reset");
    else
        $display("FAIL : data_out reset");

    //-----------------------------
    // Cache contents
    //-----------------------------

    for(i=0;i<ASSOCIATIVITY;i=i+1)
    begin
        for(j=0;j<NUM_SETS;j=j+1)
        begin

            if(DUT.cc.direct_M.valid_bit[i][j] != 0)
                $display("FAIL : valid_bit[%0d][%0d]",i,j);

            if(DUT.cc.direct_M.cache_tag[i][j] != 0)
                $display("FAIL : cache_tag[%0d][%0d]",i,j);

            if(DUT.cc.direct_M.cache_mem[i][j] != 0)
                $display("FAIL : cache_mem[%0d][%0d]",i,j);

        end
    end

    //-----------------------------
    // LRU Queue
    //-----------------------------

    for(i=0;i<ASSOCIATIVITY;i=i+1)
    begin
        for(j=0;j<NUM_SETS;j=j+1)
        begin
            if(DUT.cc.direct_M.LRU_QUE[i][j] != i)
                $display("FAIL : LRU_QUE[%0d][%0d]",i,j);
        end
    end

    $display("========== RESET TEST DONE ==========");

    #20;
    $finish;

end

endmodule