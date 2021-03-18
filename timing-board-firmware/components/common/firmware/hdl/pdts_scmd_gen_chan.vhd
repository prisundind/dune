-- pdts_scmd_gen_chan
--
-- Generates random sync commands
--
-- The division from base clock to the desired rate is done in three steps:
-- a) A pre-division by 256
-- b) Division by a power of two set by n = 2 ^ rate_div_d (ranging from 2^0 -> 2^15)
-- c) 1-in-n prescaling set by n = rate_div_p
--
-- Dave Newbold, June 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.pdts_defs.all;


entity pdts_scmd_gen_chan is
	generic(
		ID: natural
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
		rand: in std_logic_vector(31 downto 0);
		scmd_out: out cmd_w;
		scmd_in: in cmd_r;
		ack: out std_logic;
		rej: out std_logic
	);

end pdts_scmd_gen_chan;

architecture rtl of pdts_scmd_gen_chan is

	constant ID_V: std_logic_vector := std_logic_vector(to_unsigned(ID, 4));
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stb: std_logic;
	signal ctrl_en, ctrl_patt, ctrl_force: std_logic;
	signal ctrl_type: std_logic_vector(7 downto 0);
	signal ctrl_rate_div_p: std_logic_vector(7 downto 0);
	signal ctrl_rate_div_d: std_logic_vector(3 downto 0);
	signal r_i: integer range 2 ** 4 - 1 downto 0 := 0;
	signal src: std_logic_vector(31 downto 0);
	signal s, c, v: std_logic;
	signal pctr: unsigned(7 downto 0);
	signal mask: std_logic_vector(15 downto 0);
	
begin

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk,
			q => ctrl,
			stb(0) => stb
		);

	ctrl_en <= ctrl(0)(0);
	ctrl_patt <= ctrl(0)(1);
	ctrl_force <= ctrl(0)(2);
	ctrl_type <= ctrl(0)(15 downto 8);
	ctrl_rate_div_p <= ctrl(0)(23 downto 16);
	ctrl_rate_div_d <= ctrl(0)(27 downto 24);
	
	process(ctrl_rate_div_d)
	begin
		for i in mask'range loop
			if i >= to_integer(unsigned(ctrl_rate_div_d)) then
				mask(i) <= '0';
			else
				mask(i) <= '1';
			end if;
		end loop;
	end process;
	
	src <= tstamp(31 downto 0) when ctrl_patt = '0' else rand;
	s <= '1' when ctrl_en = '1' and or_reduce(src(23 downto 8) and mask) = '0' and src(7 downto 0) = '1' & std_logic_vector(to_unsigned(ID, 3)) & X"0" else '0';
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or ctrl_en = '0' then
				pctr <= X"00";
			elsif s = '1' then
				if pctr = Unsigned(ctrl_rate_div_p) then
					pctr <= X"00";
				else
					pctr <= pctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	c <= '1' when pctr = X"00" else '0';
	
	v <= (s and c) or (ctrl_force and stb);
			
	scmd_out.d <= ctrl_type;
	scmd_out.req <= v;
	scmd_out.last <= '1';
	
	ack <= v and scmd_in.ack;
	rej <= v and not scmd_in.ack;
		
end rtl;
