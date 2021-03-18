-- switchyard
--
-- Handling signal routing in fanout
--
-- master_src = 0: upstream master (via USFP) talks to ports and local endpoint ('fanout mode')
-- master_src = 1: local master talks to ports and local endpoint ('local mode')
--
-- ep_src = 0: downstream ports are routed to upstream master and local master ('fanout mode')
-- ep_src = 1: local endpoint talks back to upstream master and local master ('test mode')
--
-- Dave Newbold, February 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity switchyard is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		mclk: in std_logic;
		d_us: in std_logic; -- From upstream port
		q_us: out std_logic; -- To upstream port
		d_master: in std_logic; -- From local master
		q_master: out std_logic; -- To local master
		d_ep: in std_logic; -- From local endpoint
		q_ep: out std_logic; -- To local endpoint
		d_cdr: in std_logic; -- From downstream ports via CDR
		q: out std_logic; -- To downstream ports
		tx_dis_in: in std_logic;
		ep_rdy: in std_logic;
		tx_dis: out std_logic
	);

end switchyard;

architecture rtl of switchyard is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal ctrl_master_src, ctrl_ep_src: std_logic;
	
begin

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl
		);
		
	ctrl_master_src <= ctrl(0)(0);
	ctrl_ep_src <= ctrl(0)(1);
		
	process(mclk) -- lots of CDCs in gere, but ctrl is treated as static
	begin
		if rising_edge(mclk) then
			if ctrl_ep_src = '0' then
				q_us <= d_cdr;
				q_master <= d_cdr;
			else
				q_us <= d_ep;
				q_master <= d_ep;
			end if;
			if ctrl_master_src = '0' then
				q_ep <= d_us;
				q <= d_us;
			else
				q_ep <= d_master;
				q <= d_master;
			end if;
		end if;
	end process;

	tx_dis <= tx_dis_in when ctrl_ep_src = '1' else not ep_rdy; 

end rtl;
