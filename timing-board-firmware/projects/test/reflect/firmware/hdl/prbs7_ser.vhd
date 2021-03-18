-- prbs7_ser.vhd
--
-- PRBS7 serial bitstream generator using LFSR
--
-- Dave Newbold, December 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity prbs7_ser is
	port(
		clk: in std_logic;
		rst: in std_logic;
		load: in std_logic;
		d: in std_logic;
		q: out std_logic
	);

end prbs7_ser;

architecture rtl of prbs7_ser is

	signal r: std_logic_vector(6 downto 0);
	signal b: std_logic;
	
begin

	b <= r(6) xor r(5) when load = '0' else d;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				r <= "0000001";
			else
				r <= r(5 downto 0) & b;
			end if;
		end if;
	end process;

	q <= b when rising_edge(clk);
	
end rtl;
