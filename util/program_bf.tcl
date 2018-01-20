open_hw
connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210319A2773CA]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/210319A2773CA]
open_hw_target
set_property PROGRAM.FILE {/home/jpdoane/dev/jpu/jpu_load.bit} [get_hw_devices xc7a35t_0]
set_property PROBES.FILE {/home/jpdoane/dev/jpu/jpu.runs/impl_1/debug_nets.ltx} [get_hw_devices xc7a35t_0]
set_property FULL_PROBES.FILE {/home/jpdoane/dev/jpu/jpu.runs/impl_1/debug_nets.ltx} [get_hw_devices xc7a35t_0]
current_hw_device [get_hw_devices xc7a35t_0]
refresh_hw_device [lindex [get_hw_devices xc7a35t_0] 0]
set_property PROBES.FILE {/home/jpdoane/dev/jpu/jpu.runs/impl_1/debug_nets.ltx} [get_hw_devices xc7a35t_0]
set_property FULL_PROBES.FILE {/home/jpdoane/dev/jpu/jpu.runs/impl_1/debug_nets.ltx} [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {/home/jpdoane/dev/jpu/jpu_load.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]
refresh_hw_device [lindex [get_hw_devices xc7a35t_0] 0]
disconnect_hw_server
close_hw
