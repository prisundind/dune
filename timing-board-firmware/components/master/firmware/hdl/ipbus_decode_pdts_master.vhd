-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_pdts_master is

  constant IPBUS_SEL_WIDTH: positive := 4;
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_pdts_master(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Nov 27 14:17:41 2020 
  constant N_SLV_GLOBAL: integer := 0;
  constant N_SLV_SPILL: integer := 1;
  constant N_SLV_TSTAMP: integer := 2;
  constant N_SLV_ACMD: integer := 3;
  constant N_SLV_ECHO: integer := 4;
  constant N_SLV_SCMD_GEN: integer := 5;
  constant N_SLV_PARTITION0: integer := 6;
  constant N_SLV_PARTITION1: integer := 7;
  constant N_SLV_PARTITION2: integer := 8;
  constant N_SLV_PARTITION3: integer := 9;
  constant N_SLAVES: integer := 10;
-- END automatically generated VHDL

    
end ipbus_decode_pdts_master;

package body ipbus_decode_pdts_master is

  function ipbus_sel_pdts_master(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Nov 27 14:17:41 2020 
    if    std_match(addr, "-----------------------000000---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_GLOBAL, IPBUS_SEL_WIDTH)); -- global / base 0x00000000 / mask 0x000001f8
    elsif std_match(addr, "-----------------------00001----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_SPILL, IPBUS_SEL_WIDTH)); -- spill / base 0x00000010 / mask 0x000001f0
    elsif std_match(addr, "-----------------------000100---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TSTAMP, IPBUS_SEL_WIDTH)); -- tstamp / base 0x00000020 / mask 0x000001f8
    elsif std_match(addr, "-----------------------000101---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ACMD, IPBUS_SEL_WIDTH)); -- acmd / base 0x00000028 / mask 0x000001f8
    elsif std_match(addr, "-----------------------00011----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ECHO, IPBUS_SEL_WIDTH)); -- echo / base 0x00000030 / mask 0x000001f0
    elsif std_match(addr, "-----------------------001------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_SCMD_GEN, IPBUS_SEL_WIDTH)); -- scmd_gen / base 0x00000040 / mask 0x000001c0
    elsif std_match(addr, "-----------------------100------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PARTITION0, IPBUS_SEL_WIDTH)); -- partition0 / base 0x00000100 / mask 0x000001c0
    elsif std_match(addr, "-----------------------101------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PARTITION1, IPBUS_SEL_WIDTH)); -- partition1 / base 0x00000140 / mask 0x000001c0
    elsif std_match(addr, "-----------------------110------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PARTITION2, IPBUS_SEL_WIDTH)); -- partition2 / base 0x00000180 / mask 0x000001c0
    elsif std_match(addr, "-----------------------111------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PARTITION3, IPBUS_SEL_WIDTH)); -- partition3 / base 0x000001c0 / mask 0x000001c0
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_pdts_master;

end ipbus_decode_pdts_master;

