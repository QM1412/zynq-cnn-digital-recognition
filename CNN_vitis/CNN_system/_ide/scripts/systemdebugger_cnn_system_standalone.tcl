# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: F:\Graduate_Design\zynq_test\OV5640_HDMI_PS\CNN_vitis\CNN_system\_ide\scripts\systemdebugger_cnn_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source F:\Graduate_Design\zynq_test\OV5640_HDMI_PS\CNN_vitis\CNN_system\_ide\scripts\systemdebugger_cnn_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT3-210357A7D00EA-13722093-0"}
fpga -file F:/Graduate_Design/zynq_test/OV5640_HDMI_PS/CNN_vitis/CNN/_ide/bitstream/ov5640_hdmi_top.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw F:/Graduate_Design/zynq_test/OV5640_HDMI_PS/CNN_vitis/ov5640_hdmi_top/export/ov5640_hdmi_top/hw/ov5640_hdmi_top.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source F:/Graduate_Design/zynq_test/OV5640_HDMI_PS/CNN_vitis/CNN/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow F:/Graduate_Design/zynq_test/OV5640_HDMI_PS/CNN_vitis/CNN/Debug/CNN.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
