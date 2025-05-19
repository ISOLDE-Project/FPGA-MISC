
# 300MHZ clock
set_property PACKAGE_PIN G31 [get_ports {CLK_IN1_D_0_clk_p}]
set_property PACKAGE_PIN F31 [get_ports {CLK_IN1_D_0_clk_n}]
set_property IOSTANDARD LVDS [get_ports {CLK_IN1_D_0_clk_p}]
set_property IOSTANDARD LVDS [get_ports {CLK_IN1_D_0_clk_n}]

#GPIO LEDs (Active High)
set_property PACKAGE_PIN AT32 [get_ports {GPIO_LED_0}]
set_property PACKAGE_PIN AV34 [get_ports {GPIO_LED_1}]
set_property PACKAGE_PIN AY30 [get_ports {GPIO_LED_2}]
set_property PACKAGE_PIN BB32 [get_ports {GPIO_LED_3}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIO_LED_0}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIO_LED_1}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIO_LED_2}]
set_property IOSTANDARD LVCMOS12 [get_ports {GPIO_LED_3}]


set_property IOSTANDARD LVCMOS18  [get_ports axi_c2c_selio_rx_data*]
set_property IOSTANDARD LVCMOS18  [get_ports axi_c2c_selio_tx_data*]

set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_rx_diff_clk_in_n_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_rx_diff_clk_in_p_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_tx_diff_clk_out_n_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_tx_diff_clk_out_p_0]

# RX pins
set_property PACKAGE_PIN BC9 [get_ports axi_c2c_selio_rx_diff_clk_in_p_0]
set_property PACKAGE_PIN BC8 [get_ports axi_c2c_selio_rx_diff_clk_in_n_0]

set_property PACKAGE_PIN BD11 [get_ports {axi_c2c_selio_rx_data_in_0[0]}]
set_property PACKAGE_PIN BC11 [get_ports {axi_c2c_selio_rx_data_in_0[1]}]
set_property PACKAGE_PIN BE12 [get_ports {axi_c2c_selio_rx_data_in_0[2]}]
set_property PACKAGE_PIN BD12 [get_ports {axi_c2c_selio_rx_data_in_0[3]}]
set_property PACKAGE_PIN BF11 [get_ports {axi_c2c_selio_rx_data_in_0[4]}]
set_property PACKAGE_PIN BF12 [get_ports {axi_c2c_selio_rx_data_in_0[5]}]
set_property PACKAGE_PIN BF14 [get_ports {axi_c2c_selio_rx_data_in_0[6]}]
set_property PACKAGE_PIN BE14 [get_ports {axi_c2c_selio_rx_data_in_0[7]}]
set_property PACKAGE_PIN BE13 [get_ports {axi_c2c_selio_rx_data_in_0[8]}]
set_property PACKAGE_PIN BD13 [get_ports {axi_c2c_selio_rx_data_in_0[9]}]
set_property PACKAGE_PIN BD15 [get_ports {axi_c2c_selio_rx_data_in_0[10]}]
set_property PACKAGE_PIN BC15 [get_ports {axi_c2c_selio_rx_data_in_0[11]}]
set_property PACKAGE_PIN BF15 [get_ports {axi_c2c_selio_rx_data_in_0[12]}]
set_property PACKAGE_PIN BE15 [get_ports {axi_c2c_selio_rx_data_in_0[13]}]
set_property PACKAGE_PIN BB14 [get_ports {axi_c2c_selio_rx_data_in_0[14]}]
set_property PACKAGE_PIN BA14 [get_ports {axi_c2c_selio_rx_data_in_0[15]}]
set_property PACKAGE_PIN BB12 [get_ports {axi_c2c_selio_rx_data_in_0[16]}]
set_property PACKAGE_PIN BB13 [get_ports {axi_c2c_selio_rx_data_in_0[17]}]
set_property PACKAGE_PIN BA15 [get_ports {axi_c2c_selio_rx_data_in_0[18]}]
set_property PACKAGE_PIN BA16 [get_ports {axi_c2c_selio_rx_data_in_0[19]}]
set_property PACKAGE_PIN BC13 [get_ports {axi_c2c_selio_rx_data_in_0[20]}]
set_property PACKAGE_PIN BC14 [get_ports {axi_c2c_selio_rx_data_in_0[21]}]
#set_property PACKAGE_PIN AP13 [get_ports {axi_c2c_selio_rx_data_in_0[22]}]



# TX pins
set_property PACKAGE_PIN AV14 [get_ports axi_c2c_selio_tx_diff_clk_out_p_0]
set_property PACKAGE_PIN AV13 [get_ports axi_c2c_selio_tx_diff_clk_out_n_0]

set_property PACKAGE_PIN AY7 [get_ports {axi_c2c_selio_tx_data_out_0[0]}]
set_property PACKAGE_PIN AY8 [get_ports {axi_c2c_selio_tx_data_out_0[1]}]
set_property PACKAGE_PIN AW7 [get_ports {axi_c2c_selio_tx_data_out_0[2]}]
set_property PACKAGE_PIN AW8 [get_ports {axi_c2c_selio_tx_data_out_0[3]}]
set_property PACKAGE_PIN BC16 [get_ports {axi_c2c_selio_tx_data_out_0[4]}]
set_property PACKAGE_PIN BB16 [get_ports {axi_c2c_selio_tx_data_out_0[5]}]
set_property PACKAGE_PIN AV8 [get_ports {axi_c2c_selio_tx_data_out_0[6]}]
set_property PACKAGE_PIN AV9 [get_ports {axi_c2c_selio_tx_data_out_0[7]}]
set_property PACKAGE_PIN AT14 [get_ports {axi_c2c_selio_tx_data_out_0[8]}]
set_property PACKAGE_PIN AR14 [get_ports {axi_c2c_selio_tx_data_out_0[9]}]
set_property PACKAGE_PIN AR12 [get_ports {axi_c2c_selio_tx_data_out_0[10]}]
set_property PACKAGE_PIN AP12 [get_ports {axi_c2c_selio_tx_data_out_0[11]}]
set_property PACKAGE_PIN AY12 [get_ports {axi_c2c_selio_tx_data_out_0[12]}]
set_property PACKAGE_PIN AW12 [get_ports {axi_c2c_selio_tx_data_out_0[13]}]
set_property PACKAGE_PIN AY10 [get_ports {axi_c2c_selio_tx_data_out_0[14]}]
set_property PACKAGE_PIN AW11 [get_ports {axi_c2c_selio_tx_data_out_0[15]}]
set_property PACKAGE_PIN AV11 [get_ports {axi_c2c_selio_tx_data_out_0[16]}]
set_property PACKAGE_PIN AU11 [get_ports {axi_c2c_selio_tx_data_out_0[17]}]
set_property PACKAGE_PIN AY13 [get_ports {axi_c2c_selio_tx_data_out_0[18]}]
set_property PACKAGE_PIN AW13 [get_ports {axi_c2c_selio_tx_data_out_0[19]}]
set_property PACKAGE_PIN AP16 [get_ports {axi_c2c_selio_tx_data_out_0[20]}]
set_property PACKAGE_PIN AN16 [get_ports {axi_c2c_selio_tx_data_out_0[21]}]
#set_property PACKAGE_PIN AR13 [get_ports {axi_c2c_selio_tx_data_out_0[22]}]



# set_property PACKAGE_PIN BC8      [get_ports "FMC_HPC1_CLK0_M2C_N"] ;
# set_property PACKAGE_PIN BC9      [get_ports "FMC_HPC1_CLK0_M2C_P"] ;
# set_property PACKAGE_PIN AV13     [get_ports "FMC_HPC1_CLK1_M2C_N"] ;
# set_property PACKAGE_PIN AV14     [get_ports "FMC_HPC1_CLK1_M2C_P"] ;
# set_property PACKAGE_PIN BA9      [get_ports "FMC_HPC1_LA00_CC_N"] ;
# set_property PACKAGE_PIN AY9      [get_ports "FMC_HPC1_LA00_CC_P"] ;
# set_property PACKAGE_PIN BF9      [get_ports "FMC_HPC1_LA01_CC_N"] ;
# set_property PACKAGE_PIN BF10     [get_ports "FMC_HPC1_LA01_CC_P"] ;
# set_property PACKAGE_PIN BD11     [get_ports "FMC_HPC1_LA02_N"] ;
# set_property PACKAGE_PIN BC11     [get_ports "FMC_HPC1_LA02_P"] ;
# set_property PACKAGE_PIN BE12     [get_ports "FMC_HPC1_LA03_N"] ;
# set_property PACKAGE_PIN BD12     [get_ports "FMC_HPC1_LA03_P"] ;
# set_property PACKAGE_PIN BF11     [get_ports "FMC_HPC1_LA04_N"] ;
# set_property PACKAGE_PIN BF12     [get_ports "FMC_HPC1_LA04_P"] ;
# set_property PACKAGE_PIN BF14     [get_ports "FMC_HPC1_LA05_N"] ;
# set_property PACKAGE_PIN BE14     [get_ports "FMC_HPC1_LA05_P"] ;
# set_property PACKAGE_PIN BE13     [get_ports "FMC_HPC1_LA06_N"] ;
# set_property PACKAGE_PIN BD13     [get_ports "FMC_HPC1_LA06_P"] ;
# set_property PACKAGE_PIN BD15     [get_ports "FMC_HPC1_LA07_N"] ;
# set_property PACKAGE_PIN BC15     [get_ports "FMC_HPC1_LA07_P"] ;
# set_property PACKAGE_PIN BF15     [get_ports "FMC_HPC1_LA08_N"] ;
# set_property PACKAGE_PIN BE15     [get_ports "FMC_HPC1_LA08_P"] ;
# set_property PACKAGE_PIN BB14     [get_ports "FMC_HPC1_LA09_N"] ;
# set_property PACKAGE_PIN BA14     [get_ports "FMC_HPC1_LA09_P"] ;
# set_property PACKAGE_PIN BB12     [get_ports "FMC_HPC1_LA10_N"] ;
# set_property PACKAGE_PIN BB13     [get_ports "FMC_HPC1_LA10_P"] ;
# set_property PACKAGE_PIN BA15     [get_ports "FMC_HPC1_LA11_N"] ;
# set_property PACKAGE_PIN BA16     [get_ports "FMC_HPC1_LA11_P"] ;
# set_property PACKAGE_PIN BC13     [get_ports "FMC_HPC1_LA12_N"] ;
# set_property PACKAGE_PIN BC14     [get_ports "FMC_HPC1_LA12_P"] ;
# set_property PACKAGE_PIN AY7      [get_ports "FMC_HPC1_LA13_N"] ;
# set_property PACKAGE_PIN AY8      [get_ports "FMC_HPC1_LA13_P"] ;
# set_property PACKAGE_PIN AW7      [get_ports "FMC_HPC1_LA14_N"] ;
# set_property PACKAGE_PIN AW8      [get_ports "FMC_HPC1_LA14_P"] ;
# set_property PACKAGE_PIN BC16     [get_ports "FMC_HPC1_LA15_N"] ;
# set_property PACKAGE_PIN BB16     [get_ports "FMC_HPC1_LA15_P"] ;
# set_property PACKAGE_PIN AV8      [get_ports "FMC_HPC1_LA16_N"] ;
# set_property PACKAGE_PIN AV9      [get_ports "FMC_HPC1_LA16_P"] ;
# set_property PACKAGE_PIN AT14     [get_ports "FMC_HPC1_LA17_CC_N"] ;
# set_property PACKAGE_PIN AR14     [get_ports "FMC_HPC1_LA17_CC_P"] ;
# set_property PACKAGE_PIN AR12     [get_ports "FMC_HPC1_LA18_CC_N"] ;
# set_property PACKAGE_PIN AP12     [get_ports "FMC_HPC1_LA18_CC_P"] ;
# set_property PACKAGE_PIN AY12     [get_ports "FMC_HPC1_LA19_N"] ;
# set_property PACKAGE_PIN AW12     [get_ports "FMC_HPC1_LA19_P"] ;
# set_property PACKAGE_PIN AY10     [get_ports "FMC_HPC1_LA20_N"] ;
# set_property PACKAGE_PIN AW11     [get_ports "FMC_HPC1_LA20_P"] ;
# set_property PACKAGE_PIN AV11     [get_ports "FMC_HPC1_LA21_N"] ;
# set_property PACKAGE_PIN AU11     [get_ports "FMC_HPC1_LA21_P"] ;
# set_property PACKAGE_PIN AY13     [get_ports "FMC_HPC1_LA22_N"] ;
# set_property PACKAGE_PIN AW13     [get_ports "FMC_HPC1_LA22_P"] ;
# set_property PACKAGE_PIN AP16     [get_ports "FMC_HPC1_LA23_N"] ;
# set_property PACKAGE_PIN AN16     [get_ports "FMC_HPC1_LA23_P"] ;
# set_property PACKAGE_PIN AR13     [get_ports "FMC_HPC1_LA24_N"] ;
# set_property PACKAGE_PIN AP13     [get_ports "FMC_HPC1_LA24_P"] ;
# set_property PACKAGE_PIN AU12     [get_ports "FMC_HPC1_LA25_N"] ;
# set_property PACKAGE_PIN AT12     [get_ports "FMC_HPC1_LA25_P"] ;
# set_property PACKAGE_PIN AL15     [get_ports "FMC_HPC1_LA26_N"] ;
# set_property PACKAGE_PIN AK15     [get_ports "FMC_HPC1_LA26_P"] ;
# set_property PACKAGE_PIN AM14     [get_ports "FMC_HPC1_LA27_N"] ;
# set_property PACKAGE_PIN AL14     [get_ports "FMC_HPC1_LA27_P"] ;
# set_property PACKAGE_PIN AW10     [get_ports "FMC_HPC1_LA28_N"] ;
# set_property PACKAGE_PIN AV10     [get_ports "FMC_HPC1_LA28_P"] ;
# set_property PACKAGE_PIN AP15     [get_ports "FMC_HPC1_LA29_N"] ;
# set_property PACKAGE_PIN AN15     [get_ports "FMC_HPC1_LA29_P"] ;
# set_property PACKAGE_PIN AL12     [get_ports "FMC_HPC1_LA30_N"] ;
# set_property PACKAGE_PIN AK12     [get_ports "FMC_HPC1_LA30_P"] ;
# set_property PACKAGE_PIN AM12     [get_ports "FMC_HPC1_LA31_N"] ;
# set_property PACKAGE_PIN AM13     [get_ports "FMC_HPC1_LA31_P"] ;
# set_property PACKAGE_PIN AJ12     [get_ports "FMC_HPC1_LA32_N"] ;
# set_property PACKAGE_PIN AJ13     [get_ports "FMC_HPC1_LA32_P"] ;
# set_property PACKAGE_PIN AK13     [get_ports "FMC_HPC1_LA33_N"] ;
# set_property PACKAGE_PIN AK14     [get_ports "FMC_HPC1_LA33_P"] ;







