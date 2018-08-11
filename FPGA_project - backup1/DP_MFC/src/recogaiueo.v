`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:42:07 07/13/2012 
// Design Name: 
// Module Name:    main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	WordDetection with NeuralNetwork
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////

module recogaiueo(clk,reset, x_i,write, result_dv, result);
	input clk;			
	input reset;
	input signed [15:0] x_i;	//!< input data
	input write;				//!< Sampling rate
	output result_dv;			//!< Data valid
	output [1:0]result;	 			//!< Result
//	reg result_dv=0;
//	reg result=0;

wire clk_10MHz;
clock_divide #(.DIVCOUNT(5))
clock_devide_10M(
	.clk(clk), 
	.clk_div(clk_10MHz)
);	 


/////////////////////////////////////////////////////////////////////////////////
// Acoustic Feature MFCC
///////////////////////////////////////////////////////////////////////////////
wire signed[31:0] x_o; //!< Output MFCC
wire mfcc_dv;
wire [4:0] x_index;
MFCC MFCC(
	.clk(clk),
	.sclk(clk_10MHz),
	.x_i(x_i), 
	.write(write),
	.dv_out(mfcc_dv), 
	.out_index(x_index), 
	.x_o(x_o)
);
//////////////////////////
// Compare Mean
//////////////////////////
wire rec_load;
wire rec_done;
recog #(.BWIDTH(32),.AWIDTH(4),.MFCC_SIZE(12))
 recog(
	.clk(clk_10MHz), 
	.reset(reset), 
	.x_i(x_o), 
	.write(mfcc_dv), 
	.load(rec_load), 
	.result(result),
	.dv(result_dv),
	.done(rec_done)
);

//------------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////
/// make Segment with feature vector
///////////////////////////////////////////////////////////////////////////////
/*
wire seg_load;
wire seg_shift_start;
wire signed [31:0] seg_o;
wire seg_done;
makeSegment #(.BWIDTH(32),.AWIDTH(9),.WORDS(512),.SHIFT_SIZE(12))
 makeSegment(
	.clk(clk), 
	.reset(reset), 
	.x_i(x_o), 
	.write(mfcc_dv), 
	.load(seg_load), 
	.shift_start(seg_shift_start), 
	.x_o(seg_o), 
	.done(seg_done)
);
*/
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
/// Classify : Neural Net
///////////////////////////////////////////////////////////////////////////////
/*
reg nn_start=0;
reg nn_write=0;
wire signed [31:0] nn_o;
wire nn_done;
wire nn_dv;
wire nn_result;
NNsp NNsp(
	.clk(clk),
	.reset(reset),
	.start(nn_start),
	.write(seg_load),
	.x_i(seg_o),
	.x_o(nn_o),
	.done(nn_done),
	.dv(nn_dv),
	.result(nn_result)
);
*/
//-----------------------------------------------------------------------------


///////////////////////////////////////////////////////////////////////////////
/// Control each module
///////////////////////////////////////////////////////////////////////////////
/*
always@(posedge clk)begin
	if(seg_shift_start==1)begin
		nn_start<=1;
	end

	if(nn_dv==1)begin
		result_dv<=nn_dv;
		result<=nn_result;
		nn_start<=0;
		
	end
end
*/
//------------------------------------------------------------------------------
endmodule
