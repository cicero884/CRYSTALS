# author:509

# files you dont need to synthesize
TB_TOP_FILE		=	tb_ntt.sv
TB_MUL_TOP_FILE	=	tb_mul.sv
# files you want synthesize
TOP_FILE	=	top_ntt.sv add_sub.sv fifo.sv mo_mul.sv ntt.sv zeta_rom.sv intt.sv 
MUL_TOP_FILE	=	mo_mul.sv
# top module
TOP			=	top_ntt

PASS_STR	=	"ALL PASS"

Q				=	3329
N				=	8

.PHONY: all gtech syn gate nw clean
default:
	@echo "mul_test  => Run test for mo_mul.sv"
	@echo "rom_data  => Generate rom data"
	@echo "gtech_ntt => Run gtech level simulation of ntt"
	@echo "gtech_intt => Run gtech level simulation of intt"
	@echo "nw        => Run nWave"
	@echo "syn       => Run synthesize in interactive mode"
	@echo "gate      => Run gate-level simulation"
	@echo "clean     => Clear file after synthesize"

all: gtech_ntt syn gate

		#-debug_region+cell +memcbk \
		#-debug_access+all \
		#-debug_pp +v2k +memcbk \

rom_data: zeta2rom.c
	gcc zeta2rom.c -o zeta2rom -std=c99
	./zeta2rom $(N) $(Q)

mul_test:
	vcs -R $(TB_MUL_TOP_FILE) $(MUL_TOP_FILE) \
		+vcs+fsdbon \
		+fsdb+mda \
		+fsdbfile+mul.fsdb \
		+access+R \
		-sverilog \
		-l mo_mul.log \
		+define+Q=$(Q)

gtech_ntt: rom_data
	vcs -R $(TB_TOP_FILE) $(TOP_FILE) \
		-sverilog \
		-l ntt.log \
		+define+NTT \
		+vcs+fsdbon \
		+fsdb+mda \
		+access+R \
		+fsdbfile+ntt.fsdb \
		+define+Q=$(Q) \
		+define+NTT_STAGE_CNT=$(N)-1
# FIXME: NTT_STAGE_CNT = N-1?

gtech_intt: rom_data
	vcs -R $(TB_TOP_FILE) $(TOP_FILE) \
		+vcs+fsdbon \
		+fsdb+mda \
		+access+R \
		+fsdbfile+intt.fsdb \
		-sverilog \
		-l intt.log \
		+define+INTT \
		+define+Q=$(Q) \
		+define+NTT_STAGE_CNT=$(N)-1

# please use Ctrl+Z , bg , fg instead add & behind command
nw:
	nWave -f *.fsdb -sswr signal.rc +access+r

syn syn/$(TOP)_syn.v:
ifneq ($(wildcard ./syn),)
	dcnxt_shell -f syn/syn.tcl | tee syn.log;
else
	@echo "Require syn folder with syn.tcl inside!"
endif

gate: syn/$(TOP)_syn.v
	rm syn/$(TOP)_syn.v
	vcs -R $(TB_TOP_FILE) $(TOP)_syn.v \
		-debug_access+all \
		-diag=sdf:verbose \
		-debug_region+cell +memcbk \
		-l gtech.log
	#-v sim_model.v
#	irun $(TB_TOP_FILE) syn/$(TOP)_syn.v -v syn/tsmc13_neg.v \
#		+access+r \
#		+define+FSDB_FILE=\"$(TOP).fsdb\" \
#		+define+SDF \
#		+define+SDFFILE=\"syn/$(TOP)_syn.sdf\" \
#		-append_log
#	mv irun.log gate.log
	vcd2saif -i *.vcd -o ntt.saif

clean:
	rm ./*.err ./*.log syn/$(TOP)_syn* *.fsdb irun.history -f

