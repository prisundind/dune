-- tb_tx_sim
--
-- Testbench for basic tx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.pdts_defs.all;

entity tb_tx_sim_tstamp is
	port(
		q: out std_logic
	);
		
end tb_tx_sim_tstamp;

architecture rtl of tb_tx_sim_tstamp is

	signal sclk, clk, rst, stb, fclk: std_logic;
	signal trig: std_logic;
	signal tx_d, tx_s_d, d: std_logic_vector(7 downto 0);
	signal tx_last, tx_ack, tx_rdy, tx_s_v, tx_stb, k, tx_q: std_logic;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal evtctr: unsigned(8 * EVTCTR_WDS - 1 downto 0);
	signal ts_v, ts_last, ts_ack, ts_ren, tsc_v, tsc_last, tsc_ack: std_logic;
	signal ts_d, tsc_d: std_logic_vector(7 downto 0);

begin

-- Clock, reset, strobe

	clkgen: entity work.tb_sim_clk
		port map(
			sclk => sclk,
			clk => clk,
			rst => rst,
			stb => stb,
			fclk => open,
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

-- Counters

	trig <= '1' when tstamp(8 downto 0) = "100010000" else '0';

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				evtctr <= (others => '0');
			else
				if trig = '1' then
					evtctr <= evtctr + 1;
				end if;
			end if;
		end if;
	end process;
	
-- Timestamp tx
		
	sync: entity work.pdts_ts_gen			
		port map(
			clk => clk,
			rst => rst,
			clr => '0',
			tstamp => tstamp,
			evtctr => std_logic_vector(evtctr),
			div => "00110",
			d => ts_d,
			v => ts_v,
			last => ts_last,
			ack => ts_ack,
			ren => ts_ren
		);
		
-- Command gen

	gen: entity work.pdts_trig_gen
		port map(
			clk => clk,
			rst => rst,
			trig => trig,
			d => tsc_d,
			v => tsc_v,
			last => tsc_last,
			ack => tsc_ack,
			ren => ts_ren
		);
		
-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => 2
		)
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
			rdy => tx_rdy,
			d(7 downto 0) => tsc_d,
			d(15 downto 8) => ts_d,
			dv(0) => tsc_v,
			dv(1) => ts_v,
			last(0) => tsc_last,
			last(1) => ts_last,
			ack(0) => tsc_ack,
			ack(1) => ts_ack,
			ren => ts_ren,
			typ => open,
			tv => open,
			grp => X"F",
			q => tx_s_d,
			v => tx_s_v
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
