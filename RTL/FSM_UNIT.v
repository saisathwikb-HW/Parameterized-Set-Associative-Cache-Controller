module fsm(clk,rst,rd_req,wr_req,hit,req,ready,fillwrite,fillread,stall,capture_req,victim_dirty,WE);

input clk ,rst, rd_req,wr_req,hit,ready,victim_dirty;
output reg req,fillwrite,fillread,stall,WE;
output capture_req;


localparam COMPARE    = 3'd0;
localparam MISS_CHECK = 3'd1;
localparam WRITE_BACK = 3'd2;
localparam READ_GAP   = 3'd3;   // NEW
localparam READ_MISS  = 3'd4;

reg [2:0] state, nextstate;
reg pending_write;

wire miss_detect;

assign miss_detect = (state == COMPARE) && (rd_req ^ wr_req) && !hit;

assign capture_req = miss_detect;

always @(posedge clk or negedge rst)
begin

    if(!rst)
    begin
        state <= COMPARE;
        pending_write <= 1'b0;
    end
    else  
    begin
        state <= nextstate;

          if(miss_detect)
		 pending_write <= wr_req;
		
		else if(state == READ_MISS && ready)
		begin
			pending_write <= 1'b0;
			
			end
    end

end



always @(*) begin

    nextstate = state;

    case(state)

        COMPARE:
            if(miss_detect)
                nextstate = MISS_CHECK;

        MISS_CHECK:
            if(victim_dirty)
                nextstate = WRITE_BACK;
            else
                nextstate = READ_MISS;

        WRITE_BACK:
            begin
                if(ready)
                    nextstate = READ_GAP;   // changed
                else
                    nextstate = WRITE_BACK;
            end

        READ_GAP:
            begin
                nextstate = READ_MISS;      // exactly one cycle
            end

        READ_MISS:
            begin
                if(ready)
                    nextstate = COMPARE;
                else
                    nextstate = READ_MISS;
            end

        default:
            nextstate = COMPARE;

    endcase

end
	

			
			
				
always @(*) begin

    req       = 1'b0;
    stall     = 1'b0;
    fillwrite = 1'b0;
    fillread  = 1'b0;
    WE        = 1'b0;

    case(state)

        MISS_CHECK:
            stall = 1'b1;

        WRITE_BACK:
            begin
                req   = 1'b1;
                stall = 1'b1;
                WE    = 1'b1;
            end

        READ_GAP:               // NEW
            begin
                stall = 1'b1;
                // req intentionally kept LOW
            end

        READ_MISS:
            begin
                req   = 1'b1;
                stall = 1'b1;

                if(pending_write)
                    fillwrite = ready;
                else
                    fillread  = ready;
            end

    endcase

end
endmodule