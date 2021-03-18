-- ouroboros (master + endpoints)
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

	constant DESIGN_TYPE: std_logic_vector := X"02";
	constant N_EP: positive := 1;

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal fmc_clk, rec_clk, rec_d, q, d, rst_io, rsti, clk, stb, rst, locked: std_logic;
	signal txd, ep_clk: std_logic_vector(N_EP - 1 downto 0);
	signal rec_edge: std_logic;
		
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

	io: entity work.pdts_fmc_io
		generic map(
			CARRIER_TYPE => CARRIER_TYPE,
			DESIGN_TYPE => DESIGN_TYPE,
            SFP_OUT_FE => true
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
			cdr_lol => cdr_lol,
			cdr_los => cdr_los,
			sfp_los => sfp_los,
			sfp_tx_dis => sfp_tx_dis,
			sfp_flt => sfp_flt,
			userled => userled,
			fmc_clk_p => fmc_clk_p,
			fmc_clk_n => fmc_clk_n,
			fmc_clk => fmc_clk,
			rec_clk_p => rec_clk_p,
			rec_clk_n => rec_clk_n,
			rec_clk => rec_clk,
			rec_edge => '0',
			rec_d_p => rec_d_p,
			rec_d_n => rec_d_n,
			rec_d => rec_d,
			clk_out_p => clk_out_p,
			clk_out_n => clk_out_n,
			rj45_edge => '0',
			rj45_din_p => rj45_din_p,
			rj45_din_n => rj45_din_n,
			rj45_din => d,
			rj45_dout => q,
			rj45_dout_p => rj45_dout_p,
			rj45_dout_n => rj45_dout_n,
			sfp_dout => q,
			sfp_dout_p => sfp_dout_p,
			sfp_dout_n => sfp_dout_n,
			uid_scl => uid_scl,
			uid_sda => uid_sda,
			sfp_scl => sfp_scl,
			sfp_sda => sfp_sda,
			pll_scl => pll_scl,
			pll_sda => pll_sda,
			pll_rstn => pll_rstn,
			gpin_0_p => gpin_0_p,
			gpin_0_n => gpin_0_n,
			testclk => ep_clk(0),
			gpout_0_p => gpout_0_p,
			gpout_0_n => gpout_0_n,
			gpout_1_p => gpout_1_p,
			gpout_1_n => gpout_1_n
		);

-- Clock divider

	clkgen: entity work.pdts_rx_div_mmcm
		port map(
			sclk => fmc_clk,
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

-- master block

	master: entity work.pdts_master_top
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER_TOP),
			ipb_out => ipbr(N_SLV_MASTER_TOP),
			mclk => fmc_clk,
			clk => clk,
			rst => rst,
			q => q,
			d => d,
			t_d => '0'
		);

-- Endpoint wrapper

	egen: for i in N_EP - 1 downto 0 generate

		signal addri: std_logic_vector(7 downto 0);
		
	begin
	
		addri <= std_logic_vector(to_unsigned(i + 8, 8));
	
		wrapper: entity work.pdts_endpoint_wrapper
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw(i + N_SLV_ENDPOINT0),
				ipb_out => ipbr(i + N_SLV_ENDPOINT0),
				addr => addri,
				rec_clk => rec_clk,
				rec_d => rec_d,
				txd => txd(i),
				clk => ep_clk(i),
				sfp_los => sfp_los,
				cdr_los => cdr_los,
				cdr_lol => cdr_lol,
				sfp_tx_dis => open
			);
			
	end generate;
	
	negen: for i in 3 downto N_EP generate
	
		ipbr(i + N_SLV_ENDPOINT0) <= IPB_RBUS_NULL;
		
	end generate;

end rtl;
