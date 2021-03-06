-- master_defs
--
-- Constants and types for PDTS master
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package pdts_master_defs is

	constant MASTER_VERSION: std_logic_vector(31 downto 0) := X"00050100"; -- Version number
	constant N_PART: integer := 4; -- Number of partitions (max 4 at present)
	constant N_CHAN: integer := 5; -- Number of scmd generator channels
	constant TS_DIV: positive := 62500000; -- 1Hz (must be divisible by 25)
	constant THROTTLE_TICKS: positive := 400000; -- 10ms between triggers
	
end pdts_master_defs;
