-- pdts_rx_mul_mmcm
--
-- Clock mutliplier for tlu
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

library unisim;
use unisim.VComponents.all;

entity pdts_rx_mul_mmcm is
	port(
		clk: in std_logic;
		sclk: out std_logic;
--		clk10: out std_logic; Not working today
		ccpy: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);
		
end pdts_rx_mul_mmcm;

architecture rtl of pdts_rx_mul_mmcm is

	signal clkfbout, clkfbin, sclki, clk10u, ccpyi: std_logic;
	
begin

	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => 1000.0 / CLK_FREQ, -- System clock input
			CLKFBOUT_MULT_F => real(VCO_RATIO) * real(SCLK_RATIO) , -- Around 1GHz VCO freq
			CLKOUT0_DIVIDE_F => real(VCO_RATIO), -- IO clock output.
			CLKOUT1_DIVIDE => VCO_RATIO * SCLK_RATIO
--			CLKOUT2_DIVIDE => 100
		)
		port map(
			clkin1 => clk,
			clkfbin => clkfbin,
			clkout0 => sclki,
			clkout1 => ccpyi,
--			clkout2 => clk10u,
			clkfbout => clkfbout,
			locked => phase_locked,
			rst => phase_rst,
			pwrdwn => '0'
		);

	bufg0: BUFG
		port map(
			i => sclki,
			o => sclk
	);
	
	bufgfb: BUFG
		port map(
			i => clkfbout,
			o => clkfbin
	);

--	bufg10: BUFG
--		port map(
--			i => clk10u,
--			o => clk10
--		);

	bufgcp: BUFG
		port map(
			i => ccpyi,
			o => ccpy
	);

end rtl;
