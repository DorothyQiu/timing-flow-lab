######################################################################
# scripts/syn_demo3.tcl
# Demo3: generated clock (physically consistent parent-child model)
######################################################################

# ---- top name from Makefile ----
set design_name $env(DESIGN_NAME)

# ---- output dirs (Demo3) ----
set DEMO "demo3"
set rpt_dir "report/${DEMO}/syn"
set net_dir "netlist/${DEMO}"

file mkdir report
file mkdir netlist
file mkdir "report/${DEMO}"
file mkdir $rpt_dir
file mkdir $net_dir

puts "INFO: Demo3 (generated clock model)"

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

# ==========================================================
# Constraints (Demo3)
# ==========================================================

# Primary clock at top port
create_clock -name clk_in -period 5.0 -waveform {0 2.5} [get_ports clk_in]

# Reset
set_false_path -from [get_ports rst_n]

# Get hierarchical pins
set STATION_CLK_PIN [get_pins u_station/clk]
set USER_CLK_PIN    [get_pins u_user/clk]

if {[sizeof_collection $STATION_CLK_PIN] == 0} {
  puts "ERROR: Cannot find u_station/clk"
  exit 1
}
if {[sizeof_collection $USER_CLK_PIN] == 0} {
  puts "ERROR: Cannot find u_user/clk"
  exit 1
}

# Generated clock: derived from station clock pin
# divide_by 1 => same frequency
create_generated_clock \
  -name clk_user \
  -source $STATION_CLK_PIN \
  -divide_by 1 \
  $USER_CLK_PIN

# ==========================================================
# Sanity
# ==========================================================
check_design > ${rpt_dir}/${design_name}.check_design.rpt

# ---- compile ----
compile

# ==========================================================
# Reports
# ==========================================================

report_timing -max_paths 30 -path full -input_pins -nets -transition_time \
  > ${rpt_dir}/${design_name}.timing.rpt

report_area  > ${rpt_dir}/${design_name}.area.rpt
report_power > ${rpt_dir}/${design_name}.power.rpt

report_clocks > ${rpt_dir}/${design_name}.clocks.rpt
report_clock  -attributes > ${rpt_dir}/${design_name}.clock_attrs.rpt

# ---- outputs ----
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -out ${net_dir}/${design_name}_syn.v
write_sdf ${net_dir}/${design_name}.sdf
write_sdc ${net_dir}/${design_name}.sdc

quit
