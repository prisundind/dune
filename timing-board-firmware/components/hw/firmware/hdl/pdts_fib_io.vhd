-- pdts_fib_io
--
-- Various functions for talking to the fib board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_fib_io.all;

library unisim;
use unisim.VComponents.all;

entity pdts_fib_io is
	generic(
		CARRIER_TYPE: std_logic_vector(7 downto 0);
		DESIGN_TYPE: std_logic_vector(7 downto 0);
		USE_CDR_CLK: boolean := false; -- Selects CDR or PLL clock for sampling of CDR data input
		USE_BKP_CLK: boolean := false; -- Selects backplane or PLL clock for sampling of backplane data input
		BKP_OUT_FE: boolean := true;
		SFP_OUT_FE: boolean := true
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
		clk_bp_p: in std_logic; -- 312.5MHz master clock from backplane
		clk_bp_n: in std_logic;
		clk_bp: out std_logic;
		d_bp_edge: in std_logic;
		d_bp_p: in std_logic; -- data from backplane (MIB)
		d_bp_n: in std_logic;
		d_bp: out std_logic;
		d_sfp_edge: in std_logic_vector(3 downto 0); -- SFP sampling edge control
		d_sfp_p: in std_logic_vector(3 downto 0); -- direct data from fanout SFPs
		d_sfp_n: in std_logic_vector(3 downto 0);
		d_sfp: out std_logic_vector(3 downto 0);
		d_cdr_edge: in std_logic; -- CDR sampling edge control
		d_cdr_p: in std_logic; -- data input from CDR (via MUX)
		d_cdr_n: in std_logic;
		d_cdr: out std_logic;
		clk_pll_p: in std_logic; -- clock from PLL on FIB
		clk_pll_n: in std_logic;
		clk_pll: out std_logic;
		clk_cdr_p: in std_logic; -- clock from CDR (via MUX)
		clk_cdr_n: in std_logic;
		clk_cdr: out std_logic;
		q_sfp: in std_logic_vector(7 downto 0);
		q_sfp_p: out std_logic_vector(7 downto 0); -- output to fanout (downstream)
		q_sfp_n: out std_logic_vector(7 downto 0);
		q_bp: in std_logic;
		q_bp_p: out std_logic; -- output to backplane (upstream)
		q_bp_n: out std_logic;
		inmux: out std_logic_vector(2 downto 0); -- mux control
		sfp_scl: out std_logic_vector(7 downto 0); -- fan-out sfp control
		sfp_sda: inout std_logic_vector(7 downto 0); 
		scl: out std_logic; -- main I2C
		sda: inout std_logic;
		rstb_i2c: out std_logic -- reset for I2C expanders
	);

end pdts_fib_io;

architecture rtl of pdts_fib_io is

	constant BOARD_TYPE: std_logic_vector(7 downto 0) := X"05";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal clk_bp_i, clk_bp_u, clk_pll_i, clk_pll_u, clk_cdr_i, clk_cdr_u: std_logic;
	signal clk_cdr_s, clk_d_bp_s: std_logic;

	signal d_bp_i, d_bp_r, d_bp_f, d_cdr_i, d_cdr_r, d_cdr_f: std_logic;
	signal d_sfp_i: std_logic_vector(3 downto 0);

	signal q_bp_i, q_bp_i_r, q_bp_i_f, q_bp_o: std_logic;
	signal q_sfp_i, q_sfp_i_r, q_sfp_i_f, q_sfp_o: std_logic_vector(7 downto 0);

	signal mmcm_bad, mmcm_ok, mmcm_lm: std_logic;
	signal clkdiv: std_logic_vector(2 downto 0);
	signal sda_o: std_logic;
	
  	attribute IOB: string;
  	attribute IOB of d_bp_i, d_cdr_i, d_sfp_i, q_bp_o, q_sfp_o: signal is "TRUE";
  	
  	attribute KEEP: string;
	attribute KEEP of q_bp_i, q_sfp_i: signal is "TRUE"; -- Stop pipeline registers being merged


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
      sel => ipbus_sel_pdts_fib_io(ipb_in.ipb_addr),
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
		
	stat(0) <= X"0000000" & "00" & mmcm_lm & mmcm_ok;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	rstb_i2c <= not ctrl(0)(3);
	inmux <= ctrl(0)(6 downto 4);
		
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
	-------backplane clock------
	ibufgds_clk_bp: IBUFGDS
		port map(
			i => clk_bp_p,
			ib => clk_bp_n,
			o => clk_bp_u
		);
		
	bufg_clk_bp: BUFG
		port map(
			i => clk_bp_u,
			o => clk_bp_i
		);
		
	clk_bp <= clk_bp_i;
	----------------------------

	----------cdr clock---------
	ibufgds_clk_cdr: IBUFGDS
		port map(
			i => clk_cdr_p,
			ib => clk_cdr_n,
			o => clk_cdr_u
		);
		
	bufg_clk_cdr: BUFG
		port map(
			i => clk_cdr_u,
			o => clk_cdr_i
		);
		
	clk_cdr <= clk_cdr_i;
	----------------------------

	----------pll clock---------
	ibufgds_clk_pll: IBUFGDS
		port map(
			i => clk_pll_p,
			ib => clk_pll_n,
			o => clk_pll_u
		);
		
	bufg_clk_pll: BUFG
		port map(
			i => clk_pll_u,
			o => clk_pll_i
		);
		
	clk_pll <= clk_pll_i;
	----------------------------

-- Clock lock monitor
	mmcm_bad <= not locked;

	chk: entity work.pdts_chklock
		generic map(
			N => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			los(0) => mmcm_bad,
			ok(0) => mmcm_ok,
			ok_sticky(0) => mmcm_lm
		);

-- Data inputs
	
	-- data from backplane
	ibufds_d_bp: IBUFDS
		port map(
			i => d_bp_p,
			ib => d_bp_n,
			o => d_bp_i
		);
	
	-- which clock are going to use to sample the data coming in on the backplane?
	clk_d_bp_s <= clk_bp_i when USE_BKP_CLK else clk_pll_i;

	iddr_d_bp: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_bp_r,
			q2 => d_bp_f,
			c => clk_d_bp_s,
			ce => '1',
			d => d_bp_i,
			r => '0',
			s => '0'
		);

	d_bp <= d_bp_r when d_bp_edge = '0' else d_bp_f;

	-- data from cdr (sfp mux)
	ibufds_d_cdr: IBUFDS
		port map(
			i => d_cdr_p,
			ib => d_cdr_n,
			o => d_cdr_i
		);
	
	-- which clock are we going to use to sample the CDR data coming in from sfp mux?
	clk_cdr_s <= clk_cdr_i when USE_CDR_CLK else clk_pll_i;
		
	iddr_d_cdr: IDDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE"
		)
		port map(
			q1 => d_cdr_r,
			q2 => d_cdr_f,
			c => clk_cdr_s,
			ce => '1',
			d => d_cdr_i,
			r => '0',
			s => '0'
		);
		
	d_cdr <= d_cdr_r when d_cdr_edge = '0' else d_cdr_f;

	-- data from the four individual SFPs
	d_sfp_gen: for i in 3 downto 0 generate
		signal dr, df: std_logic;
	begin
		ibufds_d_sfp: IBUFDS
			port map(
				i => d_sfp_p(i),
				ib => d_sfp_n(i),
				o => d_sfp_i(i)
			);
			
		iddr_d_sfp: IDDR
			generic map(
				DDR_CLK_EDGE => "SAME_EDGE"
			)
			port map(
				q1 => dr,
				q2 => df,
				c => clk_cdr_s,
				ce => '1',
				d => d_sfp_i(i),
				r => '0',
				s => '0'
			);
 	
		d_sfp(i) <= dr when d_sfp_edge(i) = '0' else df;
	end generate d_sfp_gen;


-- Data outputs
	
	-- data to backplane
	q_bp_i   <= q_bp when rising_edge(clk_pll_i); -- some pipelining
	
	q_bp_i_f <= q_bp_i when falling_edge(clk_pll_i);
	q_bp_i_r <= q_bp_i when rising_edge(clk_pll_i);
	
	q_bp_o   <= q_bp_i_f when BKP_OUT_FE else q_bp_i_r;

	obuf_q_bp: OBUFDS
		port map(
			i => q_bp_o,
			o => q_bp_p,
			ob => q_bp_n
		);
	

	-- data to SFPs
	q_sfp_gen: for i in 7 downto 0 generate
   	begin
   		q_sfp_i(i)   <= q_sfp(i)   when rising_edge(clk_pll_i);

   		q_sfp_i_f(i) <= q_sfp_i(i) when falling_edge(clk_pll_i);
   		q_sfp_i_r(i) <= q_sfp_i(i) when rising_edge(clk_pll_i);
   		
   		q_sfp_o(i) <= q_sfp_i_f(i) when SFP_OUT_FE else q_sfp_i_r(i);

   		obuf_q_usfp: OBUFDS
			port map(
				i => q_sfp_o(i),
				o => q_sfp_p(i),
				ob => q_sfp_n(i)
			);
   	end generate q_sfp_gen;
   	

-- Frequency measurement

	div: entity work.freq_ctr_div
		generic map(
			N_CLK => 3
		)
		port map(
			clk(0) => clk_pll_i,
			clk(1) => clk_cdr_i,
			clk(2) => clk_bp_i,
			clkdiv => clkdiv
		);

	ctr: entity work.ipbus_freq_ctr
		generic map(
			N_CLK => 3
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ),
			ipb_out => ipbr(N_SLV_FREQ),
			clkdiv => clkdiv
		);	

-- I2C

	i2c_main: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C_MAIN),
			ipb_out => ipbr(N_SLV_I2C_MAIN),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda
		);
	
	sda <= '0' when sda_o = '0' else 'Z';
	
	i2c_sfp_gen: for i in 0 to 7 generate
	signal sfp_sda_o: std_logic;
	begin
		i2c_sfp: entity work.ipbus_i2c_master
			port map(
				clk => ipb_clk,
				rst => ipb_rst,
				ipb_in => ipbw(N_SLV_I2C_SFP0+i),
				ipb_out => ipbr(N_SLV_I2C_SFP0+i),
				scl => sfp_scl(i),
				sda_o => sfp_sda_o,
				sda_i => sfp_sda(i)
			);
		sfp_sda(i) <= '0' when sfp_sda_o = '0' else 'Z';
	end generate i2c_sfp_gen;
				
end rtl;
