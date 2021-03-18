-- pdts_scmd_gen
--
-- Generates random sync commands
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_pdts_scmd_gen.all;

use work.pdts_defs.all;

entity pdts_scmd_gen is
	generic(
		N_CHAN: positive
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;		
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		scmd_out: out cmd_w_array(N_CHAN - 1 downto 0);
		scmd_in: in cmd_r_array(N_CHAN - 1 downto 0)
	);

end pdts_scmd_gen;

architecture rtl of pdts_scmd_gen is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, ctrl_sel: ipb_reg_v(0 downto 0);
	signal ctrl_clr: std_logic;
	signal sel: std_logic_vector(3 downto 0);
	signal rand: std_logic_vector(31 downto 0);
	signal ipbw_c: ipb_wbus_array(N_CHAN - 1 downto 0);
	signal ipbr_c: ipb_rbus_array(N_CHAN - 1 downto 0);
	signal tacc, trej: std_logic_vector(N_CHAN - 1 downto 0);
	signal trst: std_logic;

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
			sel => ipbus_sel_pdts_scmd_gen(ipb_in.ipb_addr),
			ipb_to_slaves => ipbw,
			ipb_from_slaves => ipbr
		);
		
-- CSR

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CTRL),
			ipb_out => ipbr(N_SLV_CTRL),
			slv_clk => clk,
			q => ctrl,
			qmask(0) => X"00000001"
		);
	
	ctrl_clr <= ctrl(0)(0);
		
-- Channel select register

	selreg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_SEL),
			ipbus_out => ipbr(N_SLV_SEL),
			q => ctrl_sel,
			qmask(0) => (sel'range => '1', others => '0')
		);
		
	sel <= ctrl_sel(0)(sel'range);
		
-- RNG

	rng: entity work.rng_wrapper
		port map(
			clk => clk,
			rst => rst,
			random => rand
		);

-- Channels

	fabric_t: entity work.ipbus_fabric_sel
		generic map(
    	NSLV => N_CHAN,
    	SEL_WIDTH => sel'length
    )
    port map(
      ipb_in => ipbw(N_SLV_CHAN_CTRL),
      ipb_out => ipbr(N_SLV_CHAN_CTRL),
      sel => sel,
      ipb_to_slaves => ipbw_c,
      ipb_from_slaves => ipbr_c
    );
		
	tgen: for i in N_CHAN - 1 downto 0 generate	
	begin
		
		gen: entity work.pdts_scmd_gen_chan
		  generic map(
		  	ID => i
		  )
			port map(
				ipb_clk => ipb_clk,
				ipb_rst => ipb_rst,
				ipb_in => ipbw_c(i),
				ipb_out => ipbr_c(i),
				clk => clk,
				rst => rst,
				tstamp => tstamp,
				rand => rand,
				scmd_out => scmd_out(i),
				scmd_in => scmd_in(i),
				ack => tacc(i),
				rej => trej(i)
			);

	end generate;

-- Counters

	trst <= rst or ctrl_clr;

	actrs: entity work.ipbus_ctrs_v
		generic map(
			N_CTRS => N_CHAN
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
			N_CTRS => N_CHAN
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
