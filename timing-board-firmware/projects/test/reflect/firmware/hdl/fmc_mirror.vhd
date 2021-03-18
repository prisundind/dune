-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_top.all;

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
		fmc_clk_p: in std_logic;
		fmc_clk_n: in std_logic;
		rec_clk_p: in std_logic;
		rec_clk_n: in std_logic;
		rec_d_p: in std_logic;
		rec_d_n: in std_logic;
		clk_out_p: out std_logic;
		clk_out_n: out std_logic;
		rj45_din_p: in std_logic;
		rj45_din_n: in std_logic;
		rj45_dout_p: out std_logic;
		rj45_dout_n: out std_logic;
		sfp_dout_p: out std_logic;
		sfp_dout_n: out std_logic;
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		sfp_los: in std_logic;
		sfp_tx_dis: out std_logic;
		sfp_flt: in std_logic;
		uid_scl: out std_logic;
		uid_sda: inout std_logic;
		sfp_scl: out std_logic;
		sfp_sda: inout std_logic;
		pll_scl: out std_logic;
		pll_sda: inout std_logic;
		pll_rstn: out std_logic;
		gpin_0_p: in std_logic;
		gpin_0_n: in std_logic;
		gpout_0_p: out std_logic;
		gpout_0_n: out std_logic;
		gpout_1_p: out std_logic;
		gpout_1_n: out std_logic		
	);

end payload;

architecture rtl of payload is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	signal rst, mode, chk_init, rst_rec_clk: std_logic;
	signal clkin, clkin_u, rec_clk, rec_clk_u, clkout, oclk: std_logic;
	signal rst_clkin, rst_rec, chk_init_s: std_logic;
	signal gpin, rj45_din, rec_d, rec_d_r, rec_d_r2, rec_clk_b: std_logic;
	signal p, p_sfp, p_sfp_r: std_logic;
	signal cyc_ctr, err_ctr: std_logic_vector(47 downto 0);
	signal clkdiv: std_logic_vector(1 downto 0);
	signal uid_sda_o, pll_sda_o, sfp_sda_o: std_logic;
	signal zflag: std_logic;
	
	attribute IOB: string;
	attribute IOB of p_sfp: signal is "TRUE";
	attribute IOB of rec_d_r: signal is "TRUE";
	attribute KEEP: string;
	attribute KEEP of p_sfp: signal is "TRUE";
			
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
      sel => ipbus_sel_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 5
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	stat(0) <= X"000000" & "00" & rj45_din & gpin & zflag & sfp_los & cdr_los & cdr_lol;
	stat(1) <= cyc_ctr(31 downto 0);
	stat(2) <= X"0000" & cyc_ctr(47 downto 32);
	stat(3) <= err_ctr(31 downto 0);
	stat(4) <= X"0000" & err_ctr(47 downto 32);
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	mode <= ctrl(0)(3);
	pll_rstn <= not ctrl(0)(4);
	sfp_tx_dis <= ctrl(0)(5);
	chk_init <= ctrl(0)(6);
	
-- Unused signals
	
	userled <= '0';

	obufds_0: OBUFDS
		port map(
			i => '0',
			o => gpout_0_p,
			ob => gpout_0_n
		);
	
	obufds_1: OBUFDS
		port map(
			i => '0',
			o => gpout_1_p,
			ob => gpout_1_n
		);
		
	obuf_rj45_dout: OBUFDS
		port map(
			i => '0',
			o => rj45_dout_p,
			ob => rj45_dout_n
		);
		
	ibufds_gpin_0: IBUFDS
		port map(
			i => gpin_0_p,
			ib => gpin_0_n,
			o => gpin
		);
		
	ibufds_rj45: IBUFDS
		port map(
			i => rj45_din_p,
			ib => rj45_din_n,
			o => rj45_din
		);
		
-- Clock
			
	ibufg_in: IBUFGDS
		port map(
			i => fmc_clk_p,
			ib => fmc_clk_n,
			o => clkin_u
		);
		
	bufg_in: BUFG
		port map(
			i => clkin_u,
			o => clkin
		);

	rst_clkin_s: entity work.pdts_synchro
		port map(
			clk => ipb_clk,
			clks => clkin,
			d(0) => rst,
			q(0) => rst_clkin
		);
		
	ibufds_rec_clk: IBUFDS
		port map(
			i => rec_clk_p,
			ib => rec_clk_n,
			o => rec_clk_u
		);
		
	bufh_rec_clk: BUFG
		port map(
			i => rec_clk_u,
			o => rec_clk
		);
		
	rst_rec_s: entity work.pdts_synchro
		port map(
			clk => ipb_clk,
			clks => rec_clk,
			d(0) => rst,
			q(0) => rst_rec_clk
		);
		
-- Outputs
		
	oddr_clkout: ODDR -- Feedback clock, not through MMCM
		port map(
			q => clkout,
			c => clkin,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_clkout: OBUFDS
		port map(
			i => clkout,
			o => clk_out_p,
			ob => clk_out_n
		);
		
	p_sfp_r <= rec_d when rising_edge(rec_clk);
			
	obuf_sfp_dout: OBUFDS
		port map(
			i => p_sfp_r,
			o => sfp_dout_p,
			ob => sfp_dout_n
		);

-- Inputs

	ibufds_rec_d: IBUFDS
		port map(
			i => rec_d_p,
			ib => rec_d_n,
			o => rec_d
		);

	rec_d_r <= rec_d when rising_edge(rec_clk);
	
	sync_chk_init: entity work.pdts_synchro
		port map(
			clk => ipb_clk,
			clks => rec_clk,
			d(0) => chk_init,
			q(0) => chk_init_s
		);
	
	prbs_chk_sfp: entity work.prbs7_chk
		port map(
			clk => rec_clk,
			rst => rst_rec_clk,
			init => chk_init_s,
			d => rec_d_r,
			err_ctr => err_ctr,
			cyc_ctr => cyc_ctr,
			zflag => zflag
		);
		
-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 2
		)
		port map(
			clk(0) => clkin,
			clk(1) => rec_clk,
			clkdiv => clkdiv
		);

	ctr: entity work.freq_ctr
		generic map(
			N_CLK => 2
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
			ipb_in => ipbw(N_SLV_UID_I2C),
			ipb_out => ipbr(N_SLV_UID_I2C),
			scl => uid_scl,
			sda_o => uid_sda_o,
			sda_i => uid_sda
		);
	
	uid_sda <= '0' when uid_sda_o = '0' else 'Z';
	
	i2c_sfp: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SFP_I2C),
			ipb_out => ipbr(N_SLV_SFP_I2C),
			scl => sfp_scl,
			sda_o => sfp_sda_o,
			sda_i => sfp_sda
		);
	
	sfp_sda <= '0' when sfp_sda_o = '0' else 'Z';

	i2c_pll: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_PLL_I2C),
			ipb_out => ipbr(N_SLV_PLL_I2C),
			scl => pll_scl,
			sda_o => pll_sda_o,
			sda_i => pll_sda
		);
	
	pll_sda <= '0' when pll_sda_o = '0' else 'Z';
				
end rtl;
