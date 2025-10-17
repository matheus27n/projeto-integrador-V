--! Módulo Fuzzificador para Nível de Água no Reservatório
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity fuzzifier_agua is
    port (
        agua_in         : in sensor_value; -- Nível de água atual (0-100)
        agua_min_cfg    : in sensor_value; -- agua_min_pct da cultura
        
        -- Saídas: graus de pertinência (0-100)
        grau_v          : out membership_degree; -- Vazio
        grau_b          : out membership_degree; -- Baixo
        grau_m          : out membership_degree; -- Médio
        grau_c          : out membership_degree  -- Cheio
    );
end entity fuzzifier_agua;

architecture behavioral of fuzzifier_agua is
    -- Funções auxiliares para calcular pertinência triangular/trapezoidal
    function calc_triangular(val, p1, p2, p3 : integer) return membership_degree is
        variable degree : integer := 0;
    begin
        if val <= p1 or val >= p3 then
            degree := 0;
        elsif val >= p1 and val <= p2 then
            degree := (val - p1) * 100 / (p2 - p1);
        elsif val >= p2 and val <= p3 then
            degree := (p3 - val) * 100 / (p3 - p2);
        end if;
        return to_unsigned(degree, 8);
    end function;

    function calc_trapezoidal(val, p1, p2, p3, p4 : integer) return membership_degree is
        variable degree : integer := 0;
    begin
        if val <= p1 or val >= p4 then
            degree := 0;
        elsif val >= p2 and val <= p3 then
            degree := 100;
        elsif val >= p1 and val <= p2 then
            degree := (val - p1) * 100 / (p2 - p1);
        elsif val >= p3 and val <= p4 then
            degree := (p4 - val) * 100 / (p4 - p3);
        end if;
        return to_unsigned(degree, 8);
    end function;

begin
    -- Exemplo de cálculo para Alface (valores fixos para demonstração)
    -- Estes pontos seriam dinâmicos com base em agua_min_cfg
    -- Para Alface: agua_min_pct = 15

    -- Vazio: (0, 0, 10)
    grau_v <= calc_triangular(to_integer(agua_in), 0, 0, 10);
    -- Baixo: (5, 15, 25)
    grau_b  <= calc_triangular(to_integer(agua_in), 5, 15, 25);
    -- Médio: (20, 50, 70, 85) -- Trapezoidal
    grau_m  <= calc_trapezoidal(to_integer(agua_in), 20, 50, 70, 85);
    -- Cheio: (75, 100, 100)
    grau_c <= calc_triangular(to_integer(agua_in), 75, 100, 100);

end architecture behavioral;