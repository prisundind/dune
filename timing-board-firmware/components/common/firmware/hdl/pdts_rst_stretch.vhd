-- pdts_rst_stretch
--
-- Reset pulse stretcher for Xilinx FIFOs
--
-- See FIFO generator user guide for detail
-- Basically, need long reset pulse, no repeat for a few cycles, no we during reset
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity pdts_rst_stretch is
	port(
		clk: in std_logic;
		rst: in std_logic;
		rsto: out std_logic;
		wen: out std_logic
	);

end pdts_rst_stretch;

architecture rtl of pdts_rst_stretch is

	signal rst_ctr: unsigned(5 downto 0) := (others => '1');
	signal rsti: std_logic;          -- used to generate wen
        signal rst_short_i : std_logic;  -- used to generate rsto

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rst_ctr <= (others => '0');
			elsif rsti = '1' then -- count up until counter reaches
                                              -- 111111 , then stop
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;

	-- rsti goes high when rst_ctr reset to zero. The drops low when rst_ctr reaches 111111 
	rsti <= not and_reduce(std_logic_vector(rst_ctr));

        -- rst_short_i goes high when rst_ctr reset to zero. The drops low when rst_ctr reaches 011111 
        rst_short_i <= not and_reduce(std_logic_vector(rst_ctr(4 downto 0))) and (not rst_ctr(5));
        
	rsto <= rst_short_i and (rst_ctr(3) xor rst_ctr(4))  when rising_edge(clk); -- No glitches pls, used across clock domains
	wen <= not rsti when rising_edge(clk);

end rtl;
