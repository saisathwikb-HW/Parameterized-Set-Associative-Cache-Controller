module  general_set_mapping 	#(	parameter ADDR_WIDTH = 32,

						parameter NUM_LINES = 256,
						
						parameter ASSOCIATIVITY = 2,

						parameter LINE_SIZE = 2)
						
						(clk,rst,A,hit,DM_in,DM_addr,pending_addr,pending_data,fillread,fillwrite,data_out,rd_req,wr_req,data_in,victim_dirty,victim_data,victim_addr);


localparam 	NUM_SETS 			= NUM_LINES / (ASSOCIATIVITY * LINE_SIZE);

localparam 	INDEX_BITS 			= $clog2(NUM_SETS);

localparam 	OFFSET_BITS 		= $clog2(LINE_SIZE);

localparam 	LRU_BITS 			= (ASSOCIATIVITY <= 1) ? 1 : $clog2(ASSOCIATIVITY);

localparam 	CACHE_WIDTH 		= (LINE_SIZE*8);

localparam 	TAG_BITS 			= (ADDR_WIDTH - INDEX_BITS - OFFSET_BITS );

input 		[ADDR_WIDTH-1:0]	A,DM_addr,pending_addr;
input 							clk,rst,fillread,fillwrite,rd_req,wr_req;
input 		[CACHE_WIDTH-1:0]	DM_in;
input 		[7:0]   			data_in,pending_data;

output 							hit; 
output 		[7:0] 				data_out;

wire 		[INDEX_BITS -1:0] 	dm_index,pending_index;

wire 		[TAG_BITS-1:0] 		dm_tag,pending_tag;

wire 		[INDEX_BITS-1:0] 	index;

wire 		[TAG_BITS-1:0] 		tag;

wire 		[OFFSET_BITS-1:0] 	offset;

reg 		[7:0] 				temp_data;

reg 		[CACHE_WIDTH-1:0] 	cache_mem 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

reg 		[TAG_BITS-1:0] 		cache_tag 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

reg 							valid_bit 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

wire 		[ASSOCIATIVITY-1:0] hitx;

wire 		[OFFSET_BITS-1:0] 	pending_offset;



output 							victim_dirty;

output 		[CACHE_WIDTH-1:0] 	victim_data;

output 		[ADDR_WIDTH-1:0] 	victim_addr;

reg 		[LRU_BITS-1:0] 		pos;

reg 		[LRU_BITS-1:0] 		LRU_QUE	[ASSOCIATIVITY-1:0]	[0:NUM_SETS-1];

reg 		[LRU_BITS-1:0]		accessed_way;

reg 							found;

reg 							dirty_bit 	[0:ASSOCIATIVITY-1][0:NUM_SETS-1];

reg 		[CACHE_WIDTH-1:0] 	new_line;








assign index          = A[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
assign tag            = A[ADDR_WIDTH-1 : OFFSET_BITS + INDEX_BITS];
assign 	offset		 = A[OFFSET_BITS-1:0];








assign dm_index       = DM_addr[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
assign dm_tag       = DM_addr[ADDR_WIDTH-1 : OFFSET_BITS + INDEX_BITS];

assign pending_index  = pending_addr[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];


assign pending_tag      = pending_addr[ADDR_WIDTH-1 : OFFSET_BITS + INDEX_BITS];
assign  pending_offset 	= pending_addr[OFFSET_BITS-1:0];
					
assign victim_dirty = dirty_bit[LRU_QUE[0][pending_index]][pending_index];

assign victim_data =  cache_mem[LRU_QUE[0][pending_index]][pending_index];

assign victim_addr ={ cache_tag[LRU_QUE[0][pending_index]][pending_index], pending_index, {OFFSET_BITS{1'b0}}};		



integer 						m,i, j, k;


genvar g;
generate
    for(g = 0; g < ASSOCIATIVITY; g = g + 1) begin
        assign hitx[g] =
            valid_bit[g][index] &&
            (tag == cache_tag[g][index]);
    end
endgenerate

assign 	hit			= (|hitx); 

always @(*) begin
    temp_data = 8'd0;

    for(m = 0; m < ASSOCIATIVITY; m = m + 1)
        if(hitx[m])
            temp_data = cache_mem[m][index][offset*8 +: 8];
end


assign data_out = (hit&&rd_req) ? temp_data : 8'd0;



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
						LRU_QUE	 [i][j] <= i[LRU_BITS-1:0];
						dirty_bit[i][j] <= 1'b0;
					end
			end						
		end
		else if(fillread) 
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
								dirty_bit[j][dm_index] 		<= 1'b0;
								
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
							dirty_bit[accessed_way][dm_index] <= 1'b0;

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
			else if(fillwrite) 
			
			begin
			
			found = 1'b0;
			pos = 0;

			for(j=0;j<ASSOCIATIVITY;j=j+1)
					begin		
					
						if ((!found)&&(!valid_bit[j][pending_index]))			
							begin
							    accessed_way 						= j[LRU_BITS-1:0] ;
								new_line 							= DM_in;                             // Full cache block
								new_line[pending_offset*8 +:8] 		= pending_data; // Modify one byte		
				
								cache_tag[j][pending_index] <= pending_tag;
								valid_bit[j][pending_index]			<= 1'b1;								
								dirty_bit[j][pending_index] 		<= 1'b1;
								cache_mem[j][pending_index] 		<= new_line;      // Write the whole block
								
								for (k = 0; k < ASSOCIATIVITY; k = k + 1)begin
										if (LRU_QUE[k][pending_index] == accessed_way)
											pos = k;
											end
								found = 1'b1;
																							
							end	
					end
					
					if(!found)
						begin
											accessed_way 							= LRU_QUE[0][pending_index];
                                                   

											new_line 								= DM_in;                             // Full cache block
											new_line[pending_offset*8 +:8] 			= pending_data;
											cache_tag[accessed_way][pending_index]  <= pending_tag;
											valid_bit[accessed_way][pending_index] 	<= 1'b1;
											dirty_bit[accessed_way][pending_index] 	<= 1'b1;
											cache_mem[accessed_way][pending_index]	<=new_line;

											for(k=0; k<ASSOCIATIVITY-1; k=k+1) 
												begin
														LRU_QUE[k][pending_index] <= LRU_QUE[k+1][pending_index];
												end
											LRU_QUE[ASSOCIATIVITY-1][pending_index] <= accessed_way;
										end								
					if(found)
						begin		
								for (k = 0; k < ASSOCIATIVITY-1; k = k + 1)
                                    begin
                                        if (k >= pos)
                                            LRU_QUE[k][pending_index] <= LRU_QUE[k+1][pending_index];
                                    end
                                    
                                    LRU_QUE[ASSOCIATIVITY-1][pending_index] <= accessed_way;
						end	
			end																				
else if(hit)
    begin
	if(wr_req)
	begin
	pos = 0;
        for(m = 0; m < ASSOCIATIVITY; m = m + 1)
        begin
           if(hitx[m])
					begin
						cache_mem[m][index][offset*8 +:8] <= data_in;
						dirty_bit[m][index] <= 1'b1;

						accessed_way = m[LRU_BITS-1:0];
						

						// Find current LRU position
						for(k=0; k<ASSOCIATIVITY; k=k+1) begin
							if(LRU_QUE[k][index] == accessed_way)
								pos = k;
							end
						// Move to MRU
						for(k=0; k<ASSOCIATIVITY-1; k=k+1) begin
							if(k >= pos)
								LRU_QUE[k][index] <= LRU_QUE[k+1][index];								
							end
						LRU_QUE[ASSOCIATIVITY-1][index] <= accessed_way;
						end
					end
        end
	else if(rd_req) 
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
end

endmodule
	
				
					
				