-- pdts_sync_gen
--
-- Generates random sync packets for testbench
--
-- Dave Newbold, October 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.pdts_defs.all;

entity pdts_sync_gen is
	port(
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		en: in std_logic;
		clk: in std_logic;
		rst: in std_logic;
		tstamp: in std_logic_vector(3 downto 0);
		clr: in std_logic;
		stb: in std_logic;
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		rdy: in std_logic
	);

end pdts_sync_gen;

architecture rtl of pdts_sync_gen is

	signal b: std_logic;
	signal r: std_logic_vector(7 downto 0);
	signal ctr, len: unsigned(7 downto 0);
	signal typ, ts: std_logic_vector(3 downto 0);
	signal go, run, last: std_logic;
	type sctr_t is array(15 downto 0) of unsigned(31 downto 0);
	signal sctr: sctr_t;

begin

-- PRBS8 gen

	b <= r(7) xor r(5) xor r(4) xor r(3);
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				r <= X"01";
			elsif stb = '1' then
				r <= r(6 downto 0) & b;
			end if;
		end if;
	end process;
	
-- Counter                  

	go <= '1' when r(3 downto 0) = X"0" and rdy = '1' and run = '0' and en = '1' and rst = '0' else '0';
	
	process(clk)
	begin
		if rising_edge(clk) then
			run <= ((run and not (last and stb)) or go) and not rst;
			if go = '1' then
				ctr <= X"00";
				ts <= tstamp;
				typ <= r(7 downto 4);
				len <= to_unsigned(SCMD_LEN(to_integer(unsigned(r(7 downto 4)))), len'length);
			elsif run = '1' and stb = '1' then
				ctr <= ctr + 1;
			end if;
		end if;
	end process;
	
	last <= '1' when ctr = len else '0';

	with ctr select d <=
		X"F" & ts when 0,
		X"0" & typ when 1,
		r(7 downto 0) when others;

	v <= run;
	
-- Command counters

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or clr = '1' then
				sctr <= (others => (others => '0'));
			else
				for i in 15 downto 0 loop
					if unsigned(r(7 downto 4)) = i and go = '1' then
						sctr(i) <= sctr(i) + 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	ipb_out.ipb_rdata <= std_logic_vector(sctr(to_integer(unsigned(ipb_in.ipb_addr(3 downto 0)))));
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';

end rtl;
