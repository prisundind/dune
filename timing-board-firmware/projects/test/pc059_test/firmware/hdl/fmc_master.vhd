-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_top.all;

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

	constant DESIGN_TYPE: std_logic_vector := X"00";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal inmux_i: std_logic_vector(2 downto 0);
	signal clk, q, d_cdr, clk_cdr, d_hdmi, q_hdmi, d_usfp, q_usfp, d_sel: std_logic;
	signal d: std_logic_vector(7 downto 0);
	signal rst, ctrl_chk_init, cdr_rst, cdr_ctr_rst: std_logic;
	signal zflag_cdr, zflag_hdmi, zflag_usfp, chk_init_pll, chk_init_cdr, rst_pll, rst_cdr: std_logic;
	signal p: std_logic;
	signal err_cdr, err_hdmi, err_usfp: std_logic;
	signal err_sfp, zflag_sfp: std_logic_vector(7 downto 0);
	
	attribute DONT_TOUCH: string;
	attribute DONT_TOUCH of q, q_hdmi, q_usfp: signal is "true";
	
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

	io: entity work.pdts_pc059_io
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
			rst => rst,
			locked => '1',
			clk_p => clk_p,
			clk_n => clk_n,
			clk => clk,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			d_p => d_p,
			d_n => d_n,
			d => d,
			q_p => q_p,
			q_n => q_n,
			q => q,
			sfp_los => sfp_los,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			d_cdr => d_cdr,
			clk_cdr_p => clk_cdr_p,
			clk_cdr_n => clk_cdr_n,
			clk_cdr => clk_cdr,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			inmux => inmux_i,
			rstb_i2cmux => rstb_i2cmux,
			d_hdmi_p => d_hdmi_p,
			d_hdmi_n => d_hdmi_n,
			d_hdmi => d_hdmi,
			q_hdmi_p => q_hdmi_p,
			q_hdmi_n => q_hdmi_n,
			q_hdmi => q_hdmi,
			d_usfp_p => d_usfp_p,
			d_usfp_n => d_usfp_n,
			d_usfp => d_usfp,
			q_usfp_p => q_usfp_p,
			q_usfp_n => q_usfp_n,
			q_usfp => q_usfp,
			usfp_fault => usfp_fault,
			usfp_los => usfp_los,
			usfp_txdis => usfp_txdis,
			usfp_sda => usfp_sda,
			usfp_scl => usfp_scl,
			ucdr_los => ucdr_los,
			ucdr_lol => ucdr_lol,
			ledb => ledb,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c,
			gpio_p => gpio_p,
			gpio_n => gpio_n
		);
		
	inmux <= inmux_i;
    
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
		
	ctrl_chk_init <= ctrl(0)(0);
	stat(0) <= X"0000" & zflag_sfp & X"0" & '0' & zflag_usfp & zflag_hdmi & zflag_cdr;
	
	clk_s: entity work.pdts_synchro
		generic map(
			N => 2
		)
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => rst,
			d(1) => ctrl_chk_init,
			q(0) => rst_pll,
			q(1) => chk_init_pll
		);

	cdr_rst <= rst or cdr_lol; -- CDC, async signal from outside, synchronised downstream
		
	clk_cdr_s: entity work.pdts_synchro
		generic map(
			N => 2
		)
		port map(
			clk => ipb_clk,
			clks => clk_cdr,
			d(0) => cdr_rst,
			d(1) => ctrl_chk_init,
			q(0) => rst_cdr,
			q(1) => chk_init_cdr
		);
		
-- PRBS gen
		
	prbs: entity work.prbs7_ser
		port map(
			clk => clk,
			rst => rst_pll,
			load => '0',
			d => '0',
			q => p
		);

-- Cycle counter

	cyc_ctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 1,
			CTR_WDS => 2
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CYC_CTR),
			ipb_out => ipbr(N_SLV_CYC_CTR),
			clk => clk,
			rst => chk_init_pll,
			inc(0) => '1'
		);	
		
-- Downstream CDR (data in on CDR clk)
	
	chk_cdr: entity work.prbs7_chk_noctr
		port map(
			clk => clk_cdr,
			rst => rst_cdr,
			init => chk_init_cdr,
			d => d_cdr,
			err => err_cdr,
			zflag => zflag_cdr
		);

	cdr_ctr_rst <= chk_init_cdr or rst_cdr;
		
	ctrs_cdr: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 1,
			CTR_WDS => 1
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CDR_CTR),
			ipb_out => ipbr(N_SLV_CDR_CTR),
			clk => clk_cdr,
			rst => cdr_ctr_rst,
			inc(0) => err_cdr
		);
		
-- Downstream SFP direct (data out and data in on PLL clk)

	q <= p when rising_edge(clk);

	sgen: for i in 7 downto 0 generate
	
		chk_sfp: entity work.prbs7_chk_noctr
			port map(
				clk => clk,
				rst => rst_pll,
				init => chk_init_pll,
				d => d(i),
				err => err_sfp(i),
				zflag => zflag_sfp(i)
			);
			
	end generate;
	
	sfp_ctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 8,
			CTR_WDS => 1
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SFP_CTR),
			ipb_out => ipbr(N_SLV_SFP_CTR),
			clk => clk,
			rst => chk_init_pll,
			inc => err_sfp
		);	
		
-- HDMI (data out and data in on PLL clk)

	q_hdmi <= p when rising_edge(clk);
	
	chk_hdmi: entity work.prbs7_chk_noctr
		port map(
			clk => clk,
			rst => rst_pll,
			init => chk_init_pll,
			d => d_hdmi,
			err => err_hdmi,
			zflag => zflag_hdmi
		);
		
-- uSFP (data out and data in on PLL clk)

	q_usfp <= p when rising_edge(clk);
	
	chk_usfp: entity work.prbs7_chk_noctr
		port map(
			clk => clk,
			rst => rst_pll,
			init => chk_init_pll,
			d => d_usfp,
			err => err_usfp,
			zflag => zflag_usfp
		);
		
-- Counters
		
	ctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 2,
			CTR_WDS => 1
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_UST_CTR),
			ipb_out => ipbr(N_SLV_UST_CTR),
			clk => clk,
			rst => chk_init_pll,
			inc(0) => err_hdmi,
			inc(1) => err_usfp
		);	
		
end rtl;
