`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Chiba University
// Engineer:        H. Lee
// 
// Create Date:    16:47:04 11/21/2014 
// Design Name: 
// Module Name:    DNN_main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:         Specified implementation of Deep Neural Net for MFCC
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
        module DNN_0117 #(parameter XBIT=6,WBIT=14)(clk,reset,vec_in,dv_in,vec_out,dv_out,outdataP,dinV
    );
     input clk;
     input reset;
     input signed [IBIT-1:0] vec_in;
     input dv_in;
     output signed [OBIT-1:0] vec_out;
     output dv_out;
     output [15:0]outdataP;
     output [14:0] dinV;
     
    //////////////////
    //// Parameters
    //////////////////
    
    parameter IBIT = 20;            //bit of input                  (1+11+14)
    parameter IDIM = 12;            //dim of input
    parameter OBIT = XBIT;          //bit of output             (1+0+10) (+/-, int , frac)
    parameter ODIM = 42;            //dim of output
    parameter PBIT = 14;            //bit of parameters/bias    (1+3+10)
    parameter LAYERNUM = 3;     //num of layers
    parameter NODEL0 = 60;  //affine (input)
    parameter NODEL1 = 60;  //affine layer1 node4800
    parameter NODEL2 = 50;  //affine layer2 node4800
//  parameter NODEL5 = ;
    //parameter NODEL4 = 42;
    
    //mean of each mfcc dim (normalization)
    parameter INFRAME = 5;          //number of frames which will be the input for nn
    
    parameter MEAN0 = 99047;
    parameter MEAN1 = 28872;
    parameter MEAN2 = 75226;
    parameter MEAN3 = -42817;
    parameter MEAN4 = -67978;
    parameter MEAN5 = -44065;
    parameter MEAN6 = -54591;
    parameter MEAN7 = -26607;
    parameter MEAN8 = -23568;
    parameter MEAN9 = -18502;
    parameter MEAN10 = 4391;
    parameter MEAN11 = -73780;

    //////////////////////
    //// I/O & Storage
    //////////////////////  
    reg signed [10:0] vec_out = 0;  /////////////////////////////////////////
    reg dv_out = 0;
    
    //////////////////////////  
    ////    Block Memories
    //////////////////////////
    
    //Block ROM for parameters
    
    reg [15:0] addr_nowW = 0;
    
    reg [15:0] addrW = 0;
    wire signed [WBIT-1:0] doutW; ////////////////////////////////
    
    nnpara11bittest2  nnpara(
        .clka(clk), 
        .addra(addrW), 
        .douta(doutW)
    );
        
    //Block RAM for input vectors
    
    reg [5:0] addr_nowV = 0;
    
    reg writeV = 0;
    reg [5:0] addrV = 0;
    reg signed [XBIT+4:0] dinV = 0;
    wire signed [XBIT+4:0] doutV;
    
    BRAM_input6bit vec_std (
      .clka(clk), // input clka
      .wea(writeV), // input [0 : 0] wea
      .addra(addrV), // input [5 : 0] addra
      .dina(dinV), // input [15 : 0] dina
      .douta(doutV) // output [15 : 0] douta
    );
    
    
    //Block RAM for nodes
    
    reg writeN = 0;
    reg [7:0] addrN = 0;
    reg signed [XBIT+4:0] dinNf = 0;
    wire signed [XBIT+4:0] doutNf;
    reg signed [XBIT-1:0] dinN=0;
    wire signed [XBIT-1:0] doutN;
    
    BRAM_node6bit node (
      .clka(clk), // input clka
      .wea(writeN), // input [0 : 0] wea
      .addra(addrN), // input [7 : 0] addra
      .dina(dinNf), // input [10 : 0] dina
      .douta(doutNf) // output [10 : 0] douta
    );

    BRAM_newnode6bit newnode(
        .clka(clk), // input clka
        .wea(writeN), // input [0 : 0] wea
        .addra(addrN), // input [7 : 0] addra
        .dina(dinN), // input [10 : 0] dina
        .douta(doutN) // output [10 : 0] douta
    );
    
    //////////////////////  
    ////    Multipliers
    //////////////////////

    //Multiplier for Normalize
    reg signed [IBIT-1:0]indataA = 0;               //larger data (20bit)
    reg signed [13:0]indataB = 0;                       //smaller data (14bit)
    wire signed [15:0]outdataP;                     //multiplied data (16bit with 10bit frac)

    multiplier multi_std (
        .a(indataA), 
        .b(indataB), 
        .p(outdataP)
    );  
    
    //Multiply Accumulator for AffineTransform
    
    reg signed [XBIT-1:0]indataA1 = 0;  //16bit
    reg signed [WBIT-1:0]indataB1 = 0;  //14bit /////////////////////////////////////////
    reg mac_ce = 0;
    reg mac_clr = 0;
    reg signed [XBIT+4:0]indataA2=0;
    reg signed [WBIT-1:0]indataB2=0;
    
    wire signed [27:0]nodetmp;
    wire signed[27:0]nodetmp2;
    
    MultAccum6bitx mac_affine (
        .clk(clk), 
        .ce(mac_ce), 
        .sclr(mac_clr), 
        .a(indataA2), 
        .b(indataB2), 
        .s(nodetmp2)
    );
    
    
    MultAccumnew6bit mac_affinenew (
        .clk(clk), 
        .ce(mac_ce), 
        .sclr(mac_clr), 
        .a(indataA1), 
        .b(indataB1), 
        .s(nodetmp) 
    );
    //////////////////  
    ////    Sigmoid
    //////////////////
    reg signed [27:0] sigin = 0;    //IBIT-5+PBIT-10+8-1
    reg sigstart = 0;
    
    wire dv_sig;
    wire signed [OBIT-1:0] sigout;
    
    sigmoid #(.IBIT(27),    .OBIT(OBIT))
        sigmoid (
        .clk(clk), 
        .dv_in(sigstart), 
        .dv_out(dv_sig), 
        .sigin(sigin), 
        .sigout(sigout)
    );

    
    //////////////////  
    ////    Softmax
    //////////////////
/*  reg signed [OBIT+PBIT-10+6-1:0] sofin = 0;
    reg sofstart = 0;
    
    wire dv_sof;
    wire signed [OBIT-1:0] sofout;
    
    softmax #(.IBIT(OBIT+PBIT-10+6-1),  .OBIT(OBIT),    .IDIM(42))
        softmax (
        .clk(clk),
        .dv_in(sofstart),
        .dv_out(dv_sof),
        .sofin(sofin),
        .sofout(sofout)
    );

*/
    //////////////////////
    ////    Initialize
    //////////////////////      
    initial begin

    end

    
    //////////////////////////////  
    ////    Registers for control
    //////////////////////////////
    
    //reg ff = 0;                       //input index
    //wire ffnxt;                       //output index
    //assign ffnxt = !ff;
    
    reg [3:0] process = 0;              //function process (0~15)
    reg [1:0] proc_load = 0;
    reg [2:0] proc_layer = 0;   
    
    reg [4:0] layer = 0;                    //layer process (0~7)
    reg [7:0] i = 0;
    reg [7:0] out_index = 0;
    
    //for normalization
    reg signed [IBIT-1:0] x_i[0:IDIM-1];                        // 14 bit fixed
    reg bfrdv_in = 0;
    reg [4:0] dim_index = 0;        //0~31
    
    //////////////////////
    ////    Main function
    //////////////////////

    always@ (posedge clk)
    begin
        bfrdv_in <= dv_in;

        case (process)
        //////////////////////////////////////////  
        ////    Process.0 , input data detection
        //////////////////////////////////////////
        0:begin
            dv_out <= 0;
            
            if (bfrdv_in == 0 && dv_in == 1)            //if input valids
            begin
                x_i[0] <= vec_in;
                dim_index <= 1;
                process <= process + 1;
            end
        end

        //////////////////////////////////////////  
        ////    Process.1 , input data storage
        //////////////////////////////////////////      
        1:begin     
            x_i[dim_index] <= vec_in;

            if (dim_index == IDIM-1)                        //if data of 1 frame were stored
            begin
                dim_index <= 0;
                process <= process +1;
            end else begin
                dim_index <= dim_index + 1;
            end
        end
        
        //////////////////////////////////////
        ////    Process.2 , x_i = vec - mean
        //////////////////////////////////////  
        2:begin
            x_i [0] <= x_i[0] - MEAN0;
            x_i [1] <= x_i[1] - MEAN1;
            x_i [2] <= x_i[2] - MEAN2;
            x_i [3] <= x_i[3] - MEAN3;
            x_i [4] <= x_i[4] - MEAN4;
            x_i [5] <= x_i[5] - MEAN5;
            x_i [6] <= x_i[6] - MEAN6;
            x_i [7] <= x_i[7] - MEAN7;
            x_i [8] <= x_i[8] - MEAN8;
            x_i [9] <= x_i[9] - MEAN9;
            x_i [10] <= x_i[10] - MEAN10;
            x_i [11] <= x_i[11] - MEAN11;
            
            //indataS <= std;           //14bit
            //addrV <= addr_nowV - 1;
            writeV <= 0;
            dinV <= 0;
            process <= process + 1;
            
        end

        //////////////////////////////////////  
        ////    Process.3 , normalize % store 
        //////////////////////////////////////      
        3:begin
            
            case (dim_index)
            0:indataB <= 2286;
            1:indataB <= 2573;
            2:indataB <= 2240;
            3:indataB <= 2138;
            4:indataB <= 2029;
            5:indataB <= 2159;
            6:indataB <= 2178;
            7:indataB <= 2191;
            8:indataB <= 2338;
            9:indataB <= 2558;
            10:indataB <= 2681;
            11:indataB <= 2615;
            default:indataB <= 0;
            endcase         
            
            case (dim_index)
            0:begin
                indataA <= x_i[dim_index];
                dim_index <= dim_index + 1;
            end
            
            1:begin
                indataA <= x_i[dim_index];
                dim_index <= dim_index + 1;
                
                dinV <= outdataP[15:11-XBIT]; ////////////////////////////////
                writeV <= 1;
                addrV <= addr_nowV;
            end
            
            default:begin
                indataA <= x_i[dim_index];
                dim_index <= dim_index + 1;
                
                dinV <= outdataP[15:11-XBIT];           ///////////////////////
                writeV <= 1;
                addrV <= addrV + 1;
            end
            
            IDIM:begin
                indataA <= 0;
                dim_index <= dim_index + 1;
                
                dinV <= outdataP[15:11-XBIT];       /////////////////////////////////////
                writeV <= 1;
                addrV <= addrV + 1; 
                end
            
            IDIM+1:begin
                dim_index <= 0;
                process <= process + 1;
                
                if (addrV == 59)
                begin
                    addr_nowV <= 0;
                end else begin
                    addr_nowV <= addrV + 1;
                end
                addrV <= 0;
                dinV <= 0;
                writeV <= 0;
            end
            
            endcase
        end
        
        //////////////////////////////////////////  
        ////    Process.4 , node of input layer 
        //////////////////////////////////////////              
        4:begin
            case (proc_load)
            0:begin
                addrV <= addr_nowV;
                writeN <= 0;
                
                proc_load <= proc_load + 1;
            end
            
            1:begin
                addrV <= addrV + 1;
                dinNf <= doutV;
                addrN <= -1;
                
                proc_load <= proc_load + 1;
            end
            
            2:begin
                if (addrV == 59)
                begin
                    addrV <= 0;
                end else begin
                    addrV <= addrV + 1;
                end
                dinNf <= doutV;
                writeN <= 1;
                
                if (addrN == NODEL0-1)  //revised by qby on 2016.12.08, former version was NODEL0-1 
                begin
                    writeN <= 0;
                    proc_load <= proc_load + 1;
                end else begin
                    addrN <= addrN + 1;
                end
            end
            
            3:begin 
                dinNf <= 0; //clear
                
                //initialization for p5
                out_index <= 0;
                layer <= 0;
                addrW <= addr_nowW;
                addrN <= 0;
                addrV <= 0;
                
                proc_load <= 0;
                process <= process + 1;
            end

            endcase
        end

        //////////////////////////////////////////  
        ////    Process.5 , node calculation
        //////////////////////////////////////////
           5:begin
            case (layer)
            0:begin     //layer 0 -> 1
                case (proc_layer)
                0:begin     //get ready
                    indataA2 <= 0;
                    indataB2 <= 0;
                    addrN <= addrN + 1;
                    addrW <= addrW + 1;
                    sigin <= 0;
                    sigstart <= 0;
                    
                    proc_layer <= proc_layer + 1; 
                end
                
                1:begin
                    indataA2 <= doutNf;
                    indataB2 <= doutW;
                    mac_ce <= 1;
                    if (addrN == NODEL0+1)  //revised by qby on 2016.12.08, former version was NODEL0-1
                    begin
                        indataA2 <= 0;
                        indataB2 <= 0;
                        addr_nowW <= addrW -1;  //revised by qby on 2016.12.08, former version was addrW+1
                        addrW <= 6600 + out_index;
                        mac_ce <= 0;
                        proc_layer <= proc_layer + 1;
                    end else begin
                        addrN <= addrN + 1;
                        addrW <= addrW + 1;
                    end
                end
                
                2:proc_layer <= proc_layer + 1;
                
                3:begin
                    sigin <= nodetmp2 + doutW;
                    sigstart <= 1;
                    proc_layer <= proc_layer + 1;
                end
                
                4:begin
                    if (dv_sig)
                    begin
                        addrN <= 128 + out_index;
                        writeN <= 1;
                        dinN <= sigout;
                    //  vec_out<=sigout;
                        sigin <= 0;
                        sigstart <= 0;
                        mac_ce <= 1;
                        mac_clr <= 1;
                        proc_layer <= proc_layer + 1;
                    end
                end
                
                5:begin
                    writeN <= 0;
                    dinN <= 0;
                    mac_ce <= 0;
                    mac_clr <= 0;
                    proc_layer <= 0;
                    addrW <= addr_nowW;
                    
                    if (out_index == NODEL1-1)
                    begin
                        layer <= layer + 1;
                        out_index <= 0;
                        addrN <= 128;
                        addrW<=addr_nowW;       //revised by qby on 2016.12.12, former version was NULL 
                    end else begin
                        out_index <= out_index + 1;
                        addrN <= 0;
                    end
                end
                default:proc_layer <= 0;
                endcase
            end //layer 0
            
				1:begin		//layer 1 -> 2
				case (proc_layer)
				0:begin		//get ready
					indataA1 <= 0;
					indataB1 <= 0;
					addrN <= addrN + 1;
					addrW <= addrW + 1;
					sigin <= 0;
					sigstart <= 0;
					
					proc_layer <= proc_layer + 1; 
				end
				
				1:begin
						indataA1 <= doutN;
						indataB1 <= doutW;
						mac_ce <= 1;
					if (addrN-128 == NODEL1+1)
					begin
						indataA1 <= 0;
						indataB1 <= 0;
						addr_nowW <= addrW -1;
						addrW <= 6660 + out_index;
						mac_ce <= 0;
						proc_layer <= proc_layer + 1;
					end else begin
						addrN <= addrN + 1;
						addrW <= addrW + 1;
						addr_nowW <= addrW;
					end
				end
				
				2:proc_layer <= proc_layer + 1;
				
				3:begin
					sigin <= nodetmp + doutW;
					sigstart <= 1;
					proc_layer <= proc_layer + 1;
				end
				
				4:begin
					if (dv_sig)
					begin
						addrN <= out_index;
						writeN <= 1;
						dinN <= sigout;
				//		vec_out<=sigout;
						sigin <= 0;
						sigstart <= 0;
						mac_ce <= 1;
						mac_clr <= 1;
						proc_layer <= proc_layer + 1;
					end
				end
				
				5:begin
					writeN <= 0;
					dinN <= 0;
					proc_layer <= 0;
					mac_ce <= 0;
					mac_clr <= 0;
					addrW <= addr_nowW;	
					
					if (out_index == NODEL2-1)
					begin
						layer <= layer + 1;
						out_index <= 0;
						addrN <= 0;
					end else begin
						out_index <= out_index + 1;
						addrN <= 128;
					end
				end
	
				default:proc_layer <= 0;
				endcase			
			end //layer1
            

////////////////////////////////////////////////////////////////
        //output prepare
/////////////////////////////////////////////////////////////////
            
            2:begin 
                addr_nowW <= 0;
                addrW <= 0;
                addrN <= 0;
                process <= process + 1;
            end
            endcase
        end


        //////////////////////////////////////  
        ////    Process.6&7 , output vectors
        //////////////////////////////////////
        6:begin
            if (XBIT == 11)
            begin
                vec_out <=doutN;
            end else begin
                vec_out[10:11-XBIT] <= doutN[XBIT-1:0];
            end                                                     ////////////////////////////////
            addrN <= addrN + 1;
            process <= process + 1;
        end
        
        7:begin
            if (XBIT == 11)
            begin
                vec_out <=doutN;
            end else begin
                vec_out[10:11-XBIT] <= doutN[XBIT-1:0];
            end                                                     ////////////////////////////////
            dv_out <= 1;
            if (addrN == NODEL2)
            begin
                process <= 0;
                addrN <= 0;
            end else begin
                addrN <= addrN + 1;
            end 
        end
        
        endcase
    
    end
    
endmodule


/*
        //////////////////////////////////////////  
        ////    Process.5 , node calculation
        //////////////////////////////////////////
        5:begin
            //`include "src/nnpara.v"       //weight :i -> indexin ,o-> indexout
                                                    //bias : o -> indexout
            case (proc_layer)
            0:begin
                //wait for first parameter
                i <= 1;
                //if (layer == LAYERNUM)process <= process + 1;
                proc_layer <= proc_layer + 1;
            end
            
            1:begin                 // w_a is when i = 0
                indataL <= node[ff][i-1];       //i = 0;                            (22 or 11bit)
                indataS <= w_a;             //para[layer][indexout]     (15bit)
                nodetmp <= w_b;             //initialization of each node (+bias)
                i <= i + 1;
                proc_layer <= proc_layer + 1;
            end
            
            2:begin
                if (i == layernum[layer]+1)
                begin
                    i <= 0;
                    if (layer == LAYERNUM-1)    //last layer
                    begin
                        node[ffnxt][o] <= nodetmp;

                        if (o == layernum[layer+1]-1)
                        begin
                            //proc_layer <= proc_layer + 2;         //with sigmoid
                            proc_layer <= 0;                                //without sigmoid
                            process <= process + 1;                     //without sigmoid
                            o <= 0;
                            layer <= 0;
                        end else begin
                            proc_layer <= 0;
                            o <= o + 1;
                        end
                    end else begin
                        sigin <= nodetmp;
                        sigstart <= 1;
                        proc_layer <= proc_layer + 1;
                    end
                end else begin
                    i <= i + 1;
                    indataL <= node[ff][i-1];
                    indataS <= w_a;
                    nodetmp <= nodetmp + $signed(outdataM[36:10]);          //22+15-1 : 10
                end
                
            end
            
            3:begin
                if (dv_sig)                                 //wait for sigmoid done
                begin
                    node[ffnxt][o] <= sigout;
                    sigstart <= 0;
                    process <= 0;
                    
                    if (o == layernum[layer+1]-1)
                    begin
                        o <= 0;
                        ff <= ~ff;
                        layer <= layer + 1;
                    end else begin
                        o <= o + 1;
                    end
                end
            end

        
            4:begin     //softmax step 1
                sofstart <= 1;
                sofin <= node[ff][o];
                if (o == layernum[LAYERNUM-1]])
                begin
                    o <= 0;
                    proc_layer <= proc_layer + 1;
                end else begin
                    o <= o + 1;
                end
            end 
            
            5:begin     //softmax step 2
                if (sof_dv)
                begin
                    node[ffnxt][o] <= sofout;
                    if (o == layernum[LAYERNUM-1])
                    begin
                        process <= process + 1;
                        ff <= ~ff;
                        o <= 0;
                    end else begin
                        o <= o + 1;
                    end
                end
            end

            default:proc_layer <= 0;
            endcase
            
        end

*/