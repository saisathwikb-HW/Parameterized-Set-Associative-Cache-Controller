module Data_Memory #( 	parameter ADDR_WIDTH=32,
						parameter LINE_SIZE = 2,
						parameter MEM_LATENCY =1)
						
						(clk,rst,WE,WD,A,RD,req,ready,DM_addr);

    input clk,rst ,WE,req;
    
    input [ADDR_WIDTH-1:0]A;
	
	input [7:0]WD;
	
    output reg [LINE_SIZE*8-1:0]RD;
	output reg ready;
	output reg [ADDR_WIDTH-1:0]DM_addr;
	
    
  reg [7:0] mem [0:1023];
  wire [9:0] addr = A[9:0];
  
 wire [9:0] base_addr;

localparam OFFSET_BITS = $clog2(LINE_SIZE);

 
 reg [9:0] rd_addr;


  integer i;
  
reg req_d;


always @(posedge clk or negedge rst)
begin

    if(!rst)
        req_d <= 1'b0;
    else
        req_d <= req;
end

wire req_pulse = req & ~req_d;



assign base_addr = {rd_addr[9:OFFSET_BITS], {OFFSET_BITS{1'b0}}};


initial begin
    for(i=0;i<1024;i=i+1)
        mem[i] = i[7:0];
end


localparam COUNT_BITS = (MEM_LATENCY <= 1) ? 1 : $clog2(MEM_LATENCY);

reg [COUNT_BITS-1:0] count;
reg busy;


always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        busy  <= 0;
        ready <= 0;
        count <= 0;
    end
    else
    begin
        if(req_pulse && !busy)
        begin
            busy    <= 1;
            ready   <= 0;
            count   <= 0;

            rd_addr <= A[9:0];
            DM_addr <= A;
        end
        else if(busy)
                begin
                    if(count == MEM_LATENCY-1)
                    begin
                        for(i=0;i<LINE_SIZE;i=i+1)
                            RD[i*8 +: 8] <= mem[base_addr+i];
                
                        busy  <= 0;
                        ready <= 1;
                    end
                    else
                    begin
                        count <= count + 1;
                        ready <= 0;
                    end
                end
        else
            ready <= 0;

        if(WE) begin
            mem[addr] <= WD;
           
             end
             
    end
end

  
endmodule