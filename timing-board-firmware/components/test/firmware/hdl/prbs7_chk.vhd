-- prbs7_chk.vhd
--
-- PRBS7 checker
--
-- Dave Newbold, December 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity prbs7_chk is
	port(	
		clk: in std_logic;
		rst: in std_logic;
		init: in std_logic;
		d: in std_logic;
		err_ctr: out std_logic_vector(47 downto 0);
		cyc_ctr: out std_logic_vector(47 downto 0);
		zflag: out std_logic
	);

end prbs7_chk;

architecture rtl of prbs7_chk is

	signal err_ctr_i, cyc_ctr_i: unsigned(47 downto 0);
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
				err_ctr_i <= (others => '0');
				cyc_ctr_i <= (others => '0');
			else
				ctr <= "000";
				if dd /= q then
					err_ctr_i <= err_ctr_i + 1;
				end if;
				cyc_ctr_i <= cyc_ctr_i + 1;
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

	err_ctr <= std_logic_vector(err_ctr_i);
	cyc_ctr <= std_logic_vector(cyc_ctr_i);
	zflag <= z;
		
end rtl;
