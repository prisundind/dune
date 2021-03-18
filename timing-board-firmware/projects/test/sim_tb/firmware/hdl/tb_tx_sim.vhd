-- tb_tx_sim
--
-- Testbench for basic tx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.pdts_defs.all;

entity tb_tx_sim is
	port(
		q: out std_logic
	);
		
end tb_tx_sim;

architecture rtl of tb_tx_sim is

	signal sclk, clk, rst, stb: std_logic;
	signal tx_d, tx_s_d, d: std_logic_vector(7 downto 0);
	signal tx_last, tx_ack, tx_rdy, tx_s_v, tx_stb, k, tx_q: std_logic;

	
begin

-- Clock, reset, strobe

	clkgen: entity work.tb_sim_clk
		port map(
			sclk => sclk,
			clk => clk,
			rst => rst,
			stb => stb,
			phase_rst => '0',
			phase_locked => open
		);
	
-- Pattern gen

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rst,
			d => tx_d,
			last => tx_last,
			ack => tx_ack
		);
		
	sync: entity work.pdts_sync_gen
		port map(
			ipb_in => IPB_WBUS_NULL,
			ipb_out => open,
			en => '1',
			clk => clk,
			rst => rst,
			stb => stb,
			d => tx_s_d,
			v => tx_s_v,
			rdy => tx_rdy
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
			addr => X"AA",
			s_d => tx_s_d,
			s_valid => tx_s_v,
			s_rdy => tx_rdy,
			a_d => tx_d,
			a_last => tx_last,
			a_ack => tx_ack,
			q => d,
			k => k,
			stbo => tx_stb,
			err => open
		);
		
-- Tx PHY

	txphy: entity work.pdts_tx_phy_int
		port map(
			clk => clk,
			rst => rst,
			d => d,
			k => k,
			stb => tx_stb,
			txclk => sclk,
			q => tx_q
		);
		
	q <= tx_q when rising_edge(sclk);

end rtl;
