`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:30:18 07/26/2013 
// Design Name: 
// Module Name:    NN 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
// 	���̓x�N�g�����j���[�����l�b�g�ɒʂ��ďo��
// 	�d��:W_a��,�o�C�A�X:W_b ��nn.dat�ɋL�q����include
// 	���C�����͎��R�����A���C���̃T�C�Y�� layersize �ɒǉ�����K�v������
//
//	//!<�X�p�[�X�p�̉���
// 	�X�p�[�X�ɑΉ������邽�߁A�C���f�b�N�X��p�ӂ���
//	index��"���j�b�g�̃T�C�Y"�Ɠ����T�C�Y�����A1bit
//	
//	�p�����[�^�z���0�𔲂��Ă�������l�ߍ���
//	�p�����[�^�z��̃T�C�Y�ƃC���f�b�N�X��1�̐��̍��v�͓����ɂȂ��Ă���
//	�C���f�b�N�X��0�̎��͊|���Z�����������Ƀf�[�^�̃A�h���X��i�߂�B�p�����[�^�̃A�h���X�͂��̂܂܂ɂ���
//
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// 
//
//////////////////////////////////////////////////////////////////////////////////
module NNsp(clk,reset,start,write,x_i,x_o,done,dv,result);
	input clk;
	input reset;
	input start;
	input write;
	input signed [31:0] x_i;
	output signed [31:0] x_o;
	output dv;
	output done;
	output result;
	reg signed [31:0] x_o=0;
	reg dv=0;
	reg done=0;
	reg result=0;
///////////////////////////////////////////////////////////////////////////////
/// Parameter
///////////////////////////////////////////////////////////////////////////////
parameter NUMLAYER=3;			//!< LAYER�̐��B
parameter PARAMSIZE_LAYER1=400;	//!< ���ەێ����Ă���p�����[�^���B0�͊܂܂Ȃ�
parameter PARAMSIZE_LAYER2=100; //!< LAYERn-1����LAYERn����邽�߂̃p�����[�^��
parameter PARAMSIZE_LAYER3=100; 
parameter BIASSIZE_LAYER1=50;	//!< LAYER0����LAYER1����邽�߂̃o�C�A�X���̐�
parameter BIASSIZE_LAYER2=50;	
parameter BIASSIZE_LAYER3=2;	
parameter UNITSIZE_LAYER0=420;	//!< �e���C���[�T�C�Y�BLAYER0�͓��̓x�N�g��
parameter UNITSIZE_LAYER1=100;	
parameter UNITSIZE_LAYER2=100;	
parameter UNITSIZE_LAYER3=2;	//!< �o�̓��C���[

///////////////////////////////////////////////////////////////////////////////
/// Register
///////////////////////////////////////////////////////////////////////////////
//! �e���C���[�̏o�͒l[�恛�w][�e���j�b�g�̌���]
reg signed [31:0] n_a0 [0:UNITSIZE_LAYER0-1]; 
reg signed [31:0] n_a1 [0:UNITSIZE_LAYER1-1]; 
reg signed [31:0] n_a2 [0:UNITSIZE_LAYER2-1]; 
reg signed [31:0] n_a3 [0:UNITSIZE_LAYER3-1];
 
//! W_a �e���j�b�g�̃p�����[�^ [�恛�w][���j�b�g�ԍ�][���̃��j�b�g�ԍ�]
//! W_b �e���j�b�g�̃o�C�A�X��[�恛�w][���̃��j�b�g�ԍ�]
reg signed [31:0] W_a ;
reg signed [31:0] W_b ; 

//! index�z��
/* �j���[�����l�b�g�̊|���Z���s�����̃p�����[�^�̗L��
 * �p�����[�^��0�Ȃ�0�A�l�������Ă���Ȃ�1�����
 * (ex)index_1
 * ���͓�����(0�w)->�B��w(1�w)�̃l�b�g��Layer1-Unit1���\������ɂ́A
 * L0-U1����L0-U420���ꂼ��ɑ΂��Ċ|����p�����[�^������
 *
 * �܂��o�C�A�X��(b)�̗L����index_x[:][end]�ɓ������̂Ƃ���
*/
reg index;
reg [2:0] layer_ad=0;
//! 	Other Register
reg load_cp=0;	//!< input data:load complete

reg [9:0] index_ad=0;	//!< �C���f�b�N�X
reg [9:0] unit_ad=0;	//!< ���̃��j�b�g�쐬���̃A�h���X
reg [9:0] param_ad=0;	//!< ��Z�̃p�����[�^�[�̃A�h���X
reg [3:0] process=0;	//!< �v���Z�X
reg [3:0] result_process=0;
reg result_start=0;

//----------------------------------------------------------------------------
///init:ROM, unit param
//----------------------------------------------------------------------------
integer l,i,j,k;
initial begin
	for(l=0;l<UNITSIZE_LAYER0;l=l+1)begin
		n_a0[l]=0;
	end	
	for(i=0;i<UNITSIZE_LAYER1;i=i+1)begin
		n_a1[i]=0;
	end
	for(j=0;j<UNITSIZE_LAYER2;j=j+1)begin
		n_a2[j]=0;
	end
	for(k=0;k<UNITSIZE_LAYER3;k=k+1)begin
		n_a3[k]=0;
	end

end

///////////////////////////////////////////////////////////////////////////////
/// main
///////////////////////////////////////////////////////////////////////////////
always@(posedge clk)begin

	//!param
	`include "nn.dat";
	//!param index
	`include "index.dat"
	
	if(!reset)begin
		//!output port
		x_o<=0;
		dv<=0;
		done<=0;
		result<=0;
		
		//!other register
		
		
	end else if(start == 1)begin
		
		if(write==1)begin
		//!loading input feature
			n_a0[index_ad]<=x_i;
			if(index_ad == UNITSIZE_LAYER0-1)begin
				load_cp<=1;
				index_ad<=0;
			end else begin
				index_ad<=index_ad+1;
			end
		end else begin
			//!<input data complete
			if(load_cp == 1)begin
				//! calc each unit
				case(process)
				0:begin
					//!1layer�̍ŏI���j�b�g�̌v�Z���I�����
					if(unit_ad == UNITSIZE_LAYER1)begin 					//!<
						unit_ad<=0;
						param_ad<=0;
						layer_ad<=1;
						process<=1;
					end else begin
						//!1���j�b�g�̌v�Z���I�����
						if(param_ad == PARAMSIZE_LAYER1)begin 				//!<
							index_ad<=0;
							unit_ad<=unit_ad+1;
							//!���j�b�g�̃o�C�A�X�𑫂�
							if(index==1)begin					//!<
								n_a1[unit_ad]<=n_a1[unit_ad] + W_b;	//!<
							end
						end else begin
							index_ad<=index_ad+1;
							//!index���Q�Ƃ��ăp�����[�^��0�łȂ���Ί|���Z
							if(index_ad==0)begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a1[unit_ad]<= n_a0[index_ad]*W_a;//!<
								end else begin
									n_a1[unit_ad]<=0;
								end
							end else begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a1[unit_ad]<=n_a1[unit_ad] + n_a0[index_ad]*W_a;//!<
								end
							end
						end
					end
				end
				1:begin	//!< Layer1 -> Layer2
					//!1layer�̍ŏI���j�b�g�̌v�Z���I�����
					if(unit_ad == UNITSIZE_LAYER2)begin 					//!<
						unit_ad<=0;
						param_ad<=0;
						layer_ad<=2;
						process<=2;
					end else begin
						//!1���j�b�g�̌v�Z���I�����
						if(param_ad == PARAMSIZE_LAYER2)begin 				//!<
							index_ad<=0;
							unit_ad<=unit_ad+1;
							//!���j�b�g�̃o�C�A�X�𑫂�
							if(index==1)begin					//!<
								n_a2[unit_ad]<=n_a2[unit_ad] + W_b;	//!<
							end
						end else begin
							index_ad<=index_ad+1;
							//!index���Q�Ƃ��ăp�����[�^��0�łȂ���Ί|���Z
							if(index_ad==0)begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a2[unit_ad]<= n_a1[index_ad]*W_a;//!<
								end else begin
									n_a2[unit_ad]<=0;
								end
							end else begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a2[unit_ad]<=n_a2[unit_ad] + n_a1[index_ad]*W_a;//!<
								end
							end
						end
					end
				end
				2:begin
					//!1layer�̍ŏI���j�b�g�̌v�Z���I�����
					if(unit_ad == UNITSIZE_LAYER3)begin 					//!<
						unit_ad<=0;
						param_ad<=0;
						layer_ad<=0;
						process<=3;
					end else begin
						//!1���j�b�g�̌v�Z���I�����
						if(param_ad == PARAMSIZE_LAYER3)begin 				//!<
							index_ad<=0;
							unit_ad<=unit_ad+1;
							//!���j�b�g�̃o�C�A�X�𑫂�
							if(index==1)begin					//!<
								n_a3[unit_ad]<=n_a3[unit_ad] + W_b;	//!<
							end
						end else begin
							index_ad<=index_ad+1;
							//!index���Q�Ƃ��ăp�����[�^��0�łȂ���Ί|���Z
							if(index_ad==0)begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a3[unit_ad]<= n_a2[index_ad]*W_a;//!<
								end else begin
									n_a3[unit_ad]<=0;
								end
							end else begin
								if(index==1)begin					//!<
									param_ad <= param_ad+1;
									n_a3[unit_ad]<=n_a3[unit_ad] + n_a2[index_ad]*W_a;//!<
								end
							end
						end
					end
				end
				3:begin
				//!		���ʏo�͂��N��
					result_start<=1;
					load_cp<=0;
					process<=0;
				end
				endcase

			end		//load cp==1
		
		end			// write==1
		
//------------------------------------------------------------------------
//!		���ʏo��
//------------------------------------------------------------------------	
		if(result_start==1)begin
			case(result_process)
				0:begin
					done<=0;
					dv<=1;
					if(n_a3[0] > n_a3[1])begin
						result<=1;
					end
					x_o<=n_a3[0];
					result_process<=1;
				end
				1:begin
					x_o<=n_a3[1];
					result_process<=2;
				end
				2:begin
					dv<=0;
					x_o<=0;
					result_process<=0;
					result_start<=0;
				end
			endcase
		end
		
	end else begin // start == 0

	end
end

endmodule
