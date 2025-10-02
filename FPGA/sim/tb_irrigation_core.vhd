--Testa cenários principais (R1, R4, falha de água, watchdog etc.).
--Para simplificar, o clock do guard é 1 Hz aqui — cada “tick” = 1 s.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity tb_irrigation_core is end;
architecture sim of tb_irrigation_core is
  signal clk      : std_logic := '0';   -- 1 Hz (meio tosco p/ visualização)
  signal rst_n    : std_logic := '0';

  signal soil_pct : u8 := to_unsigned(50,8); -- umidade %
  signal temp_c   : u8 := to_unsigned(25,8);
  signal luz_pct  : u8 := to_unsigned(50,8);
  signal water_pct: u8 := to_unsigned(80,8);
  signal wd_kick  : std_logic := '1';

  signal pump_on  : std_logic;
  signal pump_ms  : u16;
  signal fault_code : std_logic_vector(3 downto 0);
  signal status_reg : std_logic_vector(3 downto 0);
  signal dry_val    : u8;
begin
  -- clock 1Hz: período 1s = 1 us * 1e6 (mas simularemos rápido)
  clk <= not clk after 500 ms; -- em sim: 500 ms -> toggle (ajuste conforme seu simulador)

  dut: entity work.irrigation_core
    port map(
      clk=>clk, rst_n=>rst_n,
      soil_pct=>soil_pct, temp_c=>temp_c, luz_pct=>luz_pct, water_pct=>water_pct,
      wd_kick=>wd_kick,
      pump_on=>pump_on, pump_ms=>pump_ms,
      fault_code=>fault_code, status_reg=>status_reg,
      dry_val=>dry_val
    );

  process
  begin
    -- reset
    rst_n <= '0'; wait for 1 sec; rst_n <= '1';

    -- Cenário A (R1): seco alto (umidade baixa), quente e sol -> ~20s
    soil_pct  <= to_unsigned(15,8);    -- 15% umidade → dry ~85 (seco alto)
    temp_c    <= to_unsigned(36,8);    -- quente
    luz_pct   <= to_unsigned(90,8);    -- sol
    water_pct <= to_unsigned(80,8);
    wd_kick   <= '1';
    wait for 3 sec;

    -- Cenário B (R4): seco médio, agradável -> ~8s
    soil_pct  <= to_unsigned(50,8);
    temp_c    <= to_unsigned(24,8);
    luz_pct   <= to_unsigned(50,8);
    wait for 3 sec;

    -- Cenário C (R7): seco alto + escuro -> ~6s
    soil_pct  <= to_unsigned(10,8);
    luz_pct   <= to_unsigned(5,8);
    temp_c    <= to_unsigned(22,8);
    wait for 3 sec;

    -- Fail-safe: água baixa
    water_pct <= to_unsigned(2,8);
    wait for 2 sec;

    -- Watchdog falha
    wd_kick   <= '0';
    wait for 6 sec;

    wait;
  end process;
end architecture;
