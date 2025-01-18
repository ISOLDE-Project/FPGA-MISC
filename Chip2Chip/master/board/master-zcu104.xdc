######################################
## ZCU104 board
######################################

#clock
set_property PACKAGE_PIN AH18 [get_ports CLK_IN1_D_0_clk_p]
set_property PACKAGE_PIN AH17 [get_ports CLK_IN1_D_0_clk_n]

#GPIO LEDs (Active High)
set_property PACKAGE_PIN D5 [get_ports GPIO_LED_0]
set_property PACKAGE_PIN D6 [get_ports GPIO_LED_1]
set_property PACKAGE_PIN A5 [get_ports GPIO_LED_2]
set_property PACKAGE_PIN B5 [get_ports GPIO_LED_3]

set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_0]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_1]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_2]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_3]

######################################
## c2c
######################################

#clock
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_rx_diff_clk_in_n_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_rx_diff_clk_in_p_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_tx_diff_clk_out_n_0]
set_property IOSTANDARD DIFF_SSTL18_I [get_ports axi_c2c_selio_tx_diff_clk_out_p_0]

#RX/TX IO types
set_property IOSTANDARD LVCMOS18 [get_ports axi_c2c_selio_rx_data*]
set_property IOSTANDARD LVCMOS18 [get_ports axi_c2c_selio_tx_data*]

# TX pins
set_property PACKAGE_PIN E15 [get_ports axi_c2c_selio_tx_diff_clk_out_p_0]
set_property PACKAGE_PIN E14 [get_ports axi_c2c_selio_tx_diff_clk_out_n_0]

set_property PACKAGE_PIN K20 [get_ports {axi_c2c_selio_tx_data_out_0[0]}]
set_property PACKAGE_PIN L20 [get_ports {axi_c2c_selio_tx_data_out_0[1]}]
set_property PACKAGE_PIN K18 [get_ports {axi_c2c_selio_tx_data_out_0[2]}]
set_property PACKAGE_PIN K19 [get_ports {axi_c2c_selio_tx_data_out_0[3]}]
set_property PACKAGE_PIN L16 [get_ports {axi_c2c_selio_tx_data_out_0[4]}]
set_property PACKAGE_PIN L17 [get_ports {axi_c2c_selio_tx_data_out_0[5]}]
set_property PACKAGE_PIN J17 [get_ports {axi_c2c_selio_tx_data_out_0[6]}]
set_property PACKAGE_PIN K17 [get_ports {axi_c2c_selio_tx_data_out_0[7]}]
set_property PACKAGE_PIN G19 [get_ports {axi_c2c_selio_tx_data_out_0[8]}]
set_property PACKAGE_PIN H19 [get_ports {axi_c2c_selio_tx_data_out_0[9]}]
set_property PACKAGE_PIN J15 [get_ports {axi_c2c_selio_tx_data_out_0[10]}]
set_property PACKAGE_PIN J16 [get_ports {axi_c2c_selio_tx_data_out_0[11]}]
set_property PACKAGE_PIN E17 [get_ports {axi_c2c_selio_tx_data_out_0[12]}]
set_property PACKAGE_PIN E18 [get_ports {axi_c2c_selio_tx_data_out_0[13]}]
set_property PACKAGE_PIN G16 [get_ports {axi_c2c_selio_tx_data_out_0[14]}]
set_property PACKAGE_PIN H16 [get_ports {axi_c2c_selio_tx_data_out_0[15]}]
set_property PACKAGE_PIN K15 [get_ports {axi_c2c_selio_tx_data_out_0[16]}]
set_property PACKAGE_PIN L15 [get_ports {axi_c2c_selio_tx_data_out_0[17]}]
set_property PACKAGE_PIN A12 [get_ports {axi_c2c_selio_tx_data_out_0[18]}]
set_property PACKAGE_PIN A13 [get_ports {axi_c2c_selio_tx_data_out_0[19]}]
set_property PACKAGE_PIN F18 [get_ports {axi_c2c_selio_tx_data_out_0[20]}]
set_property PACKAGE_PIN G18 [get_ports {axi_c2c_selio_tx_data_out_0[21]}]





# RX pins
set_property PACKAGE_PIN G10 [get_ports axi_c2c_selio_rx_diff_clk_in_p_0]
set_property PACKAGE_PIN F10 [get_ports axi_c2c_selio_rx_diff_clk_in_n_0]

set_property PACKAGE_PIN F15 [get_ports {axi_c2c_selio_rx_data_in_0[0]}]
set_property PACKAGE_PIN G15 [get_ports {axi_c2c_selio_rx_data_in_0[1]}]
set_property PACKAGE_PIN C12 [get_ports {axi_c2c_selio_rx_data_in_0[2]}]
set_property PACKAGE_PIN C13 [get_ports {axi_c2c_selio_rx_data_in_0[3]}]
set_property PACKAGE_PIN C16 [get_ports {axi_c2c_selio_rx_data_in_0[4]}]
set_property PACKAGE_PIN D16 [get_ports {axi_c2c_selio_rx_data_in_0[5]}]
set_property PACKAGE_PIN C17 [get_ports {axi_c2c_selio_rx_data_in_0[6]}]
set_property PACKAGE_PIN D17 [get_ports {axi_c2c_selio_rx_data_in_0[7]}]
set_property PACKAGE_PIN E10 [get_ports {axi_c2c_selio_rx_data_in_0[8]}]
set_property PACKAGE_PIN F11 [get_ports {axi_c2c_selio_rx_data_in_0[9]}]
set_property PACKAGE_PIN D10 [get_ports {axi_c2c_selio_rx_data_in_0[10]}]
set_property PACKAGE_PIN D11 [get_ports {axi_c2c_selio_rx_data_in_0[11]}]
set_property PACKAGE_PIN C11 [get_ports {axi_c2c_selio_rx_data_in_0[12]}]
set_property PACKAGE_PIN D12 [get_ports {axi_c2c_selio_rx_data_in_0[13]}]
set_property PACKAGE_PIN E12 [get_ports {axi_c2c_selio_rx_data_in_0[14]}]
set_property PACKAGE_PIN F12 [get_ports {axi_c2c_selio_rx_data_in_0[15]}]
set_property PACKAGE_PIN A10 [get_ports {axi_c2c_selio_rx_data_in_0[16]}]
set_property PACKAGE_PIN B10 [get_ports {axi_c2c_selio_rx_data_in_0[17]}]
set_property PACKAGE_PIN H12 [get_ports {axi_c2c_selio_rx_data_in_0[18]}]
set_property PACKAGE_PIN H13 [get_ports {axi_c2c_selio_rx_data_in_0[19]}]
set_property PACKAGE_PIN A11 [get_ports {axi_c2c_selio_rx_data_in_0[20]}]
set_property PACKAGE_PIN B11 [get_ports {axi_c2c_selio_rx_data_in_0[21]}]



set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_IN1_D_0_clk_p]
