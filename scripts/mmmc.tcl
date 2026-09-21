# scripts/mmmc.tcl  (minimal MMMC, reusable for demo1/2/3)

# ---- Liberty ----
set LIB_TYP "/home/scf-22/ee577/NCSU45PDK/FreePDK45/osu_soc/lib/files/gscl45nm.lib"
if {![file exists $LIB_TYP]} {
  puts "ERROR: Liberty not found: $LIB_TYP"
  exit 1
}
create_library_set -name LS_NCSU45 -timing [list $LIB_TYP]

# ---- RC corner (minimal) ----
# (cap table not provided -> Innovus will warn but can run)
create_rc_corner -name RC_MIN

# ---- Delay corner ----
create_delay_corner -name DC_NCSU45 -library_set LS_NCSU45 -rc_corner RC_MIN

# ---- Constraint mode ----
# Use SDC path passed from Makefile env(SDC)
if {[info exists ::env(SDC)] && $::env(SDC) ne ""} {
  set SDC_FILE [file normalize $::env(SDC)]
} else {
  puts "ERROR: env(SDC) not set. Makefile should pass SDC=..."
  exit 1
}
if {![file exists $SDC_FILE]} {
  puts "ERROR: SDC not found: $SDC_FILE"
  exit 1
}
create_constraint_mode -name CM_FUNC -sdc_files [list $SDC_FILE]

# ---- Analysis view ----
create_analysis_view -name AV_FUNC -delay_corner DC_NCSU45 -constraint_mode CM_FUNC
set_analysis_view -setup [list AV_FUNC] -hold [list AV_FUNC]

puts "INFO: MMMC loaded"
puts "INFO: LIB=$LIB_TYP"
puts "INFO: SDC=$SDC_FILE"
