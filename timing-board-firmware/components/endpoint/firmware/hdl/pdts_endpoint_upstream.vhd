-- pdts_endpoint_upstream
--
-- The timing endpoint design - version for receiving data upstream, from trigger or via timing network
--
-- This part omits the MMCM and uses the 'upstream mode' alignment to save resources
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_endpoint_upstream is
	generic(
		SCLK_FREQ: real := 50.0; -- Frequency (MHz) of the supplied sclk
		SIM: boolean := false
	);
	port(
		sclk: in std_logic; -- Free-running system clock
		srst: in std_logic; -- System reset (sclk domain)
		stat: out std_logic_vector(3 downto 0); -- Status output (sclk domain)
		rec_clk: in std_logic; -- CDR recovered clock from timing link
		rec_d: in std_logic; -- CDR recovered data from timing link (rec_clk domain)
		clk: in std_logic; -- 50MHz clock input
		rdy: out std_logic; -- Ready flag
		fdel: out std_logic_vector(3 downto 0);
		edge: out std_logic;
		scmd: out cmd_w; -- Sync command out
		acmd: out cmd_w -- Async command out
	);

end pdts_endpoint_upstream;

architecture rtl of pdts_endpoint_upstream is

	signal rec_rst, rxphy_aligned, clk_i, rxphy_rst, rxphy_locked, rst_i: std_logic;
	signal rx_err: std_logic_vector(2 downto 0);
	signal stb, k, s_first, a_first: std_logic;
	signal d, dr: std_logic_vector(7 downto 0);

begin

	clk_i <= clk;

-- Startup controller

	startup: entity work.pdts_ep_startup
		generic map(
			SCLK_FREQ => SCLK_FREQ,
			SIM => SIM,
			NEED_ADJUST => false,
			NEED_TSTAMP => false
		)
		port map(
			sclk => sclk,
			srst => srst,
			stat => stat,
			sfp_los => '0',
			cdr_los => '0',
			cdr_lol => '0',
			adj_req => '0',
			adj_ack => open,
			rec_clk => rec_clk,
			rec_rst => rec_rst,
			rxphy_aligned => rxphy_aligned,
			mclk => rec_clk,
			clk => clk_i,
			rxphy_rst => rxphy_rst,
			rxphy_locked => rxphy_locked,
			rst => rst_i,
			rx_err => rx_err,
			tsrdy => '0'
		);

-- Rx PHY

	rxphy: entity work.pdts_rx_phy
		generic map(
			UPSTREAM_MODE => true
		)
		port map(
			rxclk => rec_clk,
			rxd => rec_d,
			fdel_out => fdel,
			edge => edge,
			clk => clk_i,
			rec_rst => rec_rst,
			rst => rxphy_rst,
			aligned => rxphy_aligned,
			rx_locked => rxphy_locked,
			q => d,
			k => k,
			stbo => stb
		);
		
-- Rx

	rx: entity work.pdts_rx
		generic map(
			NO_TGRP => true
		)
		port map(
			clk => clk_i,
			rst => rst_i,
			stb => stb,
			tgrp => "00",
			addr => X"00",
			d => d,
			k => k,
			q => dr,
			s_stb => open,
			s_first => s_first,
			a_stb => open,
			a_first => a_first,
			err => rx_err
		);

	scmd.d <= dr;
	scmd.req <= s_first;
	scmd.last <= '1'; -- Single word commands only on return channel (for now)

	acmd.d <= dr;
	acmd.req <= a_first;
	acmd.last <= '0'; -- Need to find a better solution for this
	
	rdy <= rxphy_locked when rx_err = "000" else '0';
		
end rtl;
