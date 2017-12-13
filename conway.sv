module conway(
	// 100 MHz clock off the board
	input wire clk,
	// Outputs for the DACs for the VGA
	output wire [3:0] vgaRed,
	output wire [3:0] vgaGreen,
	output wire [3:0] vgaBlue,
	// Outputs for the horizontal and vertical sync signals for VGA
	output wire Hsync,
	output wire Vsync
    );
    // Wires for the locked 150MHz clock, the not locked 150Mhz clock 
    // and the signal saying whether the pll is locked or not
    wire clk_150, clk_150t, clk_locked;
    // Wires for the read and write addresses for the transferring
    // of data, as well as the data itself and the enable
    wire [9:0] transfer_rd_x, transfer_wr_x;
    wire [8:0] transfer_rd_y, transfer_wr_y;
    wire transfer_rd_data, transfer_wr_data, transfer_wr_en;
    // Wires for the read and write addresses for the game logic stage
    // as well as the data and enable pins
    wire [9:0] logic_rd_x, logic_wr_x;
    wire [8:0] logic_rd_y, logic_wr_y;
    wire logic_rd_data, logic_wr_data, logic_wr_en;
    // Wires for the addresses of the rasterizer to read from the
    // frame buffer and the video data
    wire [9:0] video_rd_x;
    wire [8:0] video_rd_y;
    wire video_rd_data;
    // Wires for the starting of the transfer and logic
    wire transfer_start;
    wire logic_start;
    // module for the Phase locked loop to generate the 150MHz clock used
    // throughout the design
    pixel_clock p(.clk_100(clk), .clk_150(clk_150t), .locked(clk_locked));
    // Set the wire for the clock signal equal to the output of the PLL 
    // if the pll is locked
    assign clk_150 = clk_locked ? clk_150t : 1'b0;
       // ram for the present state data
    	b_ram_2p A(				.clk(clk_150), 
        						.we(transfer_wr_en), 
        						.wr_x(transfer_wr_x),
        						.wr_y(transfer_wr_y),
        						.wr_data(transfer_wr_data),
        						.rd_x(logic_rd_x),
        						.rd_y(logic_rd_y),
        						.rd_data(logic_rd_data)
    							);
    	// Ram for the next state data						
     	b_ram_2p B(				.clk(clk_150), 
        						.we(logic_wr_en), 
        						.wr_x(logic_wr_x),
        						.wr_y(logic_wr_y),
        						.wr_data(logic_wr_data),
        						.rd_x(transfer_rd_x),
        						.rd_y(transfer_rd_y),
        						.rd_data(transfer_rd_data)
        						);
    	// Ram for the video frame buffer
        b_ram_2p V( 			.clk(clk_150), 
        						.we(transfer_wr_en), 
               					.wr_x(transfer_wr_x),
               					.wr_y(transfer_wr_y),
               					.wr_data(transfer_wr_data),
           						.rd_x(video_rd_x),
          						.rd_y(video_rd_y),
          						.rd_data(video_rd_data)
        						);
        // Module for calculating the next state of each pixel
        conway_logic_v2 conways(.start(logic_start),
        				 		.clk(clk_150),
        				 		.rd_data(logic_rd_data),
        				 		.rd_addr_x(logic_rd_x),
        				 		.rd_addr_y(logic_rd_y),
        				 		.wr_data(logic_wr_data),
        				 		.wr_en(logic_wr_en),
        				 		.wr_addr_x(logic_wr_x),
        				 		.wr_addr_y(logic_wr_y)
        				 		);
        // memory transfer module
        memory_transfer faster(	.clk(clk_150),
        				 		.start(transfer_start),
        				 		.data_in(transfer_rd_data),
        				 		.rd_addr_x(transfer_rd_x),
        				 		.rd_addr_y(transfer_rd_y),
        				 		.wr_addr_x(transfer_wr_x),
        				 		.wr_addr_y(transfer_wr_y),
        				 		.wr_en(transfer_wr_en),
        				 		.data_out(transfer_wr_data)
        				 		);
        // The video driver module for the VGA Output
    	v_driver raster(		.clk(clk_150),
        						.data(video_rd_data),
        			  			.x_val(video_rd_x),
        			  			.y_val(video_rd_y),
        						.v_sync(Vsync), 
        						.h_sync(Hsync),
        						.red(vgaRed),
        						.green(vgaGreen),
    							.blue(vgaBlue),
    							.transfer_start(transfer_start),
    							.logic_start(logic_start)
        						);
endmodule