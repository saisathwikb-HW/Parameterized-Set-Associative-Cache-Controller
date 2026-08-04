`timescale 1ns/1ps

module tb_10_write_miss_clean;

parameter ADDR_WIDTH     = 32;
parameter NUM_LINES      = 256;
parameter LINE_SIZE      = 2;
parameter ASSOCIATIVITY  = 2;
parameter MEM_LATENCY    = 4;

reg clk;
reg rst;

reg [ADDR_WIDTH-1:0] A;
reg rd_req;
reg wr_req;
reg [7:0] cpu_data;

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

////////////////////////////////////////////////////////////

always #5 clk = ~clk;

////////////////////////////////////////////////////////////

initial begin

    clk      = 0;
    rst      = 0;
    rd_req   = 0;
    wr_req   = 0;
    A        = 32'h00000000;
    cpu_data = 8'h00;

    //--------------------------------------------------
    // Reset
    //--------------------------------------------------

    #20;
    rst = 1;

    //--------------------------------------------------
    // WRITE MISS
    //--------------------------------------------------

    @(negedge clk);
    A        = 32'h00000040;
    cpu_data = 8'hAA;
    wr_req   = 1;

    @(posedge clk);     // Request sampled

    @(negedge clk);
    wr_req = 0;

    //--------------------------------------------------
    // Wait until miss is serviced
    //--------------------------------------------------

    wait(stall);
    wait(!stall);
	$display("\n------------ WRITE MISS SERVICED ------------");
	$display("Hit        = %b", DUT.CC.hit);
	$display("Stall      = %b", stall);
	$display("Req        = %b", DUT.CC.req);
	$display("FillRead   = %b", DUT.CC.fillread);
	$display("FillWrite  = %b", DUT.CC.fillwrite);
	$display("Dirty Bit  = %b",
			 DUT.CC.GSM.dirty_bit[DUT.CC.GSM.accessed_way][32]);
	$display("Cache Line = %h",
			 DUT.CC.GSM.cache_mem[DUT.CC.GSM.accessed_way][32]);
    //--------------------------------------------------
    // READ SAME LOCATION
    //--------------------------------------------------

    @(negedge clk);
    rd_req = 1;

    @(posedge clk);
    #1;
	$display("\n------------ READ AFTER WRITE MISS ------------");
$display("Hit       = %b", DUT.CC.hit);
$display("Data Out  = %h", data_out);
$display("Expected  = AA", data_out);

if(data_out == 8'hAA)
begin
    $display("PASS : Write-allocate successful");
    $display("PASS : Updated data stored in cache");
    $display("PASS : Write miss (clean) verified");
end
else
begin
    $display("FAIL : Expected AA, Got %h", data_out);
end
   

    @(negedge clk);
    rd_req = 0;

    #20;
    $finish;

end

////////////////////////////////////////////////////////////

initial begin

$monitor(
"T=%0t  A=%h  RD=%b WR=%b Stall=%b Data=%h",
$time,
A,
rd_req,
wr_req,
stall,
data_out
);

end

endmodule