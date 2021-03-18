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

package ipbus_decode_pdts_partition is

  constant IPBUS_SEL_WIDTH: positive := 3;
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_pdts_partition(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Nov 27 14:17:41 2020 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_EVTCTR: integer := 1;
  constant N_SLV_BUF: integer := 2;
  constant N_SLV_ACTRS: integer := 3;
  constant N_SLV_RCTRS: integer := 4;
  constant N_SLAVES: integer := 5;
-- END automatically generated VHDL

    
end ipbus_decode_pdts_partition;

package body ipbus_decode_pdts_partition is

  function ipbus_sel_pdts_partition(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Nov 27 14:17:41 2020 
    if    std_match(addr, "--------------------------00-00-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x00000036
    elsif std_match(addr, "--------------------------00-01-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_EVTCTR, IPBUS_SEL_WIDTH)); -- evtctr / base 0x00000002 / mask 0x00000036
    elsif std_match(addr, "--------------------------00-10-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_BUF, IPBUS_SEL_WIDTH)); -- buf / base 0x00000004 / mask 0x00000036
    elsif std_match(addr, "--------------------------01----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ACTRS, IPBUS_SEL_WIDTH)); -- actrs / base 0x00000010 / mask 0x00000030
    elsif std_match(addr, "--------------------------10----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_RCTRS, IPBUS_SEL_WIDTH)); -- rctrs / base 0x00000020 / mask 0x00000030
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_pdts_partition;

end ipbus_decode_pdts_partition;

