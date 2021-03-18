-- prbs7_chk_noctr
--
-- PRBS7 checker
--
-- Dave Newbold, December 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity prbs7_chk_noctr is
	port(	
		clk: in std_logic;
		rst: in std_logic;
		init: in std_logic;
		d: in std_logic;
		err: out std_logic;
		zflag: out std_logic
	);

end prbs7_chk_noctr;

architecture rtl of prbs7_chk_noctr is

	signal ctr: unsigned(2 downto 0);
	signal dd, q, done, load, rst_d, z: std_logic;
	
begin

	process(clk)
	begin
		if rising_edge(clk) then
			dd <= d;
			rst_d <= rst;
			load <= ((load and not done) or (init or rst_d)) and not rst;
			z <= (z or d) and not (rst or init);
			if load = '1' then
				ctr <= ctr + 1;
			else
				ctr <= "000";
			end if;
			if dd /= q then
				err <= '1';
			else
				err <= '0';
			end if;
		end if;
	end process;
	
	done <= '1' when ctr = "111" else '0';
	
	prbs: entity work.prbs7_ser
		port map(
			clk => clk,
			rst => rst,
			load => load,
			d => d,
			q => q
		);

	zflag <= z;
		
end rtl;
