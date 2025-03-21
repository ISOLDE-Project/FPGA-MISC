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
  xilinx.com:ip:mdm:*\
  xilinx.com:ip:microblaze:*\
  xilinx.com:ip:axi_intc:*\
  xilinx.com:ip:xlconcat:*\
  xilinx.com:ip:mipi_csi2_rx_subsystem:*\
  xilinx.com:ip:proc_sys_reset:*\
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
   CONFIG.c_mm2s_genlock_mode {0} \
 ] $axi_vdma_0

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
   CONFIG.NUM_MI {10} \
   CONFIG.NUM_SI {4} \
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
   CONFIG.CMN_NUM_PIXELS {2} \
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
   CONFIG.SAMPLES_PER_CLOCK {2} \
 ] $v_demosaic_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {9} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {19} \
   CONFIG.DIN_TO {12} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_WIDTH {10} \
 ] $xlslice_3

  # Create interface connections
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports GPIO_sensor] [get_bd_intf_pins axi_gpio_1/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_ports GPIO_rsvd] [get_bd_intf_pins axi_gpio_2/GPIO]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports IIC_sensor] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins microblaze_0_axi_periph/S03_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram_c1_062] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net default_250mhz_clk1_0_1 [get_bd_intf_ports default_250mhz_clk1_0] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
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
  connect_bd_net -net microblaze_0_Clk [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_gpio_2/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_axi_periph/S01_ACLK] [get_bd_pins microblaze_0_axi_periph/S02_ACLK] [get_bd_pins microblaze_0_axi_periph/S03_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aclk] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aclk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] [get_bd_pins v_demosaic_0/ap_clk]
  connect_bd_net -net microblaze_0_intr [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdata [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdata] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_2/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tdest [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tdest] [get_bd_pins xlslice_3/Din]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tlast [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tlast] [get_bd_pins v_demosaic_0/s_axis_video_TLAST]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tuser [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tuser] [get_bd_pins v_demosaic_0/s_axis_video_TUSER]
  connect_bd_net -net mipi_csi2_rx_subsyst_0_video_out_tvalid [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tvalid] [get_bd_pins v_demosaic_0/s_axis_video_TVALID]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins ddr4_0/sys_rst] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_gpio_2/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins microblaze_0_axi_periph/S01_ARESETN] [get_bd_pins microblaze_0_axi_periph/S02_ARESETN] [get_bd_pins microblaze_0_axi_periph/S03_ARESETN] [get_bd_pins mipi_csi2_rx_subsyst_0/lite_aresetn] [get_bd_pins mipi_csi2_rx_subsyst_0/video_aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins v_demosaic_0/ap_rst_n]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn]
  connect_bd_net -net v_demosaic_0_s_axis_video_TREADY [get_bd_pins mipi_csi2_rx_subsyst_0/video_out_tready] [get_bd_pins v_demosaic_0/s_axis_video_TREADY]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins v_demosaic_0/s_axis_video_TDATA] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins xlconcat_0/In1] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net xlslice_3_Dout [get_bd_pins v_demosaic_0/s_axis_video_TDEST] [get_bd_pins xlslice_3/Dout]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg] -force
  assign_bd_address -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_iic_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs axi_vdma_0/S_AXI_LITE/Reg]
  exclude_bd_addr_seg -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs microblaze_0_axi_intc/S_AXI/Reg]
  exclude_bd_addr_seg -offset 0x44A10000 -range 0x00002000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs mipi_csi2_rx_subsyst_0/csirxss_s_axi/Reg]
  exclude_bd_addr_seg -offset 0x44A20000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs v_demosaic_0/s_axi_CTRL/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.314607",
   "Default View_TopLeft":"-248,-114",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port GPIO_rsvd -pg 1 -lvl 8 -x 3160 -y 460 -defaultsOSRD
preplace port GPIO_sensor -pg 1 -lvl 8 -x 3160 -y 180 -defaultsOSRD
preplace port IIC_sensor -pg 1 -lvl 8 -x 3160 -y 970 -defaultsOSRD
preplace port ddr4_sdram_c1_062 -pg 1 -lvl 8 -x 3160 -y 1580 -defaultsOSRD
preplace port default_250mhz_clk1_0 -pg 1 -lvl 0 -x 0 -y 1610 -defaultsOSRD
preplace port led_8bits -pg 1 -lvl 8 -x 3160 -y 320 -defaultsOSRD
preplace port rs232_uart -pg 1 -lvl 8 -x 3160 -y 840 -defaultsOSRD
preplace port mipi_phy_if_0 -pg 1 -lvl 0 -x 0 -y 1590 -defaultsOSRD
preplace port reset -pg 1 -lvl 0 -x 0 -y 1300 -defaultsOSRD
preplace port bg0_pin0_nc_0 -pg 1 -lvl 0 -x 0 -y 1550 -defaultsOSRD
preplace port bg2_pin0_nc_0 -pg 1 -lvl 0 -x 0 -y 1570 -defaultsOSRD
preplace inst axi_gpio_0 -pg 1 -lvl 7 -x 2960 -y 320 -defaultsOSRD
preplace inst axi_gpio_1 -pg 1 -lvl 7 -x 2960 -y 180 -defaultsOSRD
preplace inst axi_gpio_2 -pg 1 -lvl 7 -x 2960 -y 460 -defaultsOSRD
preplace inst axi_iic_0 -pg 1 -lvl 7 -x 2960 -y 990 -defaultsOSRD
preplace inst axi_uartlite_0 -pg 1 -lvl 7 -x 2960 -y 850 -defaultsOSRD
preplace inst clk_wiz_1 -pg 1 -lvl 1 -x 140 -y 1310 -defaultsOSRD
preplace inst ddr4_0 -pg 1 -lvl 7 -x 2960 -y 1640 -defaultsOSRD
preplace inst mdm_1 -pg 1 -lvl 3 -x 970 -y 1470 -defaultsOSRD
preplace inst microblaze_0 -pg 1 -lvl 4 -x 1490 -y 1280 -defaultsOSRD
preplace inst microblaze_0_axi_intc -pg 1 -lvl 3 -x 970 -y 1250 -defaultsOSRD
preplace inst microblaze_0_axi_periph -pg 1 -lvl 5 -x 2030 -y 390 -defaultsOSRD
preplace inst microblaze_0_local_memory -pg 1 -lvl 5 -x 2030 -y 1270 -defaultsOSRD
preplace inst microblaze_0_xlconcat -pg 1 -lvl 2 -x 480 -y 1190 -defaultsOSRD
preplace inst rst_clk_wiz_1_100M -pg 1 -lvl 2 -x 480 -y 1440 -defaultsOSRD
preplace inst rst_ddr4_0_300M -pg 1 -lvl 4 -x 1490 -y 1480 -defaultsOSRD
preplace inst mipi_csi2_rx_subsyst_0 -pg 1 -lvl 6 -x 2490 -y 620 -defaultsOSRD
preplace inst v_demosaic_0 -pg 1 -lvl 3 -x 970 -y 960 -defaultsOSRD
preplace inst axi_vdma_0 -pg 1 -lvl 4 -x 1490 -y 1030 -defaultsOSRD
preplace inst xlslice_1 -pg 1 -lvl 1 -x 140 -y 840 -defaultsOSRD
preplace inst xlslice_2 -pg 1 -lvl 1 -x 140 -y 940 -defaultsOSRD
preplace inst xlslice_3 -pg 1 -lvl 2 -x 480 -y 820 -defaultsOSRD
preplace inst xlconcat_0 -pg 1 -lvl 2 -x 480 -y 930 -defaultsOSRD
preplace netloc axi_iic_0_iic2intc_irpt 1 1 7 280 1120 NJ 1120 1220J 1160 NJ 1160 NJ 1160 NJ 1160 3140
preplace netloc axi_uartlite_0_interrupt 1 1 7 260 740 NJ 740 NJ 740 1810J 830 NJ 830 2730J 770 3140
preplace netloc clk_wiz_1_locked 1 1 1 250 1330n
preplace netloc ddr4_0_c0_ddr4_ui_clk 1 0 8 20 1390 270J 1340 680J 1370 1190 1380 1840 1380 NJ 1380 NJ 1380 3140
preplace netloc ddr4_0_c0_ddr4_ui_clk_sync_rst 1 3 5 1240 1760 NJ 1760 NJ 1760 NJ 1760 3140
preplace netloc mdm_1_debug_sys_rst 1 1 3 280 1540 NJ 1540 1210
preplace netloc microblaze_0_Clk 1 1 6 280 1280 660 1110 1230 910 1830 870 2230 790 2760
preplace netloc microblaze_0_intr 1 2 1 710 1190n
preplace netloc reset_1 1 0 7 20 1230 260 1670 NJ 1670 NJ 1670 NJ 1670 NJ 1670 NJ
preplace netloc rst_clk_wiz_1_100M_bus_struct_reset 1 2 3 660J 1580 NJ 1580 1850
preplace netloc rst_clk_wiz_1_100M_mb_reset 1 2 2 700 1140 1190
preplace netloc rst_clk_wiz_1_100M_peripheral_aresetn 1 2 5 690 1360 1200 890 1770 880 2220 450 2770
preplace netloc rst_ddr4_0_300M_peripheral_aresetn 1 4 3 1860 1580 NJ 1580 2670J
preplace netloc bg0_pin0_nc_0_1 1 0 6 NJ 1550 NJ 1550 NJ 1550 1220J 1590 NJ 1590 2240J
preplace netloc bg2_pin0_nc_0_1 1 0 6 NJ 1570 NJ 1570 NJ 1570 1200J 1600 NJ 1600 2270J
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tdata 1 0 7 20 750 NJ 750 NJ 750 NJ 750 1820J 810 NJ 810 2690
preplace netloc xlslice_1_Dout 1 1 1 250J 840n
preplace netloc xlslice_2_Dout 1 1 1 NJ 940
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tdest 1 1 6 280 760 NJ 760 NJ 760 1790J 840 NJ 840 2700
preplace netloc xlconcat_0_dout 1 2 1 660 910n
preplace netloc xlslice_3_Dout 1 2 1 670J 820n
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tlast 1 2 5 730 780 1200J 860 NJ 860 NJ 860 2710
preplace netloc v_demosaic_0_s_axis_video_TREADY 1 2 5 690 770 NJ 770 1800J 820 NJ 820 2660
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tuser 1 2 5 740 810 NJ 810 1740J 850 NJ 850 2670
preplace netloc mipi_csi2_rx_subsyst_0_video_out_tvalid 1 2 5 750 1130 1210J 1150 NJ 1150 NJ 1150 2680
preplace netloc clk_wiz_1_clk_out2 1 1 5 NJ 1310 670J 1610 NJ 1610 NJ 1610 2260
preplace netloc microblaze_0_ilmb_1 1 4 1 N 1260
preplace netloc microblaze_0_dlmb_1 1 4 1 N 1240
preplace netloc microblaze_0_axi_periph_M06_AXI 1 5 2 2210J 440 2720
preplace netloc microblaze_0_intc_axi 1 2 4 720 800 NJ 800 NJ 800 2200
preplace netloc microblaze_0_axi_periph_M09_AXI 1 2 4 750 790 NJ 790 NJ 790 2180
preplace netloc microblaze_0_interrupt 1 3 1 N 1250
preplace netloc axi_vdma_0_M_AXI_S2MM 1 4 1 1760 120n
preplace netloc axi_gpio_0_GPIO 1 7 1 NJ 320
preplace netloc microblaze_0_debug 1 3 1 1210 1270n
preplace netloc axi_gpio_1_GPIO 1 7 1 NJ 180
preplace netloc axi_gpio_2_GPIO 1 7 1 NJ 460
preplace netloc axi_iic_0_IIC 1 7 1 NJ 970
preplace netloc axi_uartlite_0_UART 1 7 1 NJ 840
preplace netloc ddr4_0_C0_DDR4 1 7 1 NJ 1580
preplace netloc default_250mhz_clk1_0_1 1 0 7 NJ 1610 NJ 1610 660J 1620 NJ 1620 NJ 1620 2270J 1610 NJ
preplace netloc microblaze_0_M_AXI_DC 1 4 1 1750 80n
preplace netloc microblaze_0_M_AXI_DP 1 4 1 1730 60n
preplace netloc microblaze_0_M_AXI_IC 1 4 1 1780 100n
preplace netloc microblaze_0_axi_periph_M01_AXI 1 5 2 2270 300 NJ
preplace netloc microblaze_0_axi_periph_M02_AXI 1 5 2 2250 160 NJ
preplace netloc microblaze_0_axi_periph_M03_AXI 1 5 2 2270 410 2780J
preplace netloc microblaze_0_axi_periph_M04_AXI 1 5 2 2250 420 2750J
preplace netloc microblaze_0_axi_periph_M05_AXI 1 5 2 2220 430 2740J
preplace netloc microblaze_0_axi_periph_M08_AXI 1 5 1 2210 460n
preplace netloc microblaze_0_axi_periph_M07_AXI 1 3 3 1240 780 NJ 780 2190
preplace netloc v_demosaic_0_m_axis_video 1 3 1 1220 950n
preplace netloc mipi_phy_if_0_1 1 0 6 20J 1630 NJ 1630 NJ 1630 NJ 1630 NJ 1630 2250J
levelinfo -pg 1 0 140 480 970 1490 2030 2490 2960 3160
pagesize -pg 1 -db -bbox -sgen -220 0 3360 1770
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  # Create PFM attributes
  set_property PFM_NAME {xilinx:vcu118:vcu118_mipi_uart_115200:0.0} [get_files [current_bd_design].bd]
  set_property PFM.CLOCK {clk_out1 {id "0" is_default "true" proc_sys_reset "/rst_clk_wiz_1_100M" status "fixed" freq_hz "100000000"}} [get_bd_cells /clk_wiz_1]
  set_property PFM.AXI_PORT {M10_AXI {memport "M_AXI_GP" sptag "" memory "" is_range "false"}} [get_bd_cells /microblaze_0_axi_periph]


  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()