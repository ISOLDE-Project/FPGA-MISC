######################################
## ZCU104 board 
# https://github.com/Xilinx/XilinxBoardStore/tree/2020.1/boards/Xilinx/zcu104/1.1
#
######################################

# 300MHZ clock
set_property PACKAGE_PIN AH18 [get_ports CLK_IN1_D_0_clk_p]
set_property PACKAGE_PIN AH17 [get_ports CLK_IN1_D_0_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_IN1_D_0_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK_IN1_D_0_clk_n]

#GPIO LEDs (Active High)
set_property PACKAGE_PIN D5 [get_ports GPIO_LED_0]
set_property PACKAGE_PIN D6 [get_ports GPIO_LED_1]
set_property PACKAGE_PIN A5 [get_ports GPIO_LED_2]
set_property PACKAGE_PIN B5 [get_ports GPIO_LED_3]

set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_0]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_1]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_2]
set_property IOSTANDARD LVCMOS33 [get_ports GPIO_LED_3]