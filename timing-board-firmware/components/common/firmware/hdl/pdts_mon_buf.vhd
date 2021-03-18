-- pdts_mon_buf
--
-- A readout buffer for grabbing event records from the master or endpoint wrapper
--
-- Dave Newbold, January 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

use work.pdts_defs.all;

entity pdts_mon_buf is
	generic(
		N_FIFO: positive := 1
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		en: in std_logic; -- buffer enable; ipb_clk domain
		clk: in std_logic;
		rst: in std_logic;
		scmd: in std_logic_vector(SCMD_W - 1 downto 0);
		scmd_v: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		evtctr: in std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
		warn: out std_logic; -- buffer full warning; ipb_clk domain
		err: out std_logic -- buffer overflow; clk domain
	);
		
end pdts_mon_buf;

architecture rtl of pdts_mon_buf is

	signal rob_en_s, buf_err, rob_full: std_logic;
	signal rob_q: std_logic_vector(31 downto 0);
	signal rob_rst_u, rob_rst, rob_en, rob_we: std_logic;
	
begin
		
	rob_rst_u <= ipb_rst or not en;
		
	rsts: entity work.pdts_rst_stretch
		port map(
			clk => ipb_clk,
			rst => rob_rst_u,
			rsto => rob_rst,
			wen => rob_en
		);
	
	evt: entity work.pdts_scmd_evt
		port map(
			clk => clk,
			rst => rst,
			scmd => scmd,
			valid => scmd_v,
			tstamp => tstamp,
			evtctr => evtctr,
			empty => open,
			err => err,
			rob_clk => ipb_clk,
			rob_rst => rob_rst,
			rob_en => rob_en,
			rob_q => rob_q,
			rob_we => rob_we,
			rob_full => rob_full
		);
		
	rob: entity work.pdts_rob
		generic map(
			N_FIFO => N_FIFO,
			WARN_HWM => N_FIFO * 1024 - 256,
			WARN_LWM => N_FIFO * 1024 - 512
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			rst => rob_rst,
			d => rob_q,
			we => rob_we,
			full => rob_full,
			empty => open,
			warn => warn
		);

end rtl;
