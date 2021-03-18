-- pdts_ep_sync_pulse
--
-- Provides a sync pulse (based on a programmable command type) for external hardware.
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.pdts_defs.all;

entity pdts_ep_sync_pulse is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic; -- 50MHz clock
		rst: in std_logic; -- Sync reset
		s: in std_logic_vector(SCMD_W - 1 downto 0);
		s_stb: in std_logic;
		s_first: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		pulse_out: out std_logic
	);

end pdts_ep_sync_pulse;

architecture rtl of pdts_ep_sync_pulse is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(2 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal ctrl_en, ctrl_force, ctrl_rst: std_logic;
	signal ctrl_cmd: std_logic_vector(3 downto 0);
	signal cnt: unsigned(31 downto 0);
	signal t: std_logic_vector(63 downto 0);
	
begin

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 3
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk,
			d => stat,
			q => ctrl,
			stb => stb
		);
		
	ctrl_en <= ctrl(0)(0);
	ctrl_force <= ctrl(0)(1) and stb(0);
	ctrl_cmd <= ctrl(0)(7 downto 4);
	ctrl_rst <= ctrl(0)(8);
	
	stat(0) <= std_logic_vector(cnt);
	stat(1) <= t(31 downto 0);
	stat(2) <= t(63 downto 32);
	
	process(clk)
	begin
		if rising_edge(clk) then
			pulse_out <= '0';
			if rst = '1' or ctrl_rst = '1' then
				cnt <= (others => '0');
				t <= (others => '0');
			elsif s = ctrl_cmd and s_stb = '1' and s_first = '1' then
				cnt <= cnt + 1;
				t <= tstamp;
				pulse_out <= '1';
			end if;
		end if;
	end process;

end rtl;
