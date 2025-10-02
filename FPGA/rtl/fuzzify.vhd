-- pertinências: DRY, TEMP, LUZ (triangulares)
-- Converte umidade do solo (0–100%) em dry% = 100 − solo% e calcula pertinências triangulares para dry, temp e luz.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity fuzzify is
  port(
    clk       : in  std_logic;
    -- entradas normalizadas (0..100 % ou °C conforme faixa)
    soil_pct  : in  u8;  -- umidade do solo (%)
    temp_c    : in  u8;  -- 0..50 (assumido)
    luz_pct   : in  u8;  -- 0..100 (%)
    -- pertinências (0..255)
    dry_low   : out u8; dry_med  : out u8; dry_high : out u8;
    t_frio    : out u8; t_agrad  : out u8; t_quente : out u8;
    l_escuro  : out u8; l_nubl   : out u8; l_sol    : out u8;
    dry_val   : out u8          -- seco% (100 - umidade%)
  );
end entity;

architecture rtl of fuzzify is
  -- pontos dos triângulos (pode virar generics depois)
  -- DRY (0..100)
  constant DL_A:u8 := to_unsigned(0,8);
  constant DL_B:u8 := to_unsigned(10,8);
  constant DL_C:u8 := to_unsigned(30,8);

  constant DM_A:u8 := to_unsigned(35,8);
  constant DM_B:u8 := to_unsigned(50,8);
  constant DM_C:u8 := to_unsigned(65,8);

  constant DH_A:u8 := to_unsigned(70,8);
  constant DH_B:u8 := to_unsigned(90,8);
  constant DH_C:u8 := to_unsigned(100,8);

  -- TEMP (0..50)
  constant TF_A:u8 := to_unsigned(0,8);
  constant TF_B:u8 := to_unsigned(10,8);
  constant TF_C:u8 := to_unsigned(15,8);

  constant TA_A:u8 := to_unsigned(18,8);
  constant TA_B:u8 := to_unsigned(23,8);
  constant TA_C:u8 := to_unsigned(28,8);

  constant TQ_A:u8 := to_unsigned(28,8);
  constant TQ_B:u8 := to_unsigned(35,8);
  constant TQ_C:u8 := to_unsigned(45,8);

  -- LUZ (0..100)
  constant LE_A:u8 := to_unsigned(0,8);
  constant LE_B:u8 := to_unsigned(5,8);
  constant LE_C:u8 := to_unsigned(15,8);

  constant LN_A:u8 := to_unsigned(35,8);
  constant LN_B:u8 := to_unsigned(50,8);
  constant LN_C:u8 := to_unsigned(65,8);

  constant LS_A:u8 := to_unsigned(70,8);
  constant LS_B:u8 := to_unsigned(85,8);
  constant LS_C:u8 := to_unsigned(100,8);

  signal dry: u8;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- dry = 100 - solo%
      if soil_pct > to_unsigned(100,8) then
        dry <= (others=>'0');
      else
        dry <= to_unsigned( 100 - to_integer(soil_pct), 8);
      end if;

      dry_low  <= tri_mu(dry, DL_A, DL_B, DL_C);
      dry_med  <= tri_mu(dry, DM_A, DM_B, DM_C);
      dry_high <= tri_mu(dry, DH_A, DH_B, DH_C);

      t_frio   <= tri_mu(temp_c, TF_A, TF_B, TF_C);
      t_agrad  <= tri_mu(temp_c, TA_A, TA_B, TA_C);
      t_quente <= tri_mu(temp_c, TQ_A, TQ_B, TQ_C);

      l_escuro <= tri_mu(luz_pct, LE_A, LE_B, LE_C);
      l_nubl   <= tri_mu(luz_pct, LN_A, LN_B, LN_C);
      l_sol    <= tri_mu(luz_pct, LS_A, LS_B, LS_C);

      dry_val  <= dry;
    end if;
  end process;
end architecture;
