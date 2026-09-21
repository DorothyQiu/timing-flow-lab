###########################################################################
# Directory Structure                                                     #
# ./        -- current directory, simulation runs from here               #
# ./work    -- Cadence work library                                       #
# ./design  -- RTL verilog                                                #
# ./tb      -- testbench                                                  #
# ./netlist -- synthesis outputs (from DC)  (now: ./netlist/demoX/)       #
# ./include -- include files + stdcell verilog for sim                    #
# ./scripts -- tcl scripts for sim/syn/pnr                                #
# ./report  -- reports (now: ./report/demoX/syn , ./report/demoX/pnr )    #
# ./pnr     -- (optional legacy; we will write reports under ./report)    #
###########################################################################

# ===================== DEMO CONFIG =====================
# choose: demo1 / demo2 / demo3
DEMO ?= demo1

# DUT top (synthesis/PnR)
DESIGN_NAME = top_$(DEMO)
DESIGN_TOP  = top_$(DEMO)

# testbench tops (you can keep your tb naming if already fixed)
# e.g., tb_demo1 / tb_demo1_syn / tb_demo1_pnr ...
TOP        = tb_$(DEMO)
TOP_SYN    = tb_$(DEMO)_syn
TOP_PNR    = tb_$(DEMO)_pnr

# ===================== PATH CONFIG =====================
# RTL + TB
DESIGN_FILES = ./design/*.v
TB_FILES     = ./tb/*.v

# Stdcell verilog for simulation (needed for gate-level netlists)
LIBV = ./include/gscl45nm.v
INCLUDE_DIRECTORY = ./include

# --- per-demo output dirs ---
NETLIST_DIR = ./netlist/$(DEMO)
REPORT_DIR  = ./report/$(DEMO)
SYN_RPT_DIR = $(REPORT_DIR)/syn
PNR_RPT_DIR = $(REPORT_DIR)/pnr

# DC outputs (per-demo)
SYN_NETLIST = $(NETLIST_DIR)/$(DESIGN_TOP)_syn.v
SYN_SDC     = $(NETLIST_DIR)/$(DESIGN_TOP).sdc
SYN_SDF     = $(NETLIST_DIR)/$(DESIGN_TOP).sdf

# Innovus outputs (per-demo)
PNR_NETLIST_OUT = $(NETLIST_DIR)/$(DESIGN_TOP)_pnr.v
PNR_SDF_OUT     = $(NETLIST_DIR)/$(DESIGN_TOP)_pnr.sdf

# Scripts (per-demo)
SYN_TCL  = scripts/syn_$(DEMO).tcl
INV_TCL  = scripts/innovus_$(DEMO).tcl
MMMC_TCL = scripts/mmmc.tcl

# GUI simulation script file for pre-synthesis design
SIM_SCRIPT_FILE_GUI        = ./scripts/runscript.tcl
SIM_SCRIPT_FILE_NO_GUI     = ./scripts/runscript_nogui.tcl

# GUI simulation script file for post-synthesis design
SIM_SYN_SCRIPT_FILE_GUI    = ./scripts/runscript_syn.tcl
SIM_SYN_SCRIPT_FILE_NO_GUI = ./scripts/runscript_syn_nogui.tcl

# GUI simulation script file for PnR
SIM_PNR_SCRIPT_FILE_GUI    = ./scripts/runscript_pnr.tcl
SIM_PNR_SCRIPT_FILE_NO_GUI = ./scripts/runscript_pnr_nogui.tcl

# ===================== NC (Incisive/Xcelium) SWITCHES =====================
NCVLOG_SWITCHES = \
	-STATUS \
	-MESSAGES \
	-UPDATE \
	-INCDIR $(INCLUDE_DIRECTORY)

NCELAB_SWITCHES = \
	-ACCESS +rwc \
	-NCFATAL INVSUP \
	-NCFATAL CUNOTB \
	-ERRORMAX 5 \
	-UPDATE \
	-MESSAGES \
	-TIMESCALE '1ns/10ps' \
	-LIBVERBOSE

NCSIM_SWITCHES_NO_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_NO_GUI)

NCSIM_SWITCHES_NO_GUI_SYN = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SYN_SCRIPT_FILE_NO_GUI)

NCSIM_SWITCHES_NO_GUI_PNR = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_PNR_SCRIPT_FILE_NO_GUI)

NCSIM_SWITCHES_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_GUI) \
	-GUI

NCSIM_SWITCHES_GUI_SYN = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SYN_SCRIPT_FILE_GUI) \
	-GUI

NCSIM_SWITCHES_GUI_PNR = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_PNR_SCRIPT_FILE_GUI) \
	-GUI

export

# ===================== DEFAULT TARGET =====================
all: sim

# ===================== HELPER DIR TARGET =====================
.PHONY: dirs
dirs:
	@mkdir -p work
	@mkdir -p $(NETLIST_DIR)
	@mkdir -p $(SYN_RPT_DIR)
	@mkdir -p $(PNR_RPT_DIR)

# ===================== ANALYZE / ELAB / SIM (RTL) =====================
ana~ : $(DESIGN_FILES) $(TB_FILES)
	for f in $(DESIGN_FILES); do ncvlog $(NCVLOG_SWITCHES) -work work $$f ; done
	for f in $(TB_FILES);     do ncvlog $(NCVLOG_SWITCHES) -work work $$f ; done
	@touch ana~

elab~ : ana~
	ncelab $(NCELAB_SWITCHES) work.$(TOP)
	@touch elab~

sim : clean elab~
	ncsim $(NCSIM_SWITCHES_NO_GUI) work.$(TOP)

simg : clean elab~
	ncsim $(NCSIM_SWITCHES_GUI) work.$(TOP)

# ===================== ANALYZE / ELAB / SIM (POST-SYN) =====================
ana_syn~ : $(SYN_NETLIST) $(TB_FILES) $(LIBV)
	ncvlog $(NCVLOG_SWITCHES) -work work $(LIBV)
	ncvlog $(NCVLOG_SWITCHES) -work work $(SYN_NETLIST)
	for f in $(TB_FILES); do ncvlog $(NCVLOG_SWITCHES) -work work $$f ; done
	@touch ana_syn~

elab_syn~ : ana_syn~
	ncelab $(NCELAB_SWITCHES) work.$(TOP_SYN)
	@touch elab_syn~

sim_syn : clean elab_syn~
	ncsim $(NCSIM_SWITCHES_NO_GUI_SYN) work.$(TOP_SYN)

simg_syn : clean elab_syn~
	ncsim $(NCSIM_SWITCHES_GUI_SYN) work.$(TOP_SYN)

# ===================== ANALYZE / ELAB / SIM (POST-PNR) =====================
ana_pnr~ : $(PNR_NETLIST_OUT) ./tb/$(TOP_PNR).v $(LIBV)
	ncvlog $(NCVLOG_SWITCHES) -work work $(LIBV)
	ncvlog $(NCVLOG_SWITCHES) -work work $(PNR_NETLIST_OUT)
	ncvlog $(NCVLOG_SWITCHES) -work work ./tb/$(TOP_PNR).v
	@touch ana_pnr~

elab_pnr~ : ana_pnr~
	ncelab $(NCELAB_SWITCHES) work.$(TOP_PNR)
	@touch elab_pnr~

sim_pnr : clean elab_pnr~
	ncsim $(NCSIM_SWITCHES_NO_GUI_PNR) work.$(TOP_PNR)

simg_pnr : clean elab_pnr~
	ncsim $(NCSIM_SWITCHES_GUI_PNR) work.$(TOP_PNR)

# ===================== SYNTHESIS (DC) =====================
.PHONY: syn
syn: dirs
	@echo "==> SYN DEMO=$(DEMO) TOP=$(DESIGN_TOP)"
	@echo "    using $(SYN_TCL)"
	dc_shell -f $(SYN_TCL) -output_log_file $(SYN_RPT_DIR)/dc.log

# ===================== PNR (Innovus) =====================
.PHONY: pnr pnr_gui
pnr: dirs
	@echo "==> PNR DEMO=$(DEMO) TOP=$(DESIGN_TOP)"
	@echo "    using $(INV_TCL)"
	TOP=$(DESIGN_TOP) NETLIST=$(SYN_NETLIST) SDC=$(SYN_SDC) \
	MMMC=$(MMMC_TCL) PNR_OUT=$(PNR_NETLIST_OUT) \
	OUT_RPT=$(PNR_RPT_DIR) OUT_NETLIST=$(NETLIST_DIR) \
	innovus -no_gui -files $(INV_TCL) -log $(PNR_RPT_DIR)/innovus.log

pnr_gui: dirs
	TOP=$(DESIGN_TOP) NETLIST=$(SYN_NETLIST) SDC=$(SYN_SDC) \
	MMMC=$(MMMC_TCL) PNR_OUT=$(PNR_NETLIST_OUT) \
	OUT_RPT=$(PNR_RPT_DIR) OUT_NETLIST=$(NETLIST_DIR) \
	innovus -files $(INV_TCL) -log $(PNR_RPT_DIR)/innovus_gui.log

# ===================== CLEAN / INIT =====================
.PHONY: clean clean_demo clean_all

clean :
	@rm -rf `find . -name '*~'`
	@rm -rf work waves.shm
	@rm -rf ncsim*
	@rm -rf *.log
	@rm -f default.svf
	@rm -f ana~ elab~ ana_syn~ elab_syn~ ana_pnr~ elab_pnr~
	@mkdir -p work
	@echo 'All set for a clean start'

# remove outputs only for current demo
clean_demo:
	@echo "==> Removing outputs for DEMO=$(DEMO)"
	@rm -rf $(NETLIST_DIR)
	@rm -rf $(REPORT_DIR)

# remove outputs for all demos 
clean_all:
	@echo "==> Removing outputs for ALL demos"
	@rm -rf ./netlist/demo1 ./netlist/demo2 ./netlist/demo3
	@rm -rf ./report/demo1  ./report/demo2  ./report/demo3
	@rm -rf ./pnr_demo1 ./pnr_demo2 ./pnr_demo3
	@rm -rf ./pnr
	@echo "done."

dir :
	@mkdir -p work design tb include scripts netlist report src pnr
	@echo 'Directory structure for simulation is created'

cds.lib :
	@echo 'DEFINE work work' > cds.lib

hdl.var :
	@echo '# Hello Cadence' > hdl.var

init : dir cds.lib hdl.var
	@touch AUTHORS
	@echo 'Initialized the directory for simulation'
