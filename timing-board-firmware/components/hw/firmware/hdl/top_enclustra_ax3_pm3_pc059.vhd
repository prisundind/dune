-- Top-level design for ipbus demo
--
-- This version is for Enclustra AX3 module, using the RGMII PHY on the PM3 baseboard
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, 4/10/16

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.ALL;
use work.net_addr.all;

entity top is port(
		osc_clk: in std_logic;
		leds: out std_logic_vector(3 downto 0); -- Enclustra status LEDs
		rgmii_txd: out std_logic_vector(3 downto 0); -- Enclustra ethernet
		rgmii_tx_ctl: out std_logic;
		rgmii_txc: out std_logic;
		rgmii_rxd: in std_logic_vector(3 downto 0);
		rgmii_rx_ctl: in std_logic;
		rgmii_rxc: in std_logic;
		phy_rstn: out std_logic; -- PHY reset
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		d_p: in std_logic_vector(7 downto 0); -- data from fanout SFPs
		d_n: in std_logic_vector(7 downto 0);
		q_p: out std_logic; -- output to fanout
		q_n: out std_logic;
		sfp_los: in std_logic_vector(7 downto 0); -- fanout SFP LOS
		d_cdr_p: in std_logic; -- data input from CDR
		d_cdr_n: in std_logic;
		clk_cdr_p: in std_logic; -- clock from CDR
		clk_cdr_n: in std_logic;
		cdr_los: in std_logic; -- CDR LOS
		cdr_lol: in std_logic; -- CDR LOL
		inmux: out std_logic_vector(2 downto 0); -- mux control
		rstb_i2cmux: out std_logic; -- reset for mux
		d_hdmi_p: in std_logic; -- data from upstream HDMI
		d_hdmi_n: in std_logic;	
		q_hdmi_p: out std_logic; -- output to upstream HDMI
		q_hdmi_n: out std_logic;
		d_usfp_p: in std_logic; -- input from upstream SFP
		d_usfp_n: in std_logic;		
		q_usfp_p: out std_logic; -- output to upstream SFP
		q_usfp_n: out std_logic;
		usfp_fault: in std_logic; -- upstream SFP fault
		usfp_los: in std_logic; -- upstream SFP LOS
		usfp_txdis: out std_logic; -- upstream SFP tx_dis
		usfp_sda: inout std_logic; -- upstream SFP I2C
		usfp_scl: out std_logic;
		ucdr_los: in std_logic; -- upstream CDR LOS
		ucdr_lol: in std_logic; -- upstream CDR LOL
		ledb: out std_logic_vector(2 downto 0); -- FMC LEDs
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders
		gpio_p: out std_logic_vector(2 downto 0); -- GPIO
		gpio_n: out std_logic_vector(2 downto 0)
	);

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, nuke, soft_rst, phy_rst_e, userled, clk125: std_logic;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal inf_leds: std_logic_vector(1 downto 0);
	
begin

-- Infrastructure

	infra: entity work.enclustra_ax3_pm3_infra
		port map(
			osc_clk => osc_clk,
			clk_ipb_o => clk_ipb,
			rst_ipb_o => rst_ipb,
			clk125_o => clk125,
			rst125_o => phy_rst_e,
			nuke => nuke,
			soft_rst => soft_rst,
			leds => inf_leds,
			rgmii_txd => rgmii_txd,
			rgmii_tx_ctl => rgmii_tx_ctl,
			rgmii_txc => rgmii_txc,
			rgmii_rxd => rgmii_rxd,
			rgmii_rx_ctl => rgmii_rx_ctl,
			rgmii_rxc => rgmii_rxc,
			mac_addr => mac_addr,
			ip_addr => ip_addr,
			ipb_in => ipb_in,
			ipb_out => ipb_out
		);
		
	leds <= not ('0' & userled & inf_leds);
	phy_rstn <= not phy_rst_e;
		
	mac_addr <= MY_MAC_ADDR; -- Careful here, arbitrary addresses do not always work
	ip_addr <= MY_IP_ADDR; -- 192.168.200.65

	payload: entity work.payload
		generic map(
			CARRIER_TYPE => X"00"
		)
		port map(
			ipb_clk => clk_ipb,
			ipb_rst => rst_ipb,
			ipb_in => ipb_out,
			ipb_out => ipb_in,
			nuke => nuke,
			soft_rst => soft_rst,
			userled => userled,
			addr => ADDR,
			clk125 => clk125,
			clk_p => clk_p,
			clk_n => clk_n,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			d_p => d_p,
			d_n => d_n,
			q_p => q_p,
			q_n => q_n,
			sfp_los => sfp_los,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			clk_cdr_p => clk_cdr_p,
			clk_cdr_n => clk_cdr_n,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			inmux => inmux,
			rstb_i2cmux => rstb_i2cmux,
			d_hdmi_p => d_hdmi_p,
			d_hdmi_n => d_hdmi_n,
			q_hdmi_p => q_hdmi_p,
			q_hdmi_n => q_hdmi_n,
			d_usfp_p => d_usfp_p,
			d_usfp_n => d_usfp_n,
			q_usfp_p => q_usfp_p,
			q_usfp_n => q_usfp_n,
			usfp_fault => usfp_fault,
			ucdr_los => ucdr_los,
			ucdr_lol => ucdr_lol,
			usfp_los => usfp_los,
			usfp_txdis => usfp_txdis,
			usfp_sda => usfp_sda,
			usfp_scl => usfp_scl,
			ledb => ledb,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c,
			gpio_p => gpio_p,
			gpio_n => gpio_n
		);

end rtl;
