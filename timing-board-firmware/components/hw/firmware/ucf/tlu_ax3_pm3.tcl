set_property BITSTREAM.Config.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# For 312.5MHz bit rate
create_clock -period 16.000 -name clk [get_ports clk_p]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk] -group [get_clocks -include_generated_clocks -of_obj [get_pins -of_obj [get_cells infra/clocks/mmcm] -filter {NAME =~ *CLKOUT*}]]

set_property IOSTANDARD LVDS_25 [get_port {clk_p clk_n trig_in_*}]
set_property PACKAGE_PIN T5 [get_ports {clk_p}]
set_property PACKAGE_PIN T4 [get_ports {clk_n}]
set_property PACKAGE_PIN B1 [get_ports {trig_in_p[0]}]
set_property PACKAGE_PIN A1 [get_ports {trig_in_n[0]}]
set_property PACKAGE_PIN C4 [get_ports {trig_in_p[1]}]
set_property PACKAGE_PIN B4 [get_ports {trig_in_n[1]}]
set_property PACKAGE_PIN K2 [get_ports {trig_in_p[2]}]
set_property PACKAGE_PIN K1 [get_ports {trig_in_n[2]}]
set_property PACKAGE_PIN C6 [get_ports {trig_in_p[3]}]
set_property PACKAGE_PIN C5 [get_ports {trig_in_n[3]}]
set_property PACKAGE_PIN J4 [get_ports {trig_in_p[4]}]
set_property PACKAGE_PIN H4 [get_ports {trig_in_n[4]}]
set_property PACKAGE_PIN H1 [get_ports {trig_in_p[5]}]
set_property PACKAGE_PIN G1 [get_ports {trig_in_n[5]}]
false_path {trig_in_*} osc_clk

set_property IOSTANDARD TMDS_33 [get_port {q_sfp_* d_cdr_*}]
set_property PACKAGE_PIN F1 [get_ports {q_sfp_p}]
set_property PACKAGE_PIN E1 [get_ports {q_sfp_n}]
set_property PACKAGE_PIN J3 [get_ports {d_cdr_p}]
set_property PACKAGE_PIN J2 [get_ports {d_cdr_n}]
set_property PULLUP TRUE [get_ports {q_sfp_*}]
false_path {q_sfp_* d_cdr_*} osc_clk

set_property IOSTANDARD LVCMOS33 [get_port {q_hdmi_* d_hdmi_* rstb_clk clk_lolb rstb_i2c sfp_* cdr_*}]
set_property PACKAGE_PIN K3 [get_ports {q_hdmi_clk_0}]
set_property PACKAGE_PIN F4 [get_ports {q_hdmi_clk_1}]
set_property PACKAGE_PIN E2 [get_ports {q_hdmi_clk_2}]
set_property PACKAGE_PIN G4 [get_ports {q_hdmi_clk_3}]
set_property PACKAGE_PIN R7 [get_ports {q_hdmi_0}]
set_property PACKAGE_PIN N5 [get_ports {q_hdmi_0b}]
set_property PACKAGE_PIN U4 [get_ports {q_hdmi_1}]
set_property PACKAGE_PIN P4 [get_ports {q_hdmi_1b}]
set_property PACKAGE_PIN R8 [get_ports {q_hdmi_2}]
set_property PACKAGE_PIN K5 [get_ports {q_hdmi_3}]
set_property PACKAGE_PIN N6 [get_ports {d_hdmi_2}]
set_property PACKAGE_PIN C1 [get_ports {rstb_clk}]
set_property PACKAGE_PIN G6 [get_ports {clk_lolb}]
set_property PACKAGE_PIN C2 [get_ports {rstb_i2c}]
set_property PACKAGE_PIN G2 [get_ports {sfp_los}]
set_property PACKAGE_PIN H2 [get_ports {sfp_fault}]
set_property PACKAGE_PIN H6 [get_ports {sfp_tx_dis}]
set_property PACKAGE_PIN D7 [get_ports {cdr_lol}]
set_property PACKAGE_PIN E7 [get_ports {cdr_los}]
false_path {q_hdmi_* d_hdmi_* rstb_clk clk_lolb rstb_i2c sfp_* cdr_*} osc_clk

set_property IOSTANDARD LVCMOS25 [get_port {scl sda}]
set_property PACKAGE_PIN N17 [get_ports {scl}]
set_property PACKAGE_PIN P18 [get_ports {sda}]
false_path {scl sda} osc_clk
