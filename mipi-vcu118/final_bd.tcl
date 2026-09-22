
################################################################
# This is a generated script based on design: slave_automotive_demo
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source slave_automotive_demo.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project slave_automotive_demo slave_automotive_demo -part xcvu9p-flga2104-2L-e
   set_property BOARD_PART xilinx.com:vcu118:part0:2.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name slave_automotive_demo_bd

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

# 1. Define paths relative to the script location
set script_dir [file dirname [info script]]
set ip_repo_path [file normalize [file join $script_dir "vivado_ip/vcu118"]]
set xdc_path [file normalize [file join $script_dir "board/constr_mipi_cam0.xdc"]]

# 2. Add the local IP repository to the project
puts "INFO: Adding local IP repository: $ip_repo_path"
set_property ip_repo_paths $ip_repo_path [current_project]
update_ip_catalog -rebuild

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_chip2chip:5.0\
xilinx.com:ip:axi_protocol_converter:2.1\
xilinx.com:ip:vio:3.0\
xilinx.com:ip:axi_apb_bridge:3.0\
xilinx.com:ip:axi_vdma:6.3\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:axi_intc:4.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:hls:img2axis_v4:1.0\
xilinx.com:hls:isolde_resizer_v8:1.0\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:axi_iic:2.1\
xilinx.com:ip:mipi_csi2_rx_subsystem:6.0\
user.org:user:int_enable:2.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr


  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr


  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [list \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.use_bram_block {BRAM_Controller} \
  ] $lmb_bram


  # Create interface connections
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1  [get_bd_pins SYS_Rst] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins dlmb_v10/SYS_Rst] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] \
  [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins LMB_Clk] \
  [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins dlmb_v10/LMB_Clk] \
  [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] \
  [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: MIPI_Pipeline
proc create_hier_cell_MIPI_Pipeline { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_MIPI_Pipeline() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_rsvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_sensor

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 csirxss_s_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0


  # Create pins
  create_bd_pin -dir I bg0_pin0_nc_0
  create_bd_pin -dir I bg2_pin0_nc_0
  create_bd_pin -dir I -type clk dphy_clk_200M
  create_bd_pin -dir O -type intr iic2intc_irpt
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn
  create_bd_pin -dir O int_o

  # Create instance: axi_gpio_2, and set properties
  set axi_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_2 ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {4} \
  ] $axi_gpio_2


  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0 ]
  set_property CONFIG.IIC_FREQ_KHZ {400} $axi_iic_0


  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0 ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm_dre {1} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_s2mm_max_burst_length {32} \
  ] $axi_vdma_0


  # Create instance: mipi_csi2_rx_subsyst_0, and set properties
  set mipi_csi2_rx_subsyst_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:6.0 mipi_csi2_rx_subsyst_0 ]
  set_property -dict [list \
    CONFIG.CLK_LANE_IO_LOC {AL35} \
    CONFIG.CMN_NUM_LANES {2} \
    CONFIG.CMN_NUM_PIXELS {2} \
    CONFIG.CMN_PXL_FORMAT {RAW8} \
    CONFIG.CSI_BUF_DEPTH {1024} \
    CONFIG.C_CLK_LANE_IO_POSITION {13} \
    CONFIG.C_CSI_FILTER_USERDATATYPE {false} \
    CONFIG.C_DATA_LANE1_IO_POSITION {28} \
    CONFIG.C_DPHY_LANES {2} \
    CONFIG.C_EN_BG0_PIN0 {true} \
    CONFIG.C_EN_BG2_PIN0 {true} \
    CONFIG.C_HS_LINE_RATE {900} \
    CONFIG.C_HS_SETTLE_NS {146} \
    CONFIG.DATA_LANE0_IO_LOC {AT35} \
    CONFIG.DATA_LANE1_IO_LOC {AJ32} \
    CONFIG.DPY_EN_REG_IF {true} \
    CONFIG.DPY_LINE_RATE {900} \
    CONFIG.HP_IO_BANK_SELECTION {43} \
    CONFIG.SupportLevel {1} \
    CONFIG.VFB_TU_WIDTH {1} \
  ] $mipi_csi2_rx_subsyst_0


  # Create instance: int_enable_0, and set properties
  set int_enable_0 [ create_bd_cell -type ip -vlnv user.org:user:int_enable:2.0 int_enable_0 ]

  # Create instance: irpt_en, and set properties
  set irpt_en [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 irpt_en ]
  set_property -dict [list \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_GPIO_WIDTH {1} \
  ] $irpt_en


  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI2_1 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins irpt_en/S_AXI]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_pins GPIO_rsvd] [get_bd_intf_pins axi_gpio_2/GPIO]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins IIC_sensor] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_gpio_2/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins csirxss_s_axi] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/csirxss_s_axi]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if_0] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]

  # Create port connections
  connect_bd_net -net axi_gpio_0_gpio_io_o  [get_bd_pins irpt_en/gpio_io_o] \
  [get_bd_pins int_enable_0/def_value_i]
  connect_bd_net -net axi_iic_0_iic2intc_irpt  [get_bd_pins axi_iic_0/iic2intc_irpt] \
  [get_bd_pins iic2intc_irpt]
  connect_bd_net -net axi_vdma_0_s_axis_s2mm_tready  [get_bd_pins axi_vdma_0/s_axis_s2mm_tready] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tready]
  connect_bd_net -net bg0_pin0_nc_0_1  [get_bd_pins bg0_pin0_nc_0] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/bg0_pin0_nc]
  connect_bd_net -net bg2_pin0_nc_0_1  [get_bd_pins bg2_pin0_nc_0] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/bg2_pin0_nc]
  connect_bd_net -net clk_wiz_1_clk_out2  [get_bd_pins dphy_clk_200M] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
  connect_bd_net -net int_enable_0_int_o  [get_bd_pins int_enable_0/int_o] \
  [get_bd_pins int_o]
  connect_bd_net -net int_enable_0_t_user_o  [get_bd_pins int_enable_0/t_user_o] \
  [get_bd_pins axi_vdma_0/s_axis_s2mm_tuser]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins s_axi_aclk] \
  [get_bd_pins axi_gpio_2/s_axi_aclk] \
  [get_bd_pins axi_iic_0/s_axi_aclk] \
  [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] \
  [get_bd_pins axi_vdma_0/s_axi_lite_aclk] \
  [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk] \
  [get_bd_pins irpt_en/s_axi_aclk]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdata  [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdata] \
  [get_bd_pins axi_vdma_0/s_axis_s2mm_tdata]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tlast  [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tlast] \
  [get_bd_pins axi_vdma_0/s_axis_s2mm_tlast]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tuser  [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tuser] \
  [get_bd_pins int_enable_0/t_user_i]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tvalid  [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tvalid] \
  [get_bd_pins axi_vdma_0/s_axis_s2mm_tvalid]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins s_axi_aresetn] \
  [get_bd_pins axi_gpio_2/s_axi_aresetn] \
  [get_bd_pins axi_iic_0/s_axi_aresetn] \
  [get_bd_pins axi_vdma_0/axi_resetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn] \
  [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn] \
  [get_bd_pins irpt_en/s_axi_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: Clock_Reset
proc create_hier_cell_Clock_Reset { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_Clock_Reset() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst bus_struct_reset
  create_bd_pin -dir O -type clk clk_out2
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir O -type rst mb_reset
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn1
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir I -type clk slowest_sync_clk
  create_bd_pin -dir O -type clk slowest_sync_clk1

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [list \
    CONFIG.CLKOUT2_JITTER {88.577} \
    CONFIG.CLKOUT2_PHASE_ERROR {77.836} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $clk_wiz_1


  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]
  set_property -dict [list \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $rst_clk_wiz_1_100M


  # Create instance: rst_ddr4_0_300M, and set properties
  set rst_ddr4_0_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ddr4_0_300M ]

  # Create port connections
  connect_bd_net -net clk_wiz_1_clk_out2  [get_bd_pins clk_wiz_1/clk_out2] \
  [get_bd_pins clk_out2]
  connect_bd_net -net clk_wiz_1_locked  [get_bd_pins clk_wiz_1/locked] \
  [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk  [get_bd_pins slowest_sync_clk] \
  [get_bd_pins clk_wiz_1/clk_in1] \
  [get_bd_pins rst_ddr4_0_300M/slowest_sync_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst  [get_bd_pins ext_reset_in] \
  [get_bd_pins rst_ddr4_0_300M/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst  [get_bd_pins mb_debug_sys_rst] \
  [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins clk_wiz_1/clk_out1] \
  [get_bd_pins slowest_sync_clk1] \
  [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net reset_1  [get_bd_pins reset] \
  [get_bd_pins clk_wiz_1/reset] \
  [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset  [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] \
  [get_bd_pins bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset  [get_bd_pins rst_clk_wiz_1_100M/mb_reset] \
  [get_bd_pins mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn  [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn1]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: Resizer_BD
proc create_hier_cell_Resizer_BD { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_Resizer_BD() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_data_mem

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_cfg_port


  # Create pins
  create_bd_pin -dir I -type rst axi_resetn
  create_bd_pin -dir I -type clk m_axi_s2mm_aclk

  # Create instance: axi_vdma_1, and set properties
  set axi_vdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_1 ]
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_m_axi_s2mm_data_width {32} \
    CONFIG.c_num_fstores {2} \
    CONFIG.c_s2mm_linebuffer_depth {2048} \
  ] $axi_vdma_1


  # Create instance: img2axis_v4_0, and set properties
  set img2axis_v4_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:img2axis_v4:1.0 img2axis_v4_0 ]

  # Create instance: isolde_resizer_v8_0, and set properties
  set isolde_resizer_v8_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:isolde_resizer_v8:1.0 isolde_resizer_v8_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma_1/M_AXI_S2MM]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_1/S_AXI_LITE]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins s_axi_cfg_port] [get_bd_intf_pins img2axis_v4_0/s_axi_cfg_port]
  connect_bd_intf_net -intf_net img2axis_v4_0_m_axi_data_mem [get_bd_intf_pins m_axi_data_mem] [get_bd_intf_pins img2axis_v4_0/m_axi_data_mem]
  connect_bd_intf_net -intf_net img2axis_v4_0_stream_o [get_bd_intf_pins img2axis_v4_0/stream_o] [get_bd_intf_pins isolde_resizer_v8_0/stream_i]
  connect_bd_intf_net -intf_net isolde_resizer_v8_0_stream_o [get_bd_intf_pins axi_vdma_1/S_AXIS_S2MM] [get_bd_intf_pins isolde_resizer_v8_0/stream_o]

  # Create port connections
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins m_axi_s2mm_aclk] \
  [get_bd_pins axi_vdma_1/m_axi_s2mm_aclk] \
  [get_bd_pins axi_vdma_1/s_axi_lite_aclk] \
  [get_bd_pins axi_vdma_1/s_axis_s2mm_aclk] \
  [get_bd_pins img2axis_v4_0/ap_clk] \
  [get_bd_pins isolde_resizer_v8_0/ap_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins axi_resetn] \
  [get_bd_pins axi_vdma_1/axi_resetn] \
  [get_bd_pins img2axis_v4_0/ap_rst_n] \
  [get_bd_pins isolde_resizer_v8_0/ap_rst_n]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: CAM_Subsystem
proc create_hier_cell_CAM_Subsystem { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_CAM_Subsystem() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_rsvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_sensor

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_sensor

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M10_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1_062

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_250mhz_clk1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M11_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S06_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S07_AXI_0


  # Create pins
  create_bd_pin -dir I bg0_pin0_nc_0
  create_bd_pin -dir I bg2_pin0_nc_0
  create_bd_pin -dir O -type clk clk_out2
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir O -type clk slowest_sync_clk1
  create_bd_pin -dir I -from 0 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 interrupt_pcnn

  # Create instance: Clock_Reset
  create_hier_cell_Clock_Reset $hier_obj Clock_Reset

  # Create instance: MIPI_Pipeline
  create_hier_cell_MIPI_Pipeline $hier_obj MIPI_Pipeline

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.GPIO_BOARD_INTERFACE {led_8bits} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_gpio_0


  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [list \
    CONFIG.C_BAUDRATE {115200} \
    CONFIG.UARTLITE_BOARD_INTERFACE {rs232_uart} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $axi_uartlite_0


  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [list \
    CONFIG.C0_CLOCK_BOARD_INTERFACE {default_250mhz_clk1} \
    CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1_062} \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
  ] $ddr4_0


  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [list \
    CONFIG.C_ADDR_TAG_BITS {13} \
    CONFIG.C_CACHE_BYTE_SIZE {65536} \
    CONFIG.C_DCACHE_ADDR_TAG {13} \
    CONFIG.C_DCACHE_BYTE_SIZE {65536} \
    CONFIG.C_DEBUG_ENABLED {1} \
    CONFIG.C_D_AXI {1} \
    CONFIG.C_D_LMB {1} \
    CONFIG.C_ENABLE_CONVERSION {0} \
    CONFIG.C_I_LMB {1} \
    CONFIG.C_USE_DCACHE {1} \
    CONFIG.C_USE_ICACHE {1} \
  ] $microblaze_0


  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 microblaze_0_axi_intc ]
  set_property CONFIG.C_HAS_FAST {1} $microblaze_0_axi_intc


  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph ]
  set_property -dict [list \
    CONFIG.NUM_MI {12} \
    CONFIG.NUM_SI {8} \
  ] $microblaze_0_axi_periph


  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory $hier_obj microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 microblaze_0_xlconcat ]
  set_property CONFIG.NUM_PORTS {5} $microblaze_0_xlconcat


  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M10_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins microblaze_0_axi_periph/S05_AXI] [get_bd_intf_pins S05_AXI_0]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI] [get_bd_intf_pins M11_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins microblaze_0_axi_periph/S06_AXI] [get_bd_intf_pins S06_AXI]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins microblaze_0_axi_periph/S07_AXI] [get_bd_intf_pins S07_AXI_0]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins microblaze_0_axi_periph/S04_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_pins led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_pins GPIO_rsvd] [get_bd_intf_pins MIPI_Pipeline/GPIO_rsvd]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins IIC_sensor] [get_bd_intf_pins MIPI_Pipeline/IIC_sensor]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins MIPI_Pipeline/M_AXI_S2MM] [get_bd_intf_pins microblaze_0_axi_periph/S03_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_pins ddr4_sdram_c1_062] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net default_250mhz_clk1_0_1 [get_bd_intf_pins default_250mhz_clk1_0] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins microblaze_0/M_AXI_DC] [get_bd_intf_pins microblaze_0_axi_periph/S01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins microblaze_0/M_AXI_IC] [get_bd_intf_pins microblaze_0_axi_periph/S02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins MIPI_Pipeline/S_AXI2] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins MIPI_Pipeline/S_AXI1] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins MIPI_Pipeline/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins MIPI_Pipeline/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins MIPI_Pipeline/csirxss_s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if_0] [get_bd_intf_pins MIPI_Pipeline/mipi_phy_if_0]

  # Create port connections
  connect_bd_net -net In3_1  [get_bd_pins In3] \
  [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net MIPI_Pipeline_int_o  [get_bd_pins MIPI_Pipeline/int_o] \
  [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net axi_iic_0_iic2intc_irpt  [get_bd_pins MIPI_Pipeline/iic2intc_irpt] \
  [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt  [get_bd_pins axi_uartlite_0/interrupt] \
  [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net bg0_pin0_nc_0_1  [get_bd_pins bg0_pin0_nc_0] \
  [get_bd_pins MIPI_Pipeline/bg0_pin0_nc_0]
  connect_bd_net -net bg2_pin0_nc_0_1  [get_bd_pins bg2_pin0_nc_0] \
  [get_bd_pins MIPI_Pipeline/bg2_pin0_nc_0]
  connect_bd_net -net clk_wiz_1_clk_out2  [get_bd_pins Clock_Reset/clk_out2] \
  [get_bd_pins clk_out2] \
  [get_bd_pins MIPI_Pipeline/dphy_clk_200M]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk  [get_bd_pins ddr4_0/c0_ddr4_ui_clk] \
  [get_bd_pins Clock_Reset/slowest_sync_clk] \
  [get_bd_pins microblaze_0_axi_periph/M06_ACLK]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst  [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] \
  [get_bd_pins Clock_Reset/ext_reset_in]
  connect_bd_net -net interrupt_pcnn_1  [get_bd_pins interrupt_pcnn] \
  [get_bd_pins microblaze_0_xlconcat/In4]
  connect_bd_net -net mdm_1_debug_sys_rst  [get_bd_pins mdm_1/Debug_SYS_Rst] \
  [get_bd_pins Clock_Reset/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins Clock_Reset/slowest_sync_clk1] \
  [get_bd_pins slowest_sync_clk1] \
  [get_bd_pins MIPI_Pipeline/s_axi_aclk] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_uartlite_0/s_axi_aclk] \
  [get_bd_pins microblaze_0/Clk] \
  [get_bd_pins microblaze_0_axi_intc/processor_clk] \
  [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] \
  [get_bd_pins microblaze_0_axi_periph/ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M00_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M01_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M02_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M03_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M04_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M05_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M07_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M08_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M09_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M10_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S00_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S01_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S02_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S03_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S04_ACLK] \
  [get_bd_pins microblaze_0_local_memory/LMB_Clk] \
  [get_bd_pins microblaze_0_axi_periph/S05_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/M11_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S06_ACLK] \
  [get_bd_pins microblaze_0_axi_periph/S07_ACLK]
  connect_bd_net -net microblaze_0_intr  [get_bd_pins microblaze_0_xlconcat/dout] \
  [get_bd_pins microblaze_0_axi_intc/intr]
  connect_bd_net -net reset_1  [get_bd_pins reset] \
  [get_bd_pins Clock_Reset/reset] \
  [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset  [get_bd_pins Clock_Reset/bus_struct_reset] \
  [get_bd_pins microblaze_0_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset  [get_bd_pins Clock_Reset/mb_reset] \
  [get_bd_pins microblaze_0/Reset] \
  [get_bd_pins microblaze_0_axi_intc/processor_rst]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins Clock_Reset/peripheral_aresetn] \
  [get_bd_pins peripheral_aresetn] \
  [get_bd_pins MIPI_Pipeline/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_uartlite_0/s_axi_aresetn] \
  [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] \
  [get_bd_pins microblaze_0_axi_periph/ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S01_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S02_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S03_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S04_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S05_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S06_ARESETN] \
  [get_bd_pins microblaze_0_axi_periph/S07_ARESETN]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn  [get_bd_pins Clock_Reset/peripheral_aresetn1] \
  [get_bd_pins ddr4_0/c0_ddr4_aresetn] \
  [get_bd_pins microblaze_0_axi_periph/M06_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set GPIO_rsvd [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_rsvd ]

  set GPIO_sensor [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_sensor ]

  set IIC_sensor [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_sensor ]

  set ddr4_sdram_c1_062 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1_062 ]

  set default_250mhz_clk1_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_250mhz_clk1_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   ] $default_250mhz_clk1_0

  set led_8bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits ]

  set mipi_phy_if_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0 ]

  set rs232_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart ]

  set S05_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {4} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S05_AXI_0

  set APB_M_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:apb_rtl:1.0 APB_M_0 ]

  set APB_M2_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:apb_rtl:1.0 APB_M2_0 ]


  # Create ports
  set axi_c2c_selio_rx_data_in_0 [ create_bd_port -dir I -from 14 -to 0 axi_c2c_selio_rx_data_in_0 ]
  set axi_c2c_selio_rx_diff_clk_in_n_0 [ create_bd_port -dir I -type clk axi_c2c_selio_rx_diff_clk_in_n_0 ]
  set axi_c2c_selio_rx_diff_clk_in_p_0 [ create_bd_port -dir I -type clk axi_c2c_selio_rx_diff_clk_in_p_0 ]
  set axi_c2c_selio_tx_data_out_0 [ create_bd_port -dir O -from 14 -to 0 axi_c2c_selio_tx_data_out_0 ]
  set axi_c2c_selio_tx_diff_clk_out_n_0 [ create_bd_port -dir O -type clk axi_c2c_selio_tx_diff_clk_out_n_0 ]
  set axi_c2c_selio_tx_diff_clk_out_p_0 [ create_bd_port -dir O -type clk axi_c2c_selio_tx_diff_clk_out_p_0 ]
  set bg0_pin0_nc_0 [ create_bd_port -dir I bg0_pin0_nc_0 ]
  set bg2_pin0_nc_0 [ create_bd_port -dir I bg2_pin0_nc_0 ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset
  set interrupt_pcnn [ create_bd_port -dir I interrupt_pcnn ]
  set clk_out [ create_bd_port -dir O -type clk clk_out ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI_0} \
 ] $clk_out
  set rst_n [ create_bd_port -dir O -from 0 -to 0 -type rst rst_n ]

  # Create instance: CAM_Subsystem
  create_hier_cell_CAM_Subsystem [current_bd_instance .] CAM_Subsystem

  # Create instance: Resizer_BD
  create_hier_cell_Resizer_BD [current_bd_instance .] Resizer_BD

  # Create instance: axi_chip2chip_0, and set properties
  set axi_chip2chip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_chip2chip:5.0 axi_chip2chip_0 ]
  set_property -dict [list \
    CONFIG.C_INCLUDE_AXILITE {1} \
    CONFIG.C_INTERFACE_MODE {1} \
    CONFIG.C_MASTER_FPGA {0} \
    CONFIG.C_M_AXI_ID_WIDTH {0} \
    CONFIG.C_M_AXI_WUSER_WIDTH {0} \
    CONFIG.C_USE_DIFF_CLK {true} \
  ] $axi_chip2chip_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {3} \
    CONFIG.NUM_SI {2} \
  ] $axi_interconnect_0


  # Create instance: axi_protocol_convert_0, and set properties
  set axi_protocol_convert_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_convert_0 ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH {32} \
    CONFIG.DATA_WIDTH {32} \
    CONFIG.ID_WIDTH {0} \
    CONFIG.MI_PROTOCOL {AXI4LITE} \
    CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
    CONFIG.SI_PROTOCOL {AXI4} \
  ] $axi_protocol_convert_0


  # Create instance: vio_0, and set properties
  set vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio:3.0 vio_0 ]
  set_property CONFIG.C_NUM_PROBE_IN {0} $vio_0


  # Create instance: axi_apb_bridge_0, and set properties
  set axi_apb_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_apb_bridge:3.0 axi_apb_bridge_0 ]
  set_property CONFIG.C_APB_NUM_SLAVES {2} $axi_apb_bridge_0


  # Create instance: vdma_c2c, and set properties
  set vdma_c2c [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 vdma_c2c ]
  set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_mm2s_max_burst_length {32} \
    CONFIG.c_s2mm_max_burst_length {32} \
  ] $vdma_c2c


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
  set_property CONFIG.NUM_MI {2} $smartconnect_0


  # Create interface connections
  connect_bd_intf_net -intf_net CAM_Subsystem_M11_AXI [get_bd_intf_pins axi_apb_bridge_0/AXI4_LITE] [get_bd_intf_pins CAM_Subsystem/M11_AXI]
  connect_bd_intf_net -intf_net Resizer_BD_M_AXI_S2MM [get_bd_intf_pins Resizer_BD/M_AXI_S2MM] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins CAM_Subsystem/M10_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins CAM_Subsystem/S04_AXI] [get_bd_intf_pins Resizer_BD/m_axi_data_mem]
  connect_bd_intf_net -intf_net S05_AXI_0_1 [get_bd_intf_ports S05_AXI_0] [get_bd_intf_pins CAM_Subsystem/S05_AXI_0]
  connect_bd_intf_net -intf_net axi_apb_bridge_0_APB_M [get_bd_intf_ports APB_M_0] [get_bd_intf_pins axi_apb_bridge_0/APB_M]
  connect_bd_intf_net -intf_net axi_apb_bridge_0_APB_M2 [get_bd_intf_ports APB_M2_0] [get_bd_intf_pins axi_apb_bridge_0/APB_M2]
  connect_bd_intf_net -intf_net axi_chip2chip_0_m_axi [get_bd_intf_pins axi_chip2chip_0/m_axi] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_8bits] [get_bd_intf_pins CAM_Subsystem/led_8bits]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports GPIO_sensor] [get_bd_intf_pins CAM_Subsystem/GPIO_sensor]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_ports GPIO_rsvd] [get_bd_intf_pins CAM_Subsystem/GPIO_rsvd]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports IIC_sensor] [get_bd_intf_pins CAM_Subsystem/IIC_sensor]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins Resizer_BD/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins Resizer_BD/s_axi_cfg_port] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins vdma_c2c/S_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
  connect_bd_intf_net -intf_net axi_protocol_convert_0_M_AXI [get_bd_intf_pins axi_chip2chip_0/s_axi_lite] [get_bd_intf_pins axi_protocol_convert_0/M_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins CAM_Subsystem/rs232_uart]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXIS_MM2S [get_bd_intf_pins vdma_c2c/M_AXIS_MM2S] [get_bd_intf_pins vdma_c2c/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S [get_bd_intf_pins vdma_c2c/M_AXI_MM2S] [get_bd_intf_pins CAM_Subsystem/S06_AXI]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins vdma_c2c/M_AXI_S2MM] [get_bd_intf_pins smartconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1_062] [get_bd_intf_pins CAM_Subsystem/ddr4_sdram_c1_062]
  connect_bd_intf_net -intf_net default_250mhz_clk1_0_1 [get_bd_intf_ports default_250mhz_clk1_0] [get_bd_intf_pins CAM_Subsystem/default_250mhz_clk1_0]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_ports mipi_phy_if_0] [get_bd_intf_pins CAM_Subsystem/mipi_phy_if_0]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins axi_protocol_convert_0/S_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins smartconnect_0/M01_AXI] [get_bd_intf_pins CAM_Subsystem/S07_AXI_0]

  # Create port connections
  connect_bd_net -net CAM_Subsystem_clk_out2  [get_bd_pins CAM_Subsystem/clk_out2] \
  [get_bd_pins axi_chip2chip_0/idelay_ref_clk]
  connect_bd_net -net axi_c2c_selio_rx_data_in_0_1  [get_bd_ports axi_c2c_selio_rx_data_in_0] \
  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_data_in]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_n_0_1  [get_bd_ports axi_c2c_selio_rx_diff_clk_in_n_0] \
  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_n]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_p_0_1  [get_bd_ports axi_c2c_selio_rx_diff_clk_in_p_0] \
  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_p]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_data_out  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_data_out] \
  [get_bd_ports axi_c2c_selio_tx_data_out_0]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_n] \
  [get_bd_ports axi_c2c_selio_tx_diff_clk_out_n_0]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p  [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_p] \
  [get_bd_ports axi_c2c_selio_tx_diff_clk_out_p_0]
  connect_bd_net -net bg0_pin0_nc_0_1  [get_bd_ports bg0_pin0_nc_0] \
  [get_bd_pins CAM_Subsystem/bg0_pin0_nc_0]
  connect_bd_net -net bg2_pin0_nc_0_1  [get_bd_ports bg2_pin0_nc_0] \
  [get_bd_pins CAM_Subsystem/bg2_pin0_nc_0]
  connect_bd_net -net interrupt_pcnn_1  [get_bd_ports interrupt_pcnn] \
  [get_bd_pins CAM_Subsystem/interrupt_pcnn]
  connect_bd_net -net microblaze_0_Clk  [get_bd_pins CAM_Subsystem/slowest_sync_clk1] \
  [get_bd_pins Resizer_BD/m_axi_s2mm_aclk] \
  [get_bd_pins axi_chip2chip_0/m_aclk] \
  [get_bd_pins axi_chip2chip_0/s_axi_lite_aclk] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/M00_ACLK] \
  [get_bd_pins axi_interconnect_0/M01_ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] \
  [get_bd_pins axi_interconnect_0/S01_ACLK] \
  [get_bd_pins axi_protocol_convert_0/aclk] \
  [get_bd_pins vio_0/clk] \
  [get_bd_pins axi_apb_bridge_0/s_axi_aclk] \
  [get_bd_ports clk_out] \
  [get_bd_pins vdma_c2c/m_axi_mm2s_aclk] \
  [get_bd_pins vdma_c2c/m_axi_s2mm_aclk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins vdma_c2c/m_axis_mm2s_aclk] \
  [get_bd_pins vdma_c2c/s_axis_s2mm_aclk] \
  [get_bd_pins axi_interconnect_0/M02_ACLK] \
  [get_bd_pins vdma_c2c/s_axi_lite_aclk]
  connect_bd_net -net reset_1  [get_bd_ports reset] \
  [get_bd_pins CAM_Subsystem/reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn  [get_bd_pins CAM_Subsystem/peripheral_aresetn] \
  [get_bd_pins Resizer_BD/axi_resetn] \
  [get_bd_pins axi_chip2chip_0/m_aresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN] \
  [get_bd_pins axi_interconnect_0/M01_ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN] \
  [get_bd_pins axi_interconnect_0/S01_ARESETN] \
  [get_bd_pins axi_protocol_convert_0/aresetn] \
  [get_bd_pins axi_apb_bridge_0/s_axi_aresetn] \
  [get_bd_ports rst_n] \
  [get_bd_pins axi_interconnect_0/M02_ARESETN] \
  [get_bd_pins vdma_c2c/axi_resetn]
  connect_bd_net -net vio_0_probe_out0  [get_bd_pins vio_0/probe_out0] \
  [get_bd_pins CAM_Subsystem/In3]

  # Create address segments
  assign_bd_address -offset 0xA0010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0xA0018000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -with_name SEG_mipi_csi2_rx_subsyst_0_Reg_1 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs APB_M2_0/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs APB_M_0/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00010000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces S05_AXI_0] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs APB_M2_0/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs APB_M_0/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_v4_0/Data_m_axi_data_mem] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs Resizer_BD/img2axis_v4_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_MM2S] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs APB_M2_0/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs APB_M_0/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/irpt_en/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0xA0020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces vdma_c2c/Data_S2MM] [get_bd_addr_segs vdma_c2c/S_AXI_LITE/Reg]


  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx:vcu118:vcu118_mipi_uart_115200:0.0} [get_files [current_bd_design].bd]
  set_property PFM.CLOCK {clk_out1 {id "0" is_default "true" proc_sys_reset "/rst_clk_wiz_1_100M" status "fixed" freq_hz "100000000"}} [get_bd_cells /CAM_Subsystem/Clock_Reset/clk_wiz_1]


  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


