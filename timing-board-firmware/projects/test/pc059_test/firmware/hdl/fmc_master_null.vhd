-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;

library unisim;
use unisim.VComponents.all;

entity payload is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk125: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		d_p: in std_logic_vector(7 downto 0); -- data from fanout SFPs
		d_n: in std_logic_vector(7 downto 0);
		q_p: out std_logic; -- output to fanout
		q_n: out std_logic;
		sfp_los: in std_logic_vector(7 downto 0); -- fanout SFP LOS
		d_cdr_p: in std_logic; -- data input from CDR
		d_cdr_n: in std_logic;
		clk_cdr_p: in std_logic; -- clock from CDR
		clk_cdr_n: in std_logic;
		cdr_los: in std_logic; -- CDR LOS
		cdr_lol: in std_logic; -- CDR LOL
		inmux: out std_logic_vector(2 downto 0); -- mux control
		rstb_i2cmux: out std_logic; -- reset for mux
		d_hdmi_p: in std_logic; -- data from upstream HDMI
		d_hdmi_n: in std_logic;	
		q_hdmi_p: out std_logic; -- output to upstream HDMI
		q_hdmi_n: out std_logic;
		d_usfp_p: in std_logic; -- input from upstream SFP
		d_usfp_n: in std_logic;		
		q_usfp_p: out std_logic; -- output to upstream SFP
		q_usfp_n: out std_logic;
		usfp_fault: in std_logic; -- upstream SFP fault
		usfp_los: in std_logic; -- upstream SFP LOS
		usfp_txdis: out std_logic; -- upstream SFP tx_dis
		usfp_sda: inout std_logic; -- upstream SFP I2C
		usfp_scl: out std_logic;
		ucdr_los: in std_logic; -- upstream CDR LOS
		ucdr_lol: in std_logic; -- upstream CDR LOL
		ledb: out std_logic_vector(2 downto 0); -- FMC LEDs
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders
		gpio_p: out std_logic_vector(2 downto 0); -- GPIO
		gpio_n: out std_logic_vector(2 downto 0)
	);

end payload;

architecture rtl of payload is

	signal clk_u, clk, clk_cdr_u, clk_cdr, clko, clko_cdr, p: std_logic;
			
begin

	ipb_out <= IPB_RBUS_NULL;	
	nuke <= '0';
	soft_rst <= '0';
	userled <= '0';
	
-- Clock input

	ibufg_0: IBUFGDS
		port map(
			i => clk_p,
			ib => clk_n,
			o => clk_u
		);
		
	bufg_0: BUFG
		port map(
			i => clk_u,
			o => clk
		);

	ibufg_1: IBUFGDS
		port map(
			i => clk_cdr_p,
			ib => clk_cdr_n,
			o => clk_cdr_u
		);
		
	bufg_1: BUFG
		port map(
			i => clk_cdr_u,
			o => clk_cdr
		);

-- PRBS gen
		
	prbs: entity work.prbs7_ser
		port map(
			clk => clk,
			rst => '0',
			load => '0',
			d => '0',
			q => p
		);
		
-- Clock copy

	oddr_clk: ODDR
		port map(
			q => clko,
			c => clk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	oddr_clk_cdr: ODDR
		port map(
			q => clko_cdr,
			c => clk_cdr,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
-- Outputs
	
	obufds_0: OBUFDS
		port map(
			i => p,
			o => q_p,
			ob => q_n
		);
		
	obufds_1: OBUFDS
		port map(
			i => p,
			o => q_hdmi_p,
			ob => q_hdmi_n
		);
	
	obufds_2: OBUFDS
		port map(
			i => p,
			o => q_usfp_p,
			ob => q_usfp_n
		);
		
	obufds_g0: OBUFDS
		port map(
			i => clko,
			o => gpio_p(0),
			ob => gpio_n(0)
		);

--	obuf_g0: OBUF
--		port map(
--			i => clko,
--			o => gpio_p(0)
--		);

--	gpio_n(0) <= '0';

	obufds_g1: OBUFDS
		port map(
			i => clko_cdr,
			o => gpio_p(1),
			ob => gpio_n(1)
		);

--	obuf_g1: OBUF
--		port map(
--			i => clko_cdr,
--			o => gpio_p(1)
--		);

--	gpio_n(1) <= '1';
	
	obufds_g2: OBUFDS
		port map(
			i => p,
			o => gpio_p(2),
			ob => gpio_n(2)
		);
		
--	gpio_p(2) <= p;
--	gpio_n(2) <= p;

-- Unused outputs
		
	rstb_clk <= '1'; -- active low
	inmux <= "000";
	rstb_i2cmux <= '1'; -- active low
	
	usfp_txdis <= '0';
	usfp_sda <= '0';
	usfp_scl <= '0';
	ledb <= "010";
	scl <= '0';
	sda <= '0';
	rstb_i2c <= '1'; -- active low

-- Unused inputs

	bgen: for i in 7 downto 0 generate
		
		ibufds_bgen: IBUFDS
			port map(
				i => d_p(i),
				ib => d_n(i),
				o => open
			);
	
	end generate;
	
	ibufds_0: IBUFDS
		port map(
			i => d_cdr_p,
			ib => d_cdr_n,
			o => open
		);
		
	ibufds_1: IBUFDS
		port map(
			i => d_hdmi_p,
			ib => d_hdmi_n,
			o => open
		);
		
	ibufds_2: IBUFDS
		port map(
			i => d_usfp_p,
			ib => d_usfp_n,
			o => open
		);	
		
end rtl;
