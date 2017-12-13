module b_ram_2p(
    input wire clk, we, wr_data,
    input wire [9:0] wr_x,
    input wire [8:0] wr_y,
    input wire [9:0] rd_x, 
    input wire [8:0] rd_y,
    output wire rd_data
    );
	
	// Declare the 1 bit wide, 524k long ram
    reg ram [0:524287];
    // register to output data
    reg rd_data_reg;

	// load file of random data to be starting grid for game
    initial $readmemb("Random2.data", ram);
    
    // output the data on the read address always
    always @ (posedge clk) begin
    	rd_data_reg <= ram[{rd_y,rd_x}];
    	// Write data to write address if write enable is asserted
    	if(we) ram[{wr_y,wr_x}] <= wr_data;
    end
    
    assign rd_data = rd_data_reg;
    
endmodule