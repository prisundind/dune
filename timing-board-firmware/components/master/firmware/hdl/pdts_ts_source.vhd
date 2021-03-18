-- pdts_ts_source
--
-- Maintains the timestamp counter
--
-- A simple resettable counter for now, might be more complex (e.g. time-of-day) later
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_ts_source.all;

use work.pdts_defs.all;
use work.pdts_master_defs.all;

entity pdts_ts_source is
	generic(
		N_PART: positive
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk10: in std_logic;
		irig: in std_logic;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0)
	);

end pdts_ts_source;

architecture rtl of pdts_ts_source is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, stat: ipb_reg_v(0 downto 0);

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
      sel => ipbus_sel_pdts_ts_source(ipb_in.ipb_addr),
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
		
	stat(0) <= (others => '0');
    
-- Timestamp counter

	ctr: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => 1,
			CTR_WDS => TSTAMP_WDS / 4,
			READ_ONLY => false
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTR),
			ipb_out => ipbr(N_SLV_CTR),
			clk => clk,
			rst => rst,
			inc(0) => '1',
			q(8 * TSTAMP_WDS - 1 downto 0) => tstamp
		);
	
end rtl;
