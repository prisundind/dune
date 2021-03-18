-- pdts_master
--
-- The PDTS master timing block
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_master.all;

use work.pdts_defs.all;
use work.pdts_master_defs.all;

entity pdts_master is
	generic(
		SIM: boolean := false
	);
	port(
		ipb_clk: in std_logic; -- IPbus connection
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic; -- The serial IO clock
		clk: in std_logic; -- The system clock
		rst: in std_logic; -- Sync reset (clk domain)
		spill_warn: in std_logic;
		spill_start: in std_logic; -- Spill signals from SPS (async signals)
		spill_end: in std_logic;
		sync: out std_logic;
		clk10: in std_logic;
		irig: in std_logic;
		q: out std_logic; -- Downstream output (mclk domain)
		d: in std_logic; -- Downstream input (mclk domain)
		t_scmd_in: in cmd_w := CMD_W_NULL; -- Sync command input from trigger, and handshake
		t_scmd_out: out cmd_r;
		rdy: out std_logic;
		edge: out std_logic
	);
		
end pdts_master;

architecture rtl of pdts_master is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal sel: std_logic_vector(calc_width(N_PART) - 1 downto 0);
	signal sctr: unsigned(3 downto 0) := X"0";
	signal stb: std_logic;
	signal spill, veto: std_logic;
	signal tstamp: std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
	signal scmdw_v: cmd_w_array(N_CHAN + N_PART + 3 downto 0);
	signal scmdr_v: cmd_r_array(N_CHAN + N_PART + 3 downto 0);
	signal scmdw, acmdw, rscmdw: cmd_w;
	signal scmdr, acmdr: cmd_r;
	signal typ: std_logic_vector(SCMD_W - 1 downto 0);
	signal tv: std_logic;
	signal tgrp: std_logic_vector(N_PART - 1 downto 0);
	signal tx_q: std_logic_vector(7 downto 0);
	signal tx_err, tx_stb, tx_k: std_logic;
	signal ep_en, ep_rdy, ep_rst, ep_edge: std_logic;
	signal ep_stat, ep_fdel: std_logic_vector(3 downto 0);
	
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
      sel => ipbus_sel_pdts_master(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- Global registers

	global: entity work.pdts_global
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_GLOBAL),
			ipb_out => ipbr(N_SLV_GLOBAL),
			clk => clk,
			rst => rst,
			ep_en => ep_en,
			ep_stat => ep_stat,
			ep_rdy => ep_rdy,
			ep_edge => ep_edge,
			ep_fdel => ep_fdel,
			tx_err => tx_err
		);
		
-- Strobe gen

	process(clk)
	begin
		if rising_edge(clk) then
			if sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	stb <= '1' when sctr = 0 else '0';

-- Async command source

	acmd: entity work.pdts_acmd_master
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ACMD),
			ipb_out => ipbr(N_SLV_ACMD),		
			clk => clk,
			rst => rst,
			acmd_out => acmdw,
			acmd_in => acmdr
		);
		
-- Timestamp source

	tssrc: entity work.pdts_ts_source
		generic map(
			N_PART => N_PART
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TSTAMP),
			ipb_out => ipbr(N_SLV_TSTAMP),
			clk10 => clk10,
			irig => irig,
			clk => clk,
			rst => rst,
			tstamp => tstamp
		);
		
-- Timestamp broadcast

	ts: entity work.pdts_ts_bcast
		port map(
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(0),
			scmd_in => scmdr_v(0)
		);
		
-- Spill gate

	sgate: entity work.pdts_spill_gate
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SPILL),
			ipb_out => ipbr(N_SLV_SPILL),
			clk => clk,
			rst => rst,
			spill_warn => spill_warn,
			spill_start => spill_start,
			spill_end => spill_end,
			sync => sync,
			spill => spill,
			veto => veto,
			tstamp => tstamp,
			scmd_out => scmdw_v(1),
			scmd_in => scmdr_v(1)
		);

-- Trigger command input

	scmdw_v(2) <= t_scmd_in;
	t_scmd_out <= scmdr_v(2);
	
-- Echo command source

	echo: entity work.pdts_echo_mon
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ECHO),
			ipb_out => ipbr(N_SLV_ECHO),
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(3),
			scmd_in => scmdr_v(3),
			rscmd_in => rscmdw
		);
	
-- Partitions

	pgen: for i in N_PART - 1 downto 0 generate
	
		part: entity work.pdts_partition
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw(i + N_SLV_PARTITION0),
				ipb_out => ipbr(i + N_SLV_PARTITION0),
				clk => clk,
				rst => rst,
				tstamp => tstamp,
				spill => spill,
				veto => veto,
				scmd_out => scmdw_v(i + 4),
				scmd_in => scmdr_v(i + 4),
				typ => typ,
				tv => tv,
				tack => tgrp(i)
			);
			
	end generate;
	
	npgen: for i in 3 downto N_PART generate -- Corresponds to address table max partitions
	
		ipbr(i + N_SLV_PARTITION0) <= IPB_RBUS_NULL;
			
	end generate;

-- Sync command gen

	gen: entity work.pdts_scmd_gen
		generic map(
			N_CHAN => N_CHAN
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SCMD_GEN),
			ipb_out => ipbr(N_SLV_SCMD_GEN),
			clk => clk,
			rst => rst,
			tstamp => tstamp,
			scmd_out => scmdw_v(N_PART + 3 + N_CHAN downto N_PART + 4),
			scmd_in => scmdr_v(N_PART + 3 + N_CHAN downto N_PART + 4)
		);
		
-- Merge

	merge: entity work.pdts_scmd_merge
		generic map(
			N_SRC => N_CHAN + N_PART + 4,
			N_PART => N_PART
		)
		port map(
			clk => clk,
			rst => rst,
			scmd_in_v => scmdw_v,
			scmd_out_v => scmdr_v,
			typ => typ,
			tv => tv,
			tgrp => tgrp,
			scmd_out => scmdw,
			scmd_in => scmdr
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk,
			rst => rst,
			stb => stb,
			addr => X"00",
			scmd_in => scmdw,
			scmd_out => scmdr,
			acmd_in => acmdw,
			acmd_out => acmdr,
			q => tx_q,
			k => tx_k,
			stbo => tx_stb,
			err => tx_err
		);
		
-- Tx PHY

	txphy: entity work.pdts_tx_phy
		port map(
			clk => clk,
			rst => rst,
			d => tx_q,
			k => tx_k,
			stb => tx_stb,
			txclk => mclk,
			q => q
		);
		
-- Downstream rx

	ep_rst <= ipb_rst or not ep_en;

	ep: entity work.pdts_endpoint_upstream
		generic map(
			SCLK_FREQ => 31.25,
			SIM => SIM
		)	
		port map(
			sclk => ipb_clk,
			srst => ep_rst,
			stat => ep_stat,
			rec_clk => mclk,
			rec_d => d,
			clk => clk,
			rdy => ep_rdy,
			fdel => ep_fdel,
			edge => ep_edge,
			scmd => rscmdw,
			acmd => open
		);
		
	rdy <= ep_rdy;
	edge <= ep_edge;

end rtl;
