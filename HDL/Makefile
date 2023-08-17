# author:509

# files you dont need to synthesize
TB_TOP_FILE	=	tb.sv
# files you want synthesize
NTT_TOP_FILE	=	ntt.sv
INTT_TOP_FILE	=	intt.sv
# top module
NTT_TOP			=	ntt
INTT_TOP 		=	intt

PASS_STR	=	"ALL PASS"

all: gtech syn gate
.PHONY: all gtech syn gate nw clean
default:
	@echo "gtech	=> Run gtech level simulation"
	@echo "nw		=> Run nWave"
	@echo "syn		=> Run synthesize in interactive mode"
	@echo "gate		=> Run gate-level simulation"
	@echo "clean	=> Clear file after synthesize"

gtech:
	vcs -R $(TB_TOP_FILE) $(TOP_FILE) \
		+nospecify \
		-debug_access=+all \
		-debug_region+cell +memcbk \
		-l gtech.log
	#-v sim_model.v

#	irun $(TB_TOP_FILE) $(TOP_FILE) \
#		+access+r \
#		+define+FSDB_FILE=\"$(TOP).fsdb\" \
#		-append_log
	grep -e $(PASS_STR) gtech.log

# please use Ctrl+Z , bg , fg instead add & behind command
nw:
	vcd2saif -i *.vcd -o $(TOP).saif
	nWave -f *.saif -sswr signal.rc +access+r

syn syn/$(TOP)_syn.v:
ifneq ($(wildcard ./syn),)
	dcnxt_shell -f syn/syn.tcl | tee syn.log;
else
	@echo "Require syn folder with syn.tcl inside!"
endif

gate: syn/$(TOP)_syn.v
	rm syn/$(TOP)_syn.v
	vcs -R $(TB_TOP_FILE) $(TOP)_syn.v \
		-debug_access=+all \
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
	mv irun.log gate.log

clean:
	rm ./*.err ./*.log syn/$(TOP)_syn* *.fsdb irun.history -f

