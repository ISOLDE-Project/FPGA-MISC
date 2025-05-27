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
  xilinx.com:ip:axi_iic:*\
  xilinx.com:ip:axi_uartlite:*\
  xilinx.com:ip:axi_vdma:*\
  xilinx.com:ip:clk_wiz:*\
  xilinx.com:ip:ddr4:*\
  xilinx.com:hls:img2axis:*\
  xilinx.com:hls:isolde_resizer:*\
  xilinx.com:ip:mdm:*\
  xilinx.com:ip:microblaze:*\
  xilinx.com:ip:axi_intc:*\
  xilinx.com:ip:xlconcat:*\
  xilinx.com:ip:mipi_csi2_rx_subsystem:*\
  xilinx.com:ip:proc_sys_reset:*\
  xilinx.com:ip:v_demosaic:*\
  xilinx.com:ip:xlconstant:*\
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

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.GPIO_BOARD_INTERFACE {led_8bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

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

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
   CONFIG.UARTLITE_BOARD_INTERFACE {rs232_uart} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_0 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_m_axi_s2mm_data_width {32} \
   CONFIG.c_mm2s_genlock_mode {0} \
 ] $axi_vdma_0

  # Create instance: axi_vdma_1, and set properties
  set axi_vdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_1 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_mm2s_genlock_mode {0} \
   CONFIG.c_num_fstores {2} \
   CONFIG.c_s2mm_linebuffer_depth {1024} \
 ] $axi_vdma_1

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

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_250mhz_clk1} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c1_062} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
 ] $ddr4_0

  # Create instance: img2axis_0, and set properties
  set img2axis_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:img2axis img2axis_0 ]

  # Create instance: isolde_resizer_0, and set properties
  set isolde_resizer_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:isolde_resizer isolde_resizer_0 ]

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {18} \
   CONFIG.C_DCACHE_ADDR_TAG {18} \
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
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat microblaze_0_xlconcat ]

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

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk_wiz_1_100M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_clk_wiz_1_100M

  # Create instance: rst_ddr4_0_300M, and set properties
  set rst_ddr4_0_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_300M ]

  # Create instance: v_demosaic_0, and set properties
  set v_demosaic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic v_demosaic_0 ]
  set_property -dict [ list \
   CONFIG.SAMPLES_PER_CLOCK {1} \
 ] $v_demosaic_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_1 ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {8} \
 ] $xlconstant_1

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]

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
  connect_bd_intf_net -intf_net S04_AXI_1 [get_bd_intf_pins axi_vdma_1/M_AXI_S2MM] [get_bd_intf_pins microblaze_0_axi_periph/S04_AXI]
  connect_bd_intf_net -intf_net S05_AXI_1 [get_bd_intf_pins img2axis_0/m_axi_data_mem] [get_bd_intf_pins microblaze_0_axi_periph/S05_AXI]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports GPIO_sensor] [get_bd_intf_pins axi_gpio_1/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_ports GPIO_rsvd] [get_bd_intf_pins axi_gpio_2/GPIO]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports IIC_sensor] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins microblaze_0_axi_periph/S03_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1_062] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net default_250mhz_clk1_0_1 [get_bd_intf_ports default_250mhz_clk1_0] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net img2axis_0_stream_o [get_bd_intf_pins img2axis_0/stream_o] [get_bd_intf_pins isolde_resizer_0/stream_i]
  connect_bd_intf_net -intf_net isolde_resizer_0_stream_o [get_bd_intf_pins axi_vdma_1/S_AXIS_S2MM] [get_bd_intf_pins isolde_resizer_0/stream_o]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins microblaze_0/M_AXI_DC] [get_bd_intf_pins microblaze_0_axi_periph/S01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins microblaze_0/M_AXI_IC] [get_bd_intf_pins microblaze_0_axi_periph/S02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_gpio_1/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins axi_gpio_2/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins axi_vdma_0/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/csirxss_s_axi]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI] [get_bd_intf_pins v_demosaic_0/s_axi_CTRL]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins img2axis_0/s_axi_cfg_port] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins axi_vdma_1/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net mipi_phy_if_0_1 [get_bd_intf_ports mipi_phy_if_0] [get_bd_intf_pins mipi_csi2_rx_subsyst_0/mipi_phy_if]
  connect_bd_intf_net -intf_net v_demosaic_0_m_axis_video [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM] [get_bd_intf_pins v_demosaic_0/m_axis_video]

  # Create port connections
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net bg0_pin0_nc_0_1 [get_bd_ports bg0_pin0_nc_0] [get_bd_pins mipi_csi2_rx_subsyst_0/bg0_pin0_nc]
  connect_bd_net -net bg2_pin0_nc_0_1 [get_bd_ports bg2_pin0_nc_0] [get_bd_pins mipi_csi2_rx_subsyst_0/bg2_pin0_nc]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins clk_wiz_1/clk_out2] [get_bd_pins mipi_csi2_rx_subsyst_0/dphy_clk_200M]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins clk_wiz_1/clk_in1] [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins rst_ddr4_0_300M/slowest_sync_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_ddr4_0_300M/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_gpio_2/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins axi_vdma_1/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_1/s_axi_lite_aclk] [get_bd_pins axi_vdma_1/s_axis_s2mm_aclk] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins img2axis_0/ap_clk] [get_bd_pins isolde_resizer_0/ap_clk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_axi_periph/S01_ACLK] [get_bd_pins microblaze_0_axi_periph/S02_ACLK] [get_bd_pins microblaze_0_axi_periph/S03_ACLK] [get_bd_pins microblaze_0_axi_periph/S04_ACLK] [get_bd_pins microblaze_0_axi_periph/S05_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] [get_bd_pins v_demosaic_0/ap_clk]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdata [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdata] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdest [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdest] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tlast [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tlast] [get_bd_pins v_demosaic_0/s_axis_video_TLAST]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tuser [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tuser] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tvalid [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tvalid] [get_bd_pins v_demosaic_0/s_axis_video_TVALID]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins ddr4_0/sys_rst] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_gpio_2/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins axi_vdma_1/axi_resetn] [get_bd_pins img2axis_0/ap_rst_n] [get_bd_pins isolde_resizer_0/ap_rst_n] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins microblaze_0_axi_periph/S01_ARESETN] [get_bd_pins microblaze_0_axi_periph/S02_ARESETN] [get_bd_pins microblaze_0_axi_periph/S03_ARESETN] [get_bd_pins microblaze_0_axi_periph/S04_ARESETN] [get_bd_pins microblaze_0_axi_periph/S05_ARESETN] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins v_demosaic_0/ap_rst_n]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn]
  connect_bd_net -net v_demosaic_0_m_axis_video_TDATA [get_bd_pins v_demosaic_0/m_axis_video_TDATA] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net v_demosaic_0_m_axis_video_TKEEP [get_bd_pins v_demosaic_0/m_axis_video_TKEEP] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net v_demosaic_0_s_axis_video_TREADY [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tready] [get_bd_pins v_demosaic_0/s_axis_video_TREADY]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins xlconcat_1/In1] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins v_demosaic_0/s_axis_video_TUSER] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins v_demosaic_0/s_axis_video_TDATA] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins v_demosaic_0/s_axis_video_TDEST] [get_bd_pins xlslice_3/Dout]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_vdma_1/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_1/Data_S2MM] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg]
  exclude_bd_addr_seg -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x04060000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_vdma_1/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x00040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x00002000 -range 0x00002000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.999997",
   "Default View_TopLeft":"2333,2291",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r6  2020-01-29 bk=1.5227 VDI=41 GEI=36 GUI=JA:10.0 non-TLS
#  -string -flagsOSRD
preplace port GPIO_rsvd -pg 1 -lvl 9 -x 3850 -y 1910 -defaultsOSRD
preplace port GPIO_sensor -pg 1 -lvl 9 -x 3850 -y 1770 -defaultsOSRD
preplace port IIC_sensor -pg 1 -lvl 9 -x 3850 -y 2030 -defaultsOSRD
preplace port ddr4_sdram_c1_062 -pg 1 -lvl 9 -x 3850 -y 2370 -defaultsOSRD
preplace port default_250mhz_clk1_0 -pg 1 -lvl 0 -x -10 -y 2400 -defaultsOSRD
preplace port led_8bits -pg 1 -lvl 9 -x 3850 -y 1630 -defaultsOSRD
preplace port mipi_phy_if_0 -pg 1 -lvl 0 -x -10 -y 460 -defaultsOSRD
preplace port rs232_uart -pg 1 -lvl 9 -x 3850 -y 2210 -defaultsOSRD
preplace port bg0_pin0_nc_0 -pg 1 -lvl 0 -x -10 -y 490 -defaultsOSRD
preplace port bg2_pin0_nc_0 -pg 1 -lvl 0 -x -10 -y 520 -defaultsOSRD
preplace port reset -pg 1 -lvl 0 -x -10 -y 1720 -defaultsOSRD
preplace inst axi_gpio_0 -pg 1 -lvl 8 -x 3650 -y 1630 -defaultsOSRD
preplace inst axi_gpio_1 -pg 1 -lvl 8 -x 3650 -y 1770 -defaultsOSRD
preplace inst axi_gpio_2 -pg 1 -lvl 8 -x 3650 -y 1910 -defaultsOSRD
preplace inst axi_iic_0 -pg 1 -lvl 8 -x 3650 -y 2050 -defaultsOSRD
preplace inst axi_uartlite_0 -pg 1 -lvl 8 -x 3650 -y 2220 -defaultsOSRD
preplace inst axi_vdma_0 -pg 1 -lvl 4 -x 1520 -y 1310 -defaultsOSRD
preplace inst clk_wiz_1 -pg 1 -lvl 1 -x 480 -y 1730 -defaultsOSRD
preplace inst ddr4_0 -pg 1 -lvl 8 -x 3650 -y 2430 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 3 -x 1110 -y 1590 -defaultsOSRD
preplace inst microblaze_0 -pg 1 -lvl 4 -x 1520 -y 1710 -defaultsOSRD
preplace inst microblaze_0_axi_intc -pg 1 -lvl 3 -x 1110 -y 1820 -defaultsOSRD
preplace inst microblaze_0_axi_periph -pg 1 -lvl 5 -x 2330 -y 1920 -defaultsOSRD
preplace inst microblaze_0_local_memory -pg 1 -lvl 5 -x 2330 -y 1430 -defaultsOSRD
preplace inst microblaze_0_xlconcat -pg 1 -lvl 2 -x 770 -y 2250 -defaultsOSRD
preplace inst mipi_csi2_rx_subsyst_0 -pg 1 -lvl 6 -x 2810 -y 640 -defaultsOSRD
preplace inst rst_clk_wiz_1_100M -pg 1 -lvl 2 -x 770 -y 1710 -defaultsOSRD
preplace inst rst_ddr4_0_300M -pg 1 -lvl 4 -x 1520 -y 2630 -defaultsOSRD
preplace inst v_demosaic_0 -pg 1 -lvl 6 -x 2810 -y 180 -defaultsOSRD
preplace inst xlconcat_0 -pg 1 -lvl 2 -x 770 -y 850 -defaultsOSRD
preplace inst xlconcat_1 -pg 1 -lvl 2 -x 770 -y 990 -defaultsOSRD
preplace inst xlconstant_0 -pg 1 -lvl 1 -x 480 -y 860 -defaultsOSRD
preplace inst xlconstant_1 -pg 1 -lvl 1 -x 480 -y 1000 -defaultsOSRD
preplace inst xlslice_0 -pg 1 -lvl 5 -x 2330 -y 290 -defaultsOSRD
preplace inst xlslice_1 -pg 1 -lvl 5 -x 2330 -y 90 -defaultsOSRD
preplace inst xlslice_3 -pg 1 -lvl 5 -x 2330 -y 190 -defaultsOSRD
preplace inst img2axis_0 -pg 1 -lvl 6 -x 2810 -y 2840 -defaultsOSRD
preplace inst isolde_resizer_0 -pg 1 -lvl 7 -x 3260 -y 2850 -defaultsOSRD
preplace inst axi_vdma_1 -pg 1 -lvl 8 -x 3650 -y 2890 -defaultsOSRD
preplace netloc axi_iic_0_iic2intc_irpt 1 1 8 600 2320 NJ 2320 NJ 2320 NJ 2320 NJ 2320 NJ 2320 3470 2310 3830
preplace netloc axi_uartlite_0_interrupt 1 1 8 580 2330 NJ 2330 NJ 2330 NJ 2330 NJ 2330 NJ 2330 3450 2300 3820
preplace netloc bg0_pin0_nc_0_1 1 0 6 NJ 490 NJ 490 NJ 490 NJ 490 1750J 500 2500J
preplace netloc bg2_pin0_nc_0_1 1 0 6 NJ 520 NJ 520 NJ 520 NJ 520 NJ 520 2470J
preplace netloc clk_wiz_1_clk_out2 1 1 5 570 640 NJ 640 NJ 640 NJ 640 NJ
preplace netloc clk_wiz_1_locked 1 1 1 N 1750
preplace netloc ddr4_0_c0_ddr4_ui_clk 1 0 9 20 2420 NJ 2420 NJ 2420 1250 2420 1830 2420 NJ 2420 NJ 2420 3410 2560 3830
preplace netloc ddr4_0_c0_ddr4_ui_clk_sync_rst 1 3 6 1290 2530 NJ 2530 NJ 2530 NJ 2530 3400 2550 3820
preplace netloc mdm_1_debug_sys_rst 1 1 3 600 1610 950J 1660 1250
preplace netloc microblaze_0_Clk 1 1 7 580 1820 980 1690 1270 1500 1820 1340 2540 1340 N 1340 3480
preplace netloc microblaze_0_intr 1 2 1 990 1830n
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tdata 1 4 3 1800 430 NJ 430 3060
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tdest 1 4 3 1770 490 2530J 470 3050
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tlast 1 5 2 2560 30 3120
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tuser 1 4 3 1820 440 NJ 440 3080
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tvalid 1 5 2 2570 330 3110
preplace netloc reset_1 1 0 8 10 1810 590 1810 960J 1710 1230J 1810 1770J 2430 NJ 2430 NJ 2430 3420
preplace netloc rst_clk_wiz_1_100M_bus_struct_reset 1 2 3 940J 1490 NJ 1490 1770
preplace netloc rst_clk_wiz_1_100M_mb_reset 1 2 2 950 1700 1240
preplace netloc rst_clk_wiz_1_100M_peripheral_aresetn 1 2 6 970 1510 1280 1530 1810 1530 2550 1530 N 1530 3460
preplace netloc rst_ddr4_0_300M_peripheral_aresetn 1 4 4 1840 2410 NJ 2410 NJ 2410 3430
preplace netloc v_demosaic_0_m_axis_video_TDATA 1 1 6 590 470 NJ 470 N 470 NJ 470 2520J 460 3090
preplace netloc v_demosaic_0_m_axis_video_TKEEP 1 1 6 600 480 NJ 480 N 480 NJ 480 2500J 450 3070
preplace netloc v_demosaic_0_s_axis_video_TREADY 1 5 2 2560 340 3100
preplace netloc xlconstant_0_dout 1 1 1 NJ 860
preplace netloc xlconstant_1_dout 1 1 1 NJ 1000
preplace netloc xlslice_0_Dout 1 5 1 2470J 210n
preplace netloc xlslice_1_Dout 1 5 1 2470J 90n
preplace netloc xlslice_3_Dout 1 5 1 2470J 150n
preplace netloc ddr4_0_C0_DDR4 1 8 1 NJ 2370
preplace netloc axi_gpio_0_GPIO 1 8 1 NJ 1630
preplace netloc axi_gpio_2_GPIO 1 8 1 NJ 1910
preplace netloc axi_iic_0_IIC 1 8 1 NJ 2030
preplace netloc axi_vdma_0_M_AXI_S2MM 1 4 1 1800 1290n
preplace netloc axi_uartlite_0_UART 1 8 1 NJ 2210
preplace netloc axi_gpio_1_GPIO 1 8 1 NJ 1770
preplace netloc default_250mhz_clk1_0_1 1 0 8 NJ 2400 NJ 2400 NJ 2400 NJ 2400 NJ 2400 NJ 2400 NJ 2400 N
preplace netloc microblaze_0_M_AXI_IC 1 4 1 1760 1630n
preplace netloc microblaze_0_axi_periph_M04_AXI 1 5 3 N 1910 NJ 1910 3470
preplace netloc microblaze_0_axi_periph_M07_AXI 1 3 3 1290 1510 NJ 1510 2480
preplace netloc microblaze_0_axi_periph_M01_AXI 1 5 3 2530 1610 NJ 1610 N
preplace netloc microblaze_0_axi_periph_M09_AXI 1 5 1 2490 90n
preplace netloc microblaze_0_intc_axi 1 2 4 990 1520 NJ 1520 NJ 1520 2470
preplace netloc microblaze_0_debug 1 3 1 1260 1580n
preplace netloc microblaze_0_M_AXI_DC 1 4 1 1770 1610n
preplace netloc microblaze_0_ilmb_1 1 4 1 1780 1420n
preplace netloc microblaze_0_axi_periph_M03_AXI 1 5 3 N 1890 NJ 1890 N
preplace netloc microblaze_0_axi_periph_M06_AXI 1 5 3 N 1950 NJ 1950 3440
preplace netloc microblaze_0_axi_periph_M02_AXI 1 5 3 2570 1750 NJ 1750 N
preplace netloc microblaze_0_axi_periph_M08_AXI 1 5 1 2560 580n
preplace netloc microblaze_0_axi_periph_M05_AXI 1 5 3 N 1930 NJ 1930 3450
preplace netloc microblaze_0_dlmb_1 1 4 1 1750 1400n
preplace netloc microblaze_0_M_AXI_DP 1 4 1 1790 1590n
preplace netloc mipi_phy_if_0_1 1 0 6 NJ 460 NJ 460 NJ 460 NJ 460 NJ 460 2510J
preplace netloc microblaze_0_interrupt 1 3 1 1250 1680n
preplace netloc v_demosaic_0_m_axis_video 1 3 4 1280 20 NJ 20 NJ 20 3110
levelinfo -pg 1 -10 480 770 1110 1520 2330 2810 3260 3650 3850
pagesize -pg 1 -db -bbox -sgen -210 0 4030 3020
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx:vcu118:vcu118_mipi_uart_115200:0.0} [get_files [current_bd_design].bd]
  set_property PFM.CLOCK {clk_out1 {id "0" is_default "true" proc_sys_reset "/rst_clk_wiz_1_100M" status "fixed" freq_hz "100000000"}} [get_bd_cells /clk_wiz_1]
  set_property PFM.AXI_PORT {M10_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "false"}} [get_bd_cells /microblaze_0_axi_periph]


  save_bd_design
common::send_gid_msg -ssname BD::TCL -id 2050 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()