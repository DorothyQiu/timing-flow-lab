######################################################################
# scripts/syn_demo2.tcl  (Demo2: manual clock match with guessed offset)
######################################################################

# ---- top name from Makefile ----
set design_name $env(DESIGN_NAME)

# ---- output dirs (Demo2) ----
set DEMO "demo2"
set rpt_dir "report/${DEMO}/syn"
set net_dir "netlist/${DEMO}"
file mkdir report
file mkdir netlist
file mkdir "report/${DEMO}"
file mkdir $rpt_dir
file mkdir $net_dir

# ---- user clock offset (ns) ----
# default 0.7ns, can override by:
#   USER_CLK_OFFSET=0.4 make syn DEMO=demo2
set USER_CLK_OFFSET 0.7
if {[info exists ::env(USER_CLK_OFFSET)] && $::env(USER_CLK_OFFSET) ne ""} {
  set USER_CLK_OFFSET $::env(USER_CLK_OFFSET)
}
puts "INFO: Demo2 USER_CLK_OFFSET = ${USER_CLK_OFFSET} ns"

# ---- library setup ----
set search_path [ list . \
  ./design \
  ./include \
  /home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files ]

set target_library { gscl45nm.db }
set synthetic_library [list dw_foundation.sldb standard.sldb]
set link_library [list * gscl45nm.db dw_foundation.sldb standard.sldb]

# ---- read RTL ----
read_verilog [glob ./design/*.v]
current_design $design_name
uniquify
link

# ---- constraints (Demo2 manual match) ----
# Baseline primary clock on top port
create_clock -name clk_in -period 5.0 -waveform {0 2.5} [get_ports clk_in]

# Create a separate "user" clock on the user block clock pin.
# NOTE: This is an artificial model (manual patch) to emulate extra insertion delay.
# Make sure this pin path exists (matches your instance name in RTL).
set USER_CLK_PIN [get_pins u_user/clk]
if {[sizeof_collection $USER_CLK_PIN] == 0} {
  puts "ERROR: Cannot find pin u_user/clk. Check instance name/path."
  puts "HINT: try 'get_pins -hier *u_user*/*clk*' in DC to locate it."
  exit 1
}

create_clock -name clk_user -period 5.0 -waveform {0 2.5} $USER_CLK_PIN

# Try to avoid ambiguity: remove any existing clock association on that pin.
# Different DC versions behave differently; keep it soft.
catch { remove_clock $USER_CLK_PIN }

# Apply guessed source latency (offset) to clk_user
# (clk_in stays 0ns reference; clk_user is shifted later by USER_CLK_OFFSET)
set_clock_latency -source 0.0             [get_clocks clk_in]
set_clock_latency -source $USER_CLK_OFFSET [get_clocks clk_user]

# reset handling
set_false_path -from [get_ports rst_n]

# ---- sanity ----
check_design > ${rpt_dir}/${design_name}.check_design.rpt

# ---- compile ----
compile

# ---- reports ----
report_timing -max_paths 30 -path full -input_pins -nets -transition_time \
  > ${rpt_dir}/${design_name}.timing.rpt
report_area  > ${rpt_dir}/${design_name}.area.rpt
report_power > ${rpt_dir}/${design_name}.power.rpt

# useful clock summary
report_clocks > ${rpt_dir}/${design_name}.clocks.rpt

# (extra) show clock objects and attributes (helps debug if clock binding is weird)
report_clock -attributes > ${rpt_dir}/${design_name}.clock_attrs.rpt

# ---- outputs ----
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -out ${net_dir}/${design_name}_syn.v
write_sdf ${net_dir}/${design_name}.sdf
write_sdc ${net_dir}/${design_name}.sdc

quit
