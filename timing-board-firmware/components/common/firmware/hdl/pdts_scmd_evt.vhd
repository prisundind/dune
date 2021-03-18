-- pdts_scmd_evt
--
-- Logs sync commands to DAQ; system -> ipb clock domains crossed in this block
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

entity pdts_scmd_evt is
	port(
		clk: in std_logic;
		rst: in std_logic;
		scmd: in std_logic_vector(3 downto 0);
		valid: in std_logic;
		tstamp: in std_logic_vector(63 downto 0);
		evtctr: in std_logic_vector(31 downto 0);
		empty: out std_logic;
		err: out std_logic;
		rob_clk: in std_logic; -- readout buffer clock
		rob_rst: in std_logic;
		rob_en: in std_logic;
		rob_q: out std_logic_vector(31 downto 0);
		rob_we: out std_logic;
		rob_full: in std_logic
	);

end pdts_scmd_evt;

architecture rtl of pdts_scmd_evt is

	COMPONENT pdts_evt_fifo
		PORT (
			rst : IN STD_LOGIC;
			wr_clk : IN STD_LOGIC;
			rd_clk : IN STD_LOGIC;
			din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			wr_en : IN STD_LOGIC;
			rd_en : IN STD_LOGIC;
			dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			full : OUT STD_LOGIC;
			empty : OUT STD_LOGIC
		);
	END COMPONENT;

	signal wen: std_logic;
	type d_t is array(5 downto 0) of std_logic_vector(31 downto 0);
	signal d, q: d_t;
	signal empty_f, full_f: std_logic_vector(5 downto 0) := (others => '0');
	signal rctr: unsigned(2 downto 0);
	signal err_i, empty_i, v, done: std_logic;
	
begin

	wen <= valid and rob_en and not err_i; -- CDC for wen <= rob_en. rob_en is a guaranteed long pulse with no glitches

	d(0) <= X"aa000600"; -- DAQ word 0
	d(1) <= X"0000000" & scmd; -- DAQ word 1
	d(2) <= tstamp(31 downto 0); -- DAQ word 2
	d(3) <=	tstamp(63 downto 32); -- DAQ word 3
	d(4) <= evtctr; -- DAQ word 4
	d(5) <= X"00000000"; -- Dummy checksum (not implemented yet)
	
	fgen: for i in 4 downto 1 generate
	
	   signal ren: std_logic;
	   
	begin
	
		ren <= '1' when rctr = i and v = '1' else '0';
		
		fifo: pdts_evt_fifo
			port map(
				rst => rob_rst,
				wr_clk => clk,
				rd_clk => rob_clk,
				din => d(i),
				wr_en => wen,
				rd_en => ren,
				dout => q(i),
				full => full_f(i),
				empty => empty_f(i)
			);
		
	end generate;

	q(0) <= d(0);
	q(5) <= d(5);
	
	empty_i <= or_reduce(empty_f);
	empty <= empty_i;
	err_i <= (err_i or or_reduce(full_f)) and (rob_en and not rob_rst) when rising_edge(clk); -- err status is latched
	err <= err_i;
	
	v <= (v or not empty_i) and not (done or rob_rst or not rob_en) when rising_edge(rob_clk);
	done <= '1' when rctr = 5 else '0';
	
	process(rob_clk)
	begin
		if rising_edge(rob_clk) then
			if rob_rst = '1' then
				rctr <= (others => '0');
			elsif v = '1' and rob_full = '0' then
				if done = '1' then
					rctr <= (others => '0');
				else
					rctr <= rctr + 1;
				end if;
			end if;
		end if;
	end process;
	
	rob_q <= q(to_integer(rctr));
	rob_we <= v and not rob_full;
	
end rtl;
