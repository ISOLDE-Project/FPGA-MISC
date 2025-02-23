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
  xilinx.com:hls:LEDSupervisor:*\
  xilinx.com:hls:sensorSupervisor:*\
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
  set_property -dict [list \
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


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {33.330000000000005} \
    CONFIG.CLKOUT1_JITTER {106.018} \
    CONFIG.CLKOUT1_PHASE_ERROR {77.836} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {80.000} \
    CONFIG.CLKOUT2_JITTER {88.577} \
    CONFIG.CLKOUT2_PHASE_ERROR {77.836} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_JITTER {101.475} \
    CONFIG.CLKOUT3_PHASE_ERROR {77.836} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {Custom} \
    CONFIG.CLK_IN2_BOARD_INTERFACE {Custom} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {4.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {3.333} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {15.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {12} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIM_IN_FREQ {300.000} \
    CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]
  set_property -dict [list \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $proc_sys_reset_0


  # Create instance: smartconnect_0, and set properties
  set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect smartconnect_0 ]
  set_property -dict [list \
    CONFIG.HAS_ARESETN {0} \
    CONFIG.NUM_CLKS {2} \
    CONFIG.NUM_MI {4} \
    CONFIG.NUM_SI {1} \
  ] $smartconnect_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {3} \
  ] $axi_interconnect_0


  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_1 ]
  set_property -dict [list \
    CONFIG.RESET_BOARD_INTERFACE {reset} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $proc_sys_reset_1


  # Create instance: LEDSupervisor_0, and set properties
  set LEDSupervisor_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:LEDSupervisor LEDSupervisor_0 ]

  # Create instance: sensorSupervisor_0, and set properties
  set sensorSupervisor_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:sensorSupervisor sensorSupervisor_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN1_D_0_1 [get_bd_intf_ports CLK_IN1_D_0] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
  connect_bd_intf_net -intf_net LEDSupervisor_0_m_axi_status [get_bd_intf_pins LEDSupervisor_0/m_axi_status] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net aiml_stub_0_m_axi_data_mem [get_bd_intf_pins aiml_stub_0/m_axi_data_mem] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_chip2chip_0_m_axi [get_bd_intf_pins axi_chip2chip_0/m_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_chip2chip_0/s_axi_lite]
  connect_bd_intf_net -intf_net sensorSupervisor_0_m_axi_status [get_bd_intf_pins sensorSupervisor_0/m_axi_status] [get_bd_intf_pins axi_interconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins aiml_stub_0/s_axi_cfg_port1] [get_bd_intf_pins smartconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M01_AXI [get_bd_intf_pins aiml_stub_0/s_axi_cfg_port2] [get_bd_intf_pins smartconnect_0/M01_AXI]
  connect_bd_intf_net -intf_net smartconnect_0_M02_AXI [get_bd_intf_pins smartconnect_0/M02_AXI] [get_bd_intf_pins LEDSupervisor_0/s_axi_cfg]
  connect_bd_intf_net -intf_net smartconnect_0_M03_AXI [get_bd_intf_pins smartconnect_0/M03_AXI] [get_bd_intf_pins sensorSupervisor_0/s_axi_cfg]

  # Create port connections
  connect_bd_net -net ARESETN_1 [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
  connect_bd_net -net M00_ARESETN_1 [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
  connect_bd_net -net axi_c2c_selio_rx_data_in_1 [get_bd_ports axi_c2c_selio_rx_data_in_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_data_in]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_n_1 [get_bd_ports axi_c2c_selio_rx_diff_clk_in_n_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_n]
  connect_bd_net -net axi_c2c_selio_rx_diff_clk_in_p_1 [get_bd_ports axi_c2c_selio_rx_diff_clk_in_p_0] [get_bd_pins axi_chip2chip_0/axi_c2c_selio_rx_diff_clk_in_p]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_link_status_out [get_bd_pins axi_chip2chip_0/axi_c2c_link_status_out] [get_bd_ports GPIO_LED_0]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_multi_bit_error_out [get_bd_pins axi_chip2chip_0/axi_c2c_multi_bit_error_out] [get_bd_ports GPIO_LED_1]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_data_out [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_data_out] [get_bd_ports axi_c2c_selio_tx_data_out_0]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_n] [get_bd_ports axi_c2c_selio_tx_diff_clk_out_n_0]
  connect_bd_net -net axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p [get_bd_pins axi_chip2chip_0/axi_c2c_selio_tx_diff_clk_out_p] [get_bd_ports axi_c2c_selio_tx_diff_clk_out_p_0]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_chip2chip_0/s_axi_lite_aclk] [get_bd_pins smartconnect_0/aclk1]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins axi_chip2chip_0/idelay_ref_clk]
  connect_bd_net -net clk_wiz_0_clk_out3 [get_bd_pins clk_wiz_0/clk_out3] [get_bd_pins aiml_stub_0/ap_clk] [get_bd_pins smartconnect_0/aclk] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_chip2chip_0/m_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins proc_sys_reset_1/slowest_sync_clk] [get_bd_pins sensorSupervisor_0/ap_clk] [get_bd_pins LEDSupervisor_0/ap_clk] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_interconnect_0/S02_ACLK]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_chip2chip_0/m_aresetn] [get_bd_pins aiml_stub_0/ap_rst_n] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins LEDSupervisor_0/ap_rst_n] [get_bd_pins sensorSupervisor_0/ap_rst_n] [get_bd_pins axi_interconnect_0/S02_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins proc_sys_reset_1/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs LEDSupervisor_0/s_axi_cfg/Reg] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs aiml_stub_0/s_axi_cfg_port1/Reg] -force
  assign_bd_address -offset 0x00020000 -range 0x00010000 -with_name SEG_aiml_stub_0_Reg_1 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs aiml_stub_0/s_axi_cfg_port2/Reg] -force
  assign_bd_address -offset 0x00030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_chip2chip_0/MAXI] [get_bd_addr_segs sensorSupervisor_0/s_axi_cfg/Reg] -force

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces LEDSupervisor_0/Data_m_axi_status] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces aiml_stub_0/Data_m_axi_data_mem] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg]
  exclude_bd_addr_seg -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces sensorSupervisor_0/Data_m_axi_status] [get_bd_addr_segs axi_chip2chip_0/s_axi_lite/Reg]

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Color Coded",
   "Color Coded_ExpandedHierarchyInLayout":"",
   "Color Coded_Layout":"# # String gsaved with Nlview 7.5.8 2022-09-21 7111 VDI=41 GEI=38 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port CLK_IN1_D_0 -pg 1 -lvl 0 -x 0 -y 620 -defaultsOSRD
preplace port port-id_GPIO_LED_0 -pg 1 -lvl 6 -x 2020 -y 670 -defaultsOSRD
preplace port port-id_GPIO_LED_1 -pg 1 -lvl 6 -x 2020 -y 690 -defaultsOSRD
preplace port port-id_axi_c2c_selio_rx_diff_clk_in_n_0 -pg 1 -lvl 0 -x 0 -y 760 -defaultsOSRD
preplace port port-id_axi_c2c_selio_rx_diff_clk_in_p_0 -pg 1 -lvl 0 -x 0 -y 740 -defaultsOSRD
preplace port port-id_axi_c2c_selio_tx_diff_clk_out_n_0 -pg 1 -lvl 6 -x 2020 -y 650 -defaultsOSRD
preplace port port-id_axi_c2c_selio_tx_diff_clk_out_p_0 -pg 1 -lvl 6 -x 2020 -y 630 -defaultsOSRD
preplace port port-id_reset -pg 1 -lvl 0 -x 0 -y 700 -defaultsOSRD
preplace portBus axi_c2c_selio_rx_data_in_0 -pg 1 -lvl 0 -x 0 -y 720 -defaultsOSRD
preplace portBus axi_c2c_selio_tx_data_out_0 -pg 1 -lvl 6 -x 2020 -y 610 -defaultsOSRD
preplace inst aiml_stub_0 -pg 1 -lvl 3 -x 920 -y 90 -defaultsOSRD
preplace inst axi_chip2chip_0 -pg 1 -lvl 5 -x 1760 -y 630 -defaultsOSRD
preplace inst clk_wiz_0 -pg 1 -lvl 1 -x 140 -y 620 -defaultsOSRD
preplace inst proc_sys_reset_0 -pg 1 -lvl 3 -x 920 -y 590 -defaultsOSRD
preplace inst smartconnect_0 -pg 1 -lvl 2 -x 470 -y 350 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 4 -x 1310 -y 500 -defaultsOSRD
preplace inst proc_sys_reset_1 -pg 1 -lvl 2 -x 470 -y 540 -defaultsOSRD
preplace inst LEDSupervisor_0 -pg 1 -lvl 3 -x 920 -y 240 -defaultsOSRD
preplace inst sensorSupervisor_0 -pg 1 -lvl 3 -x 920 -y 400 -defaultsOSRD
preplace netloc axi_c2c_selio_rx_data_in_1 1 0 5 NJ 720 NJ 720 NJ 720 NJ 720 1500J
preplace netloc axi_c2c_selio_rx_diff_clk_in_n_1 1 0 5 NJ 760 NJ 760 NJ 760 NJ 760 1520J
preplace netloc axi_c2c_selio_rx_diff_clk_in_p_1 1 0 5 NJ 740 NJ 740 NJ 740 NJ 740 1510J
preplace netloc axi_chip2chip_0_axi_c2c_link_status_out 1 5 1 NJ 670
preplace netloc axi_chip2chip_0_axi_c2c_multi_bit_error_out 1 5 1 NJ 690
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_data_out 1 5 1 NJ 610
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n 1 5 1 NJ 650
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p 1 5 1 NJ 630
preplace netloc clk_wiz_0_clk_out2 1 1 4 260 710 NJ 710 NJ 710 1480J
preplace netloc reset_1 1 0 3 20J 540 280 440 650J
preplace netloc clk_wiz_0_clk_out3 1 1 4 270 250 720 480 1130 680 1460
preplace netloc clk_wiz_0_clk_out1 1 1 4 290 640 720 700 1160 700 1490J
preplace netloc proc_sys_reset_1_peripheral_aresetn 1 2 3 700 690 1140 690 1470J
preplace netloc ARESETN_1 1 2 2 710J 490 1120
preplace netloc M00_ARESETN_1 1 3 1 1150 540n
preplace netloc CLK_IN1_D_0_1 1 0 1 NJ 620
preplace netloc smartconnect_0_M01_AXI 1 2 1 660 80n
preplace netloc smartconnect_0_M00_AXI 1 2 1 650 60n
preplace netloc axi_chip2chip_0_m_axi 1 1 5 290 260 680J 320 NJ 320 NJ 320 2000
preplace netloc aiml_stub_0_m_axi_data_mem 1 3 1 1160 90n
preplace netloc axi_interconnect_0_M00_AXI 1 4 1 1460 500n
preplace netloc LEDSupervisor_0_m_axi_status 1 3 1 1130 240n
preplace netloc sensorSupervisor_0_m_axi_status 1 3 1 1120 400n
preplace netloc smartconnect_0_M02_AXI 1 2 1 670 220n
preplace netloc smartconnect_0_M03_AXI 1 2 1 N 380
levelinfo -pg 1 0 140 470 920 1310 1760 2020
pagesize -pg 1 -db -bbox -sgen -290 0 2320 780
",
   "Color Coded_ScaleFactor":"1.10945",
   "Color Coded_TopLeft":"233,7",
   "Default View_ScaleFactor":"0.650106",
   "Default View_TopLeft":"-385,-334",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace port CLK_IN1_D_0 -pg 1 -lvl 0 -x -100 -y 630 -defaultsOSRD
preplace port port-id_GPIO_LED_0 -pg 1 -lvl 7 -x 2140 -y 550 -defaultsOSRD
preplace port port-id_GPIO_LED_1 -pg 1 -lvl 7 -x 2140 -y 570 -defaultsOSRD
preplace port port-id_axi_c2c_selio_rx_diff_clk_in_n_0 -pg 1 -lvl 0 -x -100 -y 570 -defaultsOSRD
preplace port port-id_axi_c2c_selio_rx_diff_clk_in_p_0 -pg 1 -lvl 0 -x -100 -y 550 -defaultsOSRD
preplace port port-id_axi_c2c_selio_tx_diff_clk_out_n_0 -pg 1 -lvl 7 -x 2140 -y 530 -defaultsOSRD
preplace port port-id_axi_c2c_selio_tx_diff_clk_out_p_0 -pg 1 -lvl 7 -x 2140 -y 510 -defaultsOSRD
preplace port port-id_reset -pg 1 -lvl 0 -x -100 -y 400 -defaultsOSRD
preplace portBus axi_c2c_selio_rx_data_in_0 -pg 1 -lvl 0 -x -100 -y 530 -defaultsOSRD
preplace portBus axi_c2c_selio_tx_data_out_0 -pg 1 -lvl 7 -x 2140 -y 470 -defaultsOSRD
preplace inst LEDSupervisor_0 -pg 1 -lvl 4 -x 1080 -y 80 -defaultsOSRD
preplace inst aiml_stub_0 -pg 1 -lvl 4 -x 1080 -y 430 -defaultsOSRD
preplace inst axi_chip2chip_0 -pg 1 -lvl 6 -x 1860 -y 510 -defaultsOSRD
preplace inst axi_smc_1 -pg 1 -lvl 5 -x 1460 -y 220 -defaultsOSRD
preplace inst clk_wiz_0 -pg 1 -lvl 1 -x 50 -y 630 -defaultsOSRD
preplace inst proc_sys_reset_0 -pg 1 -lvl 2 -x 370 -y 420 -defaultsOSRD
preplace inst sensorSupervisor_0 -pg 1 -lvl 4 -x 1080 -y 250 -defaultsOSRD
preplace inst smartconnect_0 -pg 1 -lvl 3 -x 710 -y 430 -defaultsOSRD
preplace netloc axi_c2c_selio_rx_data_in_1 1 0 6 NJ 530 NJ 530 NJ 530 NJ 530 NJ 530 NJ
preplace netloc axi_c2c_selio_rx_diff_clk_in_n_1 1 0 6 -70J 550 170J 570 NJ 570 NJ 570 NJ 570 NJ
preplace netloc axi_c2c_selio_rx_diff_clk_in_p_1 1 0 6 -80J 540 NJ 540 NJ 540 NJ 540 NJ 540 1600J
preplace netloc axi_chip2chip_0_axi_c2c_link_status_out 1 6 1 NJ 550
preplace netloc axi_chip2chip_0_axi_c2c_multi_bit_error_out 1 6 1 NJ 570
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_data_out 1 6 1 2100J 470n
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_n 1 6 1 NJ 530
preplace netloc axi_chip2chip_0_axi_c2c_selio_tx_diff_clk_out_p 1 6 1 NJ 510
preplace netloc clk_wiz_0_clk_out2 1 1 5 190J 560 NJ 560 NJ 560 1290J 510 N
preplace netloc clk_wiz_0_clk_out3 1 1 5 180 320 560 320 870 160 1300 120 1610
preplace netloc proc_sys_reset_0_peripheral_aresetn 1 2 4 550 340 880 340 1290J 470 N
preplace netloc reset_1 1 0 2 NJ 400 NJ
preplace netloc CLK_IN1_D_0_1 1 0 1 NJ 630
preplace netloc LEDSupervisor_0_m_axi_status 1 4 1 1290 80n
preplace netloc aiml_stub_0_m_axi_data_mem 1 4 1 1280 180n
preplace netloc axi_chip2chip_0_m_axi 1 2 5 570 330 NJ 330 NJ 330 NJ 330 2100
preplace netloc axi_smc_1_M00_AXI 1 5 1 1620 220n
preplace netloc sensorSupervisor_0_m_axi_status 1 4 1 1290 220n
preplace netloc smartconnect_0_M00_AXI 1 3 1 N 400
preplace netloc smartconnect_0_M01_AXI 1 3 1 N 420
preplace netloc smartconnect_0_M02_AXI 1 3 1 850 60n
preplace netloc smartconnect_0_M03_AXI 1 3 1 860 230n
levelinfo -pg 1 -100 50 370 710 1080 1460 1860 2140
pagesize -pg 1 -db -bbox -sgen -390 0 2440 980
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()
