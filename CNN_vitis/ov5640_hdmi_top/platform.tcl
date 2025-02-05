# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct F:\Graduate_Design\zynq_test\OV5640_HDMI_PS\CNN_vitis\ov5640_hdmi_top\platform.tcl
# 
# OR launch xsct and run below command.
# source F:\Graduate_Design\zynq_test\OV5640_HDMI_PS\CNN_vitis\ov5640_hdmi_top\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {ov5640_hdmi_top}\
-hw {F:\Graduate_Design\zynq_test\OV5640_HDMI_PS\ov5640_hdmi\ov5640_hdmi_top.xsa}\
-out {F:/Graduate_Design/zynq_test/OV5640_HDMI_PS/CNN_vitis}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {ov5640_hdmi_top}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
