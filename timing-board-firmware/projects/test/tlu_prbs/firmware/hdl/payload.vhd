-- payload_tlu
--
-- Wrapper for TLU overlord design
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_decode_top.all;
use work.ipbus_reg_types.all;

entity payload is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0)
	);
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
		trig_in_p: in std_logic_vector(5 downto 0);
		trig_in_n: in std_logic_vector(5 downto 0);
		q_hdmi_clk_0: out std_logic;
		q_hdmi_clk_1: out std_logic;
		q_hdmi_clk_2: out std_logic;
		q_hdmi_clk_3: out std_logic;
		q_hdmi_0: out std_logic; -- output to HDMI 0 (BUSY)
		q_hdmi_0b: out std_logic; -- output to HDMI 0 (CONT)
		q_hdmi_1: out std_logic; -- output to HDMI 1 (BUSY)
		q_hdmi_1b: out std_logic; -- output to HDMI 1 (CONT)
		q_hdmi_2: out std_logic; -- output to HDMI 2
		q_hdmi_3: out std_logic; -- output to HDMI 3
		d_hdmi_2: in std_logic; -- input from HDMI 3
		q_sfp_p: out std_logic;
		q_sfp_n: out std_logic;
		d_cdr_p: in std_logic;
		d_cdr_n: in std_logic;
		sfp_los: in std_logic;
		sfp_fault: in std_logic;
		sfp_tx_dis: out std_logic;
		cdr_lol: in std_logic;
		cdr_los: in std_logic;
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
	);

end payload;

architecture rtl of payload is

	constant DESIGN_TYPE: std_logic_vector := X"06";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	signal mclk, rst_io, rsti, clk, stb, rst, locked, q, d: std_logic;
	signal cyc_ctr, err_ctr: std_logic_vector(47 downto 0);
	signal ctrl_chk_init, zflag: std_logic;
	
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

-- IO

	io: entity work.pdts_tlu_io
		generic map(
			CARRIER_TYPE => CARRIER_TYPE,
			DESIGN_TYPE => DESIGN_TYPE
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_IO),
			ipb_out => ipbr(N_SLV_IO),
			soft_rst => soft_rst,
			nuke => nuke,
			rst => rst_io,
			locked => locked,
			clk_p => clk_p,
			clk_n => clk_n,
			clk => clk,
			mclk => mclk,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			trig_in_p => trig_in_p,
			trig_in_n => trig_in_n,
			trig_in => open,
			q_hdmi_clk_0 => q_hdmi_clk_0,
			q_hdmi_clk_1 => q_hdmi_clk_1,
			q_hdmi_clk_2 => q_hdmi_clk_2,
			q_hdmi_clk_3 => q_hdmi_clk_3,
			sync => '0',
			q_hdmi_0 => q_hdmi_0,
			q_hdmi_0b => q_hdmi_0b,
			q_hdmi_1 => q_hdmi_1,
			q_hdmi_1b => q_hdmi_1b,
			q_hdmi => q,
			q_hdmi_2 => q_hdmi_2,
			q_hdmi_3 => q_hdmi_3,
			d_hdmi_2 => d_hdmi_2,
			d_hdmi => d,
			hdmi_edge => '0',
			q_sfp => q,
			q_sfp_p => q_sfp_p,
			q_sfp_n => q_sfp_n,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			d_cdr => open,
			cdr_edge => '0',
			sfp_los => sfp_los,
			sfp_fault => sfp_fault,
			sfp_tx_dis => sfp_tx_dis,
			cdr_lol => cdr_lol,
			cdr_los => cdr_los,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c
		);

-- Clock divider

	clkgen: entity work.pdts_rx_mul_mmcm
		port map(
			clk => clk,
			sclk => mclk,
			phase_rst => rst_io,
			phase_locked => locked
		);

	rsti <= rst_io or not locked;	
	
	synchro: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => ipb_clk,
			clks => mclk,
			d(0) => rsti,
			q(0) => rst
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
		
	stat(0) <= X"0000000" & "000" & zflag;
	stat(1) <= cyc_ctr(31 downto 0);
	stat(2) <= X"0000" & cyc_ctr(47 downto 32);
	stat(3) <= err_ctr(31 downto 0);
	stat(4) <= X"0000" & err_ctr(47 downto 32);
	
	ctrl_chk_init <= ctrl(0)(0);	

-- PRBS gen

	prbs: entity work.prbs7_ser
		port map(
			clk => mclk,
			rst => rst,
			load => '0',
			d => '0',
			q => q
		);
		
-- PRBS check

	prbs_chk: entity work.prbs7_chk
		port map(
			clk => mclk,
			rst => rst,
			init => ctrl_chk_init,
			d => d,
			err_ctr => err_ctr,
			cyc_ctr => cyc_ctr,
			zflag => zflag
		);	

end rtl;
