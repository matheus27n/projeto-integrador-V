--! Testbench para o sistema de irrigação fuzzy
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity fuzzy_irrigation_system_tb is
end entity fuzzy_irrigation_system_tb;

architecture tb of fuzzy_irrigation_system_tb is

    -- Componente a ser testado (DUT - Device Under Test)
    component fuzzy_irrigation_system
        port (
            clk             : in std_logic;
            reset           : in std_logic;
            culture_select  : in unsigned(4 downto 0);
            
            umidade_sensor  : in sensor_value;
            luz_sensor      : in sensor_value;
            agua_sensor     : in sensor_value;

            pump_control_ms : out pump_time
        );
    end component;

    -- Sinais para o testbench
    signal clk_tb             : std_logic := '0';
    signal reset_tb           : std_logic := '1';
    signal culture_select_tb  : unsigned(4 downto 0) := (others => '0'); -- 0 para Alface
    signal umidade_sensor_tb  : sensor_value := (others => '0');
    signal luz_sensor_tb      : sensor_value := (others => '0');
    signal agua_sensor_tb     : sensor_value := (others => '0');
    signal pump_control_ms_tb : pump_time;

    -- Constantes
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instanciação do DUT
    DUT : fuzzy_irrigation_system
    port map (
        clk             => clk_tb,
        reset           => reset_tb,
        culture_select  => culture_select_tb,
        umidade_sensor  => umidade_sensor_tb,
        luz_sensor      => luz_sensor_tb,
        agua_sensor     => agua_sensor_tb,
        pump_control_ms => pump_control_ms_tb
    );

    -- Geração do clock
    clk_gen : process
    begin
        loop
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clk_gen;

    -- Geração de estímulos
    stimulus : process
    begin
        -- Reset inicial
        reset_tb <= '1';
        wait for CLK_PERIOD * 2;
        reset_tb <= '0';
        wait for CLK_PERIOD * 2;

        -- Cenários de Teste para Alface (culture_select = 0)
        culture_select_tb <= to_unsigned(0, 5); -- Alface

        -- Alface Cenário 1: Solo muito seco, luz ideal, água suficiente
        -- Umidade (10 - Muito Baixa), Luz (65 - Ideal), Água (70 - Cheio)
        -- Regra: IF Umidade MB AND (Água M OR Água C) THEN Irrigação ML (80000 ms)
        umidade_sensor_tb <= to_unsigned(10, 8);
        luz_sensor_tb     <= to_unsigned(65, 8);
        agua_sensor_tb    <= to_unsigned(70, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 80000 (Muito Longo)

        -- Alface Cenário 2: Solo seco, luz muito alta, água suficiente
        -- Umidade (30 - Baixa), Luz (95 - Muito Alta), Água (80 - Cheio)
        -- Regra: IF Umidade B AND Luz MA THEN Irrigação ML (80000 ms)
        umidade_sensor_tb <= to_unsigned(30, 8);
        luz_sensor_tb     <= to_unsigned(95, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 80000 (Muito Longo)

        -- Alface Cenário 3: Solo ideal, luz ideal, água suficiente
        -- Umidade (60 - Ideal), Luz (70 - Ideal), Água (80 - Cheio)
        -- Regra: IF Umidade I AND Luz I THEN Irrigação N (0 ms)
        umidade_sensor_tb <= to_unsigned(60, 8);
        luz_sensor_tb     <= to_unsigned(70, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 0 (Nenhum)

        -- Alface Cenário 4: Solo ideal, luz alta, água suficiente
        -- Umidade (60 - Ideal), Luz (85 - Alta), Água (80 - Cheio)
        -- Regra: IF Umidade I AND (Luz A OR Luz MA) THEN Irrigação C (10000 ms)
        umidade_sensor_tb <= to_unsigned(60, 8);
        luz_sensor_tb     <= to_unsigned(85, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 10000 (Curto)

        -- Alface Cenário 5: Solo muito alto, luz ideal, água suficiente
        -- Umidade (90 - Muito Alta), Luz (70 - Ideal), Água (80 - Cheio)
        -- Regra: IF (Umidade A OR Umidade MA) THEN Irrigação N (0 ms)
        umidade_sensor_tb <= to_unsigned(90, 8);
        luz_sensor_tb     <= to_unsigned(70, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 0 (Nenhum)

        -- Alface Cenário 6: Nível de água baixo
        -- Umidade (40 - Baixa), Luz (70 - Ideal), Água (5 - Baixo)
        -- Regra: IF (Água V OR Água B) THEN Irrigação N (0 ms)
        umidade_sensor_tb <= to_unsigned(40, 8);
        luz_sensor_tb     <= to_unsigned(70, 8);
        agua_sensor_tb    <= to_unsigned(5, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 0 (Nenhum)

        -- Cenários de Teste para Tomate (culture_select = 1)
        culture_select_tb <= to_unsigned(1, 5); -- Tomate (umidade_min=35, umidade_max=75, luz_min=80, luz_max=100, tempo_bomba_ref=25000)

        -- Tomate Cenário 1: Solo seco, luz ideal, água suficiente
        -- Umidade (30 - Baixa para Tomate), Luz (90 - Ideal para Tomate), Água (80 - Cheio)
        -- Regra: IF Umidade B AND (Água M OR Água C) THEN Irrigação L (50000 ms)
        umidade_sensor_tb <= to_unsigned(30, 8);
        luz_sensor_tb     <= to_unsigned(90, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 50000 (Longo)

        -- Tomate Cenário 2: Solo ideal, luz alta, água suficiente
        -- Umidade (60 - Ideal para Tomate), Luz (95 - Ideal para Tomate), Água (80 - Cheio)
        -- Regra: IF Umidade I AND Luz I THEN Irrigação N (0 ms)
        umidade_sensor_tb <= to_unsigned(60, 8);
        luz_sensor_tb     <= to_unsigned(95, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 0 (Nenhum)

        -- Cenários de Teste para Morango (culture_select = 5)
        culture_select_tb <= to_unsigned(5, 5); -- Morango (umidade_min=40, umidade_max=80, luz_min=60, luz_max=90, tempo_bomba_ref=25000)

        -- Morango Cenário 1: Solo muito seco, luz ideal, água suficiente
        -- Umidade (20 - Muito Baixa para Morango), Luz (75 - Ideal para Morango), Água (70 - Cheio)
        -- Regra: IF Umidade MB AND (Água M OR Água C) THEN Irrigação ML (80000 ms)
        umidade_sensor_tb <= to_unsigned(20, 8);
        luz_sensor_tb     <= to_unsigned(75, 8);
        agua_sensor_tb    <= to_unsigned(70, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 80000 (Muito Longo)

        -- Morango Cenário 2: Solo ideal, luz baixa, água suficiente
        -- Umidade (60 - Ideal para Morango), Luz (50 - Baixa para Morango), Água (80 - Cheio)
        -- Regra: IF Umidade I AND Luz MB THEN Irrigação M (30000 ms)
        umidade_sensor_tb <= to_unsigned(60, 8);
        luz_sensor_tb     <= to_unsigned(50, 8);
        agua_sensor_tb    <= to_unsigned(80, 8);
        wait for CLK_PERIOD * 10;
        -- EXPECTED: pump_control_ms_tb = 30000 (Médio)

        wait; -- Finaliza a simulação
    end process stimulus;

end architecture tb;