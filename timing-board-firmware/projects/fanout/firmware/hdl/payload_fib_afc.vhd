-- master
--
-- Interface to afc+fib fanout board for PDTS master block
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
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
		addr: in std_logic_vector(3 downto 0);
		clk125: in std_logic;
		
		clk_bp_p: in std_logic; -- 62.5MHz master clock from PLL
		clk_bp_n: in std_logic;
		
		clk_pll_p: in std_logic;
		clk_pll_n: in std_logic;
		
		clk_cdr_p: in std_logic;
		clk_cdr_n: in std_logic;
		
		d_bp_p: in std_logic;
		d_bp_n: in std_logic;
				
		d_sfp_p: in std_logic_vector(3 downto 0); 
		d_sfp_n: in std_logic_vector(3 downto 0);

		d_cdr_p: in std_logic; -- data input from CDR (via MUX)
		d_cdr_n: in std_logic;

		q_sfp_p: out std_logic_vector(7 downto 0); -- output to fanout (downstream)
		q_sfp_n: out std_logic_vector(7 downto 0);

		q_bp_p: out std_logic;
		q_bp_n: out std_logic;

		inmux: out std_logic_vector(2 downto 0); -- mux control

		scl: out std_logic;
		sda: inout std_logic;
		rstb_i2c: out std_logic; -- reset for I2C expanders

		sfp_scl: out std_logic_vector(7 downto 0); -- fan-out sfp control
		sfp_sda: inout std_logic_vector(7 downto 0)
	);

end payload;

architecture rtl of payload is

	constant DESIGN_TYPE: std_logic_vector := X"05";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal clk_bp, clk_pll, clk, rst, rsti, rst_io, locked: std_logic;
	signal cdr_edge, q_edge, d_bp, d_hdmi, d_usfp, q_bp, q_usfp, d_master, q_master, d_ep, q_ep, d_cdr, q, ep_tx_dis, ep_rdy, tx_dis, ctrl_master_src1 : std_logic;
	signal sfp_q: std_logic_vector(7 downto 0);

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

	io: entity work.pdts_fib_io
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
			locked => '1',
			clk_bp_p => clk_bp_p,
			clk_bp_n => clk_bp_n,
			clk_bp => clk_bp,
			clk_pll_p => clk_pll_p,
			clk_pll_n => clk_pll_n,
			clk_pll => clk_pll,
			clk_cdr_p => clk_cdr_p,
			clk_cdr_n => clk_cdr_n,
			clk_cdr => open,
			d_bp_edge => '0',
			d_bp_p => d_bp_p,
			d_bp_n => d_bp_n,
			d_bp => d_bp,
			d_sfp_edge => "0000",
			d_sfp_p => d_sfp_p,
			d_sfp_n => d_sfp_n,
			d_sfp => open,
			d_cdr_edge => cdr_edge,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			d_cdr => d_cdr,
			q_sfp => sfp_q,
			q_sfp_p => q_sfp_p,
			q_sfp_n => q_sfp_n,
			q_bp => q_bp,
			q_bp_p => q_bp_p,
			q_bp_n => q_bp_n,
			inmux => inmux,
			sfp_scl => sfp_scl,
			sfp_sda => sfp_sda,
			scl => scl,
			sda => sda,
			rstb_i2c => rstb_i2c
		);
		
-- Clock divider

	clkgen: entity work.pdts_rx_div_mmcm
		port map(
			sclk => clk_pll,
			clk => clk,
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
			clks => clk,
			d(0) => rsti,
			q(0) => rst
		);

-- Switchyard

	sw: entity work.switchyard
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SWITCH),
			ipb_out => ipbr(N_SLV_SWITCH),
			mclk => clk_pll,
			d_us => d_bp,
			q_us => q_bp,
			d_master => q_master,
			q_master => d_master,
			d_ep => q_ep,
			q_ep => d_ep,
			d_cdr => d_cdr,
			q => q,
			tx_dis_in => ep_tx_dis,
			ep_rdy => ep_rdy,
			tx_dis => tx_dis
		);
	
	sfp_q <= (others      => q);
	
-- Master block

	master: entity work.pdts_master_top
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER_TOP),
			ipb_out => ipbr(N_SLV_MASTER_TOP),
			mclk => clk_pll,
			clk => clk,
			rst => rst,
			q => q_master,
			d => d_master,
			t_d => '0',
			edge => cdr_edge,
			rdy => ep_rdy
		);
	end rtl;

