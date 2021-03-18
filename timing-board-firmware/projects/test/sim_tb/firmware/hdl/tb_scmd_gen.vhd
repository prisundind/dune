-- tb_scmd_gen
--
-- Generates time stamp packets
--
-- Dave Newbold, March 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.pdts_defs.all;

entity tb_scmd_gen is
	port(
		clk: in std_logic;
		rst: in std_logic;
		d: out std_logic_vector(7 downto 0);
		v: out std_logic;
		last: out std_logic;
		ack: in std_logic;
		ren: in std_logic
	);

end tb_scmd_gen;

architecture rtl of tb_scmd_gen is

begin

	

end rtl;
