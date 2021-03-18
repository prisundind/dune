-- pdts_trig_rx
--
-- Receiver for trigger command input
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_trig_rx.all;

use work.pdts_defs.all;

entity pdts_trig_rx is
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
		d: in std_logic; -- Input from trigger
		edge: out std_logic;
		scmd_out: out cmd_w;
		scmd_in: in cmd_r
	);

end pdts_trig_rx;

architecture rtl of pdts_trig_rx is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_ep_en, ctrl_ext_trig_en: std_logic;
	signal ep_stat, ep_fdel: std_logic_vector(3 downto 0);
	signal ep_rst, ep_rdy, ep_edge: std_logic;
	signal scmd: cmd_w;
	signal t: std_logic_vector(SCMD_MAX downto 0);
	
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
      sel => ipbus_sel_pdts_trig_rx(ipb_in.ipb_addr),
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
		
	ctrl_ep_en <= ctrl(0)(0);
	ctrl_ext_trig_en <= ctrl(0)(1);
	stat(0) <= X"0000" & "000" & ep_edge & ep_fdel & "000" & ep_rdy & ep_stat; -- CDC, don't care (pseudo static levels)

-- The rx endpoint

	ep_rst <= ipb_rst or not ctrl_ep_en;

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
			scmd => scmd,
			acmd => open
		);
		
	edge <= ep_edge;

-- Trigger counters

	process(scmd) -- Unroll sync command
	begin
		for i in t'range loop
			if scmd.d = std_logic_vector(to_unsigned(i, scmd.d'length)) and scmd.req = '1' and ep_rdy = '1' then
				t(i) <= '1';
			else
				t(i) <= '0';
			end if;
		end loop;
	end process;

	ctrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => t'length
		)
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			clk => clk,
			rst => ep_rst,
			inc => t
		);
		
-- outputs

	scmd_out <= scmd when ctrl_ext_trig_en = '1' else CMD_W_NULL;
	
end rtl;
