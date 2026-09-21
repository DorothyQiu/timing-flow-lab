############################################################
# scripts/innovus_demo3.tcl  (Enhanced, compatible)
# Demo3: generated clocks + propagated clock after CTS
# - Avoid unsupported commands (e.g., report_clock_tree)
# - Enable interactive MMMC constraint mode (best-effort)
# Reports naming:
#   demo3_preCTS_*.txt / demo3_postCTS_*.txt / demo3_postRoute_*.txt
############################################################

proc must_exist {label path} {
  if {![file exists $path]} {
    puts "ERROR: $label not found: $path"
    exit 1
  }
}

# ---- env checks ----
foreach v {TOP NETLIST MMMC PNR_OUT OUT_RPT OUT_NETLIST} {
  if {![info exists ::env($v)]} { puts "ERROR: env($v) missing"; exit 1 }
}

set TOP        $::env(TOP)
set NETLIST    [file normalize $::env(NETLIST)]
set MMMC_FILE  [file normalize $::env(MMMC)]
set PNR_OUT    [file normalize $::env(PNR_OUT)]
set OUT_RPT    [file normalize $::env(OUT_RPT)]
set OUT_NETL   [file normalize $::env(OUT_NETLIST)]

set LEF_FILE    [file normalize "./lib/gscl45nm.lef"]
set TECH_FILE   [file normalize "./lib/gscl45nm.tlf"]
set PNR_SDF_OUT [file normalize "${OUT_NETL}/${TOP}_pnr.sdf"]

file mkdir $OUT_RPT
file mkdir $OUT_NETL
file mkdir [file dirname $PNR_OUT]

must_exist "NETLIST" $NETLIST
must_exist "MMMC"    $MMMC_FILE
must_exist "LEF"     $LEF_FILE
if {![file exists $TECH_FILE]} { puts "WARN: TECH not found (may be OK): $TECH_FILE" }

puts "INFO: TOP      = $TOP"
puts "INFO: NETLIST  = $NETLIST"
puts "INFO: MMMC     = $MMMC_FILE"
puts "INFO: OUT_RPT  = $OUT_RPT"
puts "INFO: OUT_NETL = $OUT_NETL"

# ---- init_design ----
set init_top_cell  $TOP
set init_verilog   $NETLIST
set init_lef_file  [list $LEF_FILE]
catch { set init_tech_file $TECH_FILE }
catch { set init_tlf_file  $TECH_FILE }
set init_mmmc_file $MMMC_FILE
init_design

# ============================================================
# Enable interactive MMMC constraint modes (best-effort)
# ============================================================
# Your mmmc.tcl creates constraint mode "CM_FUNC".
# Some Innovus builds require enabling it for interactive constraints.
catch { set_interactive_constraint_modes [list CM_FUNC] }
catch { report_constraint_modes > "${OUT_RPT}/demo3_report_constraint_modes.txt" }
catch { report_analysis_views  > "${OUT_RPT}/demo3_report_analysis_views.txt" }

# ============================================================
# Floorplan + Place
# ============================================================
floorPlan -site CoreSite -r 1.0 0.60 10 10 10 10
placeDesign

# ============================================================
# PRE-CTS
# ============================================================
puts "INFO: PRE-CTS timing..."
catch { timeDesign -preCTS -outDir "${OUT_RPT}/preCTS" }

catch { report_clocks > "${OUT_RPT}/demo3_preCTS_report_clocks.txt" }
catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo3_preCTS_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo3_preCTS_report_timing_hold.txt" }

# ============================================================
# CTS (ONLY for clk_in)
# ============================================================
puts "INFO: CTS..."
create_ccopt_clock_tree_spec
set_ccopt_property library_trimming false

# Guard: generated clocks exist in SDC but must NOT be CTS roots
# (names may vary by your SDC; keep both)
catch { set_ccopt_property skip_clock true -clock_tree clk_station }
catch { set_ccopt_property skip_clock true -clock_tree clk_user }
catch { delete_ccopt_clock_tree -name clk_station }
catch { delete_ccopt_clock_tree -name clk_user }

set CTS_BUFS [list BUFX2 BUFX4 CLKBUF1 CLKBUF2 CLKBUF3]
set CTS_INVS [list INVX1 INVX2 INVX4 INVX8]
set_ccopt_property buffer_cells   $CTS_BUFS -clock_tree clk_in
set_ccopt_property inverter_cells $CTS_INVS -clock_tree clk_in

ccopt_design

# ============================================================
# After CTS: propagated clocks (best-effort)
# ============================================================
# If interactive MMMC isn't enabled, this can be ignored;
# we keep it in catch so flow never stops.
catch { set_propagated_clock [all_clocks] }

# ============================================================
# POST-CTS
# ============================================================
puts "INFO: POST-CTS timing..."
catch { timeDesign -postCTS -outDir "${OUT_RPT}/postCTS" }

catch { report_clocks > "${OUT_RPT}/demo3_postCTS_report_clocks.txt" }
catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo3_postCTS_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo3_postCTS_report_timing_hold.txt" }

# CCOpt tree / skew reports (safe)
catch { report_ccopt_clock_trees > "${OUT_RPT}/demo3_postCTS_report_ccopt_trees.txt" }
catch { report_ccopt_skew_groups > "${OUT_RPT}/demo3_postCTS_report_ccopt_skew_groups.txt" }
catch { report_ccopt_clock_trees -skew > "${OUT_RPT}/demo3_postCTS_report_ccopt_trees_skew.txt" }
catch { report_clock_trees > "${OUT_RPT}/demo3_postCTS_report_clock_trees.txt" }
catch { report_clock_trees -skew > "${OUT_RPT}/demo3_postCTS_report_clock_trees_skew.txt" }

# ============================================================
# ROUTE
# ============================================================
puts "INFO: routeDesign..."
routeDesign

# ============================================================
# POST-ROUTE
# ============================================================
puts "INFO: POST-ROUTE timing..."
catch { timeDesign -postRoute -outDir "${OUT_RPT}/postRoute" }

catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo3_postRoute_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo3_postRoute_report_timing_hold.txt" }
catch { report_ccopt_clock_trees > "${OUT_RPT}/demo3_postRoute_report_ccopt_trees.txt" }

# ============================================================
# OUTPUTS
# ============================================================
puts "INFO: writing outputs..."
saveNetlist $PNR_OUT
write_sdf -version 2.1 $PNR_SDF_OUT

puts "INFO: DONE"
exit
