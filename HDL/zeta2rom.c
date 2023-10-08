/*********
 * zetas2rom
 * convert zetas to required data files for rom to read
 * input : argv1=root_of_unit, argv2=log2(poly size), argv3=prine
 * (for kyber is 8,3329,17)
 * (https://www.ietf.org/archive/id/draft-cfrg-schwabe-kyber-01.html)
 * output : multiple files for rom to read
 * *************/
//TODO: extend bits?
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
unsigned bit_size;
long long unsigned Q;
// return MSB*2
long long unsigned MSB_2(long long unsigned msb_q){
	for(int i=1; i <= 32; i<<=1){
		msb_q |= (msb_q>>i);
	}
	return msb_q+1;
}
long long unsigned inverse(long long unsigned a){
	long long unsigned i;
	for(i=1; i<Q; i++){
		if(((i*a)%Q)==1) return i;
	}
	if(i==Q) printf("inverse not found!\n");
	return 0;
}
int main(int argc,char *argv[]){
	if(argc < 3){
		printf("input : argv1=log2(poly size), argv2=Q, [argv3=mul_type], [argv4=root of unity]\n");
		printf("for kyber is 7 3329 [mul type] 17\n");
		printf("ex: %s 7 3329 MULTYPE_MWR2MM_N 17\n",argv[0]);
		printf("or: %s 7 3329\n",argv[0]);
		return 1;
	}
	bit_size = atoi(argv[1]);
	Q = atoi(argv[2]);
	long long unsigned zeta;
	if(argc == 4){
		long long unsigned i;
		for(i=2; i<Q; i++){
			long long unsigned tmp = i;
			zeta = i;
			for(int j=0; j<bit_size; j++) tmp=(tmp*tmp)%Q;
			if(tmp == Q-1) break;
		}
		if(i == Q) printf("root of unity not found!\n");
		else printf("zeta: %llu\n", zeta);
	}
	else zeta = atoi(argv[4]);

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
		if(argc>4 && (!strcmp(argv[3],"MULTYPE_KRED"))){
			//TODO:change 169 to be able to calculate
			if(Q!=3329 && bit_size!=7){
				printf("error: fix 169 to your k**l");
				return 1;
			}
			out_num = (out_num * inverse(169)) % Q;
		}
		else out_num = (out_num * MSB_2(Q)) % Q;

		if(!(i&(i-1))){
			if(fd) {
				fclose(fd);
			}
			sprintf(fname,"rom_%d.dat",rom_index);
			fd = fopen(fname,"w");
			rom_index++;
		}
		else fprintf(fd," ");
		fprintf(fd,"%x",out_num);
	}
	fclose(fd);
	return 0;
}
