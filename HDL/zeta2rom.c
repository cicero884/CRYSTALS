/*********
 * zetas2rom
 * convert zetas to required data files for rom to read
 * input : argv1=root_of_unit, argv2=log2(poly size), argv3=prine
 * (for kyber is 17,8,3329)
 * (https://www.ietf.org/archive/id/draft-cfrg-schwabe-kyber-01.html)
 * output : multiple files for rom to read
 * *************/
//TODO: extend bits
#include<stdio.h>
#include<stdlib.h>

unsigned zeta, bit_size;
long long unsigned Q;
// return MSB*2
long long unsigned MSB_2(long long unsigned msb_q){
	for(int i=1; i <= 32; i<<=1){
		msb_q |= (msb_q>>i);
	}
	return msb_q+1;
}
int main(int argc,char *argv[]){
	if(argc != 4){
		printf("input : argv1=root of unity, argv2=log2(poly size), argv3=Q\n");
		printf("for kyber is 17 8 3329\n");
		printf("ex: %s 17 8 3329\n",argv[0]);
		return 1;
	}
	zeta = atoi(argv[1]);
	bit_size = atoi(argv[2])-1;
	Q = atoi(argv[3]);

	unsigned zeta_2[bit_size];
	zeta_2[0] = zeta;
	// pre calculate zeta^1,zeta^2,zeta^4,zeta^8....zeta^64
	// inside zeta_2[0],zeta[1]...zeta[6];
	for(int i=1; i<bit_size; ++i){
		zeta_2[i] = ((unsigned long long)zeta_2[i-1]*zeta_2[i-1])%Q;
	}

	unsigned rom_index=0;
	unsigned out_num;
	FILE *fd = NULL;
	char fname[30];
	//sprintf(fname,"rom_%d.rom",rom_index);
	//fd = fopen(fname,"w");
	for(int i=1; i<(1<<(bit_size)); ++i){
		out_num=1;
		for(int j=0; j<bit_size; j++){
			if((1<<j)&i) out_num = (unsigned long long)out_num*zeta_2[bit_size-1-j];
			out_num = out_num % Q;
		}
		// pre-multiply with numbers for later mo_mul
		// for k-red require k^(-l)
		// for MWR2MM require 2^n(FIXME)
		out_num = (out_num * MSB_2(Q)) % Q;

		if(!(i&(i-1))){
			if(fd) fclose(fd);
			sprintf(fname,"rom_%d.rom",rom_index);
			fd = fopen(fname,"w");
			rom_index++;
		}
		else fprintf(fd," ",out_num);
		fprintf(fd,"%x",out_num);
	}
	fclose(fd);
	return 0;
}
