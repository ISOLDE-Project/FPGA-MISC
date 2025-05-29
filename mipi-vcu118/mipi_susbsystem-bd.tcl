# Proc to create BD $::_xil_proj_name_
proc cr_bd_$::_xil_proj_name_ { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name $::_xil_proj_name_

  common::send_gid_msg -ssname BD::TCL -id 2010 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:axi_gpio:*\
  xilinx.com:ip:axi_uartlite:*\
  xilinx.com:ip:ddr4:*\
  xilinx.com:ip:mdm:*\
  xilinx.com:ip:microblaze:*\
  xilinx.com:ip:axi_intc:*\
  xilinx.com:ip:xlconcat:*\
  xilinx.com:ip:axi_vdma:*\
  xilinx.com:hls:img2axis:*\
  xilinx.com:hls:isolde_resizer:*\
  xilinx.com:ip:clk_wiz:*\
  xilinx.com:ip:proc_sys_reset:*\
  xilinx.com:ip:axi_iic:*\
  xilinx.com:ip:mipi_csi2_rx_subsystem:*\
  xilinx.com:ip:v_demosaic:*\
  xilinx.com:ip:xlslice:*\
  xilinx.com:ip:lmb_bram_if_cntlr:*\
  xilinx.com:ip:lmb_v10:*\
  xilinx.com:ip:blk_mem_gen:*\
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
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram ]
  set_property -dict [ list \
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
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Perform GUI Layout
  regenerate_bd_layout -hierarchy [get_bd_cells /CAM_Subsystem/microblaze_0_local_memory] -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"1.0",
   "Default View_TopLeft":"-222,-142",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port DLMB -pg 1 -lvl 0 -x -10 -y 50 -defaultsOSRD
preplace port ILMB -pg 1 -lvl 0 -x -10 -y 220 -defaultsOSRD
preplace port LMB_Clk -pg 1 -lvl 0 -x -10 -y 70 -defaultsOSRD
preplace port SYS_Rst -pg 1 -lvl 0 -x -10 -y 90 -defaultsOSRD
preplace inst dlmb_bram_if_cntlr -pg 1 -lvl 2 -x 390 -y 90 -defaultsOSRD
preplace inst dlmb_v10 -pg 1 -lvl 1 -x 140 -y 70 -defaultsOSRD
preplace inst ilmb_bram_if_cntlr -pg 1 -lvl 2 -x 390 -y 260 -defaultsOSRD
preplace inst ilmb_v10 -pg 1 -lvl 1 -x 140 -y 240 -defaultsOSRD
preplace inst lmb_bram -pg 1 -lvl 3 -x 640 -y 100 -defaultsOSRD
preplace netloc SYS_Rst_1 1 0 2 10 150 270
preplace netloc microblaze_0_Clk 1 0 2 20 160 260
preplace netloc microblaze_0_ilmb_bus 1 1 1 N 240
preplace netloc microblaze_0_ilmb_cntlr 1 2 1 510 110n
preplace netloc microblaze_0_dlmb 1 0 1 NJ 50
preplace netloc microblaze_0_dlmb_bus 1 1 1 N 70
preplace netloc microblaze_0_dlmb_cntlr 1 2 1 N 90
preplace netloc microblaze_0_ilmb 1 0 1 NJ 220
levelinfo -pg 1 -10 140 390 640 780
pagesize -pg 1 -db -bbox -sgen -120 -10 780 340
"
}

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_sensor

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_sensor

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 csirxss_s_axi

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_CTRL


  # Create pins
  create_bd_pin -dir I bg0_pin0_nc_0
  create_bd_pin -dir I bg2_pin0_nc_0
  create_bd_pin -dir I -type clk dphy_clk_200M
  create_bd_pin -dir O -type intr iic2intc_irpt
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -type rst s_axi_aresetn

  # Create instance: axi_gpio_1, and set properties
  set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {2} \
 ] $axi_gpio_1

  # Create instance: axi_gpio_2, and set properties
  set axi_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_2 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $axi_gpio_2

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0 ]
  set_property -dict [ list \
   CONFIG.IIC_FREQ_KHZ {400} \
 ] $axi_iic_0

  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_0 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_m_axi_s2mm_data_width {32} \
   CONFIG.c_mm2s_genlock_mode {0} \
 ] $axi_vdma_0

  # Create instance: mipi_csi2_rx_subsyst_0, and set properties
  set mipi_csi2_rx_subsyst_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem mipi_csi2_rx_subsyst_0 ]
  set_property -dict [ list \
   CONFIG.CLK_LANE_IO_LOC {AL35} \
   CONFIG.CLK_LANE_IO_LOC_NAME {IO_L7P_T1L_N0_QBC_AD13P_43} \
   CONFIG.CMN_NUM_LANES {2} \
   CONFIG.CMN_NUM_PIXELS {1} \
   CONFIG.CMN_PXL_FORMAT {RAW10} \
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
   CONFIG.DATA_LANE0_IO_LOC_NAME {IO_L2P_T0L_N2_43} \
   CONFIG.DATA_LANE1_IO_LOC {AJ32} \
   CONFIG.DATA_LANE1_IO_LOC_NAME {IO_L14P_T2L_N2_GC_43} \
   CONFIG.DPY_EN_REG_IF {true} \
   CONFIG.DPY_LINE_RATE {900} \
   CONFIG.HP_IO_BANK_SELECTION {43} \
   CONFIG.SupportLevel {1} \
   CONFIG.VFB_TU_WIDTH {64} \
 ] $mipi_csi2_rx_subsyst_0

  # Create instance: v_demosaic_0, and set properties
  set v_demosaic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic v_demosaic_0 ]
  set_property -dict [ list \
   CONFIG.SAMPLES_PER_CLOCK {1} \
 ] $v_demosaic_0

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {64} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {9} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {16} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_1

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {10} \
 ] $xlslice_3

  # Create interface connections
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_pins GPIO_sensor] [get_bd_intf_pins axi_gpio_1/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_pins GPIO_rsvd] [get_bd_intf_pins axi_gpio_2/GPIO]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins IIC_sensor] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins S_AXI2] [get_bd_intf_pins axi_gpio_1/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_gpio_2/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins csirxss_s_axi] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/csirxss_s_axi]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins s_axi_CTRL] [get_bd_intf_pins v_demosaic_0/s_axi_CTRL]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if_0] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]
  connect_bd_intf_net -intf_net v_demosaic_0_m_axis_video [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM] [get_bd_intf_pins v_demosaic_0/m_axis_video]

  # Create port connections
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins iic2intc_irpt] [get_bd_pins axi_iic_0/iic2intc_irpt]
  connect_bd_net -net bg0_pin0_nc_0_1 [get_bd_pins bg0_pin0_nc_0] [get_bd_pins mipi_csi2_rx_subsyst_0/bg0_pin0_nc]
  connect_bd_net -net bg2_pin0_nc_0_1 [get_bd_pins bg2_pin0_nc_0] [get_bd_pins mipi_csi2_rx_subsyst_0/bg2_pin0_nc]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins dphy_clk_200M] [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins s_axi_aclk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_gpio_2/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk] [get_bd_pins v_demosaic_0/ap_clk]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdata [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdata] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdest [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdest] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tlast [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tlast] [get_bd_pins v_demosaic_0/s_axis_video_TLAST]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tuser [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tuser] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tvalid [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tvalid] [get_bd_pins v_demosaic_0/s_axis_video_TVALID]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_gpio_2/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn] [get_bd_pins v_demosaic_0/ap_rst_n]
  connect_bd_net -net v_demosaic_0_s_axis_video_TREADY [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tready] [get_bd_pins v_demosaic_0/s_axis_video_TREADY]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins v_demosaic_0/s_axis_video_TUSER] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins v_demosaic_0/s_axis_video_TDATA] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins v_demosaic_0/s_axis_video_TDEST] [get_bd_pins xlslice_3/Dout]

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
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_1 ]
  set_property -dict [ list \
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
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk_wiz_1_100M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_1_100M

  # Create instance: rst_ddr4_0_300M, and set properties
  set rst_ddr4_0_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_300M ]

  # Create port connections
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins clk_out2] [get_bd_pins clk_wiz_1/clk_out2]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins slowest_sync_clk] [get_bd_pins clk_wiz_1/clk_in1] [get_bd_pins rst_ddr4_0_300M/slowest_sync_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ext_reset_in] [get_bd_pins rst_ddr4_0_300M/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mb_debug_sys_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins slowest_sync_clk1] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
  connect_bd_net -net reset_1 [get_bd_pins reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins bus_struct_reset] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins mb_reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins peripheral_aresetn1] [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn]

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
  set axi_vdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_1 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_mm2s_genlock_mode {0} \
   CONFIG.c_num_fstores {2} \
   CONFIG.c_s2mm_linebuffer_depth {1024} \
 ] $axi_vdma_1

  # Create instance: img2axis_0, and set properties
  set img2axis_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:img2axis img2axis_0 ]

  # Create instance: isolde_resizer_0, and set properties
  set isolde_resizer_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:isolde_resizer isolde_resizer_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_vdma_1/M_AXI_S2MM]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins m_axi_data_mem] [get_bd_intf_pins img2axis_0/m_axi_data_mem]
  connect_bd_intf_net -intf_net img2axis_0_stream_o [get_bd_intf_pins img2axis_0/stream_o] [get_bd_intf_pins isolde_resizer_0/stream_i]
  connect_bd_intf_net -intf_net isolde_resizer_0_stream_o [get_bd_intf_pins axi_vdma_1/S_AXIS_S2MM] [get_bd_intf_pins isolde_resizer_0/stream_o]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins s_axi_cfg_port] [get_bd_intf_pins img2axis_0/s_axi_cfg_port]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_vdma_1/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net microblaze_0_Clk [get_bd_pins m_axi_s2mm_aclk] [get_bd_pins axi_vdma_1/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_1/s_axi_lite_aclk] [get_bd_pins axi_vdma_1/s_axis_s2mm_aclk] [get_bd_pins img2axis_0/ap_clk] [get_bd_pins isolde_resizer_0/ap_clk]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins axi_resetn] [get_bd_pins axi_vdma_1/axi_resetn] [get_bd_pins img2axis_0/ap_rst_n] [get_bd_pins isolde_resizer_0/ap_rst_n]

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

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M11_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S04_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S05_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram_c1_062

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_250mhz_clk1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart


  # Create pins
  create_bd_pin -dir I bg0_pin0_nc_0
  create_bd_pin -dir I bg2_pin0_nc_0
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir I -type rst reset
  create_bd_pin -dir O -type clk slowest_sync_clk1

  # Create instance: Clock_Reset
  create_hier_cell_Clock_Reset $hier_obj Clock_Reset

  # Create instance: MIPI_Pipeline
  create_hier_cell_MIPI_Pipeline $hier_obj MIPI_Pipeline

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.GPIO_BOARD_INTERFACE {led_8bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
   CONFIG.UARTLITE_BOARD_INTERFACE {rs232_uart} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_250mhz_clk1} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1_062} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
 ] $ddr4_0

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {15} \
   CONFIG.C_CACHE_BYTE_SIZE {65536} \
   CONFIG.C_DCACHE_ADDR_TAG {15} \
   CONFIG.C_DCACHE_BYTE_SIZE {65536} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_USE_DCACHE {1} \
   CONFIG.C_USE_ICACHE {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
   CONFIG.NUM_SI {6} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory $hier_obj microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat microblaze_0_xlconcat ]

  # Create interface connections
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins S04_AXI] [get_bd_intf_pins microblaze_0_axi_periph/S04_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins S05_AXI] [get_bd_intf_pins microblaze_0_axi_periph/S05_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_pins led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_pins GPIO_sensor] [get_bd_intf_pins MIPI_Pipeline/GPIO_sensor]
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
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins MIPI_Pipeline/s_axi_CTRL] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins M10_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins M11_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_pins mipi_phy_if_0] [get_bd_intf_pins MIPI_Pipeline/mipi_phy_if_0]

  # Create port connections
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins MIPI_Pipeline/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net bg0_pin0_nc_0_1 [get_bd_pins bg0_pin0_nc_0] [get_bd_pins MIPI_Pipeline/bg0_pin0_nc_0]
  connect_bd_net -net bg2_pin0_nc_0_1 [get_bd_pins bg2_pin0_nc_0] [get_bd_pins MIPI_Pipeline/bg2_pin0_nc_0]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins Clock_Reset/clk_out2] [get_bd_pins MIPI_Pipeline/dphy_clk_200M]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins Clock_Reset/slowest_sync_clk] [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins microblaze_0_axi_periph/M06_ACLK]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins Clock_Reset/ext_reset_in] [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins Clock_Reset/mb_debug_sys_rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins slowest_sync_clk1] [get_bd_pins Clock_Reset/slowest_sync_clk1] [get_bd_pins MIPI_Pipeline/s_axi_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_axi_periph/S01_ACLK] [get_bd_pins microblaze_0_axi_periph/S02_ACLK] [get_bd_pins microblaze_0_axi_periph/S03_ACLK] [get_bd_pins microblaze_0_axi_periph/S04_ACLK] [get_bd_pins microblaze_0_axi_periph/S05_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net reset_1 [get_bd_pins reset] [get_bd_pins Clock_Reset/reset] [get_bd_pins ddr4_0/sys_rst]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins Clock_Reset/bus_struct_reset] [get_bd_pins microblaze_0_local_memory/SYS_Rst]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins Clock_Reset/mb_reset] [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins Clock_Reset/peripheral_aresetn] [get_bd_pins MIPI_Pipeline/s_axi_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins microblaze_0_axi_periph/S01_ARESETN] [get_bd_pins microblaze_0_axi_periph/S02_ARESETN] [get_bd_pins microblaze_0_axi_periph/S03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S04_ARESETN] [get_bd_pins microblaze_0_axi_periph/S05_ARESETN]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins Clock_Reset/peripheral_aresetn1] [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  variable script_folder

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


  # Create ports
  set bg0_pin0_nc_0 [ create_bd_port -dir I bg0_pin0_nc_0 ]
  set bg2_pin0_nc_0 [ create_bd_port -dir I bg2_pin0_nc_0 ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset

  # Create instance: CAM_Subsystem
  create_hier_cell_CAM_Subsystem [current_bd_instance .] CAM_Subsystem

  # Create instance: Resizer_BD
  create_hier_cell_Resizer_BD [current_bd_instance .] Resizer_BD

  # Create interface connections
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins CAM_Subsystem/S04_AXI] [get_bd_intf_pins Resizer_BD/M_AXI_S2MM]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins CAM_Subsystem/S05_AXI] [get_bd_intf_pins Resizer_BD/m_axi_data_mem]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_8bits] [get_bd_intf_pins CAM_Subsystem/led_8bits]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports GPIO_sensor] [get_bd_intf_pins CAM_Subsystem/GPIO_sensor]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_ports GPIO_rsvd] [get_bd_intf_pins CAM_Subsystem/GPIO_rsvd]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports IIC_sensor] [get_bd_intf_pins CAM_Subsystem/IIC_sensor]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins CAM_Subsystem/rs232_uart]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1_062] [get_bd_intf_pins CAM_Subsystem/ddr4_sdram_c1_062]
  connect_bd_intf_net -intf_net default_250mhz_clk1_0_1 [get_bd_intf_ports default_250mhz_clk1_0] [get_bd_intf_pins CAM_Subsystem/default_250mhz_clk1_0]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins CAM_Subsystem/M10_AXI] [get_bd_intf_pins Resizer_BD/s_axi_cfg_port]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins CAM_Subsystem/M11_AXI] [get_bd_intf_pins Resizer_BD/S_AXI_LITE]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_ports mipi_phy_if_0] [get_bd_intf_pins CAM_Subsystem/mipi_phy_if_0]

  # Create port connections
  connect_bd_net -net bg0_pin0_nc_0_1 [get_bd_ports bg0_pin0_nc_0] [get_bd_pins CAM_Subsystem/bg0_pin0_nc_0]
  connect_bd_net -net bg2_pin0_nc_0_1 [get_bd_ports bg2_pin0_nc_0] [get_bd_pins CAM_Subsystem/bg2_pin0_nc_0]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins CAM_Subsystem/slowest_sync_clk1] [get_bd_pins Resizer_BD/m_axi_s2mm_aclk]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins CAM_Subsystem/reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins CAM_Subsystem/peripheral_aresetn] [get_bd_pins Resizer_BD/axi_resetn]

  # Create address segments
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs Resizer_BD/img2axis_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs Resizer_BD/img2axis_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Data] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/v_demosaic_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/microblaze_0/Instruction] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/v_demosaic_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs Resizer_BD/img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/v_demosaic_0/s_axi_CTRL/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs Resizer_BD/img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/axi_vdma_1/Data_S2MM] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/v_demosaic_0/s_axi_CTRL/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs Resizer_BD/axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs Resizer_BD/img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces Resizer_BD/img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs CAM_Subsystem/MIPI_Pipeline/v_demosaic_0/s_axi_CTRL/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.9352",
   "Default View_TopLeft":"-217,-91",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port GPIO_rsvd -pg 1 -lvl 3 -x 840 -y 160 -defaultsOSRD
preplace port GPIO_sensor -pg 1 -lvl 3 -x 840 -y 180 -defaultsOSRD
preplace port IIC_sensor -pg 1 -lvl 3 -x 840 -y 140 -defaultsOSRD
preplace port ddr4_sdram_c1_062 -pg 1 -lvl 3 -x 840 -y 120 -defaultsOSRD
preplace port default_250mhz_clk1_0 -pg 1 -lvl 0 -x 0 -y 110 -defaultsOSRD
preplace port led_8bits -pg 1 -lvl 3 -x 840 -y 80 -defaultsOSRD
preplace port mipi_phy_if_0 -pg 1 -lvl 0 -x 0 -y 130 -defaultsOSRD
preplace port rs232_uart -pg 1 -lvl 3 -x 840 -y 100 -defaultsOSRD
preplace port bg0_pin0_nc_0 -pg 1 -lvl 0 -x 0 -y 210 -defaultsOSRD
preplace port bg2_pin0_nc_0 -pg 1 -lvl 0 -x 0 -y 230 -defaultsOSRD
preplace port reset -pg 1 -lvl 0 -x 0 -y 190 -defaultsOSRD
preplace inst Resizer_BD -pg 1 -lvl 1 -x 220 -y 410 -defaultsOSRD
preplace inst CAM_Subsystem -pg 1 -lvl 2 -x 600 -y 170 -defaultsOSRD
preplace netloc bg0_pin0_nc_0_1 1 0 2 NJ 210 NJ
preplace netloc bg2_pin0_nc_0_1 1 0 2 NJ 230 NJ
preplace netloc reset_1 1 0 2 NJ 190 NJ
preplace netloc microblaze_0_Clk 1 0 3 20 10 NJ 10 820
preplace netloc rst_clk_wiz_1_100M_peripheral_aresetn 1 0 3 30 320 NJ 320 800
preplace netloc default_250mhz_clk1_0_1 1 0 2 NJ 110 NJ
preplace netloc ddr4_0_C0_DDR4 1 2 1 NJ 120
preplace netloc axi_uartlite_0_UART 1 2 1 NJ 100
preplace netloc axi_iic_0_IIC 1 2 1 NJ 140
preplace netloc S04_AXI_1 1 1 1 390 150n
preplace netloc axi_gpio_2_GPIO 1 2 1 NJ 160
preplace netloc S05_AXI_1 1 1 1 400 170n
preplace netloc axi_gpio_0_GPIO 1 2 1 NJ 80
preplace netloc axi_gpio_1_GPIO 1 2 1 NJ 180
preplace netloc microblaze_0_axi_periph_M11_AXI 1 0 3 50 310 NJ 310 810
preplace netloc mipi_phy_if_0_1 1 0 2 NJ 130 NJ
preplace netloc microblaze_0_axi_periph_M10_AXI 1 0 3 40 20 NJ 20 810
levelinfo -pg 1 0 220 600 840
pagesize -pg 1 -db -bbox -sgen -220 0 1040 490
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx:vcu118:vcu118_mipi_uart_115200:0.0} [get_files [current_bd_design].bd]
  set_property PFM.AXI_PORT {M10_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "false"}} [get_bd_cells /CAM_Subsystem/microblaze_0_axi_periph]
  set_property PFM.CLOCK {clk_out1 {id "0" is_default "true" proc_sys_reset "/rst_clk_wiz_1_100M" status "fixed" freq_hz "100000000"}} [get_bd_cells /CAM_Subsystem/Clock_Reset/clk_wiz_1]


  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()