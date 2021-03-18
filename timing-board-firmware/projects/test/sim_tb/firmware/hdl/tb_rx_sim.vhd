-- tb_rx_sim
--
-- Testbench for basic rx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.pdts_defs.all;

entity tb_rx_sim is
	port(
		d: in std_logic
	);
		
end tb_rx_sim;

architecture rtl of tb_rx_sim is

	signal sclk, clk, rst, phase_rst, phase_locked, fclk: std_logic;
	signal kr, stb: std_logic;
	signal dr, rx_d: std_logic_vector(7 downto 0);
	signal aligned, rxl, rx_rst, s_valid, s_first, xrst: std_logic;
	
begin

-- Clock, reset, strobe

	clkgen: entity work.tb_sim_clk
		port map(
			sclk => sclk,
			clk => clk,
			rst => rst,
			stb => open,
			fclk => fclk,
			phase_rst => phase_rst,
			phase_locked => phase_locked
		);
	
-- Rx PHY

	xrst <= not aligned when rising_edge(clk);

	rxphy: entity work.pdts_rx_phy
		port map(
			fclk => fclk,
			frst => rst,
			rxclk => sclk,
			rxd => d,
			phase_rst => phase_rst,
			phase_locked => phase_locked,
			aligned => aligned,			
			clk => clk,
			rst => xrst,
			rx_locked => rxl,
			q => dr,
			k => kr,
			stbo => stb
		);

-- Rx

	rx_rst <= rst or not rxl;

	rx: entity work.pdts_rx
		port map(
			clk => clk,
			rst => rx_rst,
			stb => stb,
			grp => "00",
			addr => X"01",
			d => dr,
			k => kr,
			q => rx_d,
			s_valid => s_valid,
			s_first => s_first,
			a_valid => open,
			a_last => open,
			err => open
		);
		
-- Counters

	ctrs: entity work.pdts_sync_ctr
		port map(
			ipb_in => IPB_WBUS_NULL,
			ipb_out => open,
			clk => clk,
			rst => rx_rst,
			d => rx_d(3 downto 0),
			v => s_valid
		);
		
-- Timestamp

	ts: entity work.pdts_tstamp
		port map(
			clk => clk,
			rst => rx_rst,
			d => rx_d,
			s_valid => s_valid,
			s_first => s_first,
			tstamp => open,
			evtctr => open,
			rdy => open
		);

end rtl;
