#include<stdio.h>
#include<stdint.h>
#include<stdlib.h>
#include<time.h>
// for third party cal ntt
// put data into https://www.nayuki.io/page/number-theoretic-transform-integer-dft
// to generate ans
FILE *fp;
int main(){
	srand(time(NULL));
	fp = fopen("ntt_in.dat", "w");
	printf("[");
	unsigned tmp;
	for (int i=0;i<256;++i){
		if (i) printf(", ");
		tmp = ((unsigned)rand()) % 3329;
		fprintf(fp, "%04x ", tmp);
		printf("%d", tmp);
	}
	printf("]");
	fclose(fp);
	return 0;
}

