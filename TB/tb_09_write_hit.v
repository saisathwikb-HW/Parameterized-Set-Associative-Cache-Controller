`timescale 1ns/1ps

module tb_09_write_hit;

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

always #5 clk = ~clk;

initial begin
    clk      = 0;
    rst      = 0;
    A        = 0;
    rd_req   = 0;
    wr_req   = 0;
    cpu_data = 8'h00;

    //---------------- Reset ----------------
    #20;
    rst = 1;

    //---------------- Read Miss ----------------
    @(posedge clk);
    A      = 32'h20;
    rd_req = 1;

    @(posedge clk);
    rd_req = 0;

    wait(stall);
    wait(!stall);

        //---------------- Write Hit ----------------
    @(posedge clk);
    cpu_data = 8'h55;
    wr_req   = 1;

    #1;

    $display("\n------------ WRITE HIT ------------");
    $display("Hit        = %b", DUT.CC.hit);
    $display("Stall      = %b", stall);
    $display("Dirty Bit  = %b", DUT.CC.GSM.dirty_bit[DUT.CC.GSM.accessed_way][16]);
    $display("Cache Data = %h", DUT.CC.GSM.cache_mem[DUT.CC.GSM.accessed_way][16]);
    $display("FillRead   = %b", DUT.CC.fillread);
    $display("FillWrite  = %b", DUT.CC.fillwrite);
    $display("Req        = %b", DUT.CC.req);

    @(posedge clk);
    wr_req = 0;

       //---------------- Read Hit ----------------
    @(posedge clk);
    rd_req = 1;

    #1;

    $display("\n------------ READ AFTER WRITE ------------");
    $display("Hit       = %b", DUT.CC.hit);
    $display("Data Out  = %h", data_out);
    $display("Expected  = 55");

    if(data_out == 8'h55)
        $display("\nPASS : WRITE HIT VERIFIED\n");
    else
        $display("\nFAIL : Expected 55, Got %h\n", data_out);

    @(posedge clk);
    rd_req = 0;

    #20;
    $finish;
end

initial begin
    $monitor("T=%0t  A=%h  RD=%b WR=%b Stall=%b Data=%h",
             $time,
             A,
             rd_req,
             wr_req,
             stall,
             data_out);
end

endmodule
