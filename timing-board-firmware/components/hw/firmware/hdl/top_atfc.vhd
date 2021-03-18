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
        eth_clk_p: in std_logic; -- 125MHz MGT clock
        eth_clk_n: in std_logic;
        eth_rx_p: in std_logic; -- Ethernet MGT input
        eth_rx_n: in std_logic;
        eth_tx_p: out std_logic; -- Ethernet MGT output
        eth_tx_n: out std_logic;
        sfp_los: in std_logic;
        sfp_tx_disable: out std_logic;
        leds: out std_logic_vector(7 downto 0); -- TE712 LEDs
        --dip_sw: in std_logic_vector(3 downto 0); -- carrier switches
		fmc_clk_p: in std_logic;
		fmc_clk_n: in std_logic;
		rec_clk_p: in std_logic;
		rec_clk_n: in std_logic;
		rec_d_p: in std_logic;
		rec_d_n: in std_logic;
		clk_out_p: out std_logic;
		clk_out_n: out std_logic;
		rj45_din_p: in std_logic;
		rj45_din_n: in std_logic;
		rj45_dout_p: out std_logic;
		rj45_dout_n: out std_logic;
		sfp_dout_p: out std_logic;
		sfp_dout_n: out std_logic;
		pll_rstn: out std_logic;
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		--sfp_los: in std_logic;
		--sfp_tx_dis: out std_logic;
		sfp_flt: in std_logic;
		uid_scl: out std_logic;
		uid_sda: inout std_logic;
		sfp_scl: out std_logic;
		sfp_sda: inout std_logic;
		pll_scl: out std_logic;
		pll_sda: inout std_logic;
		gpin_0_p: in std_logic;
		gpin_0_n: in std_logic;
		gpout_0_p: out std_logic;
		gpout_0_n: out std_logic;
		gpout_1_p: out std_logic;
		gpout_1_n: out std_logic
	   );

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, nuke, soft_rst, phy_rst_e, userled, clk125: std_logic;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal infra_leds: std_logic_vector(1 downto 0);
	
begin

-- Infrastructure

	infra: entity work.atfc_infra -- Should work for artix also...
		port map(
			            eth_clk_p => eth_clk_p,
                        eth_clk_n => eth_clk_n,
                        eth_tx_p => eth_tx_p,
                        eth_tx_n => eth_tx_n,
                        eth_rx_p => eth_rx_p,
                        eth_rx_n => eth_rx_n,
                        sfp_los => sfp_los,
                        clk_ipb_o => clk_ipb,
                        rst_ipb_o => rst_ipb,
                        clk125_o => open,
                        rst125_o => open,
                        clk200 => open,
                        pllclk => open,
                        pllrefclk => open,
                        nuke => nuke,
                        soft_rst => soft_rst,
                        leds => infra_leds,
                        debug => open,
                        mac_addr => mac_addr,
                        ip_addr => ip_addr,
                        ipb_in => ipb_in,
                        ipb_out => ipb_out
		);
		
        leds <= userled & "11" & "11" & userled & infra_leds; -- Turning on green LED will lead to blindness
        --sfp_tx_disable <= '0';
		
        mac_addr <= X"020ddba11511"; -- Careful here, arbitrary addresses do not always work
        ip_addr <= X"c0a8c821"; -- 192.168.200.33
        --mac_addr <= X"020ddba1158" & dip_sw; -- Careful here, arbitrary addresses do not always work
        --ip_addr <= X"c0a8eb8" & dip_sw; -- 192.168.200.16+n
        

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.payload
		generic map(
			CARRIER_TYPE => X"03"
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
			fmc_clk_p => fmc_clk_p,
			fmc_clk_n => fmc_clk_n,
			rec_clk_p => rec_clk_p,
			rec_clk_n => rec_clk_n,
			rec_d_p => rec_d_p,
			rec_d_n => rec_d_n,
			clk_out_p => clk_out_p,
			clk_out_n => clk_out_n,
			rj45_din_p => rj45_din_p,
			rj45_din_n => rj45_din_n,
			rj45_dout_p => rj45_dout_p,
			rj45_dout_n => rj45_dout_n,
			sfp_dout_p => sfp_dout_p,
			sfp_dout_n => sfp_dout_n,
			cdr_lol => cdr_lol,
			cdr_los => cdr_los,
			sfp_los => sfp_los,
			sfp_tx_dis => sfp_tx_disable,
			--sfp_tx_dis => open,
			sfp_flt => sfp_flt,
			uid_scl => uid_scl,
			uid_sda => uid_sda,
			sfp_scl => sfp_scl,
			sfp_sda => sfp_sda,
			pll_scl => pll_scl,
			pll_sda => pll_sda,
			pll_rstn => pll_rstn,
			gpin_0_p => gpin_0_p,
			gpin_0_n => gpin_0_n,
			gpout_0_p => gpout_0_p,
			gpout_0_n => gpout_0_n,
			gpout_1_p => gpout_1_p,
			gpout_1_n => gpout_1_n
		);

end rtl;
