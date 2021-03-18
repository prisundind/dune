set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.Config.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

proc false_path {patt clk} {
    set p [get_ports -quiet $patt -filter {direction != out}]
    if {[llength $p] != 0} {
        set_input_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != out}]
        set_false_path -from [get_ports $patt -filter {direction != out}]
    }
    set p [get_ports -quiet $patt -filter {direction != in}]
    if {[llength $p] != 0} {
       	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	    set_false_path -to [get_ports $patt -filter {direction != in}]
	}
}

# System clock (200MHz)
create_clock -period 20.000 -name osc_clk [get_ports osc_clk]
create_clock -period 4.000 -name fmc_clk [get_ports fmc_clk_p]
create_clock -period 4.000 -name rec_clk [get_ports rec_clk_p]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks fmc_clk] -group [get_clocks -include_generated_clocks rec_clk] -group [get_clocks -include_generated_clocks -of_obj [get_pins -of_obj [get_cells infra/clocks/mmcm] -filter {NAME =~ *CLKOUT*}]]

set_false_path -through [get_pins infra/clocks/rst_reg/Q]
set_false_path -through [get_nets infra/clocks/nuke_i]

set_property IOSTANDARD LVCMOS25 [get_ports osc_clk]
set_property PACKAGE_PIN P17 [get_ports osc_clk]

set_property IOSTANDARD LVCMOS25 [get_ports {leds[*]}]
set_property SLEW SLOW [get_ports {leds[*]}]
set_property PACKAGE_PIN M16 [get_ports {leds[0]}]
set_property PACKAGE_PIN M17 [get_ports {leds[1]}]
set_property PACKAGE_PIN L18 [get_ports {leds[2]}]
set_property PACKAGE_PIN M18 [get_ports {leds[3]}]
false_path {leds[*]} osc_clk

set_property IOSTANDARD LVCMOS25 [get_ports {rgmii_* phy_rstn}]
set_property PACKAGE_PIN R18 [get_ports {rgmii_txd[0]}]
set_property PACKAGE_PIN T18 [get_ports {rgmii_txd[1]}]
set_property PACKAGE_PIN U17 [get_ports {rgmii_txd[2]}]
set_property PACKAGE_PIN U18 [get_ports {rgmii_txd[3]}]
set_property PACKAGE_PIN T16 [get_ports {rgmii_tx_ctl}]
set_property PACKAGE_PIN N16 [get_ports {rgmii_txc}]
set_property PACKAGE_PIN U16 [get_ports {rgmii_rxd[0]}]
set_property PACKAGE_PIN V17 [get_ports {rgmii_rxd[1]}]
set_property PACKAGE_PIN V15 [get_ports {rgmii_rxd[2]}]
set_property PACKAGE_PIN V16 [get_ports {rgmii_rxd[3]}]
set_property PACKAGE_PIN R16 [get_ports {rgmii_rx_ctl}]
set_property PACKAGE_PIN T14 [get_ports {rgmii_rxc}]
set_property PACKAGE_PIN M13 [get_ports {phy_rstn}]
false_path {phy_rstn} osc_clk

set_property IOSTANDARD LVDS_25 [get_port {fmc_clk_* rec_clk_* rec_d_* clk_out_* rj45_din_* rj45_dout_* sfp_dout_* gpin_* gpout_*}]
set_property DIFF_TERM TRUE [get_port {fmc_clk_* rec_clk_* rec_d_* rj45_din_* gpin_*}]
set_property PACKAGE_PIN T5 [get_ports {fmc_clk_p}]
set_property PACKAGE_PIN T4 [get_ports {fmc_clk_n}]
set_property PACKAGE_PIN E3 [get_ports {rec_clk_p}]
set_property PACKAGE_PIN D3 [get_ports {rec_clk_n}]
set_property PACKAGE_PIN M4 [get_ports {rec_d_p}]
set_property PACKAGE_PIN N4 [get_ports {rec_d_n}]
set_property PACKAGE_PIN N5 [get_ports {clk_out_p}]
set_property PACKAGE_PIN P5 [get_ports {clk_out_n}]
set_property PACKAGE_PIN K3 [get_ports {rj45_din_p}]
set_property PACKAGE_PIN L3 [get_ports {rj45_din_n}]
set_property PACKAGE_PIN G6 [get_ports {rj45_dout_p}]
set_property PACKAGE_PIN F6 [get_ports {rj45_dout_n}]
set_property PACKAGE_PIN D8 [get_ports {sfp_dout_p}]
set_property PACKAGE_PIN C7 [get_ports {sfp_dout_n}]
set_property PACKAGE_PIN N2 [get_ports {gpin_0_p}]
set_property PACKAGE_PIN N1 [get_ports {gpin_0_n}]
set_property PACKAGE_PIN L6 [get_ports {gpout_0_p}]
set_property PACKAGE_PIN L5 [get_ports {gpout_0_n}]
set_property PACKAGE_PIN M6 [get_ports {gpout_1_p}]
set_property PACKAGE_PIN N6 [get_ports {gpout_1_n}]
false_path {rec_d_* clk_out_* rj45_din_* rj45_dout_* sfp_dout_* gpin_* gpout_*} osc_clk

set_property IOSTANDARD LVCMOS25 [get_port {pll_rstn cdr_lol cdr_los sfp_los sfp_tx_dis sfp_flt uid_scl uid_sda sfp_scl sfp_sda pll_scl pll_sda}]
set_property PACKAGE_PIN R6 [get_ports {cdr_lol}]
set_property PACKAGE_PIN R5 [get_ports {cdr_los}]
set_property PACKAGE_PIN P2 [get_ports {sfp_los}]
set_property PACKAGE_PIN U4 [get_ports {sfp_tx_dis}]
set_property PACKAGE_PIN U3 [get_ports {sfp_flt}]
set_property PACKAGE_PIN N17 [get_ports {uid_scl}]
set_property PACKAGE_PIN P18 [get_ports {uid_sda}]
set_property PACKAGE_PIN M3 [get_ports {sfp_scl}]
set_property PACKAGE_PIN M2 [get_ports {sfp_sda}]
set_property PACKAGE_PIN U1 [get_ports {pll_scl}]
set_property PACKAGE_PIN V1 [get_ports {pll_sda}]
set_property PACKAGE_PIN H1 [get_ports {pll_rstn}]
false_path {pll_rstn cdr_lol cdr_los sfp_los sfp_tx_dis sfp_flt uid_scl uid_sda sfp_scl sfp_sda pll_scl pll_sda} osc_clk

set_property IOSTANDARD LVCMOS25 [get_ports {cfg[*]}]
set_property PULLTYPE PULLUP [get_ports {cfg[*]}]
set_property PACKAGE_PIN K2 [get_ports {cfg[0]}]
set_property PACKAGE_PIN K1 [get_ports {cfg[1]}]
set_property PACKAGE_PIN J4 [get_ports {cfg[2]}]
set_property PACKAGE_PIN H4 [get_ports {cfg[3]}]
