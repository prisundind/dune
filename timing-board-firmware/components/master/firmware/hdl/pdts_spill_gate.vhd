-- pdts_spill_gate
--
-- Generates spill gate signal
--
-- cyc_len and spill_len are in units of 1 / (50MHz / 2^24) = 0.34s
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_spill_gate.all;

use work.pdts_defs.all;

entity pdts_spill_gate is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		spill_warn: in std_logic;
		spill_start: in std_logic;
		spill_end: in std_logic;
		sync: out std_logic;
		spill: out std_logic;
		veto: out std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end pdts_spill_gate;

architecture rtl of pdts_spill_gate is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal ectr: unsigned(23 downto 0) := (others => '0');
	signal cctr: unsigned(7 downto 0) := (others => '0');
	signal ctrl_en, ctrl_src, ctrl_force, ctrl_clr: std_logic;
	signal ctrl_fake_cyc_len, ctrl_fake_spill_len: std_logic_vector(7 downto 0);
	signal veto_f, veto_i, spill_i, spill_f, spill_r, spill_e, ss, se, sw, ss_d, se_d, sw_d, ss_i, se_i, sw_i, trst, sinc: std_logic;
	signal start_ts, end_ts, warn_ts: std_logic_vector(63 downto 0);
	signal d: std_logic_vector(191 downto 0);
	signal sctr: unsigned(3 downto 0);
	
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
      sel => ipbus_sel_pdts_spill_gate(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => clk,
			d => stat,
			q => ctrl,
			stb => stb
		);
		
	stat(0) <= X"0000000" & "000" & spill_i;
	ctrl_en <= ctrl(0)(0);
	ctrl_src <= ctrl(0)(1);
	ctrl_force <= ctrl(0)(2) and stb(0);
	ctrl_clr <= ctrl(0)(3);
	ctrl_fake_cyc_len <= ctrl(0)(23 downto 16);
	ctrl_fake_spill_len <= ctrl(0)(31 downto 24);
	
-- Debounce of external spill signals

	debounce: entity work.pdts_debounce
		generic map(
			N => 3
		)
		port map(
			clk => clk,
			rst => rst,
			d(0) => spill_start,
			d(1) => spill_end,
			d(2) => spill_warn,
			q(0) => ss,
			q(1) => se,
			q(2) => sw
		);
		
	ss_d <= ss when rising_edge(clk);
	se_d <= se when rising_edge(clk);
	sw_d <= sw when rising_edge(clk);
	
	ss_i <= ss and not ss_d;
	se_i <= se and not se_d;
	sw_i <= sw and not sw_d;
	
	spill_e <= (spill_e or ss_i) and not (se_i or rst) when rising_edge(clk);
	veto_i <= (veto_i or sw_i) and not (ss_i or rst) when rising_edge(clk);

-- Stretched sync pulse for BI

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				sctr <= (others => '0');
			elsif sctr /= "0000" or ss_i = '1' then
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	sync <= or_reduce(std_logic_vector(sctr));

-- Fake generator

	process(clk)
	begin
		if rising_edge(clk) then
			ectr <= ectr + 1;
			if rst = '1' or ctrl_en = '0' then
				cctr <= (others => '0');
			elsif and_reduce(std_logic_vector(ectr)) = '1' then
				if cctr = unsigned(ctrl_fake_cyc_len) then
					cctr <= (others => '0');
				else
					cctr <= cctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	spill_f <= '1' when cctr < unsigned(ctrl_fake_spill_len) else '0';
	veto_f <= '1' when cctr = unsigned(ctrl_fake_cyc_len) else '0';
	
-- Combine spill sources
	
	spill_r <= (spill_e and not ctrl_src) or (spill_f and ctrl_src) or ctrl_force;
	veto <= ctrl_en and ((veto_i and not ctrl_src) or (veto_f and ctrl_src));

-- Command generator

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or spill_r = spill_i or ctrl_en = '0' then
				scmd_out <= CMD_W_NULL;
			else
				if spill_r = '1' and spill_i = '0' then
					scmd_out.d <= X"0" & SCMD_SPILL_START;
				else
					scmd_out.d <= X"0" & SCMD_SPILL_STOP;
				end if;
				scmd_out.req <= '1';
				scmd_out.last <= '1';
			end if;
		end if;
	end process;

-- Spill signal

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or ctrl_en = '0' then
				spill_i <= '0';
			elsif scmd_in.ack = '1' then
				spill_i <= spill_r;
			end if;
		end if;
	end process;
	
	spill <= spill_i;
	
-- Counters

	trst <= rst or ctrl_clr;
	sinc <= spill_r and scmd_in.ack;

	actrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			clk => clk,
			rst => trst,
			inc(0) => sinc,
			inc(1) => ss_i,
			inc(2) => se_i,
			inc(3) => sw_i
		);
		
-- Timestamp logs

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				start_ts <= (others => '0');
				end_ts <= (others => '0');
				warn_ts <= (others => '0');
			else
				if ss_i = '1' then
					start_ts <= tstamp;
				end if;
				if se_i = '1' then
					end_ts <= tstamp;
				end if;
				if sw_i = '1' then
					warn_ts <= tstamp;
				end if;
			end if;
		end if;
	end process;
	
	d <= warn_ts & end_ts & start_ts;
	
	ts_ctrs: entity work.ipbus_ctrs_samp
		generic map(
			N_CTRS => 3,
			CTR_WDS => 2
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TSTAMP),
			ipb_out => ipbr(N_SLV_TSTAMP),
			clk => clk,
			d => d
		);

end rtl;
