`timescale 1ns/1ps

module tb_03_lru_replacement;

parameter ADDR_WIDTH     = 32;
parameter NUM_LINES      = 256;
parameter LINE_SIZE      = 2;
parameter ASSOCIATIVITY  = 2;
parameter MEM_LATENCY    = 4;

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
// Read Task
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

    if(stall) begin
        wait(!stall);
    end

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

    $display("\n========== TB-03 LRU REPLACEMENT ==========\n");

    //--------------------------------------------------
    // A
    //--------------------------------------------------

    read_addr(32'h00000010);

    //--------------------------------------------------
    // B (same set, different tag)
    //--------------------------------------------------

    read_addr(32'h00000210);

    //--------------------------------------------------
    // Access A again
    //--------------------------------------------------

    read_addr(32'h00000010);

    //--------------------------------------------------
    // C (same set, different tag)
    //--------------------------------------------------

    read_addr(32'h00000410);

    //--------------------------------------------------
    // Check if B was evicted
    //--------------------------------------------------

    @(negedge clk);
    A      = 32'h00000210;
    rd_req = 1;

    @(posedge clk);

    #1;

    if(!DUT.CC.hit)
        $display("\nPASS : LRU Replacement Verified (B Evicted)\n");
    else
        $display("\nFAIL : B Still Present\n");

    @(negedge clk);
    rd_req = 0;

    #30;

    $display("\n========== TB-03 COMPLETE ==========\n");

    $finish;

end

endmodule