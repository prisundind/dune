-- pdts_tlu_io
--
-- Various functions for talking to the TLU board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_tlu_io.all;
use work.pdts_defs.all;

library unisim;
use unisim.VComponents.all;

entity pdts_tlu_io is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0);
		DESIGN_TYPE: std_logic_vector(7 downto 0)
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		soft_rst: out std_logic;
		nuke: out std_logic;
		rst: out std_logic;
		locked: in std_logic;
		clk_p: in std_logic; -- 50MHz master clock from PLL
		clk_n: in std_logic;
		clk: out std_logic; -- 50MHz system clock out
		mclk: in std_logic; -- 250MHz IO clock out
		rstb_clk: out std_logic; -- reset for PLL
		clk_lolb: in std_logic; -- PLL LOL
		trig_in_p: in std_logic_vector(5 downto 0);
		trig_in_n: in std_logic_vector(5 downto 0);
		trig_in: out std_logic_vector(5 downto 0);
		q_hdmi_clk_0: out std_logic; -- output to HDMI 0
		q_hdmi_clk_1: out std_logic; -- output to HDMI 1
		q_hdmi_clk_2: out std_logic; -- output to HDMI 2
		q_hdmi_clk_3: out std_logic; -- output to HDMI 3
		sync: in std_logic;
		q_hdmi_0: out std_logic; -- output to HDMI 0
		q_hdmi_0b: out std_logic; -- output to HDMI 0
		q_hdmi_1: out std_logic; -- output to HDMI 1
		q_hdmi_1b: out std_logic; -- output to HDMI 1
		q_hdmi: in std_logic;
		q_hdmi_2: out std_logic; -- output to HDMI 2
		q_hdmi_3: out std_logic; -- output to HDMI 3
		d_hdmi_2: in std_logic;
		d_hdmi: out std_logic;
		hdmi_edge: in std_logic;
		q_sfp: in std_logic;
		q_sfp_p: out std_logic;
		q_sfp_n: out std_logic;
		d_cdr_p: in std_logic;
		d_cdr_n: in std_logic;
		d_cdr: out std_logic;
		cdr_edge: in std_logic; -- CDR sampling edge control
		sfp_los: in std_logic;
		sfp_fault: in std_logic;
		sfp_tx_dis: out std_logic;
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
	);

end pdts_tlu_io;

architecture rtl of pdts_tlu_io is

	constant BOARD_TYPE: std_logic_vector(7 downto 0) := X"04";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_rst_lock_mon: std_logic;
	signal rst_i, clk_i, clk_u, mclk_i, mclk_u: std_logic;
	signal mmcm_bad, mmcm_ok, pll_bad, pll_ok, mmcm_lm, pll_lm: std_logic;
	signal d_hdmi_2_r, d_hdmi_2_f: std_logic;
	signal d_cdr_i, d_cdr_r, d_cdr_f, q_sfp_r, q_sfp_i: std_logic;
	signal clkdiv: std_logic_vector(0 downto 0);
	signal sda_o: std_logic;
	
  attribute IOB: string;
  attribute IOB of q_hdmi_0, q_hdmi_1, q_hdmi_2, q_sfp_i: signal is "TRUE";

begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
	generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_pdts_tlu_io(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	stat(0) <= X"00000" & cdr_los & cdr_lol & sfp_los & sfp_fault & "00" & pll_lm & mmcm_lm & "00" & pll_ok & mmcm_ok;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst_i <= ctrl(0)(2);
	rstb_clk <= not ctrl(0)(3);
	rstb_i2c <= not ctrl(0)(5);
	ctrl_rst_lock_mon <= ctrl(0)(6);
	
	rst <= rst_i;
	
	sfp_tx_dis <= '0';
	
-- Config info

	config: entity work.ipbus_roreg_v
		generic map(
			N_REG => 1,
			DATA(31 downto 24) => X"00",
			DATA(23 downto 16) => BOARD_TYPE,
			DATA(15 downto 8) => CARRIER_TYPE,
			DATA(7 downto 0) => DESIGN_TYPE
		)
		port map(
			ipb_in => ipbw(N_SLV_CONFIG),
			ipb_out => ipbr(N_SLV_CONFIG)
		);

-- Clocks
			
	ibufg_clk: IBUFGDS
		port map(
			i => clk_p,
			ib => clk_n,
			o => clk_u
		);
		
	bufg_clk: BUFG
		port map(
			i => clk_u,
			o => clk_i
		);
		
	clk <= clk_i;
		
-- Clock lock monitor

	mmcm_bad <= not locked;
	pll_bad <= not clk_lolb;

	chk: entity work.pdts_chklock
		generic map(
			N => 2
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			los(0) => mmcm_bad,
			los(1) => pll_bad,
			ok(0) => mmcm_ok,
			ok(1) => pll_ok,
			ok_sticky(0) => mmcm_lm,
			ok_sticky(1) => pll_lm
		);

-- Trigger inputs (no IOB registers, we don't care much about timing)

	tigen: for i in 5 downto 0 generate
	
		ibufds_ti: IBUFDS
			port map(
				i => trig_in_p(i),
				ib => trig_in_n(i),
				o => trig_in(i)
			);
			
	end generate;
		
-- Data inputs

	ibufds_cdr: IBUFDS
		port map(
			i => d_cdr_p,
			ib => d_cdr_n,
			o => d_cdr_i
		);
		
	iddr_cdr: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_cdr_r,
			q2 => d_cdr_f,
			c => mclk,
			ce => '1',
			d => d_cdr_i,
			r => '0',
			s => '0'
		);
		
	d_cdr <= d_cdr_r when cdr_edge = '0' else d_cdr_f;

	iddr_hdmi: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_hdmi_2_r,
			q2 => d_hdmi_2_f,
			c => mclk,
			ce => '1',
			d => d_hdmi_2,
			r => '0',
			s => '0'
		);
		
	d_hdmi <= d_hdmi_2_r when hdmi_edge = '0' else d_hdmi_2_f;

-- Data outputs
	
	q_sfp_r <= q_sfp when falling_edge(mclk);
	q_sfp_i <= q_sfp_r when falling_edge(mclk);
	
	obuf_q_usfp: OBUFDS
		port map(
			i => q_sfp_i,
			o => q_sfp_p,
			ob => q_sfp_n
		);

	q_hdmi_0 <= sync when rising_edge(clk_i);
	q_hdmi_0b <= sync when rising_edge(clk_i);
	q_hdmi_1 <= sync when rising_edge(clk_i);
	q_hdmi_1b <= sync when rising_edge(clk_i);
	q_hdmi_2 <= q_hdmi when falling_edge(mclk);
	q_hdmi_3 <= '0';
	
-- Clock outputs

	oddr_clk_0: ODDR
		port map(
			q => q_hdmi_clk_0,
			c => mclk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);

	oddr_clk_1: ODDR
		port map(
			q => q_hdmi_clk_1,
			c => mclk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	oddr_clk_2: ODDR
		port map(
			q => q_hdmi_clk_2,
			c => mclk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	oddr_clk_3: ODDR
		port map(
			q => q_hdmi_clk_3,
			c => mclk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 1
		)
		port map(
			clk(0) => clk_i,
			clkdiv => clkdiv
		);

	ctr: entity work.ipbus_freq_ctr
		generic map(
			N_CLK => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ),
			ipb_out => ipbr(N_SLV_FREQ),
			clkdiv => clkdiv
		);	

-- I2C

	i2c_uid: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda
		);
	
	sda <= '0' when sda_o = '0' else 'Z';
				
end rtl;
