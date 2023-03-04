
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name unoxt2 -dir "D:/Xilinx/share/pcxt/PCXT_ZXUno/ise/planAhead_run_3" -part xc6slx25ftg256-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "D:/Xilinx/share/pcxt/PCXT_ZXUno/ise/unoxt2_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {D:/Xilinx/share/pcxt/PCXT_ZXUno/ise} {ipcore_dir} }
add_files [list {ipcore_dir/vram.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "D:/Xilinx/share/pcxt/PCXT_ZXUno/HW/unoxt/unoxt2_pins.ucf" [current_fileset -constrset]
add_files [list {D:/Xilinx/share/pcxt/PCXT_ZXUno/HW/unoxt/unoxt2_pins.ucf}] -fileset [get_property constrset [current_run]]
link_design
