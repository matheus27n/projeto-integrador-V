-- tipos e utilitários (μ triangular, min/max)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fuzzy_pkg is
  subtype u8  is unsigned(7 downto 0);
  subtype u16 is unsigned(15 downto 0);
  subtype u32 is unsigned(31 downto 0);

  function u8_min(a, b: u8) return u8;
  function u8_max(a, b: u8) return u8;

  -- triangular membership (altura = 255). Pontos a < b < c.
  function tri_mu(x, a, b, c: u8) return u8;
end package;

package body fuzzy_pkg is
  function u8_min(a, b: u8) return u8 is
  begin
    if a < b then return a; else return b; end if;
  end;
  function u8_max(a, b: u8) return u8 is
  begin
    if a > b then return a; else return b; end if;
  end;
  function tri_mu(x, a, b, c: u8) return u8 is
    variable mu: u8 := (others=>'0');
    variable num, den: integer;
  begin
    if (x <= a) or (x >= c) then
      mu := to_unsigned(0, 8);
    elsif (x = b) then
      mu := to_unsigned(255, 8);
    elsif (x > a) and (x < b) then
      den := to_integer(b - a);
      if den = 0 then return to_unsigned(0,8); end if;
      num := to_integer(x - a) * 255 / den;
      mu := to_unsigned(num, 8);
    else
      den := to_integer(c - b);
      if den = 0 then return to_unsigned(0,8); end if;
      num := to_integer(c - x) * 255 / den;
      mu := to_unsigned(num, 8);
    end if;
    return mu;
  end;
end package body;
