-- tb_tx
--
-- Testbench for basic tx functions
--
-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_tb_tx.all;
use work.pdts_defs.all;

entity tb_tx is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		fmc_clk: in std_logic;
		rst: in std_logic;
		q: out std_logic
	);
		
end tb_tx;

architecture rtl of tb_tx is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal ctrl_mmcm_rst, ctrl_en, ctrl_clr: std_logic;
	signal clr, clkfbout, clkfbin, clki, phase_locked, clk, rsti, rstl: std_logic;
	signal sctr: unsigned(3 downto 0) := X"0";
	signal stb, en, tx_err, tx_last, tx_ack, tx_rdy, tx_s_v, tx_stb, k: std_logic;
	signal tx_d, tx_s_d: std_logic_vector(7 downto 0);
	signal d: std_logic_vector(7 downto 0);

	attribute IOB: string;
	attribute IOB of q: signal is "TRUE";
	
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_tb_tx(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => clk,
			d => stat,
			q => ctrl
		);

	stat(0) <= X"0000000" & "00" & tx_err & phase_locked;
	ctrl_en <= ctrl(0)(0);
	ctrl_clr <= ctrl(0)(1);
		
-- Clock divider

	clkgen: entity work.pdts_rx_div_mmcm
		port map(
			sclk => fmc_clk,
			clk => clk,
			phase_rst => '0',
			phase_locked => phase_locked
		);

	rstl <= rst or not phase_locked;
	
	synchro: entity work.pdts_synchro
		generic map(
			N => 3
		)
		port map(
			clk => ipb_clk,
			clks => clk,
			d(0) => rstl,
			d(1) => ctrl_en,
			d(2) => ctrl_clr,
			q(0) => rsti,
			q(1) => en,
			q(2) => clr
		);

-- Strobe gen

	process(clk)
	begin
		if rising_edge(clk) then
			if sctr = (10 / SCLK_RATIO) - 1 then
				sctr <= X"0";
			else
				sctr <= sctr + 1;
			end if;
		end if;
	end process;
	
	stb <= '1' when sctr = 0 else '0';

-- Pattern gen

	idle: entity work.pdts_idle_gen
		port map(
			clk => clk,
			rst => rsti,
			d => tx_d,
			last => tx_last,
			ack => tx_ack
		);
		
	sync: entity work.pdts_sync_gen
		port map(
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			en => en,
			clk => clk,
			rst => rsti,
			clr => clr,
			stb => stb,
			d => tx_s_d,
			v => tx_s_v,
			rdy => tx_rdy
		);
		
-- Tx

	tx: entity work.pdts_tx
		port map(
			clk => clk,
			rst => rsti,
			stb => stb,
			addr => X"AA",
			s_d => tx_s_d,
			s_valid => tx_s_v,
			s_rdy => tx_rdy,
			a_d => tx_d,
			a_last => tx_last,
			a_ack => tx_ack,
			q => d,
			k => k,
			stbo => tx_stb,
			err => tx_err
		);
		
-- Tx PHY

	txphy: entity work.pdts_tx_phy_int
		port map(
			clk => clk,
			rst => rsti,
			d => d,
			k => k,
			stb => tx_stb,
			txclk => fmc_clk,
			q => q
		);

end rtl;
