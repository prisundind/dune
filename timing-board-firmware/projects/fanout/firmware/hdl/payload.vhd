-- master
--
-- Interface to pc059 fanout board for PDTS master block
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

	constant DESIGN_TYPE: std_logic_vector := X"05";

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal clk_pll,clk, rst, rsti, rst_io, locked: std_logic;
	signal cdr_edge, hdmi_edge, d_hdmi, d_usfp, q_usfp, d_master, q_master, d_ep, q_ep, d_cdr, q, ep_tx_dis, ep_rdy, tx_dis: std_logic;
	signal master_src: std_logic_vector(1 downto 0);	
	
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
			rst => rst_io,
			locked => '1',
			master_src => master_src,
			clk_p => clk_p,
			clk_n => clk_n,
			clk => clk_pll,
			rstb_clk => rstb_clk,
			clk_lolb => clk_lolb,
			d_p => d_p,
			d_n => d_n,
			d => open,
			q_p => q_p,
			q_n => q_n,
			q => q,
			sfp_los => sfp_los,
			d_cdr_p => d_cdr_p,
			d_cdr_n => d_cdr_n,
			d_cdr => d_cdr,
			clk_cdr_p => clk_cdr_p,
			clk_cdr_n => clk_cdr_n,
			clk_cdr => open, -- This will go to phase measurement one day
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			cdr_edge => cdr_edge,
			inmux => inmux,
			rstb_i2cmux => rstb_i2cmux,
			hdmi_edge => hdmi_edge,
			d_hdmi_p => d_hdmi_p,
			d_hdmi_n => d_hdmi_n,
			d_hdmi => d_hdmi,
			q_hdmi_p => q_hdmi_p,
			q_hdmi_n => q_hdmi_n,
			q_hdmi => q_master, -- Not using HDMI for now
			d_usfp_p => d_usfp_p,
			d_usfp_n => d_usfp_n,
			d_usfp => d_usfp,
			q_usfp_p => q_usfp_p,
			q_usfp_n => q_usfp_n,
			q_usfp => q_usfp,
			usfp_fault => usfp_fault,
			usfp_los => usfp_los,
			tx_dis => tx_dis,
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
			d_us => d_usfp,
			q_us => q_usfp,
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
			t_d => d_hdmi,
			rdy => ep_rdy,
			edge => cdr_edge,
			t_edge => hdmi_edge
		);

-- Endpoint wrapper

	wrapper: entity work.pdts_endpoint_wrapper
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ENDPOINT0),
			ipb_out => ipbr(N_SLV_ENDPOINT0),
			addr(2 downto 0) => addr(2 downto 0),
			addr(7 downto 3) => std_logic_vector'("11111"),
			rec_clk => clk_pll,
			rec_d => d_ep,
			txd => q_ep,
			sfp_los => usfp_los,
			cdr_los => ucdr_los,
			cdr_lol => ucdr_lol,
			sfp_tx_dis => ep_tx_dis
		);

end rtl;
