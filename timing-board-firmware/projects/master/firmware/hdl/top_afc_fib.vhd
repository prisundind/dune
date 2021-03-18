-- Top-level design for ipbus demo
--
-- This version is for AFC module
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, 4/10/16

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.ALL;

entity top is port(
--		leds: out std_logic_vector(3 downto 0); -- status LEDs
		eth_clk_p: in std_logic; -- 125MHz MGT clock
		eth_clk_n: in std_logic;
		eth_rx_p: in std_logic; -- Ethernet MGT input
		eth_rx_n: in std_logic;
		eth_tx_p: out std_logic; -- Ethernet MGT output
		eth_tx_n: out std_logic;
		
		clk_bp_p: in std_logic; -- clock from backplane
		clk_bp_n: in std_logic;

		clk_pll_p: in std_logic;
		clk_pll_n: in std_logic;
		
		clk_cdr_p: in std_logic;
		clk_cdr_n: in std_logic;
		
		d_bp_p: in std_logic; -- data from backplane
		d_bp_n: in std_logic;

		d_sfp_p: in std_logic_vector(3 downto 0); 
		d_sfp_n: in std_logic_vector(3 downto 0);

		d_cdr_p: in std_logic; -- data input from CDR (via MUX)
		d_cdr_n: in std_logic;

		q_sfp_p: out std_logic_vector(7 downto 0); -- output to fanout (downstream)
		q_sfp_n: out std_logic_vector(7 downto 0);

		q_bp_p: out std_logic; -- data to backplane
		q_bp_n: out std_logic;

		inmux: out std_logic_vector(2 downto 0); -- mux control

		scl: out std_logic;
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders

		sfp_scl: out std_logic_vector(7 downto 0); -- fan-out sfp control
		sfp_sda: inout std_logic_vector(7 downto 0);
		pll_rstn: out std_logic -- temp, needed to keep PLL from resetting on FMC
	);

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, nuke, soft_rst, phy_rst_e, userled, clk125: std_logic;
	signal addr: std_logic_vector(3 downto 0);
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal inf_leds: std_logic_vector(1 downto 0);
	
begin
	
	pll_rstn <= '1';

-- Infrastructure
	infra: entity work.afc_infra 
	port map(
		eth_clk_p => eth_clk_p,
		eth_clk_n => eth_clk_n,
		eth_tx_p => eth_tx_p,
		eth_tx_n => eth_tx_n,
		eth_rx_p => eth_rx_p,
		eth_rx_n => eth_rx_n,
		clk_ipb_o => clk_ipb,
		rst_ipb_o => rst_ipb,
		clk125_o => clk125,
		rst125_o => phy_rst_e,
		nuke => nuke,
		soft_rst => soft_rst,
		leds => inf_leds,
		mac_addr(47 downto 0) => X"020ddba11410",
		ip_addr(31 downto 0) => X"c0a87964",
		ipb_in => ipb_in,
		ipb_out => ipb_out
	);

--	leds <= not ('0' & userled & inf_leds);

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.payload
		generic map(
			CARRIER_TYPE => X"04"
		)
		port map(
			ipb_clk => clk_ipb,
			ipb_rst => rst_ipb,
			ipb_in => ipb_out,
			ipb_out => ipb_in,
			nuke => nuke,
			soft_rst => soft_rst,
			userled => userled,
			addr => addr,
			clk125 => clk125,

			clk_bp_p => clk_bp_p,
			clk_bp_n => clk_bp_n,

			clk_pll_p => clk_pll_p,
			clk_pll_n => clk_pll_n,
			
			clk_cdr_p => clk_cdr_p,
			clk_cdr_n => clk_cdr_n,

			d_bp_p => d_bp_p,
			d_bp_n => d_bp_n,

			d_sfp_p => d_sfp_p,
			d_sfp_n => d_sfp_n,

			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,

			q_sfp_p => q_sfp_p,
			q_sfp_n => q_sfp_n,

			q_bp_p => q_bp_p,
			q_bp_n => q_bp_n,

			inmux => inmux,
			sfp_scl => sfp_scl,
			sfp_sda => sfp_sda,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c
		);

end rtl;

