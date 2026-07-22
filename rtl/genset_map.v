module  general_set_mapping 	#(	parameter ADDR_WIDTH = 32,

						parameter NUM_LINES = 256,
						
						parameter ASSOCIATIVITY = 2,

						parameter LINE_SIZE = 2)
						
						(clk,rst,A,hit,DM_in,DM_addr,fill,data_out);


localparam 	NUM_SETS 			= NUM_LINES / (ASSOCIATIVITY * LINE_SIZE);

localparam 	INDEX_BITS 			= $clog2(NUM_SETS);

localparam 	OFFSET_BITS 		= $clog2(LINE_SIZE);

localparam 	LRU_BITS 			= (ASSOCIATIVITY <= 1) ? 1 : $clog2(ASSOCIATIVITY);

localparam 	CACHE_WIDTH 		= (LINE_SIZE*8);

localparam 	TAG_BITS 			= (ADDR_WIDTH - INDEX_BITS - OFFSET_BITS );

input 		[ADDR_WIDTH-1:0]	A,DM_addr;
input 							clk,rst,fill;
input 		[CACHE_WIDTH-1:0]	DM_in;

output 							hit; 
output 		[7:0] 				data_out;

wire 		[INDEX_BITS -1:0] 	dm_index;

wire 		[TAG_BITS-1:0] 		dm_tag;

wire 		[INDEX_BITS-1:0] 	index;

wire 		[TAG_BITS-1:0] 		tag;

wire 		[OFFSET_BITS-1:0] 	offset;

reg 		[7:0] 				temp_data;

reg 		[CACHE_WIDTH-1:0] 	cache_mem 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

reg 		[TAG_BITS-1:0] 		cache_tag 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

reg 							valid_bit 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

wire 		[ASSOCIATIVITY-1:0] hitx;



reg 		[LRU_BITS-1:0] 		pos;

reg 		[LRU_BITS-1:0] 		LRU_QUE	[ASSOCIATIVITY-1:0]	[0:NUM_SETS-1];

reg 		[LRU_BITS-1:0]		accessed_way;

reg 							found;

assign 	index 		= A[INDEX_BITS -1:OFFSET_BITS];
assign 	tag 		= A[ADDR_WIDTH -1:INDEX_BITS + OFFSET_BITS];
assign 	offset		= A[OFFSET_BITS-1:0];




integer 						m,i, j, k;




always @(*) begin
    temp_data = 8'd0;

    for(m = 0; m < ASSOCIATIVITY; m = m + 1)
        if(hitx[m])
            temp_data = cache_mem[m][index][offset*8 +: 8];
end


assign 	dm_index 	= DM_addr[INDEX_BITS-1:OFFSET_BITS];
assign 	dm_tag   	= DM_addr[ADDR_WIDTH-1:INDEX_BITS+ OFFSET_BITS ];



genvar g;
generate
    for(g = 0; g < ASSOCIATIVITY; g = g + 1) begin
        assign hitx[g] =
            valid_bit[g][index] &&
            (tag == cache_tag[g][index]);
    end
endgenerate

assign 	hit			= (|hitx); 

assign data_out = hit ? temp_data : 8'd0;

always @(posedge clk or negedge rst) 
    begin
		if (!rst) 
		begin
		
			for(i=0;i<ASSOCIATIVITY;i=i+1)
			begin										
					for(j=0;j<NUM_SETS;j=j+1)
					begin
						valid_bit[i][j] <= 1'b0;
						cache_mem[i][j] <= {CACHE_WIDTH{1'b0}};
						cache_tag[i][j] <= {TAG_BITS{1'b0}};
						LRU_QUE[i][j] <= i[LRU_BITS-1:0];
					end
			end						
		end
		else if(fill) 
			begin
			found = 1'b0;
			pos = 0;

			for(j=0;j<ASSOCIATIVITY;j=j+1)
					begin		
					
						if ((!found)&&(!valid_bit[j][dm_index]))			
							begin
							    
								cache_mem[j][dm_index] 		<= DM_in;			
								cache_tag[j][dm_index]   	<= dm_tag;
								valid_bit[j][dm_index]		<= 1'b1;
								accessed_way 				= j[LRU_BITS-1:0] ;
								
								for (k = 0; k < ASSOCIATIVITY; k = k + 1)
										if (LRU_QUE[k][dm_index] == accessed_way)
											pos = k;
								found = 1'b1;
																							
							end	
					end
					
					if(!found)
						begin
							accessed_way = LRU_QUE[0][dm_index];
							cache_mem[accessed_way][dm_index] <= DM_in;
							cache_tag[accessed_way][dm_index] <= dm_tag;
							valid_bit[accessed_way][dm_index] <= 1'b1;

							for(k=0; k<ASSOCIATIVITY-1; k=k+1) 
								begin
										LRU_QUE[k][dm_index] <= LRU_QUE[k+1][dm_index];
								end
							LRU_QUE[ASSOCIATIVITY-1][dm_index] <= accessed_way;
						end
						
					if(found)
						begin		
								for (k = 0; k < ASSOCIATIVITY-1; k = k + 1)
                                    begin
                                        if (k >= pos)
                                            LRU_QUE[k][dm_index] <= LRU_QUE[k+1][dm_index];
                                    end
                                    
                                    LRU_QUE[ASSOCIATIVITY-1][dm_index] <= accessed_way;
						end	
			end								
else 
			begin
				pos = 0;
					for(j=0;j<ASSOCIATIVITY;j=j+1)
						begin
						
							if(hitx[j]) 
							begin
								accessed_way 				= j[LRU_BITS-1:0] ;
								
								for(k=0;k<ASSOCIATIVITY;k=k+1)
									begin
										if(LRU_QUE[k][index] == accessed_way)
											pos = k;
									end
								for (k = 0; k < ASSOCIATIVITY-1; k = k + 1)
                                    begin
                                        if (k >= pos)
                                            LRU_QUE[k][index] <= LRU_QUE[k+1][index];
                                    end
                                    
                                    LRU_QUE[ASSOCIATIVITY-1][index] <= accessed_way;
							end
						 end
			end		
	end				
endmodule
					
				
					
			