
/***********************************�᎟���̎��o��******************************/

case(pick_cnt)
	//�f�[�^�̓ǂݍ���
	2:begin
		pick_tmp<=outdata3;
		pick_cnt<=pick_cnt+1;
	end
	
	//�f�[�^�̏�������
	3:begin
		//�擪(�p���[)��C0�Ƃ��Ĉ�U�m�ۂ���
		if(pick_calc_index==0)begin
			write3<=0;
			C0<=outdata3;
			pick_calc_index<=pick_calc_index+1;
			
		//��ԍŌ�i12�Ԗځj�ɂȂ�����A�����܂�
		end else if(pick_calc_index==13) begin
			write3<=1;
			addr3<=pick_calc_index-1;
			indata3<=C0;
			
			pick_tmp<=0;
			pick_calc_index<=0;
			process_index<=process_index+1;

		//����ȊO�̎��́A��O�̃A�h���X�Ƀf�[�^������
		end else begin
			write3<=1;
			addr3<=pick_calc_index-1;
			indata3<=pick_tmp;
			pick_calc_index<=pick_calc_index+1;
		end
		pick_cnt<=0;
	end
	
	//�A�h���X���X�V
	default:begin
		addr3<=pick_calc_index;		//�O�̃v���Z�X�ŃA�h���X������������Ă��Ȃ��Ă�������0����X�^�[�g�o����
		write3<=0;
		pick_cnt<=pick_cnt+1;	
	end
endcase
