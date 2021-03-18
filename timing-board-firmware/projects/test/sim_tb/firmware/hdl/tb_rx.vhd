-- tb_rx
--
-- Testbench for basic rx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_tb_rx.all;

entity tb_rx is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rec_clk: in std_logic;
		d: in std_logic;
		sfp_los: in std_logic;
		cdr_los: in std_logic;
		cdr_lol: in std_logic
	);
		
end tb_rx;

architecture rtl of tb_rx is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(2 downto 0);
	signal ctrl_rst: std_logic;
	signal ctrl_addr: std_logic_vector(7 downto 0);
	signal ctrl_tgrp: std_logic_vector(1 downto 0);
	signal ep_stat: std_logic_vector(3 downto 0);
	signal clk, rst, rdy: std_logic;
	signal sync: std_logic_vector(3 downto 0);
	signal sync_v: std_logic;
	signal tstamp: std_logic_vector(63 downto 0);
	signal evtctr: std_logic_vector(31 downto 0);

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
      sel => ipbus_sel_tb_rx(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 3
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);

	stat(0) <= X"000000" & "000" & rdy & ep_stat;
	stat(1) <= tstamp(31 downto 0);
	stat(2) <= evtctr;
	ctrl_rst <= ctrl(0)(0);
	ctrl_addr <= ctrl(0)(15 downto 8);
	ctrl_tgrp <= ctrl(0)(17 downto 16);
		
-- Endpoint

	endpoint: entity work.pdts_endpoint
		generic map(
			SCLK_FREQ => 31.25
		)
		port map(
			sclk => ipb_clk,
			srst => ctrl_rst,
			addr => ctrl_addr,
			tgrp => ctrl_tgrp,
			stat => ep_stat,
			rec_clk => rec_clk,
			rec_d => d,
			sfp_los => sfp_los,
			cdr_los => cdr_los,
			cdr_lol => cdr_lol,
			clk => clk,
			rst => rst,
			rdy => rdy,
			sync => sync,
			sync_v => sync_v
		);

-- Counters

	ctrs: entity work.pdts_sync_ctr
		port map(
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			clk => clk,
			rst => rst,
			d => sync,
			v => sync_v
		);

end rtl;
