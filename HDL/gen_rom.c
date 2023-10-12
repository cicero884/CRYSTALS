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
enum algorithm {CRYSTALS=0,DIFDIT=1};
enum algorithm alg;
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
		printf("input : argv1=log2(poly size), argv2=Q, argv3=algorithm, [argv4=MUL_TYPE], [argv5=root of unity]\n");
		printf("available algorithm: ALG_CRYSTALS, ALG_DIFDIT, ");
		printf("available MUL_TYPE(effect bias): MULTYPE_KRED(default), MULTYPE_MWR2MM");
		printf("for kyber with MWR2MM is 7 3329 ALG_CRYSTALS MULTYPE_MWR2MM 17\n");
		printf("for kyber with K-RED  is 7 3329 ALG_CRYSTALS\n");
		printf("ex: %s 7 3329 ALG_CRYSTALS MULTYPE_MWR2MM 17\n",argv[0]);
		printf("or: %s 7 3329 ALG_CRYSTALS\n",argv[0]);
		return 1;
	}
	bit_size = atoi(argv[1]);
	Q = atoi(argv[2]);
	if(!strcmp(argv[3],"ALG_CRYSTALS"))	alg = CRYSTALS;
	else if(!strcmp(argv[3],"ALG_DIFDIT")) alg = DIFDIT;
	else{
		printf("Error: Algorithm not found!\n");
		return 1;
	}

	// calculate bias for different mul
	long long unsigned data_max = MSB_2(Q);
	if(argc>4){
		if(!strcmp(argv[4],"MULTYPE_MWR2MM")){
			bias = data_max%Q;
		}
		else if(!strcmp(argv[4],"MULTYPE_KRED")){
			// Q=(q_k<<q_m)+1
			int q_m = __builtin_popcount((Q-2)^Q);
			int l = (__builtin_ctzll(data_max)-1)/q_m+1;
			int q_k = Q>>q_m;
			printf("q_k=%d, q_m=%d l=%d\n",q_k,q_m,l);
			bias = 1;
			while(l--) bias = (bias*q_k)%Q;
			bias = inverse(bias)%Q;
		}
		else{
			char *ptr;
			long ret = strtol(argv[4], &ptr, 10);
			if(!ret){
				printf("unknown multype or set bias to 0\n");
				return 1;
			}
			bias = ret;
		}
	}
	printf("bias = %llu\n",bias);

	// calculate root of unity
	if(argc < 6){
		long long unsigned i;
		for(i=2; i<Q; i++){
			long long unsigned tmp = i;
			zeta = i;
			// for CRYSTAL is x**(2<<bit_size)=1
			// for DIFDIT  is x**(1<<bit_size)=1
			for(int j=alg; j<bit_size; j++) tmp=(tmp*tmp)%Q;
			if(tmp == Q-1) break;
		}
		if(i == Q) printf("root of unity not found!\n");
		else printf("auto calculate twiddle_factor/zeta: %llu\n", zeta);
	}
	else zeta = atoi(argv[5]);

	// pre calculate zeta^1,zeta^2,zeta^4,zeta^8....zeta^64
	// inside zeta_2[0],zeta[1]...zeta[6];
	unsigned zeta_2[bit_size];
	zeta_2[0] = zeta;
	for(int i=1; i<bit_size; ++i){
		zeta_2[i] = ((unsigned long long)zeta_2[i-1]*zeta_2[i-1])%Q;
	}

	remove("fake_rom.svh");
	FILE *frfp = fopen("fake_rom.svh","w");
	fprintf(frfp,"parameter [%d:0] zeta_rom_array[%d] = '{\n",__builtin_ctzll(data_max)-1,(1<<bit_size));
	fprintf(frfp,"%llu",zeta);

	unsigned long long out_num;
	FILE *fd = NULL;
	char fname[30];
	unsigned total_cnt=1;
	for(unsigned i=0; i<bit_size; i++){
		sprintf(fname,"rom_%d.dat",i);
		fd = fopen(fname,"w");
		// for DIFDIT , twiddle factor is bit reverse order
		// ex:
		// 0
		// 4,0
		// 6,2,4,0
		// 7,3,5,1,6,2,4,0
		for(int j=0; j<(1<<i); j++){
			if(j) fprintf(fd," ");
			out_num=1;

			switch(alg){
				case DIFDIT:
					for(int k=0; k<i; k++){
						if((1<<k)&j) out_num = (out_num*zeta_2[bit_size-2-k])%Q;
					}
					break;
				case CRYSTALS:
					for(int k=0; k<bit_size; k++){
						if((1<<k)&total_cnt) out_num = (out_num*zeta_2[bit_size-1-k])%Q;
					}
					break;
			}
			out_num = (out_num*bias)%Q;
			total_cnt++;
			fprintf(fd,"%llx",out_num);
			fprintf(frfp,", %llu",out_num);
		}
		fclose(fd);
	}
	fprintf(frfp,"\n};");
	fclose(frfp);
	/*
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
	*/
	return 0;
}
