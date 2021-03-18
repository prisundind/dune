-------------------------------------------------------------------------------
-- Title      : Testbench for design "pdts_rst_stretch"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pdts_rst_stretch_tb.vhd
-- Author     : David Cussans  <phdgc@localhost.localdomain>
-- Company    : 
-- Created    : 2020-10-05
-- Last update: 2020-10-05
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2020 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-10-05  1.0      phdgc	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity pdts_rst_stretch_tb is

end entity pdts_rst_stretch_tb;

-------------------------------------------------------------------------------

architecture behavioural of pdts_rst_stretch_tb is

  -- component ports
  signal rst  : std_logic := '0';
  signal rsto : std_logic;
  signal wen  : std_logic;

  -- clock
  signal Clk : std_logic := '1';

begin  -- architecture behavioural

  -- component instantiation
  DUT: entity work.pdts_rst_stretch
    port map (
      clk  => clk,
      rst  => rst,
      rsto => rsto,
      wen  => wen);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- waveform generation
  WaveGen_Proc: process
  begin
    -- insert signal assignments here
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    
    --wait until Clk = '1';
    wait;
    
  end process WaveGen_Proc;

  report_rsto: process(rsto,wen) 
  begin  -- process report_rsto
    report "state of RSTO =" & std_logic'image(rsto) severity note;
    report "state of WEN =" & std_logic'image(wen) severity note;
  end process report_rsto;

end architecture behavioural;

-------------------------------------------------------------------------------

-- configuration pdts_rst_stretch_tb_behavioural_cfg of pdts_rst_stretch_tb is
--   for behavioural
--   end for;
-- end pdts_rst_stretch_tb_behavioural_cfg;

-------------------------------------------------------------------------------
