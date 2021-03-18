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
		trig_in_p: in std_logic_vector(5 downto 0);
		trig_in_n: in std_logic_vector(5 downto 0);
		q_hdmi_clk_0: out std_logic;
		q_hdmi_clk_1: out std_logic;
		q_hdmi_clk_2: out std_logic;
		q_hdmi_clk_3: out std_logic;		
		q_hdmi_0: out std_logic; -- output to downstream HDMI 0
		q_hdmi_0b: out std_logic;
		q_hdmi_1: out std_logic; -- output to downstream HDMI 1
		q_hdmi_1b: out std_logic;
		q_hdmi_2: out std_logic; -- output to upstream HDMI 2
		q_hdmi_3: out std_logic; -- output to downstream HDMI 3
		d_hdmi_2: in std_logic;
		q_sfp_p: out std_logic;
		q_sfp_n: out std_logic;
		d_cdr_p: in std_logic;
		d_cdr_n: in std_logic;
		sfp_los: in std_logic;
		sfp_fault: in std_logic;
		sfp_tx_dis: out std_logic;
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
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
		
	mac_addr <= X"020ddba11640"; -- Careful here, arbitrary addresses do not always work
	ip_addr <= X"c0a8c840"; -- 192.168.200.64

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.payload
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
			clk125 => clk125,
			clk_p => clk_p,
			clk_n => clk_n,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			trig_in_p => trig_in_p,
			trig_in_n => trig_in_n,
			q_hdmi_clk_0 => q_hdmi_clk_0,
			q_hdmi_clk_1 => q_hdmi_clk_1,
			q_hdmi_clk_2 => q_hdmi_clk_2,
			q_hdmi_clk_3 => q_hdmi_clk_3,			
			q_hdmi_0 => q_hdmi_0,
			q_hdmi_0b => q_hdmi_0b,
			q_hdmi_1 => q_hdmi_1,
			q_hdmi_1b => q_hdmi_1b,
			q_hdmi_2 => q_hdmi_2,
			q_hdmi_3 => q_hdmi_3,
			d_hdmi_2 => d_hdmi_2,
			q_sfp_p => q_sfp_p,
			q_sfp_n => q_sfp_n,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			sfp_los => sfp_los,
			sfp_fault => sfp_fault,
			sfp_tx_dis => sfp_tx_dis,
			cdr_lol => cdr_lol,
			cdr_los => cdr_los,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c
		);

end rtl;
