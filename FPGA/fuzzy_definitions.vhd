--! Pacote para definições globais do sistema fuzzy
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fuzzy_definitions is

    --! Tipo para representar um grau de pertinência (0 a 100, por exemplo)
    subtype membership_degree is unsigned(7 downto 0); -- 0 a 100 para simplificar

    --! Tipo para os valores de entrada dos sensores (0 a 100)
    subtype sensor_value is unsigned(7 downto 0);

    --! Tipo para o tempo de bomba (em ms, por exemplo, 0 a 90000)
    subtype pump_time is unsigned(16 downto 0); -- Suporta até 131071

    --! Estrutura para armazenar os parâmetros de uma cultura
    type culture_params_type is record
        umidade_min_pct : sensor_value;
        umidade_max_pct : sensor_value;
        luz_min         : sensor_value;
        luz_max         : sensor_value;
        agua_min_pct    : sensor_value;
        tempo_bomba_ref : pump_time; -- Tempo de bomba de referência para defuzzificação
    end record;

    --! Constantes para os parâmetros da Alface
    constant ALFACE_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(80, 8),
        luz_min         => to_unsigned(50, 8),
        luz_max         => to_unsigned(80, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(30000, 17)
    );

    --! Constantes para os parâmetros do Tomate
    constant TOMATE_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(80, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Cenoura
    constant CENOURA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros do Feijão
    constant FEIJAO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(70, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros do Milho
    constant MILHO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(90, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(30000, 17)
    );

    --! Constantes para os parâmetros do Morango
    constant MORANGO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(80, 8),
        luz_min         => to_unsigned(60, 8),
        luz_max         => to_unsigned(90, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Melancia
    constant MELANCIA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(85, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(28000, 17)
    );

    --! Constantes para os parâmetros da Batata
    constant BATATA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Mandioca
    constant MANDIOCA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(25, 8),
        umidade_max_pct => to_unsigned(65, 8),
        luz_min         => to_unsigned(80, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

    --! Constantes para os parâmetros do Pimentão
    constant PIMENTAO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Couve
    constant COUVE_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(45, 8),
        umidade_max_pct => to_unsigned(85, 8),
        luz_min         => to_unsigned(60, 8),
        luz_max         => to_unsigned(90, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

    --! Constantes para os parâmetros do Repolho
    constant REPOLHO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(80, 8),
        luz_min         => to_unsigned(60, 8),
        luz_max         => to_unsigned(90, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Bananeira
    constant BANANEIRA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(80, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(30000, 17)
    );

    --! Constantes para os parâmetros do Café
    constant CAFE_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(70, 8),
        luz_min         => to_unsigned(60, 8),
        luz_max         => to_unsigned(90, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

    --! Constantes para os parâmetros da Laranja
    constant LARANJA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(85, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros do Limão
    constant LIMAO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(30, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(85, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros da Uva
    constant UVA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(25, 8),
        umidade_max_pct => to_unsigned(65, 8),
        luz_min         => to_unsigned(80, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

    --! Constantes para os parâmetros do Gramado
    constant GRAMADO_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(80, 8),
        luz_min         => to_unsigned(60, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(30000, 17)
    );

    --! Constantes para os parâmetros da Rosa
    constant ROSA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(25000, 17)
    );

    --! Constantes para os parâmetros do Cactos
    constant CACTOS_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(10, 8),
        umidade_max_pct => to_unsigned(40, 8),
        luz_min         => to_unsigned(90, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(5000, 17)
    );

    --! Constantes para os parâmetros da Suculenta
    constant SUCULENTA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(10, 8),
        umidade_max_pct => to_unsigned(40, 8),
        luz_min         => to_unsigned(70, 8),
        luz_max         => to_unsigned(100, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(5000, 17)
    );

    --! Constantes para os parâmetros da Dracena
    constant DRACENA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(25, 8),
        umidade_max_pct => to_unsigned(65, 8),
        luz_min         => to_unsigned(40, 8),
        luz_max         => to_unsigned(70, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(15000, 17)
    );

    --! Constantes para os parâmetros da Espada-de-São-Jorge
    constant ESPADA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(10, 8),
        umidade_max_pct => to_unsigned(45, 8),
        luz_min         => to_unsigned(30, 8),
        luz_max         => to_unsigned(80, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(7000, 17)
    );

    --! Constantes para os parâmetros da Begônia
    constant BEGONIA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(40, 8),
        luz_max         => to_unsigned(70, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

    --! Constantes para os parâmetros da Violeta
    constant VIOLETA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(40, 8),
        umidade_max_pct => to_unsigned(80, 8),
        luz_min         => to_unsigned(30, 8),
        luz_max         => to_unsigned(60, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(15000, 17)
    );

    --! Constantes para os parâmetros da Hera
    constant HERA_PARAMS : culture_params_type := (
        umidade_min_pct => to_unsigned(35, 8),
        umidade_max_pct => to_unsigned(75, 8),
        luz_min         => to_unsigned(40, 8),
        luz_max         => to_unsigned(80, 8),
        agua_min_pct    => to_unsigned(15, 8),
        tempo_bomba_ref => to_unsigned(20000, 17)
    );

end package fuzzy_definitions;

package body fuzzy_definitions is
end package body fuzzy_definitions;