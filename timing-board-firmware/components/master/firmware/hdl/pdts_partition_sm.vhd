-- pdts_partition_sm
--
-- Run control state machine for partition
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity pdts_partition_sm is
	port(
		clk: in std_logic;
		rst: in std_logic;
		part_en_req: in std_logic;
		run_req: in std_logic;
		spill: in std_logic;
		scmd_out: out cmd_w;
		scmd_in: in cmd_r;
		part_en: out std_logic;
		run: out std_logic
	);

end pdts_partition_sm;

architecture rtl of pdts_partition_sm is

	type state_t is (DIS, EN, W_START, RUNNING, W_STOP);
	signal state: state_t;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state <= DIS;
			elsif spill = '0' then
				case state is
-- Partition disabled
				when DIS =>
					if part_en_req = '1' then
						state <= EN;
					end if;
-- Partition enabled
				when EN =>
					if part_en_req = '0' then
						state <= DIS;
					elsif run_req = '1' then
						state <= W_START;
					end if;
-- Wait for start command
				when W_START =>
					if scmd_in.ack = '1' then 
						state <= RUNNING;
					end if;
-- Wait for frequency match
				when RUNNING =>
					if run_req = '0' or part_en_req = '0' then
						state <= W_STOP;
					end if;
-- Wait for rxphy lock
				when W_STOP =>
					if scmd_in.ack = '1' then
						state <= EN;
					end if;
				end case;
			end if;
		end if;
	end process;
	
	scmd_out.d <= (7 downto SCMD_W => '0') & SCMD_RUN_START when state = W_START else (7 downto SCMD_W => '0') & SCMD_RUN_STOP;
	scmd_out.req <= '1' when (state = W_START or state = W_STOP) and spill = '0' else '0';
	scmd_out.last <= '1';
	
	part_en <= '0' when state = DIS else '1';
	run <= '1' when state = RUNNING else '0';

end rtl;
