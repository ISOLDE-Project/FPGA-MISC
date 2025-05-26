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
  xilinx.com:ip:axi_intc:*\
  xilinx.com:ip:axi_vdma:*\
  xilinx.com:hls:img2axis:*\
  xilinx.com:hls:isolde_resizer:*\
  xilinx.com:ip:xlslice:*\
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
  set M_AXI_S2MM [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {0} \
   CONFIG.NUM_READ_OUTSTANDING {16} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
   ] $M_AXI_S2MM

  set interrupt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mbinterrupt_rtl:1.0 interrupt ]

  set m_axi_data_mem [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_data_mem ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {16} \
   CONFIG.NUM_WRITE_OUTSTANDING {16} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_ONLY} \
   ] $m_axi_data_mem

  set s_axi_cfg_port [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_cfg_port ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {16} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.MAX_BURST_LENGTH {1} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_cfg_port


  # Create ports
  set Dout [ create_bd_port -dir O -from 15 -to 0 Dout ]
  set ap_clk [ create_bd_port -dir I -type clk -freq_hz 100000000 ap_clk ]
  set_property -dict [ list \
   CONFIG.CLK_DOMAIN {design1_clk_wiz_0_0_clk_out1} \
 ] $ap_clk
  set ap_rst_n [ create_bd_port -dir I -type rst ap_rst_n ]

  # Create instance: axi_intc_0, and set properties
  set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]

  # Create instance: axi_vdma_0, and set properties
  set axi_vdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma axi_vdma_0 ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s {0} \
   CONFIG.c_m_axi_s2mm_data_width {32} \
   CONFIG.c_mm2s_genlock_mode {0} \
   CONFIG.c_num_fstores {2} \
   CONFIG.c_s2mm_linebuffer_depth {2048} \
 ] $axi_vdma_0

  # Create instance: img2axis_0, and set properties
  set img2axis_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:img2axis img2axis_0 ]

  # Create instance: isolde_resizer_0, and set properties
  set isolde_resizer_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:isolde_resizer isolde_resizer_0 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {16} \
   CONFIG.DIN_TO {1} \
   CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_1

  # Create interface connections
  connect_bd_intf_net -intf_net axi_intc_0_interrupt [get_bd_intf_ports interrupt] [get_bd_intf_pins axi_intc_0/interrupt]
  connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_S2MM [get_bd_intf_ports M_AXI_S2MM] [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM]
  connect_bd_intf_net -intf_net img2axis_0_m_axi_data_mem [get_bd_intf_ports m_axi_data_mem] [get_bd_intf_pins img2axis_0/m_axi_data_mem]
  connect_bd_intf_net -intf_net img2axis_0_stream_o [get_bd_intf_pins img2axis_0/stream_o] [get_bd_intf_pins isolde_resizer_0/stream_i]
  connect_bd_intf_net -intf_net isolde_resizer_0_stream_o [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM] [get_bd_intf_pins isolde_resizer_0/stream_o]
  connect_bd_intf_net -intf_net s_axi_cfg_port_1 [get_bd_intf_ports s_axi_cfg_port] [get_bd_intf_pins img2axis_0/s_axi_cfg_port]

  # Create port connections
  connect_bd_net -net axi_vdma_0_s2mm_introut [get_bd_pins axi_intc_0/intr] [get_bd_pins axi_vdma_0/s2mm_introut]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_ports ap_clk] [get_bd_pins axi_intc_0/s_axi_aclk] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] [get_bd_pins axi_vdma_0/s_axi_lite_aclk] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] [get_bd_pins img2axis_0/ap_clk] [get_bd_pins isolde_resizer_0/ap_clk]
  connect_bd_net -net img2axis_0_stream_o_TUSER [get_bd_pins img2axis_0/stream_o_TUSER] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net img2axis_0_stream_o_TVALID [get_bd_pins img2axis_0/stream_o_TVALID] [get_bd_pins isolde_resizer_0/stream_i_TVALID]
  connect_bd_net -net isolde_resizer_0_stream_i_TREADY [get_bd_pins img2axis_0/stream_o_TREADY] [get_bd_pins isolde_resizer_0/stream_i_TREADY]
  connect_bd_net -net rst_clk_wiz_0_100M_peripheral_aresetn [get_bd_ports ap_rst_n] [get_bd_pins axi_intc_0/s_axi_aresetn] [get_bd_pins axi_vdma_0/axi_resetn] [get_bd_pins img2axis_0/ap_rst_n] [get_bd_pins isolde_resizer_0/ap_rst_n]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins isolde_resizer_0/stream_i_TUSER] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_ports Dout] [get_bd_pins xlslice_1/Dout]

  # Create address segments
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_vdma_0/Data_S2MM] [get_bd_addr_segs M_AXI_S2MM/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces img2axis_0/Data_m_axi_data_mem] [get_bd_addr_segs m_axi_data_mem/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces s_axi_cfg_port] [get_bd_addr_segs img2axis_0/s_axi_cfg_port/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.915325",
   "Default View_TopLeft":"-152,-232",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
#  -string -flagsOSRD
preplace inst axi_intc_0 -pg 1 -lvl 4 -x 1410 -y 300 -defaultsOSRD
preplace inst axi_vdma_0 -pg 1 -lvl 3 -x 1080 -y 170 -defaultsOSRD
preplace inst img2axis_0 -pg 1 -lvl 1 -x 250 -y 110 -defaultsOSRD
preplace inst xlslice_0 -pg 1 -lvl 1 -x 250 -y 280 -defaultsOSRD
preplace inst xlslice_1 -pg 1 -lvl 1 -x 250 -y 420 -defaultsOSRD -resize 180 88
preplace inst isolde_resizer_0 -pg 1 -lvl 2 -x 680 -y 130 -defaultsOSRD
preplace netloc axi_vdma_0_s2mm_introut 1 3 1 1280 190n
preplace netloc clk_wiz_0_clk_out1 1 0 4 20 340 480 240 870 290 NJ
preplace netloc img2axis_0_stream_o_TUSER 1 0 2 40 220 460
preplace netloc img2axis_0_stream_o_TVALID 1 1 1 N 100
preplace netloc isolde_resizer_0_stream_i_TREADY 1 1 1 N 120
preplace netloc proc_sys_reset_0_peripheral_aresetn 1 2 2 880 310 NJ
preplace netloc rst_clk_wiz_0_100M_peripheral_aresetn 1 0 2 30 350 490J
preplace netloc xlslice_0_Dout 1 1 1 470J 140n
preplace netloc img2axis_0_stream_o 1 1 1 N 80
preplace netloc isolde_resizer_0_stream_o 1 2 1 N 130
levelinfo -pg 1 0 250 680 1080 1410 1550
pagesize -pg 1 -db -bbox -sgen 0 0 1550 480
"
}

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_$::_xil_proj_name_()