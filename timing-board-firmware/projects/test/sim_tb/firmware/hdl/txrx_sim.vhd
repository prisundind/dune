-- tb_txrx
--
-- Testbench for basic tx/rx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;

entity txrx_sim is

end txrx_sim;

architecture tb of txrx_sim is

	signal s: std_logic;
	
begin

-- Tx

	tx: entity work.tb_tx_sim
		port map(
			q => s
		);

-- Rx

	rx: entity work.tb_rx_sim
		port map(
			d => s
		);

end tb;
