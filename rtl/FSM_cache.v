module fsm(clk,rst,cpu_req,hit,req,ready,fill,stall);

input clk ,rst, cpu_req,hit,ready;
output reg req,fill,stall;


parameter compare = 1'b0;
parameter missstate = 1'b1;

reg state , nextstate;

always @(posedge clk or negedge rst)
begin
if(!rst)
state<=compare;
else 
state <= nextstate;
end

always @(*)
	begin
	nextstate = state;
		case(state)
		compare 	: begin				
				if (cpu_req && !hit)
				nextstate = missstate;
				end
		missstate	: begin
				if(ready)
				nextstate = compare;
				else 
				nextstate =missstate;
				
				end
		default 	: nextstate =compare;
		endcase
	end
				
always @(*) begin
    req   = 1'b0;
    stall = 1'b0;
    fill  = 1'b0;

    case(state)
        missstate: begin
            req   = 1'b1;
            stall = 1'b1;
            fill  = ready;
        end
    endcase
end
endmodule