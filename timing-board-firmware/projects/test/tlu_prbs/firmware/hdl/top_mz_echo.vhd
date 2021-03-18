-- Standalone endpoint top level design
--
-- Dave Newbold, 14/1/18

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity top is port(
		sysclk_p: in std_logic;
		sysclk_n: in std_logic;
		clk_in_p: in std_logic;
		clk_in_n: in std_logic;
		d_in_p: in std_logic;
		d_in_n: in std_logic;
		clk_out_p: out std_logic;
		clk_out_n: out std_logic;
		d_out_p: out std_logic;
		d_out_n: out std_logic;
		debug: out std_logic_vector(11 downto 0)
	);

end top;

architecture rtl of top is

	signal sysclk_u, sysclk: std_logic;
	signal clk_u, clk, d_in, dd, q: std_logic;
	signal clkout, clk_uf, clk_ug, clkfb2: std_logic;
	
begin

-- Clock and data in

	ibufg_sysclk: IBUFGDS
		port map(
			i => sysclk_p,
			ib => sysclk_n,
			o => sysclk_u
		);
		
	bufg_sysclk: BUFG
		port map(
			i => sysclk_u,
			o => sysclk
		);

	ibufg_clk: IBUFGDS
		port map(
			i => clk_in_p,
			ib => clk_in_n,
			o => clk_u
		);
	
	bufg_clk: BUFG
		port map(
			i => clk_u,
			o => clk_uf
		);
		
	ibufds_d: IBUFDS
		port map(
			i => d_in_p,
			ib => d_in_n,
			o => d_in
		);

-- Clock cleanup

	mmcm_f: MMCME2_BASE
		generic map(
			BANDWIDTH => "LOW",
			CLKIN1_PERIOD => 4.0, -- 250MHz input
			CLKFBOUT_MULT_F => 4.0, -- 1GHz VCO freq
			CLKOUT0_DIVIDE_F => 4.0 -- 250MHz output
		)
		port map(
			clkin1 => clk_uf,
			clkfbin => clkfb2,
			clkout0 => clk_ug,
			clkfbout => clkfb2,
			locked => open,
			rst => '0',
			pwrdwn => '0'
		);

	bufg_f: BUFG
		port map(
			i => clk_ug,
			o => clk
		);
		
-- Registers

	dd <= d_in when rising_edge(clk);
	q <=  dd when rising_edge(clk);

-- Clock and data out

	oddr_clk: ODDR
		port map(
			q => clkout,
			c => clk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_clk: OBUFDS
		port map(
			i => clkout,
			o => clk_out_p,
			ob => clk_out_n
		);
		
	obuf_d: OBUFDS
		port map(
			i => q,
			o => d_out_p,
			ob => d_out_n
		);

	debug <= (others => '0');
	
end rtl;
