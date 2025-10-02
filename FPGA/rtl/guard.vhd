-- histerese, watchdog, cortes e fail-safe
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_pkg.all;

entity guard is
  generic(
    SOIL_ON_TH   : integer := 30;     -- liga quando umidade <=30% (dry >=70)
    SOIL_OFF_TH  : integer := 40;     -- desliga quando umidade >=40% (dry <=60)
    WATER_MIN    : integer := 5;      -- %
    PUMP_MAX_MS  : integer := 20000;  -- ms (coerente com R1)
    WD_TIMEOUT_S : integer := 5       -- s sem kick => falha
  );
  port(
    clk         : in  std_logic;   -- assumir 1 Hz no TB (ou dividir clock)
    rst_n       : in  std_logic;
    soil_pct    : in  u8;          -- umidade %
    water_pct   : in  u8;          -- nível água %
    wd_kick     : in  std_logic;   -- pulso periódico do ESP32
    pump_ms_sug : in  u16;
    pump_on     : out std_logic;
    pump_ms     : out u16;
    fault_code  : out std_logic_vector(3 downto 0); -- [0]WD [1]WATER [2]SENS [3]OVR
    status_reg  : out std_logic_vector(3 downto 0)  -- [0]stateON [1]soil_low [2]wd_ok [3]water_ok
  );
end entity;

architecture rtl of guard is
  signal state_on     : std_logic := '0';
  signal wd_cnt_s     : unsigned(15 downto 0) := (others=>'0');
  signal wd_ok        : std_logic := '1';
  signal water_ok     : std_logic := '1';
  signal soil_low     : std_logic := '0';
  signal pump_ms_lim  : u16 := (others=>'0');
  signal fault_wd, fault_water, fault_ovr, fault_sens : std_logic := '0';
begin
  -- watchdog (assuma clk=1Hz no TB; em HW real, gere 1Hz por divisor)
  process(clk, rst_n)
  begin
    if rst_n='0' then
      wd_cnt_s <= (others=>'0'); wd_ok <= '1';
    elsif rising_edge(clk) then
      if wd_kick='1' then wd_cnt_s <= (others=>'0');
      else wd_cnt_s <= wd_cnt_s + 1; end if;

      if to_integer(wd_cnt_s) > WD_TIMEOUT_S then wd_ok <= '0'; else wd_ok <= '1'; end if;
    end if;
  end process;

  water_ok <= '1' when (to_integer(water_pct) >= WATER_MIN) else '0';
  soil_low <= '1' when (to_integer(soil_pct) <= SOIL_ON_TH) else '0';

  process(pump_ms_sug)
    variable v: integer;
  begin
    v := to_integer(pump_ms_sug);
    if v > PUMP_MAX_MS then
      pump_ms_lim <= to_unsigned(PUMP_MAX_MS,16);
      fault_ovr   <= '1';
    else
      pump_ms_lim <= pump_ms_sug;
      fault_ovr   <= '0';
    end if;
  end process;

  -- histerese
  process(clk, rst_n)
  begin
    if rst_n='0' then
      state_on <= '0';
    elsif rising_edge(clk) then
      if state_on='0' then
        if (to_integer(soil_pct) <= SOIL_ON_TH) and (wd_ok='1') and (water_ok='1') then
          state_on <= '1';
        end if;
      else
        if (to_integer(soil_pct) >= SOIL_OFF_TH) or (wd_ok='0') or (water_ok='0') then
          state_on <= '0';
        end if;
      end if;
    end if;
  end process;

  fault_water <= (not water_ok);
  fault_wd    <= (not wd_ok);
  fault_sens  <= '0';

  pump_on    <= state_on when (fault_wd='0' and fault_water='0') else '0';
  pump_ms    <= pump_ms_lim when pump_on='1' else (others=>'0');

  fault_code <= fault_wd & fault_water & fault_sens & fault_ovr;
  status_reg <= state_on & soil_low & wd_ok & water_ok;
end architecture;
