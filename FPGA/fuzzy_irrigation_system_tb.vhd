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

        -- Teste 1: Alface - Umidade muito baixa, água suficiente, luz ideal
        -- Espera-se irrigação "Muito Longa" (80000 ms)
        culture_select_tb <= to_unsigned(0, 5); -- Alface
        umidade_sensor_tb <= to_unsigned(10, 8); -- Muito Baixa
        luz_sensor_tb     <= to_unsigned(65, 8); -- Ideal
        agua_sensor_tb    <= to_unsigned(70, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Teste 2: Alface - Umidade baixa, água suficiente, luz muito alta
        -- Espera-se irrigação "Muito Longa" (80000 ms)
        umidade_sensor_tb <= to_unsigned(30, 8); -- Baixa
        luz_sensor_tb     <= to_unsigned(95, 8); -- Muito Alta
        agua_sensor_tb    <= to_unsigned(80, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Teste 3: Alface - Umidade ideal, luz ideal
        -- Espera-se irrigação "Nenhum" (0 ms)
        umidade_sensor_tb <= to_unsigned(60, 8); -- Ideal
        luz_sensor_tb     <= to_unsigned(70, 8); -- Ideal
        agua_sensor_tb    <= to_unsigned(80, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Teste 4: Alface - Umidade ideal, luz alta
        -- Espera-se irrigação "Curto" (10000 ms)
        umidade_sensor_tb <= to_unsigned(60, 8); -- Ideal
        luz_sensor_tb     <= to_unsigned(85, 8); -- Alta
        agua_sensor_tb    <= to_unsigned(80, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Teste 5: Alface - Umidade muito alta
        -- Espera-se irrigação "Nenhum" (0 ms)
        umidade_sensor_tb <= to_unsigned(90, 8); -- Muito Alta
        luz_sensor_tb     <= to_unsigned(70, 8); -- Ideal
        agua_sensor_tb    <= to_unsigned(80, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Teste 6: Alface - Nível de água baixo
        -- Espera-se irrigação "Nenhum" (0 ms)
        umidade_sensor_tb <= to_unsigned(40, 8); -- Baixa
        luz_sensor_tb     <= to_unsigned(70, 8); -- Ideal
        agua_sensor_tb    <= to_unsigned(5, 8);  -- Baixo
        wait for CLK_PERIOD * 10;

        -- Teste 7: Troca para Tomate - Umidade baixa, luz ideal, água suficiente
        -- (Tomate: umidade_min=35, umidade_max=75, luz_min=80, luz_max=100, tempo_bomba_ref=25000)
        -- Espera-se irrigação "Longo" (50000 ms) ou "Médio" (25000 ms) dependendo das regras
        culture_select_tb <= to_unsigned(1, 5); -- Tomate
        umidade_sensor_tb <= to_unsigned(30, 8); -- Baixa para Tomate
        luz_sensor_tb     <= to_unsigned(90, 8); -- Ideal para Tomate
        agua_sensor_tb    <= to_unsigned(80, 8); -- Cheio
        wait for CLK_PERIOD * 10;

        -- Finaliza a simulação
        wait;
    end process stimulus;

end architecture tb;