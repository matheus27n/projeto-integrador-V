--! Módulo Top-Level do Sistema de Irrigação Fuzzy
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity fuzzy_irrigation_system is
    port (
        clk             : in std_logic;
        reset           : in std_logic;
        culture_select  : in unsigned(4 downto 0); -- Ex: 0="Alface", 1="Tomate", etc.
        
        umidade_sensor  : in sensor_value;
        luz_sensor      : in sensor_value;
        agua_sensor     : in sensor_value;

        pump_control_ms : out pump_time -- Tempo em ms para acionar a bomba
    );
end entity fuzzy_irrigation_system;

architecture structural of fuzzy_irrigation_system is
    -- Sinais para configuração da cultura
    signal current_umidade_min_pct : sensor_value;
    signal current_umidade_max_pct : sensor_value;
    signal current_luz_min         : sensor_value;
    signal current_luz_max         : sensor_value;
    signal current_agua_min_pct    : sensor_value;
    signal current_tempo_bomba_ref : pump_time;

    -- Sinais para graus de pertinência do fuzzificador de umidade
    signal umidade_mb, umidade_b, umidade_i, umidade_a, umidade_ma : membership_degree;
    -- Sinais para graus de pertinência do fuzzificador de luz
    signal luz_mb, luz_b, luz_i, luz_a, luz_ma                     : membership_degree;
    -- Sinais para graus de pertinência do fuzzificador de água
    signal agua_v, agua_b, agua_m, agua_c                         : membership_degree;

    -- Sinais para graus de ativação da máquina de inferência
    signal ativa_nenhum_s, ativa_curto_s, ativa_medio_s, ativa_longo_s, ativa_muito_longo_s : membership_degree;

begin
    -- Módulo de Seleção de Cultura (lógica combinacional simples)
    process(culture_select)
    begin
        case to_integer(culture_select) is
            when 0 => -- Alface
                current_umidade_min_pct <= ALFACE_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= ALFACE_PARAMS.umidade_max_pct;
                current_luz_min         <= ALFACE_PARAMS.luz_min;
                current_luz_max         <= ALFACE_PARAMS.luz_max;
                current_agua_min_pct    <= ALFACE_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= ALFACE_PARAMS.tempo_bomba_ref;
            when 1 => -- Tomate
                current_umidade_min_pct <= TOMATE_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= TOMATE_PARAMS.umidade_max_pct;
                current_luz_min         <= TOMATE_PARAMS.luz_min;
                current_luz_max         <= TOMATE_PARAMS.luz_max;
                current_agua_min_pct    <= TOMATE_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= TOMATE_PARAMS.tempo_bomba_ref;
            when 2 => -- Cenoura
                current_umidade_min_pct <= CENOURA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= CENOURA_PARAMS.umidade_max_pct;
                current_luz_min         <= CENOURA_PARAMS.luz_min;
                current_luz_max         <= CENOURA_PARAMS.luz_max;
                current_agua_min_pct    <= CENOURA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= CENOURA_PARAMS.tempo_bomba_ref;
            when 3 => -- Feijão
                current_umidade_min_pct <= FEIJAO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= FEIJAO_PARAMS.umidade_max_pct;
                current_luz_min         <= FEIJAO_PARAMS.luz_min;
                current_luz_max         <= FEIJAO_PARAMS.luz_max;
                current_agua_min_pct    <= FEIJAO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= FEIJAO_PARAMS.tempo_bomba_ref;
            when 4 => -- Milho
                current_umidade_min_pct <= MILHO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= MILHO_PARAMS.umidade_max_pct;
                current_luz_min         <= MILHO_PARAMS.luz_min;
                current_luz_max         <= MILHO_PARAMS.luz_max;
                current_agua_min_pct    <= MILHO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= MILHO_PARAMS.tempo_bomba_ref;
            when 5 => -- Morango
                current_umidade_min_pct <= MORANGO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= MORANGO_PARAMS.umidade_max_pct;
                current_luz_min         <= MORANGO_PARAMS.luz_min;
                current_luz_max         <= MORANGO_PARAMS.luz_max;
                current_agua_min_pct    <= MORANGO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= MORANGO_PARAMS.tempo_bomba_ref;
            when 6 => -- Melancia
                current_umidade_min_pct <= MELANCIA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= MELANCIA_PARAMS.umidade_max_pct;
                current_luz_min         <= MELANCIA_PARAMS.luz_min;
                current_luz_max         <= MELANCIA_PARAMS.luz_max;
                current_agua_min_pct    <= MELANCIA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= MELANCIA_PARAMS.tempo_bomba_ref;
            when 7 => -- Batata
                current_umidade_min_pct <= BATATA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= BATATA_PARAMS.umidade_max_pct;
                current_luz_min         <= BATATA_PARAMS.luz_min;
                current_luz_max         <= BATATA_PARAMS.luz_max;
                current_agua_min_pct    <= BATATA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= BATATA_PARAMS.tempo_bomba_ref;
            when 8 => -- Mandioca
                current_umidade_min_pct <= MANDIOCA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= MANDIOCA_PARAMS.umidade_max_pct;
                current_luz_min         <= MANDIOCA_PARAMS.luz_min;
                current_luz_max         <= MANDIOCA_PARAMS.luz_max;
                current_agua_min_pct    <= MANDIOCA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= MANDIOCA_PARAMS.tempo_bomba_ref;
            when 9 => -- Pimentão
                current_umidade_min_pct <= PIMENTAO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= PIMENTAO_PARAMS.umidade_max_pct;
                current_luz_min         <= PIMENTAO_PARAMS.luz_min;
                current_luz_max         <= PIMENTAO_PARAMS.luz_max;
                current_agua_min_pct    <= PIMENTAO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= PIMENTAO_PARAMS.tempo_bomba_ref;
            when 10 => -- Couve
                current_umidade_min_pct <= COUVE_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= COUVE_PARAMS.umidade_max_pct;
                current_luz_min         <= COUVE_PARAMS.luz_min;
                current_luz_max         <= COUVE_PARAMS.luz_max;
                current_agua_min_pct    <= COUVE_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= COUVE_PARAMS.tempo_bomba_ref;
            when 11 => -- Repolho
                current_umidade_min_pct <= REPOLHO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= REPOLHO_PARAMS.umidade_max_pct;
                current_luz_min         <= REPOLHO_PARAMS.luz_min;
                current_luz_max         <= REPOLHO_PARAMS.luz_max;
                current_agua_min_pct    <= REPOLHO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= REPOLHO_PARAMS.tempo_bomba_ref;
            when 12 => -- Bananeira
                current_umidade_min_pct <= BANANEIRA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= BANANEIRA_PARAMS.umidade_max_pct;
                current_luz_min         <= BANANEIRA_PARAMS.luz_min;
                current_luz_max         <= BANANEIRA_PARAMS.luz_max;
                current_agua_min_pct    <= BANANEIRA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= BANANEIRA_PARAMS.tempo_bomba_ref;
            when 13 => -- Café
                current_umidade_min_pct <= CAFE_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= CAFE_PARAMS.umidade_max_pct;
                current_luz_min         <= CAFE_PARAMS.luz_min;
                current_luz_max         <= CAFE_PARAMS.luz_max;
                current_agua_min_pct    <= CAFE_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= CAFE_PARAMS.tempo_bomba_ref;
            when 14 => -- Laranja
                current_umidade_min_pct <= LARANJA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= LARANJA_PARAMS.umidade_max_pct;
                current_luz_min         <= LARANJA_PARAMS.luz_min;
                current_luz_max         <= LARANJA_PARAMS.luz_max;
                current_agua_min_pct    <= LARANJA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= LARANJA_PARAMS.tempo_bomba_ref;
            when 15 => -- Limão
                current_umidade_min_pct <= LIMAO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= LIMAO_PARAMS.umidade_max_pct;
                current_luz_min         <= LIMAO_PARAMS.luz_min;
                current_luz_max         <= LIMAO_PARAMS.luz_max;
                current_agua_min_pct    <= LIMAO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= LIMAO_PARAMS.tempo_bomba_ref;
            when 16 => -- Uva
                current_umidade_min_pct <= UVA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= UVA_PARAMS.umidade_max_pct;
                current_luz_min         <= UVA_PARAMS.luz_min;
                current_luz_max         <= UVA_PARAMS.luz_max;
                current_agua_min_pct    <= UVA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= UVA_PARAMS.tempo_bomba_ref;
            when 17 => -- Gramado
                current_umidade_min_pct <= GRAMADO_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= GRAMADO_PARAMS.umidade_max_pct;
                current_luz_min         <= GRAMADO_PARAMS.luz_min;
                current_luz_max         <= GRAMADO_PARAMS.luz_max;
                current_agua_min_pct    <= GRAMADO_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= GRAMADO_PARAMS.tempo_bomba_ref;
            when 18 => -- Rosa
                current_umidade_min_pct <= ROSA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= ROSA_PARAMS.umidade_max_pct;
                current_luz_min         <= ROSA_PARAMS.luz_min;
                current_luz_max         <= ROSA_PARAMS.luz_max;
                current_agua_min_pct    <= ROSA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= ROSA_PARAMS.tempo_bomba_ref;
            when 19 => -- Cactos
                current_umidade_min_pct <= CACTOS_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= CACTOS_PARAMS.umidade_max_pct;
                current_luz_min         <= CACTOS_PARAMS.luz_min;
                current_luz_max         <= CACTOS_PARAMS.luz_max;
                current_agua_min_pct    <= CACTOS_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= CACTOS_PARAMS.tempo_bomba_ref;
            when 20 => -- Suculenta
                current_umidade_min_pct <= SUCULENTA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= SUCULENTA_PARAMS.umidade_max_pct;
                current_luz_min         <= SUCULENTA_PARAMS.luz_min;
                current_luz_max         <= SUCULENTA_PARAMS.luz_max;
                current_agua_min_pct    <= SUCULENTA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= SUCULENTA_PARAMS.tempo_bomba_ref;
            when 21 => -- Dracena
                current_umidade_min_pct <= DRACENA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= DRACENA_PARAMS.umidade_max_pct;
                current_luz_min         <= DRACENA_PARAMS.luz_min;
                current_luz_max         <= DRACENA_PARAMS.luz_max;
                current_agua_min_pct    <= DRACENA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= DRACENA_PARAMS.tempo_bomba_ref;
            when 22 => -- Espada-de-São-Jorge
                current_umidade_min_pct <= ESPADA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= ESPADA_PARAMS.umidade_max_pct;
                current_luz_min         <= ESPADA_PARAMS.luz_min;
                current_luz_max         <= ESPADA_PARAMS.luz_max;
                current_agua_min_pct    <= ESPADA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= ESPADA_PARAMS.tempo_bomba_ref;
            when 23 => -- Begônia
                current_umidade_min_pct <= BEGONIA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= BEGONIA_PARAMS.umidade_max_pct;
                current_luz_min         <= BEGONIA_PARAMS.luz_min;
                current_luz_max         <= BEGONIA_PARAMS.luz_max;
                current_agua_min_pct    <= BEGONIA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= BEGONIA_PARAMS.tempo_bomba_ref;
            when 24 => -- Violeta
                current_umidade_min_pct <= VIOLETA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= VIOLETA_PARAMS.umidade_max_pct;
                current_luz_min         <= VIOLETA_PARAMS.luz_min;
                current_luz_max         <= VIOLETA_PARAMS.luz_max;
                current_agua_min_pct    <= VIOLETA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= VIOLETA_PARAMS.tempo_bomba_ref;
            when 25 => -- Hera
                current_umidade_min_pct <= HERA_PARAMS.umidade_min_pct;
                current_umidade_max_pct <= HERA_PARAMS.umidade_max_pct;
                current_luz_min         <= HERA_PARAMS.luz_min;
                current_luz_max         <= HERA_PARAMS.luz_max;
                current_agua_min_pct    <= HERA_PARAMS.agua_min_pct;
                current_tempo_bomba_ref <= HERA_PARAMS.tempo_bomba_ref;
            when others => -- Default ou erro
                current_umidade_min_pct <= (others => '0');
                current_umidade_max_pct <= (others => '0');
                current_luz_min         <= (others => '0');
                current_luz_max         <= (others => '0');
                current_agua_min_pct    <= (others => '0');
                current_tempo_bomba_ref <= (others => '0');
        end case;
    end process;

    -- Instanciação do Fuzzificador de Umidade
    fuzz_umidade_inst : entity work.fuzzifier_umidade
    port map (
        umidade_in      => umidade_sensor,
        umidade_min_cfg => current_umidade_min_pct,
        umidade_max_cfg => current_umidade_max_pct,
        grau_mb         => umidade_mb,
        grau_b          => umidade_b,
        grau_i          => umidade_i,
        grau_a          => umidade_a,
        grau_ma         => umidade_ma
    );

    -- Instanciação do Fuzzificador de Luminosidade
    fuzz_luz_inst : entity work.fuzzifier_luz
    port map (
        luz_in          => luz_sensor,
        luz_min_cfg     => current_luz_min,
        luz_max_cfg     => current_luz_max,
        grau_mb         => luz_mb,
        grau_b          => luz_b,
        grau_i          => luz_i,
        grau_a          => luz_a,
        grau_ma         => luz_ma
    );

    -- Instanciação do Fuzzificador de Nível de Água
    fuzz_agua_inst : entity work.fuzzifier_agua
    port map (
        agua_in         => agua_sensor,
        agua_min_cfg    => current_agua_min_pct,
        grau_v          => agua_v,
        grau_b          => agua_b,
        grau_m          => agua_m,
        grau_c          => agua_c
    );

    -- Instanciação da Máquina de Inferência
    inference_inst : entity work.inference_engine
    port map (
        umidade_mb_in   => umidade_mb,
        umidade_b_in    => umidade_b,
        umidade_i_in    => umidade_i,
        umidade_a_in    => umidade_a,
        umidade_ma_in   => umidade_ma,
        agua_v_in       => agua_v,
        agua_b_in       => agua_b,
        agua_m_in       => agua_m,
        agua_c_in       => agua_c,
        luz_mb_in       => luz_mb,
        luz_b_in        => luz_b,
        luz_i_in        => luz_i,
        luz_a_in        => luz_a,
        luz_ma_in       => luz_ma,
        ativa_nenhum    => ativa_nenhum_s,
        ativa_curto     => ativa_curto_s,
        ativa_medio     => ativa_medio_s,
        ativa_longo     => ativa_longo_s,
        ativa_muito_longo => ativa_muito_longo_s
    );

    -- Instanciação do Defuzzificador
    defuzz_inst : entity work.defuzzifier
    port map (
        ativa_nenhum_in     => ativa_nenhum_s,
        ativa_curto_in      => ativa_curto_s,
        ativa_medio_in      => ativa_medio_s,
        ativa_longo_in      => ativa_longo_s,
        ativa_muito_longo_in => ativa_muito_longo_s,
        tempo_bomba_ref_cfg => current_tempo_bomba_ref,
        tempo_bomba_out     => pump_control_ms
    );

end architecture structural;