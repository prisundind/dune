-- pdts_ts_bcast
--
-- Generates time stamp sync commands
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;
use work.pdts_master_defs.all;

entity pdts_ts_bcast is
	port(
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end pdts_ts_bcast;

architecture rtl of pdts_ts_bcast is

	signal dctr: unsigned(31 downto 0);
	signal cap: std_logic_vector(8 * (TSTAMP_WDS + 1) - 1 downto 0);
	signal ctr: unsigned(3 downto 0);
	signal sync, go, done: std_logic;

begin
	
-- Timestamp trigger

	process(clk)
	begin
	   if rising_edge(clk) then
    		if rst = '1' or sync = '1' then
	       	dctr <= (others => '0');
		    else
			    dctr <= dctr + 1;
		    end if;
	   end if;
	end process;
	
	sync <= '1' when dctr = TS_DIV - 1 else '0';
	
-- Sending packet

	go <= sync and scmd_in.ack;
	
-- Capture

	cap(cap'left downto 8) <= tstamp when go = '1' and rising_edge(clk);
	cap(7 downto 0) <= (7 downto SCMD_W => '0') & SCMD_SYNC;
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ctr <= X"0";
			elsif scmd_in.ren = '1' then
				if done = '1' then
					ctr <= X"0";
				else
					ctr <= ctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	done <= '1' when ctr = TSTAMP_WDS else '0';

-- Output

	scmd_out.d <= cap(8 * (to_integer(ctr) + 1) - 1 downto 8 * to_integer(ctr));
	scmd_out.req <= sync;
	scmd_out.last <= done;

end rtl;
