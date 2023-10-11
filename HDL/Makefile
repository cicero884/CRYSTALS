# author:509
# basic parameters
SHELL := /bin/bash

# kyber
Q = 3329
NTT_STAGE_CNT = 7

# dilithium
#Q = 8380417
#NTT_STAGE_CNT = 8

# new-hope kyber
#Q = 12289
#NTT_STAGE_CNT = 9

# qTESLA
#Q = 343576577
#NTT_STAGE_CNT = 9

#define to use which mo_mul
#available: "MULTYPE_KRED", "MULTYPE_MWR2MM"
#default is "MULTYPE_MWR2MM"
#MO_MUL_TYPE = MULTYPE_KRED
MO_MUL_TYPE = MULTYPE_KRED

##############

# files you dont need to synthesize
PKG_FILE		=	ntt_pkg.sv
TB_TOP_FILE		=	tb_ntt.sv
TB_MUL_TOP_FILE	=	tb_mul.sv
# files you want synthesize
TOP_FILE		=	top_ntt.sv add_sub.sv fifo.sv mo_mul.sv ntt.sv zeta_rom.sv intt.sv
#add_sub.svh fifo.svh mo_mul.svh ntt.svh ntt_param.svh rom.svh
MUL_TOP_FILE	=	mo_mul.sv
# top module
TOP			=	top_ntt
SDC			=	syn/$(TOP).sdc

PASS_STR	=	"ALL PASS"


.PHONY: all gtech syn gate nw clean
default:
	@echo "mul_test   => Run test for mo_mul.sv"
	@echo "gtech_ntt  => Run gtech level simulation of ntt"
	@echo "gtech_intt => Run gtech level simulation of intt"
	@echo "nw         => Run nWave"
	@echo "syn        => Run synthesize in interactive mode"
	@echo "gate_ntt   => Run ntt gate-level simulation"
	@echo "clean      => Clear file after synthesize"
	@echo "-----------------"
	@echo "gen_files  => Generate all require file by parameter in Makefile"
	@echo "zeta2rom   => make zeta2rom which calculate zeta_rom values"
	@echo "gen_rom    => run zeta2rom calculate rom values"

all: gtech_ntt syn gate

		#-debug_region+cell +memcbk \
		#-debug_access+all \
		#-debug_pp +v2k +memcbk \

zeta2rom: zeta2rom.c
	gcc zeta2rom.c -o zeta2rom -std=c99

gen_rom: zeta2rom
	./zeta2rom $(NTT_STAGE_CNT) $(Q) $(MO_MUL_TYPE)

gen_files: gen_rom
# parameters for ntt
	echo -e " \
		//THIS IS GENERATED FILE!\n\
		parameter Q=$(Q);\n\
		parameter NTT_STAGE_CNT=$(NTT_STAGE_CNT);\n\
		\`define $(MO_MUL_TYPE)\n\
		\`define MAX_FIFO_ADDR_BITS 30" \
		> ntt_param.svh;
	echo -e " \
		//THIS IS GENERATED FILE!\n\
		parameter ROM0_DATA='h$(shell cat rom_0.dat);\n\
		parameter ROM_PATH=\"$(shell pwd)\";" \
		> rom.svh;
	@echo "all file generated!"

mul_test:
	vcs -R $(TB_MUL_TOP_FILE) $(MUL_TOP_FILE) \
		+vcs+fsdbon \
		+fsdb+mda \
		+fsdbfile+mul.fsdb \
		+access+R \
		-sverilog \
		-l mo_mul.log

gtech_ntt: gen_files
	vcs -R $(PKG_FILE) $(TB_TOP_FILE) $(TOP_FILE) \
		-sverilog \
		-l ntt.log \
		+vcs+fsdbon \
		+fsdb+mda \
		+access+R \
		+fsdbfile+ntt.fsdb \
		+define+NTT

gtech_intt: gen_files
	vcs -R $(PKG_FILE) $(TB_TOP_FILE) $(TOP_FILE) \
		+vcs+fsdbon \
		+fsdb+mda \
		+access+R \
		+fsdbfile+intt.fsdb \
		-sverilog \
		-l intt.log \
		+define+INTT

# please use Ctrl+Z , bg , fg instead add & behind command
nw:
	nWave -f *.fsdb -sswr signal.rc +access+r

syn syn/$(TOP)_syn.v: gen_files

ifneq ($(wildcard ./syn),)
	dc_shell -f syn/syn.tcl -output_log_file syn.log -x \
		"\
		set top $(TOP); \
		set src_file {$(PKG_FILE) $(TOP_FILE)}; \
		set sdc_file $(SDC); \
		";

else
	@echo "syn folder with syn.tcl & tsmc13_neg.v inside require!"
endif
#syn/$(TOP)_syn.v
gate_ntt: 
	vcs -R $(PKG_FILE) $(TB_TOP_FILE) syn/$(TOP)_syn.v syn/tsmc13_neg.v \
		-sverilog \
		-debug_access+all \
		-diag=sdf:verbose \
		+vcs+fsdbon \
		+fsdb+mda \
		+access+R \
		+fsdbfile+gate_ntt.fsdb \
		+neg_tchk \
		-notice \
		+lint=TFIPC-L \
		-debug_region+cell +memcbk \
		+define+SDF \
		-l gate_ntt.log \
		+define+NTT
	#-v sim_model.v
	#	irun $(TB_TOP_FILE) syn/$(TOP)_syn.v -v syn/tsmc13_neg.v \
		#		+access+r \
		#		+define+FSDB_FILE=\"$(TOP).fsdb\" \
		#		+define+SDF \
		#		+define+SDFFILE=\"syn/$(TOP)_syn.sdf\" \
		#		-append_log
	#	mv irun.log gate.log
	#	vcd2saif -i *.vcd -o ntt.saif

clean:
# simulation files
	rm ./*.err ./*.log syn/$(TOP)_syn* *.fsdb irun.history -f
# generated files
	rm *.dat ntt_param.svh rom.svh fake_rom.svh zeta2rom -f

