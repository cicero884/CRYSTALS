#include<stdio.h>
#include<stdlib.h>
// convert third party ntt result
// get data from https://www.nayuki.io/page/number-theoretic-transform-integer-dft
FILE *fp;
int main(){
	int tmp;
	fp = fopen("ntt_out.dat", "w");
	scanf("[");
	for(int i=0;i<256;++i){
		scanf("%d, ",&tmp);
		fprintf(fp, "%04x ", tmp);
	}
	fclose(fp);
	return 0;
}
