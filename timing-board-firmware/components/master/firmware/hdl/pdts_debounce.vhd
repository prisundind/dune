-- pdts_debounce
--
-- Monitors lock status of external devices
--
-- Dave Newbold, April 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus_reg_types.all;

entity pdts_debounce is
	generic(
		N: positive := 1;
		WINDOW: positive := 16
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: in std_logic_vector(N - 1 downto 0);
		q: out std_logic_vector(N - 1 downto 0)
	);

end pdts_debounce;

architecture rtl of pdts_debounce is

	type ctrs_t is array(N - 1 downto 0) of unsigned(calc_width(WINDOW) - 1 downto 0);
	signal ctrs: ctrs_t;
	signal da, db, qi: std_logic_vector(N - 1 downto 0);
	
	attribute ASYNC_REG: string;
	attribute ASYNC_REG of da, db: signal is "yes";
	
begin

-- Sync reg

	da <= d when rising_edge(clk);
	db <= da when rising_edge(clk);
	
-- Debounce

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ctrs <= (others => (others => '0'));
				qi <= (others => '0');
			else
				for i in N - 1 downto 0 loop
					if db(i) = qi(i) then
						ctrs(i) <= (others => '0');
					else
						if and_reduce(std_logic_vector(ctrs(i))) = '1' then
							qi(i) <= not qi(i);
						end if;
						ctrs(i) <= ctrs(i) + 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	q <= qi;
	
end rtl;
