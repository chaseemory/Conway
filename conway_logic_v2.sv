module conway_logic_v2(
	// Signal to start calculating the next state frame
	 input wire start,
	 // Input clock
	 input wire clk,
	 // Addresses to read data as well as the read data
	 input wire rd_data,
	 output reg [9:0] rd_addr_x = 10'd1,
	 output reg [8:0] rd_addr_y = 9'd479,
	 // Addresses to write the next state data as well as the data
	 // and the write enable signal
	 output reg wr_data = 1'b0,
	 output reg wr_en = 1'b0,
	 output reg [9:0] wr_addr_x = 10'b0000000000,
	 output reg [8:0] wr_addr_y = 9'b000000000
    );
    // Parameters for the size of the screen
	parameter X_MAX 	= 10'd639;
    parameter Y_MAX 	= 9'd479;
    parameter X_ZERO 	= 10'b0000000000;
    parameter Y_ZERO 	= 9'b000000000;
    
    // Registers to track the pixel being calculated
    reg [9:0] x_pos = X_ZERO, x_pos_next = X_ZERO;
    reg [8:0] y_pos = Y_ZERO, y_pos_next = Y_ZERO;
    // Registers to track the next state of the data read address registers
    reg [9:0] rd_addr_x_next = X_ZERO, wr_addr_x_next = X_ZERO;
    reg [8:0] rd_addr_y_next = Y_ZERO, wr_addr_y_next = Y_ZERO;
    // Register to track the nest state of the write enable
    reg wr_en_next = 1'b0;
    // Registers to track the current and next state of whether the
    // logic is running
	reg enable = 1'b0, enable_next = 1'b0;
	// registers to store the result of the calculation, how many
	// of the surrounding cells are alive, what the values of the
	// surrounding cells are, and what state we are in for retrieving data
    reg conway_result;
    reg [3:0] conway_life = 4'b0000;
    reg [8:0] conway_grid = 9'b000000000;
    reg [3:0] count = 4'b0000, count_next = 4'b0000;
    
    // Always block to clock through the next state of all the main variables
    always @ (posedge clk) begin
    
    		enable <= enable_next;
        	
        	if(enable) begin
        		x_pos		<= x_pos_next;
        		y_pos		<= y_pos_next;
        		wr_addr_x 	<= x_pos;
        		wr_addr_y 	<= y_pos;
        		rd_addr_x 	<= rd_addr_x_next;
        		rd_addr_y 	<= rd_addr_y_next;
        		wr_data		<= conway_result;
        		wr_en		<= wr_en_next;
        		count 		<= count_next;
        	
        		// Read the read data into the conway grid
        		case(count)
        			1: conway_grid[0] <= rd_data;
        			2: conway_grid[1] <= rd_data;
        			3: conway_grid[2] <= rd_data;
        			4: if(x_pos == 0) conway_grid[3] <= rd_data;
        			5: begin 
        			    	if(x_pos == 0) conway_grid[4] <= rd_data;
        			    	else conway_grid <= {conway_grid[5:0],3'b000};
        			    end
        			6: if(x_pos == 0) conway_grid[5] <= rd_data;
        			7: if(x_pos == 0) conway_grid[6] <= rd_data;
        			8: if(x_pos == 0) conway_grid[7] <= rd_data;
        			9: if(x_pos == 0) conway_grid[8] <= rd_data;
        			10: conway_grid <= {conway_grid[5:0],3'b000};
        		endcase
        	end
    	end
        // always block to determine the next state of all the variables based on which pixel is being read
        // and to calculate the total number of living cells as well as the next state of the given cell
        always_comb begin
        
        	conway_life = conway_grid[0] + conway_grid[1] + conway_grid[2] + conway_grid[3] 
        					+ conway_grid[5] + conway_grid[6] + conway_grid[7] + conway_grid[8];
        	
        	case(conway_grid[4])
        		1'b0: conway_result = (conway_life == 4'b0011) ? 1'b1 : 1'b0;
        		1'b1: conway_result = (conway_life == 4'b0010 | conway_life == 4'b0011)	? 1'b1 : 1'b0;
        		default:	conway_result = 1'b1;
        	endcase
        	
        	// The cells being read wrap around on the sides as well as the top and bottom of the screen
        	case(count)
        		0: 	begin
        				rd_addr_x_next = ( x_pos == X_MAX ) ? X_ZERO : x_pos + 1'b1;
        				rd_addr_y_next = y_pos;
        				count_next = count + 1'b1;
        				wr_en_next = 1'b0;
        				x_pos_next = x_pos;
        				y_pos_next = y_pos;
        				enable_next = ( x_pos == X_ZERO & y_pos == Y_ZERO & start == 1'b1) ? 1'b1 : enable;
        			end
        		1:	begin
        				rd_addr_x_next = ( x_pos == X_MAX ) ? X_ZERO : x_pos + 1'b1;
        		    	rd_addr_y_next = ( y_pos == Y_MAX ) ? Y_ZERO : y_pos + 1'b1;
        		    	count_next = count + 1'b1;
        		    	wr_en_next = 1'b0;
        		    	x_pos_next = x_pos;
        		    	y_pos_next = y_pos;
        		    	enable_next = enable;
        		    end
        		2:	begin
        				rd_addr_x_next = x_pos;
        				rd_addr_y_next = ( y_pos == Y_ZERO ) ? Y_MAX : y_pos - 1'b1;
        				count_next = count + 1'b1;
        				x_pos_next = x_pos;
        				y_pos_next = y_pos;
        				wr_en_next = 1'b0;
        				enable_next = enable;	
        			end
    			3:	begin
    					rd_addr_x_next = x_pos;
    			    	rd_addr_y_next = y_pos;
    			    	count_next = count + 1'b1;
    			    	wr_en_next = 1'b0;
    			    	x_pos_next = x_pos;
    			    	y_pos_next = y_pos;
    			    	enable_next = enable;
    
        		    end
        		4:	begin
        				case(x_pos)
        					0:			begin
        					    			rd_addr_x_next = x_pos;
        					    			rd_addr_y_next = ( y_pos == Y_MAX ) ? Y_ZERO : y_pos + 1'b1;
        					    			count_next = count + 1'b1;
        					    			wr_en_next = 1'b0;
        					    			x_pos_next = x_pos;
        					    			y_pos_next = y_pos;
        					    			enable_next = enable;
        								end
        					 default:	begin
        					   				rd_addr_x_next = 2'bxx;
        					     		    rd_addr_y_next = 2'bxx;
        					     		    count_next = count + 1'b1;
        					     		    wr_en_next = 1'b0;
        					     		    x_pos_next = x_pos;
        					     		    y_pos_next = y_pos;
        					     		    enable_next = enable;
        					        	end	
        				endcase	
        			end
        		5:	begin
        				case(x_pos)
        				    0:			begin
        				    				rd_addr_x_next = ( x_pos == X_ZERO ) ? X_MAX : x_pos - 1'b1;
        				        			rd_addr_y_next = ( y_pos == Y_ZERO ) ? Y_MAX : y_pos - 1'b1;
        				        			count_next = count + 1'b1;
        				        			wr_en_next = 1'b0;
        				        			x_pos_next = x_pos;
        				        			y_pos_next = y_pos;
        				        			enable_next = enable;
        				    			end
        				    default:	begin
        				    				wr_en_next = 1'b1;
        				    				x_pos_next = (x_pos == X_MAX) ? X_ZERO : x_pos + 1'b1;
        				    				y_pos_next = (x_pos == X_MAX) ? ( (y_pos < Y_MAX) ? y_pos + 1'b1 : Y_ZERO) : y_pos;
        				    				rd_addr_x_next = ( x_pos_next == X_MAX ) ? X_ZERO : x_pos_next + 1'b1;
        				    				rd_addr_y_next = ( y_pos_next == Y_ZERO ) ? Y_MAX : y_pos_next - 1'b1;
        				    				count_next = 4'b0000;
        				    				enable_next = (x_pos == X_MAX & y_pos == Y_MAX) ? 1'b0 : 1'b1;
        				    			end	
        				endcase
        			end
        		6:	begin
        		    	rd_addr_x_next = ( x_pos == X_ZERO ) ? X_MAX : x_pos - 1'b1;
        		    	rd_addr_y_next = y_pos;
        		    	count_next = count + 1'b1;
        		    	wr_en_next = 1'b0;
        		    	x_pos_next = x_pos;
        		    	y_pos_next = y_pos;
        		    	enable_next = enable;
        		    end
        		7:	begin
        				rd_addr_x_next = ( x_pos == X_ZERO ) ? X_MAX : x_pos - 1'b1;
        				rd_addr_y_next = ( y_pos == Y_MAX ) ? Y_ZERO : y_pos + 1'b1;
        				count_next = count + 1'b1;
        				wr_en_next = 1'b0;
        				x_pos_next = x_pos;
        				y_pos_next = y_pos;
        				enable_next = enable;
        			end
        		8:	begin
        				rd_addr_x_next = ( x_pos_next == X_MAX ) ? X_ZERO : x_pos_next + 1'b1;
        				rd_addr_y_next = ( y_pos_next == Y_ZERO ) ? Y_MAX : y_pos_next - 1'b1;
        				count_next = count + 1'b1;
        				wr_en_next = 1'b0;
        				x_pos_next = x_pos;
        				y_pos_next = y_pos;
        				enable_next = enable;
        		    end
        		9:	begin
        		        rd_addr_x_next = 10'bxxxxxxxxxx;
        		        rd_addr_y_next = 9'bxxxxxxxxx;
        		        count_next = count + 1'b1;
        		        wr_en_next = 1'b0;
        		        x_pos_next = x_pos;
        		        y_pos_next = y_pos;
        		        enable_next = enable;
        		    end
        		10:	begin
        		        count_next = 1'b0;
        		        wr_en_next = 1'b1;
        		        x_pos_next = (x_pos == X_MAX) ? X_ZERO : x_pos + 1'b1;
        		        y_pos_next = (x_pos == X_MAX) ? ( (y_pos > Y_MAX) ? y_pos + 1'b1 : Y_ZERO) : y_pos;
        		        enable_next = enable;
        		        rd_addr_x_next = ( x_pos_next == X_MAX ) ? X_ZERO : x_pos_next + 1'b1;
        		        rd_addr_y_next = ( y_pos_next == Y_ZERO ) ? Y_MAX : y_pos_next - 1'b1;
        		    end
        		default:
        			begin
        				rd_addr_x_next = 2'bxx;
        			    rd_addr_y_next = 2'bxx;
        			    count_next = 4'bxxxx;
        			    wr_en_next = 1'bx;
        			    x_pos_next = 2'bxx;
        			    y_pos_next = 2'bxx;
        			    enable_next = 1'bx;
        			end
        	endcase
        end   
    endmodule