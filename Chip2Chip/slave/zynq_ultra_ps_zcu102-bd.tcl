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
  xilinx.com:hls:aiml_stub:*\
  xilinx.com:ip:axi_chip2chip:*\
  xilinx.com:ip:clk_wiz:*\
  xilinx.com:ip:proc_sys_reset:*\
  xilinx.com:ip:smartconnect:*\
  xilinx.com:ip:system_ila:*\
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
  set CLK_IN1_D_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 CLK_IN1_D_0 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $CLK_IN1_D_0


  # Create ports
  set GPIO_LED_0 [ create_bd_port -dir O GPIO_LED_0 ]
  set GPIO_LED_1 [ create_bd_port -dir O GPIO_LED_1 ]
  set axi_c2c_selio_rx_data_in_0 [ create_bd_port -dir I -from 21 -to 0 axi_c2c_selio_rx_data_in_0 ]
  set axi_c2c_selio_rx_diff_clk_in_n_0 [ create_bd_port -dir I -type clk -freq_hz 80000000 axi_c2c_selio_rx_diff_clk_in_n_0 ]
  set axi_c2c_selio_rx_diff_clk_in_p_0 [ create_bd_port -dir I -type clk -freq_hz 80000000 axi_c2c_selio_rx_diff_clk_in_p_0 ]
  set axi_c2c_selio_tx_data_out_0 [ create_bd_port -dir O -from 21 -to 0 axi_c2c_selio_tx_data_out_0 ]
  set axi_c2c_selio_tx_diff_clk_out_n_0 [ create_bd_port -dir O -type clk axi_c2c_selio_tx_diff_clk_out_n_0 ]
  set axi_c2c_selio_tx_diff_clk_out_p_0 [ create_bd_port -dir O -type clk axi_c2c_selio_tx_diff_clk_out_p_0 ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset

  # Create instance: aiml_stub_0, and set properties
  set aiml_stub_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:aiml_stub aiml_stub_0 ]

  # Create instance: axi_chip2chip_0, and set properties
  set axi_chip2chip_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_chip2chip axi_chip2chip_0 ]
  set_property -dict [ list \
   CONFIG.C_AXI_DATA_WIDTH {64} \
   CONFIG.C_AXI_STB_WIDTH {8} \
   CONFIG.C_COMMON_CLK {0} \
   CONFIG.C_INCLUDE_AXILITE {1} \
   CONFIG.C_INTERFACE_MODE {1} \
   CONFIG.C_MASTER_FPGA {0} \
   CONFIG.C_M_AXI_ID_WIDTH {0} \
   CONFIG.C_M_AXI_WUSER_WIDTH {0} \
   CONFIG.C_USE_DIFF_CLK {true} \
 ] $axi_chip2chip_0

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $axi_interconnect_0

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
   CONFIG.CLKOUT1_JITTER {106.018} \
   CONFIG.CLKOUT1_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {80.000} \
   CONFIG.CLKOUT2_JITTER {88.577} \
   CONFIG.CLKOUT2_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {106.018} \
   CONFIG.CLKOUT3_PHASE_ERROR {77.836} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {80.000} \
   CONFIG.CLKOUT3_USED {false} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
   CONFIG.CLK_IN2_BOARD_INTERFACE {Custom} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {4.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {3.333} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {15.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {2} \
   CONFIG.PRIM_IN_FREQ {300.000} \
   CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
   CONFIG.RESET_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_LOCKED {false} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_0

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $proc_sys_reset_0

  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [ list \
   CONFIG.HAS_ARESETN {0} \
   CONFIG.NUM_CLKS {1} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
 ] $smartconnect_0

  # Create instance: system_ila_0, and set properties
  set system_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila system_ila_0 ]
  set_property -dict [ list \
   CONFIG.C_MON_TYPE {INTERFACE} \
   CONFIG.C_NUM_MONITOR_SLOTS {2} \
   CONFIG.C_SLOT_0_APC_EN {0} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
   CONFIG.C_SLOT_1_APC_EN {0} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AR_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_AW_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_B_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_R_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_DATA {1} \
   CONFIG.C_SLOT_1_AXI_W_SEL_TRIG {1} \
   CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:aximm_rtl:1.0} \
 ] $system_ila_0

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN1_D_0_1 [get_bd_intf_ports CLK_IN1_D_0] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
  connect_bd_intf_net -intf_net aiml_stub_0_m_axi_data_mem [get_bd_intf_pins aiml_stub_0/m_axi_data_mem] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets aiml_stub_0_m_axi_data_mem] [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins system_ila_0/SLOT_0_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets aiml_stub_0_m_axi_data_mem]
  connect_bd_intf_net -intf_net axi_chip2chip_0_m_axi [get_bd_intf_pins axi_chip2chip_0/m_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_chip2chip_0/s_axi_lite] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins aiml_stub_0/s_axi_cfg_port1] [get_bd_intf_pins smartconnect_0/M00_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets smartconnect_0_M00_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins system_ila_0/SLOT_1_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets smartconnect_0_M00_AXI]

  # Create port connections
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins aiml_stub_0/ap_rst_n] [get_bd_pins axi_chip2chip_0/m_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins system_ila_0/resetn]
  connect_bd_net -net axi_c2c_selio_rx_data_in_1 [get_bd_ports axi_c2c_selio_rx_data_in_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_data_in]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_n_1 [get_bd_ports axi_c2c_selio_rx_diff_clk_in_n_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_n]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_p_1 [get_bd_ports axi_c2c_selio_rx_diff_clk_in_p_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_p]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_link_status_out [get_bd_ports GPIO_LED_0] [get_bd_pins axi_chip2chip_0/axi_c2c_link_status_out]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_multi_bit_error_out [get_bd_ports GPIO_LED_1] [get_bd_pins axi_chip2chip_0/axi_c2c_multi_bit_error_out]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_data_out [get_bd_ports axi_c2c_selio_tx_data_out_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_data_out]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n [get_bd_ports axi_c2c_selio_tx_diff_clk_out_n_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_n]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p [get_bd_ports axi_c2c_selio_tx_diff_clk_out_p_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_p]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins aiml_stub_0/ap_clk] [get_bd_pins axi_chip2chip_0/m_aclk] [get_bd_pins axi_chip2chip_0/s_axi_lite_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins system_ila_0/clk]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins axi_chip2chip_0/idelay_ref_clk] [get_bd_pins clk_wiz_0/clk_out2]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0xFFFD0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces aiml_stub_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0xA0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs aiml_stub_0/s_axi_cfg_port1/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.717936",
   "Default View_TopLeft":"247,84",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port CLK_IN1_D_0 -pg 1 -lvl 0 -x 0 -y 480 -defaultsOSRD
preplace port GPIO_LED_0 -pg 1 -lvl 6 -x 2160 -y 740 -defaultsOSRD
preplace port GPIO_LED_1 -pg 1 -lvl 6 -x 2160 -y 760 -defaultsOSRD
preplace port axi_c2c_selio_rx_diff_clk_in_n_0 -pg 1 -lvl 0 -x 0 -y 760 -defaultsOSRD
preplace port axi_c2c_selio_rx_diff_clk_in_p_0 -pg 1 -lvl 0 -x 0 -y 740 -defaultsOSRD
preplace port axi_c2c_selio_tx_diff_clk_out_n_0 -pg 1 -lvl 6 -x 2160 -y 720 -defaultsOSRD
preplace port axi_c2c_selio_tx_diff_clk_out_p_0 -pg 1 -lvl 6 -x 2160 -y 700 -defaultsOSRD
preplace port reset -pg 1 -lvl 0 -x 0 -y 570 -defaultsOSRD
preplace portBus axi_c2c_selio_rx_data_in_0 -pg 1 -lvl 0 -x 0 -y 720 -defaultsOSRD
preplace portBus axi_c2c_selio_tx_data_out_0 -pg 1 -lvl 6 -x 2160 -y 680 -defaultsOSRD
preplace inst axi_chip2chip_0 -pg 1 -lvl 5 -x 1900 -y 700 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 4 -x 1350 -y 500 -defaultsOSRD
preplace inst clk_wiz_0 -pg 1 -lvl 1 -x 140 -y 480 -defaultsOSRD
preplace inst proc_sys_reset_0 -pg 1 -lvl 3 -x 910 -y 590 -defaultsOSRD
preplace inst smartconnect_0 -pg 1 -lvl 2 -x 470 -y 350 -defaultsOSRD
preplace inst system_ila_0 -pg 1 -lvl 4 -x 1350 -y 180 -defaultsOSRD
preplace inst aiml_stub_0 -pg 1 -lvl 3 -x 910 -y 230 -defaultsOSRD
preplace netloc M00_ARESETN_1 1 2 3 640 310 1140 660 N
preplace netloc axi_c2c_selio_rx_data_in_1 1 0 5 NJ 720 NJ 720 NJ 720 NJ 720 NJ
preplace netloc axi_c2c_selio_rx_diff_clk_in_n_1 1 0 5 NJ 760 NJ 760 NJ 760 NJ 760 NJ
preplace netloc axi_c2c_selio_rx_diff_clk_in_p_1 1 0 5 NJ 740 NJ 740 NJ 740 NJ 740 NJ
preplace netloc axi_chip2chip_0_axi_c2c_link_status_out 1 5 1 NJ 740
preplace netloc axi_chip2chip_0_axi_c2c_multi_bit_error_out 1 5 1 NJ 760
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_data_out 1 5 1 NJ 680
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n 1 5 1 NJ 720
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p 1 5 1 NJ 700
preplace netloc clk_wiz_0_clk_out1 1 1 4 260 270 630 320 1120 670 1510J
preplace netloc clk_wiz_0_clk_out2 1 1 4 N 490 NJ 490 1110J 620 1500J
preplace netloc reset_1 1 0 3 NJ 570 N 570 NJ
preplace netloc axi_interconnect_0_M00_AXI 1 4 1 1510 500n
preplace netloc axi_chip2chip_0_m_axi 1 1 5 270 280 620J 330 NJ 330 NJ 330 2140
preplace netloc smartconnect_0_M00_AXI 1 2 2 610 150 1120
preplace netloc CLK_IN1_D_0_1 1 0 1 NJ 480
preplace netloc aiml_stub_0_m_axi_data_mem 1 3 1 1130 150n
levelinfo -pg 1 0 140 470 910 1350 1900 2160
pagesize -pg 1 -db -bbox -sgen -290 0 2460 840
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()