-- pdts_rob
--
-- Readout buffer; size of buffer is 1k words * N_FIFO
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

entity pdts_rob is
	generic(
		N_FIFO: positive := 1;
		WARN_HWM: natural := 768;
		WARN_LWM: natural := 512
	);
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rst: in std_logic; -- Buffer enable / nreset
		d: in std_logic_vector(31 downto 0); -- data in 
		we: in std_logic; -- write enable in
		full: out std_logic; -- full flag out
		empty: out std_logic; -- empty flag out
		warn: out std_logic -- warning flag out
	);

end pdts_rob;

architecture rtl of pdts_rob is

	signal rsti, re: std_logic;
	signal ctr: std_logic_vector(17 downto 0);
	signal d_fifo, q_fifo: std_logic_vector(35 downto 0);
	signal valid, w: std_logic;

begin

  rsti <= rst or ipb_rst;	
	re <= ipb_in.ipb_strobe and not ipb_in.ipb_addr(0) and not ipb_in.ipb_write and valid;
	
	d_fifo <= X"0" & d;
	
	buf: entity work.big_fifo_36
		generic map(
			N_FIFO => N_FIFO
		)
		port map(
			clk => ipb_clk,
			rst => rsti,
			d => d_fifo,
			wen => we,
			full => full,
			empty => empty,
			ctr => ctr,
			ren => re,
			q => q_fifo,
			valid => valid
		);
	
	ipb_out.ipb_rdata <= q_fifo(31 downto 0) when ipb_in.ipb_addr(0) = '0' else (31 downto ctr'length => '0') & ctr;
	ipb_out.ipb_ack <= ipb_in.ipb_strobe and not ipb_in.ipb_write and (valid or ipb_in.ipb_addr(0));
	ipb_out.ipb_err <= ipb_in.ipb_strobe and (ipb_in.ipb_write or not (valid or ipb_in.ipb_addr(0)));
	
	process(ipb_clk)
	begin
		if rising_edge(ipb_clk) then
			if rsti = '1' then
				w <= '0';
			elsif unsigned(ctr) > WARN_HWM then
				w <= '1';
			elsif unsigned(ctr) < WARN_LWM then
				w <= '0';
			end if;
		end if;
	end process;
	
	warn <= w;
	
end rtl;
