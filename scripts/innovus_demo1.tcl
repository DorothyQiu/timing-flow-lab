############################################################
# scripts/innovus_demo1.tcl  (Enhanced, compatible)
# - Demo1 report naming: demo1_preCTS_*, demo1_postCTS_*, demo1_postRoute_*
# - Avoids unsupported commands (e.g., report_clock_tree)
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

set LEF_FILE   [file normalize "./lib/gscl45nm.lef"]
set TECH_FILE  [file normalize "./lib/gscl45nm.tlf"]
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
# Floorplan + Place
# ============================================================
floorPlan -site CoreSite -r 1.0 0.60 10 10 10 10
placeDesign

# ============================================================
# PRE-CTS
# ============================================================
puts "INFO: PRE-CTS timing..."
catch { timeDesign -preCTS -outDir "${OUT_RPT}/preCTS" }
catch { report_clocks > "${OUT_RPT}/demo1_preCTS_report_clocks.txt" }
catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo1_preCTS_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo1_preCTS_report_timing_hold.txt" }

# ============================================================
# CTS
# ============================================================
puts "INFO: CTS..."
create_ccopt_clock_tree_spec
set_ccopt_property library_trimming false

set CTS_BUFS [list BUFX2 BUFX4 CLKBUF1 CLKBUF2 CLKBUF3]
set CTS_INVS [list INVX1 INVX2 INVX4 INVX8]
set_ccopt_property buffer_cells   $CTS_BUFS -clock_tree clk_in
set_ccopt_property inverter_cells $CTS_INVS -clock_tree clk_in

ccopt_design

# ============================================================
# POST-CTS
# ============================================================
puts "INFO: POST-CTS timing..."
catch { timeDesign -postCTS -outDir "${OUT_RPT}/postCTS" }
catch { report_clocks > "${OUT_RPT}/demo1_postCTS_report_clocks.txt" }
catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo1_postCTS_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo1_postCTS_report_timing_hold.txt" }

# CCOpt tree summary (you already know this works)
catch { report_ccopt_clock_trees > "${OUT_RPT}/demo1_postCTS_report_ccopt_trees.txt" }

# Try to dump skew/latency style reports if supported (safe with catch)
catch { report_ccopt_skew_groups > "${OUT_RPT}/demo1_postCTS_report_ccopt_skew_groups.txt" }
catch { report_ccopt_clock_trees -skew > "${OUT_RPT}/demo1_postCTS_report_ccopt_trees_skew.txt" }
catch { report_clock_trees > "${OUT_RPT}/demo1_postCTS_report_clock_trees.txt" }
catch { report_clock_trees -skew > "${OUT_RPT}/demo1_postCTS_report_clock_trees_skew.txt" }

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
catch { report_timing -max_paths 30 -path_type full_clock > "${OUT_RPT}/demo1_postRoute_report_timing.txt" }
catch { report_timing -max_paths 30 -hold -path_type full_clock > "${OUT_RPT}/demo1_postRoute_report_timing_hold.txt" }
catch { report_ccopt_clock_trees > "${OUT_RPT}/demo1_postRoute_report_ccopt_trees.txt" }

# ============================================================
# OUTPUTS
# ============================================================
puts "INFO: writing outputs..."
saveNetlist $PNR_OUT
write_sdf -version 2.1 $PNR_SDF_OUT

puts "INFO: DONE"
exit
