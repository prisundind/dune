-- mmcm_test
--
-- Testing the 'brute force' method of MMCM phase alignment
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity mmcm_test is
	port(
		clk_ipb: in std_logic; -- ipbus clock
		rst_ipb: in std_logic; -- ipbus reset
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic -- 50MHz
	);

end mmcm_test;

architecture rtl of mmcm_test is

	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal mmcm_rst_0, locked_0, clk_in_u, clk_in, clkfb_0, clk100, clk250, clk100_b: std_logic;
	signal mmcm_rst_1, rst_s, locked_1, clkfb_1, clk50x, clk50x_b, clk250x, clk250x_b: std_logic;
	signal t: std_logic;
	signal tr, tx: std_logic_vector(9 downto 0);
	signal sync_en, done, match: std_logic;
	signal ctr: unsigned(5 downto 0);

begin

	reg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk_ipb,
			reset => rst_ipb,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl,
			stb => open
		);
		
	mmcm_rst_0 <= ctrl(0)(0);
	mmcm_rst_1 <= ctrl(0)(1);
	sync_en <= ctrl(0)(2);
	stat(0) <= X"000" & "00" & tx & "0000" & done & match & locked_1 & locked_0;

	ibufgds0: IBUFG port map(
		i => clk,
		o => clk_in_u
	);

	bufg_clk_in: BUFG port map(
		i => clk_in_u,
		o => clk_in
	);
	
	mmcm0: MMCME2_BASE -- From 50 to 250
		generic map(
			CLKIN1_PERIOD => 20.0,
			CLKFBOUT_MULT_F => 20.0,
			CLKOUT0_DIVIDE_F => 10.0,
			CLKOUT1_DIVIDE => 2
		)
		port map(
			clkin1 => clk_in,
			clkfbin => clkfb_0,
			clkout0 => clk100,
			clkout1 => clk250,
			clkfbout => clkfb_0,
			locked => locked_0,
			rst => mmcm_rst_0,
			pwrdwn => '0'
		);
		
	bufg100: BUFG port map(
		i => clk100,
		o => clk100_b
	);

	t <= (not t) and locked_0 when rising_edge(clk100_b);

	mmcm1: MMCME2_BASE -- From 250 to 50
		generic map(
			CLKIN1_PERIOD => 2.0,
			CLKFBOUT_MULT_F => 2.0,
			CLKOUT0_DIVIDE_F => 20.0,
			CLKOUT1_DIVIDE => 2
		)
		port map(
			clkin1 => clk250,
			clkfbin => clkfb_1,
			clkout0 => clk50x,
			clkout1 => clk250x,
			clkfbout => clkfb_1,
			locked => locked_1,
			rst => rst_s,
			pwrdwn => '0'
		);
		
	bufg50x: BUFG port map(
		i => clk50x,
		o => clk50x_b
	);
	
	bufg250: BUFG port map(
		i => clk250x,
		o => clk250x_b
	);

	tr <= tr(8 downto 0) & t when rising_edge(clk250x_b);
	tx <= tr when rising_edge(clk50x_b);
	
	process(clk_in)
	begin
		if rising_edge(clk_in) then
			if locked_1 = '0' then
				ctr <= (others => '0');
			elsif done = '0' then
				ctr <= ctr + 1;
			end if;
		end if;
	end process;
	
	done <= and_reduce(std_logic_vector(ctr));
	match <= '1' when tx = "0000011111" else '0';
	rst_s <= mmcm_rst_1 or (sync_en and done and not match);
	
end rtl;
