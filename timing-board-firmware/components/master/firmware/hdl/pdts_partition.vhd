-- pdts_partition
--
-- The PDTS master partition block
--
-- TODO: grabbing sync word...
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_partition.all;

use work.pdts_defs.all;
use work.pdts_master_defs.all;

entity pdts_partition is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		spill: in std_logic;
		veto: in std_logic;
		scmd_out: out cmd_w;
		scmd_in: in cmd_r;
		typ: in std_logic_vector(SCMD_W - 1 downto 0);
		tv: in std_logic;
		tack: out std_logic
	);
		
end pdts_partition;

architecture rtl of pdts_partition is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_part_en, ctrl_run_req, ctrl_trig_en, ctrl_evtctr_rst, ctrl_trig_ctr_rst, ctrl_buf_en, ctrl_rate_ctrl_en, ctrl_spill_gate_en: std_logic;
	signal ctrl_trig_mask, ctrl_frag_mask: std_logic_vector(7 downto 0);
	signal frag_mask: std_logic_vector(15 downto 0);
	signal run_int, part_up: std_logic;
	signal v, grab, trig, frag, trst: std_logic;
	signal evtctr: std_logic_vector(8 * EVTCTR_WDS - 1 downto 0);
	signal t, tacc, trej: std_logic_vector(SCMD_MAX downto 0);
	signal buf_warn, buf_err, in_spill, in_run, rob_en_s: std_logic;
	signal thr: std_logic;
	signal tctr: unsigned(calc_width(THROTTLE_TICKS) - 1 downto 0);
	
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
      sel => ipbus_sel_pdts_partition(ipb_in.ipb_addr),
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
			q => ctrl
		);

	ctrl_part_en <= ctrl(0)(0);
	ctrl_run_req <= ctrl(0)(1);
	ctrl_trig_en <= ctrl(0)(2);
	ctrl_buf_en <= ctrl(0)(3);
	ctrl_trig_ctr_rst	<= ctrl(0)(4);
	ctrl_rate_ctrl_en <= ctrl(0)(5);
	ctrl_spill_gate_en <= ctrl(0)(6);
	ctrl_trig_mask <= ctrl(0)(15 downto 8);
	ctrl_frag_mask <= ctrl(0)(23 downto 16);
	stat(0) <= X"000000" & "00" & in_run & in_spill & run_int & part_up & buf_warn & buf_err;

-- Run start / stop

	sm: entity work.pdts_partition_sm
		port map(
			clk => clk,
			rst => rst,
			part_en_req => ctrl_part_en,
			run_req => ctrl_run_req,
			spill => spill,
			scmd_out => scmd_out,
			scmd_in => scmd_in,
			part_en => part_up,
			run => run_int
		);
	
-- Command masks

	v <= '1' when tv = '1' and part_up = '1' and (in_run = '1' or unsigned(typ) < 8) else '0';

	grab <= v when ((typ = SCMD_RUN_START or typ = SCMD_RUN_STOP) and scmd_in.ack = '1') -- Grab run start or stop only if we issued it
		or (unsigned(typ) < 8 and typ /= SCMD_RUN_START and typ /= SCMD_RUN_STOP) -- Grab all other system commands if partition is running
		or (unsigned(typ) > 7 and ctrl_trig_en = '1' and veto = '0' and not (ctrl_spill_gate_en = '1' and spill = '0') and ctrl_trig_mask(to_integer(unsigned(typ(2 downto 0)))) = '1' and thr = '0') -- Otherwise apply trigger masks
		else '0';
		
	tack <= grab;
	trig <= grab and EVTCTR_MASK(to_integer(unsigned(typ))); -- A physics trigger
	
-- Rate control

	process(clk)
	begin
		if rising_edge(clk) then
			if part_up = '0' or ctrl_rate_ctrl_en = '0' then
				tctr <= (others => '0');
			elsif thr = '1' or trig = '1' then
				if tctr = THROTTLE_TICKS - 1 then
					tctr <= (others => '0');
				else
					tctr <= tctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	thr <= or_reduce(std_logic_vector(tctr));

-- Command counters
	
	process(typ) -- Unroll typ
	begin
		for i in t'range loop
			if typ = std_logic_vector(to_unsigned(i, typ'length)) then
				t(i) <= '1';
			else
				t(i) <= '0';
			end if;
		end loop;
	end process;
	
	tacc <= t when v = '1' and grab = '1' else (others => '0');
	trej <= t when v = '1' and grab = '0' else (others => '0');

-- Event counter etc

	decode: entity work.pdts_ep_decoder
		port map(
			clk => clk,
			rst => rst,
			rdy => '1',
			scmd => typ,
			scmd_v => grab,
			in_spill => in_spill,
			in_run => in_run,
			evtctr => evtctr
		);

-- Event counter

	esamp: entity work.ipbus_ctrs_samp
		generic map(
			N_CTRS => 1,
			CTR_WDS => EVTCTR_WDS / 4
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_EVTCTR),
			ipb_out => ipbr(N_SLV_EVTCTR),
			clk => clk,
			d => evtctr
		);
		
-- Event buffer

	synchro: entity work.pdts_synchro
		generic map(
			N => 1
		)
		port map(
			clk => clk,
			clks => ipb_clk,
			d(0) => ctrl_buf_en,
			q(0) => rob_en_s
		);
		
	frag_mask <= EVTCTR_MASK(15 downto 8) & ctrl_frag_mask;
	frag <= grab and frag_mask(to_integer(unsigned(typ))); -- Generate a fragment

	rob: entity work.pdts_mon_buf
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			en => rob_en_s,
			clk => clk,
			rst => rst,
			scmd => typ,
			scmd_v => frag,
			tstamp => tstamp,
			evtctr => evtctr,
			warn => buf_warn,
			err => buf_err
		);

-- Trigger counters

	trst <= rst or ctrl_trig_ctr_rst or not ctrl_part_en;
	
	actrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ACTRS),
			ipb_out => ipbr(N_SLV_ACTRS),
			clk => clk,
			rst => trst,
			inc => tacc
		);

	rctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_RCTRS),
			ipb_out => ipbr(N_SLV_RCTRS),
			clk => clk,
			rst => trst,
			inc => trej
		);	
	
end rtl;
