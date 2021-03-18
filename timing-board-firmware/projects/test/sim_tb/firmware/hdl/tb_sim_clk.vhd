-- tb_sim_clk
--
-- Clock generation for pdts sim
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pdts_defs.all;

entity tb_sim_clk is
	port(
		sclk: out std_logic;
		clk: out std_logic;
		rst: out std_logic;
		stb: out std_logic;
		fclk: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);

end tb_sim_clk;

architecture tb of tb_sim_clk is

	signal bclk, clki, fclki: std_logic := '1';
	signal rsti: std_logic := '1';
	signal bclkd, lock: std_logic;
	signal ctr, sctr: unsigned(3 downto 0) := X"0";
	
begin

	fclki <= not fclki after 16 ns;
	fclk <= fclki;
	bclk <= not bclk after 10 ns / SCLK_RATIO;
	bclkd <= bclk;
	sclk <= bclkd; -- Align delta delays between sclk and clk
	
	process(bclk)
	begin
		if bclk'event then
			if phase_rst = '1' then
				ctr <= X"0";
				clki <= bclk;
				if rising_edge(bclk) then
					lock <= '0';
				end if;
			else
				if rising_edge(bclk) then
					lock <= '1';
				end if;
				if ctr = SCLK_RATIO - 1 then
					ctr <= X"0";
					clki <= not clki;
				else
					ctr <= ctr + 1;
				end if;
			end if;
		end if;
	end process;

	clk <= clki;
	rsti <= '0' after 30 ns;
	rst <= rsti when rising_edge(clki);
	
-- Fake the random response behaviour of an MMCM
	
	process(lock)
		variable seed1, seed2: integer := 123456789;
		variable rand: real;
	begin
		if lock = '0' then
			phase_locked <= '0';
		else
			uniform(seed1, seed2, rand);
			phase_locked <= '1' after rand * 1 us;
		end if;
	end process;
		
	process(clki)
	begin
		if rising_edge(clki) then
			if sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	stb <= '1' when sctr = 0 else '0';

end tb;
