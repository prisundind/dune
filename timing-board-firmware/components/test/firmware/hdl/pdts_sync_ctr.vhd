-- pdts_sync_ctr
--
-- Counts received sync commands
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.pdts_defs.all;

entity pdts_sync_ctr is
	port(
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		d: in std_logic_vector(3 downto 0);
		v: in std_logic
	);

end pdts_sync_ctr;

architecture rtl of pdts_sync_ctr is

	type sctr_t is array(15 downto 0) of unsigned(31 downto 0);
	signal sctr: sctr_t;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sctr <= (others => (others => '0'));
			else
				for i in 15 downto 0 loop
					if d = std_logic_vector(to_unsigned(i, 4)) and v = '1' then
						if sctr(i) /= X"FFFFFFFF" then
							sctr(i) <= sctr(i) + 1;
						end if;
					end if;
				end loop;
			end if;
		end if;
	end process;

	ipb_out.ipb_rdata <= std_logic_vector(sctr(to_integer(unsigned(ipb_in.ipb_addr(3 downto 0)))));
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
	
end rtl;
