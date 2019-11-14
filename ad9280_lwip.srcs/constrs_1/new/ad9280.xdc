
set_property PACKAGE_PIN Y19 [get_ports adc_CNV_0]
set_property PACKAGE_PIN AA19 [get_ports adc_SCK_0]

set_property PACKAGE_PIN M15 [get_ports adc_CLKOUT_0]

set_property PACKAGE_PIN P15 [get_ports adc_SDO1_0]
set_property PACKAGE_PIN N15 [get_ports adc_SDO2_0]
set_property PACKAGE_PIN T19 [get_ports adc_SDO3_0]
set_property PACKAGE_PIN R19 [get_ports adc_SDO4_0]


set_property IOSTANDARD LVCMOS25 [get_ports adc_CNV_0]
set_property IOSTANDARD LVCMOS25 [get_ports adc_SCK_0]

set_property IOSTANDARD LVCMOS25 [get_ports adc_CLKOUT_0]

set_property IOSTANDARD LVCMOS25 [get_ports adc_SDO1_0]
set_property IOSTANDARD LVCMOS25 [get_ports adc_SDO2_0]
set_property IOSTANDARD LVCMOS25 [get_ports adc_SDO3_0]
set_property IOSTANDARD LVCMOS25 [get_ports adc_SDO4_0]


#set_false_path -reset_path -from [get_pins {design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/slv_reg1_reg[*]/C}] -to [get_pins {design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/sample_inst/sample_len_d0_reg[*]/D}]
#set_false_path -reset_path -from [get_pins {design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/slv_reg1_reg[*]/C}] -to [get_pins {design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/sample_inst/dma_len_d0_reg[*]/D}]
#set_false_path -reset_path -from [get_pins {design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/slv_reg0_reg[0]/C}] -to [get_pins design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/sample_inst/sample_start_d0_reg/D]


#set_false_path -reset_path -from [get_pins design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/sample_inst/st_clr_reg/C] -to [get_pins design_1_i/ad9280_sample_0/inst/ad9280_sample_v1_0_S00_AXI_inst/st_clr_d0_reg/D]
