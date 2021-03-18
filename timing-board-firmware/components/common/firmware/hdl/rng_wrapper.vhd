-- rng_wrapper
--
-- Wrapper for decent uniform 32b PRNG:
--
-- http://cas.ee.ic.ac.uk/people/dt10/research/rngs-fpga-lut_sr.html
--
-- Note that for reproducibility, we seed the RNG after every reset with an arbitrary 
-- hardwired pattern; a full seed load cycle is necessary to flush any state
-- from the RNG FIFOs.
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity rng_wrapper is
	port(
		clk: in std_logic;
		rst: in std_logic;
		random: out std_logic_vector(31 downto 0)
	);

end rng_wrapper;

architecture rtl of rng_wrapper is

	signal mode, s_in: std_logic;
	signal cnt: unsigned(9 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				cnt <= (others => '0');
				mode <= '1';
			elsif mode = '1' then
				cnt <= cnt + 1;
				if cnt = "1111111111" then
					mode <= '0';
				end if;
			end if;
		end if;
	end process;
	
	s_in <= cnt(3); -- Any seed value except zero will do
	
	rng: entity work.rng_n1024_r32_t5_k32_s1c48
		port map(
			clk => clk,
			ce => '1',
			mode => mode,
			s_in => s_in,
			rng => random
		);

end rtl;
