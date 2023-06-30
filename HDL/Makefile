# author:509
# lazy & dirty version for emergency run rtl without ordering files
# Not test synthesize because dont need to synthesize in this homework
# inspire by WeiCheng14159

# files you dont need to synthesize
TB_TOP_FILE	=	tb_ntt.sv
# files you want synthesize
TOP_FILE	=	ntt.sv
# top module
TOP			=	ntt

PASS_STR	=	"ALL PASS"

all: pre syn gate
.PHONY: all pre syn gate nw clean
default:
	@echo "pre		=> Run RTL simulation"
	@echo "nw		=> Run nWave"
	@echo "syn		=> Run synthesize in interactive mode"
	@echo "gate		=> Run gate-level simulation"
	@echo "clean	=> Clear file after synthesize"

pre:
	irun $(TB_TOP_FILE) $(TOP_FILE) \
		+access+r \
		+define+FSDB_FILE=\"$(TOP).sdb\" \
		-append_log
	mv irun.log pre.log
	grep -e $(PASS_STR) pre.log

# please use Ctrl+Z , bg , fg instead add & behind command
nw:
	nWave -f *.fsdb -sswr signal.rc +access+r

syn syn/$(TOP)_syn.v:
ifneq ($(wildcard ./syn),)
	dcnxt_shell -f syn/syn.tcl | tee syn.log;
else
	@echo "syn folder with syn.tcl & tsmc13_neg.v inside require!"
endif

gate: syn/$(TOP)_syn.v
	rm syn/$(TOP)_syn.v
	irun $(TB_TOP_FILE) syn/$(TOP)_syn.v -v syn/tsmc13_neg.v \
		+access+r \
		+define+FSDB_FILE=\"$(TOP).fsdb\" \
		+define+SDF \
		+define+SDFFILE=\"syn/$(TOP)_syn.sdf\" \
		-append_log
	mv irun.log gate.log

clean:
	rm ./*.err ./*.log syn/$(TOP)_syn* *.fsdb irun.history -f

