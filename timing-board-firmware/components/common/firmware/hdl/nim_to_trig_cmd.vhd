-- nim_to_trig_cmd
--
-- Generates trigger command based on external spill gate signal
--
-- David Cussans, December 2018
-- Based on "spill_gate.vhd" Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
-- use work.ipbus_decode_spill.all;

use work.pdts_defs.all;

entity nim_to_trig_cmd is
	port(
		clk: in std_logic;
		rst: in std_logic;
		nim_trig_signal: in std_logic;
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end nim_to_trig_cmd;

architecture rtl of nim_to_trig_cmd is


	signal ss, ss_d, ss_i: std_logic;
        attribute mark_debug: string;
        attribute mark_debug of rst , nim_trig_signal, scmd_out , ss_i: signal is "true";

begin

-- Debounce of external signals

	debounce: entity work.pdts_debounce
		generic map(
			N => 1
		)
		port map(
			clk => clk,
			rst => rst,
			d(0) => nim_trig_signal,
			q(0) => ss
		);
		
	ss_d <= ss when rising_edge(clk);
	
	ss_i <= ss and not ss_d;

-- Command generator

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or ss_i = '0' then
				scmd_out <= CMD_W_NULL;
			else
				if ss_i = '1'  then
					scmd_out.d <= X"0" & SCMD_TRIG_BEAM;
				end if;
				scmd_out.req <= '1';
				scmd_out.last <= '1';
			end if;
		end if;
	end process;


end rtl;
