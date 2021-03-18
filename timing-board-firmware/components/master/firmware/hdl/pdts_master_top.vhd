-- pdts_master_top
--
-- The top-level timing master design
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_decode_pdts_master_top.all;

use work.pdts_defs.all;

entity pdts_master_top is
	generic(
		SIM: boolean := false;
		NIM_TRIGGER : boolean := false
	);
	port(
		ipb_clk: in std_logic; -- IPbus connection
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic; -- The serial IO clock
		clk: in std_logic; -- The system clock
		rst: in std_logic; -- Sync reset (clk domain)
		spill_warn: in std_logic := '0';
		spill_start: in std_logic := '0';
		spill_end: in std_logic := '0';
		sync: out std_logic;
		clk10: in std_logic := '0';
		irig: in std_logic := '0';
		q: out std_logic; -- Output (mclk domain)
		d: in std_logic; -- Input (mclk domain)
		t_d: in std_logic; -- Input from trigger
		rdy: out std_logic; -- Ready output from built-in endpoint
		edge: out std_logic; -- Edge control output from built-in endpoint
		t_edge: out std_logic -- Edge control output from trigger endpoint
	);

end pdts_master_top;

architecture rtl of pdts_master_top is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal scmd_in: cmd_w;
	signal scmd_out: cmd_r;
	
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
      sel => ipbus_sel_pdts_master_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- The master

	master: entity work.pdts_master
		generic map(
			SIM => SIM
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_MASTER),
			ipb_out => ipbr(N_SLV_MASTER),
			mclk => mclk,
			clk => clk,
			rst => rst,
			spill_warn => spill_warn,
			spill_start => spill_start,
			spill_end => spill_end,
			sync => sync,
			clk10 => clk10,
			irig => irig,
			q => q,
			d => d,
			t_scmd_in => scmd_in,
			t_scmd_out => scmd_out,
			rdy => rdy,
			edge => edge
		);

-- Trigger receiver
generate_trig_input: if NIM_TRIGGER generate
	-- Generate trigger commands from NIM input
	-- Used for ICEBERG
	NimTrig: entity work.nim_to_trig_cmd
		port map(
			clk => clk,
			rst => rst,
			nim_trig_signal => spill_warn,
			scmd_out => scmd_in,
			scmd_in => scmd_out
		);
else generate
	-- Generate trigger from signals on HDMI cable
	-- Used for ProtoDUNE-I
	trigRx: entity work.pdts_trig_rx
		generic map(
			SIM => SIM
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TRIG),
			ipb_out => ipbr(N_SLV_TRIG),
			mclk => mclk,
			clk => clk,
			d => t_d,
			edge => t_edge,
			scmd_out => scmd_in,
			scmd_in => scmd_out
		);
end generate;


 
end rtl;
