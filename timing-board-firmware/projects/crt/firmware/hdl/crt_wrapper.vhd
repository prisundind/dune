-- crt_wrapper
--
-- Variant of endpoint wrapper to provide sync signal to CRT / BI
--
-- Dave Newbold, July 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_crt_wrapper.all;

use work.pdts_defs.all;

entity crt_wrapper is
	generic(
		SIM: boolean := false
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		addr: in std_logic_vector(7 downto 0);
		rec_clk: in std_logic; -- CDR recovered clock
		rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
		txd: out std_logic; -- Output data to timing link (rec_clk domain)
		sfp_los: in std_logic; -- SFP LOS line (async, sampled in sclk domain)
		cdr_los: in std_logic; -- CDR LOS line (async, sampled in sclk domain)
		cdr_lol: in std_logic; -- CDR LOL line (async, sampled in sclk domain)
		sfp_tx_dis: out std_logic; -- SFP tx disable line (clk domain)
		pulse_out: out std_logic -- Pulse output
	);
		
end crt_wrapper;

architecture rtl of crt_wrapper is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, ctrl_cmd: ipb_reg_v(0 downto 0);
	signal stat, stat_cmd: ipb_reg_v(0 downto 0);
	signal ctrl_tgrp: std_logic_vector(1 downto 0);
	signal ep_stat: std_logic_vector(3 downto 0);
	signal ep_clk, ep_rsto, ep_rdy, ep_en, ep_rst, ep_v, ep_s: std_logic;
	signal ep_scmd: std_logic_vector(SCMD_W - 1 downto 0);
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);

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
      sel => ipbus_sel_crt_wrapper(ipb_in.ipb_addr),
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

	ctrl_tgrp <= ctrl(0)(1 downto 0);
	ep_en <= ctrl(0)(2);
	stat(0) <= X"000000" & ep_stat & "000" & ep_rdy;

	ep_rst <= ipb_rst or not ep_en;
-- The endpoint

	ep: entity work.pdts_endpoint
		generic map(
			SCLK_FREQ => 31.25,
			SIM => SIM,
			NEED_ADJUST => false
		)
		port map(
			sclk => ipb_clk,
			srst => ipb_rst,
			addr => addr,
			tgrp => ctrl_tgrp,
			stat => ep_stat,
			rec_clk => rec_clk,
			rec_d => rec_d,
			txd => txd,
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			clk => ep_clk,
			rst => ep_rsto,
			rdy => ep_rdy,
			sync => ep_scmd,
			sync_stb => ep_s,
			sync_first => ep_v,
			tstamp => tstamp
		);
		
-- Pulse generator

	pulse: entity work.pdts_ep_sync_pulse
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_PULSE),
			ipb_out => ipbr(N_SLV_PULSE),
			clk => ep_clk,
			rst => ep_rsto,
			s => ep_scmd,
			s_stb => ep_s,
			s_first => ep_v,
			tstamp => tstamp,
			pulse_out => pulse_out
		);

end rtl;
