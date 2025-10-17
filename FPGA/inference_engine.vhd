--! Módulo de Inferência Fuzzy (Exemplo de uma regra)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity inference_engine is
    port (
        -- Entradas fuzzy (graus de pertinência)
        umidade_mb_in   : in membership_degree;
        umidade_b_in    : in membership_degree;
        umidade_i_in    : in membership_degree;
        umidade_a_in    : in membership_degree;
        umidade_ma_in   : in membership_degree;

        agua_v_in       : in membership_degree;
        agua_b_in       : in membership_degree;
        agua_m_in       : in membership_degree;
        agua_c_in       : in membership_degree;

        luz_mb_in       : in membership_degree;
        luz_b_in        : in membership_degree;
        luz_i_in        : in membership_degree;
        luz_a_in        : in membership_degree;
        luz_ma_in       : in membership_degree;

        -- Saídas: graus de ativação para os consequentes de saída
        ativa_nenhum    : out membership_degree;
        ativa_curto     : out membership_degree;
        ativa_medio     : out membership_degree;
        ativa_longo     : out membership_degree;
        ativa_muito_longo : out membership_degree
    );
end entity inference_engine;

architecture behavioral of inference_engine is
    -- Sinal para armazenar o grau de ativação de cada regra
    signal rule1_activation : membership_degree; -- Ex: Umidade MB AND Agua M/C -> Muito Longo
    signal rule2_activation : membership_degree; -- Ex: Umidade B AND Agua M/C -> Longo
    signal rule3_activation : membership_degree; -- Ex: Umidade I AND Luz I -> Nenhum
    signal rule4_activation : membership_degree; -- Ex: Umidade I AND (Luz A OR Luz MA) -> Curto
    signal rule5_activation : membership_degree; -- Ex: (Umidade A OR Umidade MA) -> Nenhum
    signal rule6_activation : membership_degree; -- Ex: (Agua V OR Agua B) -> Nenhum
    signal rule7_activation : membership_degree; -- Ex: Umidade B AND Luz MB -> Médio
    signal rule8_activation : membership_degree; -- Ex: Umidade B AND Luz MA -> Muito Longo

    -- Função para operador fuzzy AND (mínimo)
    function fuzzy_and(a, b : membership_degree) return membership_degree is
    begin
        return to_unsigned(minimum(to_integer(a), to_integer(b)), 8);
    end function;

    -- Função para operador fuzzy OR (máximo)
    function fuzzy_or(a, b : membership_degree) return membership_degree is
    begin
        return to_unsigned(maximum(to_integer(a), to_integer(b)), 8);
    end function;

    -- Funções auxiliares para mínimo/máximo de inteiros
    function minimum(a, b : integer) return integer is
    begin
        if a < b then return a; else return b; end if;
    end function;

    function maximum(a, b : integer) return integer is
    begin
        if a > b then return a; else return b; end if;
    end function;

begin
    -- Implementação das regras de inferência (Exemplos para Alface)

    -- Regra 1: SE Umidade do Solo é Muito Baixa E (Nível de Água é Médio OU Nível de Água é Cheio) ENTÃO Tempo de Irrigação é Muito Longo.
    rule1_activation <= fuzzy_and(umidade_mb_in, fuzzy_or(agua_m_in, agua_c_in));

    -- Regra 2: SE Umidade do Solo é Baixa E (Nível de Água é Médio OU Nível de Água é Cheio) ENTÃO Tempo de Irrigação é Longo.
    rule2_activation <= fuzzy_and(umidade_b_in, fuzzy_or(agua_m_in, agua_c_in));

    -- Regra 3: SE Umidade do Solo é Ideal E Luminosidade é Ideal ENTÃO Tempo de Irrigação é Nenhum.
    rule3_activation <= fuzzy_and(umidade_i_in, luz_i_in);

    -- Regra 4: SE Umidade do Solo é Ideal E (Luminosidade é Alta OU Luminosidade é Muito Alta) ENTÃO Tempo de Irrigação é Curto.
    rule4_activation <= fuzzy_and(umidade_i_in, fuzzy_or(luz_a_in, luz_ma_in));

    -- Regra 5: SE Umidade do Solo é Alta OU Umidade do Solo é Muito Alta ENTÃO Tempo de Irrigação é Nenhum.
    rule5_activation <= fuzzy_or(umidade_a_in, umidade_ma_in);

    -- Regra 6: SE Nível de Água é Vazio OU Nível de Água é Baixo ENTÃO Tempo de Irrigação é Nenhum.
    rule6_activation <= fuzzy_or(agua_v_in, agua_b_in);

    -- Regra 7: SE Umidade do Solo é Baixa E Luminosidade é Muito Baixa ENTÃO Tempo de Irrigação é Médio.
    rule7_activation <= fuzzy_and(umidade_b_in, luz_mb_in);

    -- Regra 8: SE Umidade do Solo é Baixa E Luminosidade é Muito Alta ENTÃO Tempo de Irrigação é Muito Longo.
    rule8_activation <= fuzzy_and(umidade_b_in, luz_ma_in);

    -- Combinação dos consequentes para cada termo de saída (usando OR para agregação)
    ativa_nenhum      <= fuzzy_or(rule3_activation, fuzzy_or(rule5_activation, rule6_activation));
    ativa_curto       <= rule4_activation;
    ativa_medio       <= rule7_activation;
    ativa_longo       <= rule2_activation;
    ativa_muito_longo <= fuzzy_or(rule1_activation, rule8_activation);

end architecture behavioral;