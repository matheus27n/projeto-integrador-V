-- regras R1..R8 (Sugeno 0-ordem)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity rules_sugeno is
  port(
    clk : in std_logic;
    -- pertinências:
    dry_low, dry_med, dry_high : in u8;
    t_frio, t_agrad, t_quente  : in u8;
    l_escuro, l_nubl, l_sol    : in u8;
    -- saída
    pump_ms_sug : out u16;  -- tempo sugerido (ms)
    sum_w       : out u16   -- soma de pesos p/ debug
  );
end entity;

architecture rtl of rules_sugeno is
  -- singletons (ms) conforme tabela
  constant MS_R1 : u16 := to_unsigned(20000,16);
  constant MS_R2 : u16 := to_unsigned(16000,16);
  constant MS_R3 : u16 := to_unsigned(12000,16);
  constant MS_R4 : u16 := to_unsigned( 8000,16);
  constant MS_R5 : u16 := to_unsigned(    0,16);
  constant MS_R6 : u16 := to_unsigned(    0,16);
  constant MS_R7 : u16 := to_unsigned( 6000,16);
  constant MS_R8 : u16 := to_unsigned( 4000,16);

  function min3(a,b,c:u8) return u8 is
  begin
    return u8_min(a, u8_min(b,c));
  end;
  function max2(a,b:u8) return u8 is
  begin
    return u8_max(a,b);
  end;
begin
  process(clk)
    variable w1,w2,w3,w4,w5,w6,w7,w8 : u8;
    variable sw       : unsigned(15 downto 0);
    variable num      : unsigned(31 downto 0);
    variable den      : unsigned(15 downto 0);
    variable out_val  : u16;
  begin
    if rising_edge(clk) then
      -- R1: Seco alto ∧ Temp quente ∧ Sol
      w1 := min3(dry_high, t_quente, l_sol);

      -- R2: Seco alto ∧ (Temp quente ∨ Agradável)
      w2 := u8_min(dry_high, max2(t_quente, t_agrad));

      -- R3: Seco médio ∧ Temp quente ∧ Sol
      w3 := min3(dry_med, t_quente, l_sol);

      -- R4: Seco médio ∧ (Temp quente ∨ Agradável)
      w4 := u8_min(dry_med, max2(t_quente, t_agrad));

      -- R5: Seco baixo (solo úmido)
      w5 := dry_low;

      -- R6: Temp frio ∧ Escuro
      w6 := u8_min(t_frio, l_escuro);

      -- R7: Seco alto ∧ Escuro
      w7 := u8_min(dry_high, l_escuro);

      -- R8: Seco médio ∧ Escuro
      w8 := u8_min(dry_med, l_escuro);

      -- soma de pesos
      sw := (others=>'0');
      sw := sw + resize(unsigned(w1),16);
      sw := sw + resize(unsigned(w2),16);
      sw := sw + resize(unsigned(w3),16);
      sw := sw + resize(unsigned(w4),16);
      sw := sw + resize(unsigned(w5),16);
      sw := sw + resize(unsigned(w6),16);
      sw := sw + resize(unsigned(w7),16);
      sw := sw + resize(unsigned(w8),16);
      den := sw;

      if den = 0 then
        out_val := (others=>'0');
      else
        num := (others=>'0');
        num := num + resize(unsigned(w1),32) * resize(unsigned(MS_R1),32);
        num := num + resize(unsigned(w2),32) * resize(unsigned(MS_R2),32);
        num := num + resize(unsigned(w3),32) * resize(unsigned(MS_R3),32);
        num := num + resize(unsigned(w4),32) * resize(unsigned(MS_R4),32);
        num := num + resize(unsigned(w5),32) * resize(unsigned(MS_R5),32);
        num := num + resize(unsigned(w6),32) * resize(unsigned(MS_R6),32);
        num := num + resize(unsigned(w7),32) * resize(unsigned(MS_R7),32);
        num := num + resize(unsigned(w8),32) * resize(unsigned(MS_R8),32);

        out_val := u16( to_unsigned( to_integer( num / resize(den,32) ), 16) );
      end if;

      pump_ms_sug <= out_val;
      sum_w       <= u16(den);
    end if;
  end process;
end architecture;
