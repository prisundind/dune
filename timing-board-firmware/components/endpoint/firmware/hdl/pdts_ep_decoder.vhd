-- pdts_ep_decoder
--
-- Simple decoder to provide run and spill status signals from endpoint commands, plus the
-- event counter
--
-- Can be used as-is, or as an example of how to decode commands
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity pdts_ep_decoder is
	port(
		clk: in std_logic; -- 50MHz clock
		rst: in std_logic; -- Sync reset
		rdy: in std_logic; -- Timing system up flag
		scmd: in std_logic_vector(SCMD_W - 1 downto 0); -- Sync command input
		scmd_v: in std_logic; -- Sync command valid flag
		in_spill: out std_logic; -- Spill flag
		in_run: out std_logic; -- Run flag
		evtctr: out std_logic_vector(8 * EVTCTR_WDS - 1 downto 0) -- Event counter out
	);

end pdts_ep_decoder;

architecture rtl of pdts_ep_decoder is

	signal ins, inr: std_logic;
	signal evtctr_i: unsigned(8 * EVTCTR_WDS - 1 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or rdy = '0' then
				ins <= '0';
				inr <= '0';
				evtctr_i <= (others => '0');
			elsif scmd_v = '1' then
				if scmd = SCMD_SPILL_START then
					ins <= '1';
				elsif scmd = SCMD_SPILL_STOP then
					ins <= '0';
				elsif scmd = SCMD_RUN_START then
					inr <= '1';
					evtctr_i <= (others => '0');
				elsif scmd = SCMD_RUN_STOP then
					inr <= '0';
				elsif EVTCTR_MASK(to_integer(unsigned(scmd))) = '1' and inr = '1' then
					evtctr_i <= evtctr_i + 1;
				end if;
			end if;
		end if;
	end process;
	
	in_spill <= ins;
	in_run <= inr;
	evtctr <= std_logic_vector(evtctr_i);
		
end rtl;
