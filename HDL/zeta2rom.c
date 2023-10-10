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
long long unsigned Q, bias, zeta;
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
	if(argc < 4){
		printf("input : argv1=log2(poly size), argv2=Q, [argv3=MUL_TYPE], [argv4=root of unity]\n");
		printf("for kyber with MWR2MM is 7 3329 MULTYPE_MWR2MM 17\n");
		printf("for kyber with K-RED  is 7 3329 MULTYPE_KRED 17\n");
		printf("ex: %s 7 3329 MULTYPE_MWR2MM 17\n",argv[0]);
		printf("or: %s 7 3329 MULTYPE_MWR2MM\n",argv[0]);
		return 1;
	}
	bit_size = atoi(argv[1]);
	Q = atoi(argv[2]);

	// calculate bias
	long long unsigned data_max = MSB_2(Q);
	if(!strcmp(argv[3],"MULTYPE_KRED")){
		// Q=(q_k<<q_m)+1
		int q_m = __builtin_popcount((Q-2)^Q);
		int l = (__builtin_ctzll(data_max)-1)/q_m+1;
		int q_k = Q>>q_m;
		printf("q_k=%d, q_m=%d l=%d\n",q_k,q_m,l);
		bias = 1;
		while(l--) bias = (bias*q_k)%Q;
		bias = inverse(bias)%Q;
	}
	else if(!strcmp(argv[3],"MULTYPE_MWR2MM")){
		bias = data_max%Q;
	}
	printf("bias = %llu\n",bias);

	// calculate root of unity
	if(argc < 5){ 
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

	// pre calculate zeta^1,zeta^2,zeta^4,zeta^8....zeta^64
	// inside zeta_2[0],zeta[1]...zeta[6];
	unsigned zeta_2[bit_size];
	zeta_2[0] = zeta;
	for(int i=1; i<bit_size; ++i){
		zeta_2[i] = ((unsigned long long)zeta_2[i-1]*zeta_2[i-1])%Q;
	}

	remove("fake_rom.svh");
	FILE *frfp = fopen("fake_rom.svh","w");
	fprintf(frfp,"parameter [%d:0] zeta_rom[%d] = '{\n",__builtin_ctzll(data_max)-1,(1<<bit_size));
	fprintf(frfp,"%llu",zeta);

	unsigned rom_index=0;
	unsigned long long out_num;
	FILE *fd = NULL;
	char fname[30];
	for(int i=1; i<(1<<(bit_size)); ++i){
		out_num=1;
		for(int j=0; j<bit_size; j++){
			if((1<<j)&i) out_num = (unsigned long long)out_num*zeta_2[bit_size-1-j];
			out_num = out_num % Q;
		}
		// pre-multiply with numbers for later mo_mul
		// for k-red require k^(-l)
		// for MWR2MM require 2^n
		out_num = (out_num*bias)%Q;

		if(!(i&(i-1))){
			if(fd) {
				fclose(fd);
			}
			sprintf(fname,"rom_%d.dat",rom_index);
			fd = fopen(fname,"w");
			rom_index++;
		}
		else fprintf(fd," ");
		fprintf(fd,"%llx",out_num);
		fprintf(frfp,", %llu",out_num);
	}
	fclose(fd);
	fprintf(frfp,"\n};");
	fclose(frfp);
	return 0;
}
