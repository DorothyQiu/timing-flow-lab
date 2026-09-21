######################################################################
# scripts/syn_demo1.tcl  (Demo1: single ideal clock)
######################################################################

# ---- top name from Makefile ----
set design_name $env(DESIGN_NAME)

# ---- output dirs (Demo1) ----
set DEMO "demo1"
set rpt_dir "report/${DEMO}/syn"
set net_dir "netlist/${DEMO}"
file mkdir report
file mkdir netlist
file mkdir "report/${DEMO}"
file mkdir $rpt_dir
file mkdir $net_dir

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

# ---- constraints (Demo1 baseline) ----
create_clock -name clk_in -period 5.0 -waveform {0 2.5} [get_ports clk_in]
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

# (optional but useful) clock summary
report_clocks > ${rpt_dir}/${design_name}.clocks.rpt

# ---- outputs ----
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -out ${net_dir}/${design_name}_syn.v
write_sdf ${net_dir}/${design_name}.sdf
write_sdc ${net_dir}/${design_name}.sdc

quit
