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
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module main_DP(clk,dat_i,switch,sclk,led1,led2,led3,beep);
   input clk;		//!< Global Clock(50MHz)
   input dat_i;		//!< MEMS mic : data
	input switch;
   output sclk;		//!< Mic clock
   output led1;    	//!< led on FPGA
   output led2;		//!< led on FPGA
   output led3;		//!< led on board
   output beep;		//!< piezo Speaker
   reg 	  sclk=0;
   reg 	  led1=0;
   reg 	  led2=0;
   reg 	  led3=0;
   reg 	  beep=0;

   reg 	  reset=1;

   //-----------------------------------------
   //			Clock
   //-----------------------------------------
   wire   clk_10MHz;
   clock_divide #(.DIVCOUNT(5))
   clock_devide_10M(
		    .clk(clk), 
		    .clk_div(clk_10MHz)
		    );
   
   wire   clk_2MHz;
   clock_divide #(.DIVCOUNT(25))
   clock_devide_2M(
		   .clk(clk), 
		   .clk_div(clk_2MHz)
		   );
   wire   clk_4000Hz;
   clock_divide #(.DIVCOUNT(12500)) 
   clock_devide_4000(
		     .clk(clk), 
		     .clk_div(clk_4000Hz)
		     );	
   wire   clk_100Hz;
   clock_divide #(.DIVCOUNT(500000)) 
   clock_devide_100(
		    .clk(clk), 
		    .clk_div(clk_100Hz)
		    );	
   wire   clk_5Hz;
   clock_divide #(.DIVCOUNT(20)) 
   clock_devide_5(
		  .clk(clk_100Hz), 
		  .clk_div(clk_5Hz)
		  );
   wire   clk_1Hz;
   clock_divide #(.DIVCOUNT(100)) 
   clock_devide_1(
		  .clk(clk_100Hz), 
		  .clk_div(clk_1Hz)
		  );
   //------------------------------------------


   //*  Decimaion Filter (PDM->PCM)  *//
   wire   SPM0405HD4H_dv;
   wire signed [15:0] dat_o;
   SPM0405HD4H SPM0405HD4H (
			    .clk(clk),
			    .reset(reset),
			    .sclk(clk_2MHz),
			    .dat_i(dat_i),
			    .dv(SPM0405HD4H_dv),
			    .dat_o(dat_o));


	///////////////////////////////////
	///////		MFCC
	///////////////////////////////////
   wire signed [25:0]x_o; // Output MFCC
   wire mfc_dv;
   wire [4:0]x_index;
	wire mfc_vad;
   MFCC MFCC(.clk(clk),
	     .sclk(clk),
	     .x_i(dat_o), 
	     .write(SPM0405HD4H_dv),
	     .dv_out(mfc_dv), 
	     .out_index(x_index), 
	     .x_o(x_o),
		  .vad(mfc_vad));


   //*  Word Detect  *//
	parameter SCRPRVMFC = 1150000;
	parameter SCRPUBMFC = 1180000;
	parameter TMPSIZE = 38;
	
	reg [30:0]scr_mfc = SCRPRVMFC;	
	
	
   reg [15:0] 	      counter=0;
   wire 	      dv;
	wire	vad;
//   wire [1:0] 	      active_frame;	
	wire active_frame;
	
		DP_main_mfc #(.BIT(26),	.HPENALTY(10),	.VPENALTY(10),	.TMPSIZE(TMPSIZE) )
			DP_main_mfc(
			.clk(clk),
			.reset(reset), 
			.vec_in(x_o),
			.dv_in(mfc_dv),
			.vad_in(mfc_vad),
			.detected_scr(scr_mfc),
			.result_dv(dv), 
			.result(active_frame),
			.vad_out(vad)
			);
				
   //*   LED,beep   *//
   reg 		      beep_start=0;
   reg 		      _beforedv=0;
   reg [20:0] 	      _beforei=0;
   reg 		      active_frame_bfr=0;
   reg [31:0] 	      beep_cnt=0;
   always@(posedge clk)
	begin
      sclk<=clk_2MHz;  //!< mic
/*      if(clk_2MHz)begin
			led1<=active_frame;
			led2<=clk_1Hz;
      end
*/      
		led3 <= active_frame;
		led1 <= vad;
		
	if (switch)begin
		scr_mfc <= SCRPRVMFC;
		led2 <= clk_1Hz;
	end else begin
		scr_mfc <= SCRPUBMFC;
		led2 <= 0;
	end

      //! Sound Beep
      //! if "active_frame=1" is succession,  active beep
      if(beep_start==1)
		begin
			beep<=clk_4000Hz;
      end else begin
			beep<=0;
      end
      
		if(beep_start==1)
		begin
			if(beep_cnt==50000000)
			begin
				beep_start<=0;
				beep_cnt<=0;
			end else begin
				beep_cnt<=beep_cnt+1;
			end
      end else begin
				if( active_frame_bfr==1 && active_frame==1)
				begin
					beep_start<=1;
				end
			active_frame_bfr<=active_frame;
      end	
   end // always@ (posedge clk)
   
endmodule
