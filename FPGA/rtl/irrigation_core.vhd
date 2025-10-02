-- top que integra tudo
--Top que conecta fuzzify + rules + guard.
--Se for usar com uart_regs_simple, instancie ambos no top do projeto da placa.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity irrigation_core is
  port(
    clk      : in  std_logic;
    rst_n    : in  std_logic;

    soil_pct : in  u8;     -- umidade %
    temp_c   : in  u8;     -- °C 0..50
    luz_pct  : in  u8;     -- %
    water_pct: in  u8;     -- %
    wd_kick  : in  std_logic;

    pump_on  : out std_logic;
    pump_ms  : out u16;
    fault_code : out std_logic_vector(3 downto 0);
    status_reg : out std_logic_vector(3 downto 0);

    -- debug
    dry_val  : out u8
  );
end entity;

architecture rtl of irrigation_core is
  signal dry_low, dry_med, dry_high : u8;
  signal t_frio, t_agrad, t_quente  : u8;
  signal l_escuro, l_nubl, l_sol    : u8;
  signal pump_ms_sug : u16;
  signal sum_w       : u16;
  signal dry_int     : u8;
begin
  FUZZ: entity work.fuzzify
    port map(
      clk=>clk,
      soil_pct=>soil_pct, temp_c=>temp_c, luz_pct=>luz_pct,
      dry_low=>dry_low, dry_med=>dry_med, dry_high=>dry_high,
      t_frio=>t_frio, t_agrad=>t_agrad, t_quente=>t_quente,
      l_escuro=>l_escuro, l_nubl=>l_nubl, l_sol=>l_sol,
      dry_val=>dry_int
    );

  RULES: entity work.rules_sugeno
    port map(
      clk=>clk,
      dry_low=>dry_low, dry_med=>dry_med, dry_high=>dry_high,
      t_frio=>t_frio, t_agrad=>t_agrad, t_quente=>t_quente,
      l_escuro=>l_escuro, l_nubl=>l_nubl, l_sol=>l_sol,
      pump_ms_sug=>pump_ms_sug, sum_w=>sum_w
    );

  GUARD: entity work.guard
    generic map(
      SOIL_ON_TH=>30, SOIL_OFF_TH=>40, WATER_MIN=>5, PUMP_MAX_MS=>20000, WD_TIMEOUT_S=>5
    )
    port map(
      clk=>clk, rst_n=>rst_n,
      soil_pct=>soil_pct, water_pct=>water_pct, wd_kick=>wd_kick,
      pump_ms_sug=>pump_ms_sug,
      pump_on=>pump_on, pump_ms=>pump_ms,
      fault_code=>fault_code, status_reg=>status_reg
    );

  dry_val <= dry_int;
end architecture;
