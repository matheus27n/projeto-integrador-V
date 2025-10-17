--! Módulo Defuzzificador (Centro de Gravidade Simplificado)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity defuzzifier is
    port (
        -- Entradas: graus de ativação para os consequentes de saída
        ativa_nenhum_in     : in membership_degree;
        ativa_curto_in      : in membership_degree;
        ativa_medio_in      : in membership_degree;
        ativa_longo_in      : in membership_degree;
        ativa_muito_longo_in : in membership_degree;

        -- Parâmetro de referência da cultura
        tempo_bomba_ref_cfg : in pump_time;

        -- Saída: tempo de bomba "crisp"
        tempo_bomba_out     : out pump_time
    );
end entity defuzzifier;

architecture behavioral of defuzzifier is
    -- Pontos de referência para os consequentes de saída (ex: para Alface)
    -- Estes seriam escalados com base em tempo_bomba_ref_cfg
    constant PUMP_NENHUM_VAL : integer := 0;
    constant PUMP_CURTO_VAL  : integer := 10000; -- 10 segundos
    constant PUMP_MEDIO_VAL  : integer := 30000; -- 30 segundos (tempo_bomba_ref)
    constant PUMP_LONGO_VAL  : integer := 50000; -- 50 segundos
    constant PUMP_MLONGO_VAL : integer := 80000; -- 80 segundos

    signal numerator   : unsigned(63 downto 0); -- Para soma dos produtos (resultado de 32x32 bits)
    signal denominator : unsigned(15 downto 0); -- Para soma dos graus de pertinência

begin
    -- Cálculo do Centro de Gravidade (simplificado)
    -- Numerador = SUM(grau_ativacao * valor_crisp_do_consequente)
    -- Denominador = SUM(grau_ativacao)

    numerator <= (to_unsigned(PUMP_NENHUM_VAL, 32) * resize(ativa_nenhum_in, 32)) +
                 (to_unsigned(PUMP_CURTO_VAL, 32) * resize(ativa_curto_in, 32)) +
                 (to_unsigned(PUMP_MEDIO_VAL, 32) * resize(ativa_medio_in, 32)) +
                 (to_unsigned(PUMP_LONGO_VAL, 32) * resize(ativa_longo_in, 32)) +
                 (to_unsigned(PUMP_MLONGO_VAL, 32) * resize(ativa_muito_longo_in, 32));

    denominator <= resize(ativa_nenhum_in, 16) +
                   resize(ativa_curto_in, 16) +
                   resize(ativa_medio_in, 16) +
                   resize(ativa_longo_in, 16) +
                   resize(ativa_muito_longo_in, 16);

    -- Evitar divisão por zero
    process(numerator, denominator)
    begin
        if to_integer(denominator) /= 0 then
            tempo_bomba_out <= resize(numerator / denominator, 17);
        else
            tempo_bomba_out <= (others => '0'); -- Nenhuma ativação, bomba desligada
        end if;
    end process;

end architecture behavioral;