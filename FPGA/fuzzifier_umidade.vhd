--! Módulo Fuzzificador para Umidade do Solo
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity fuzzifier_umidade is
    port (
        umidade_in      : in sensor_value; -- Umidade atual do solo (0-100)
        umidade_min_cfg : in sensor_value; -- umidade_min_pct da cultura
        umidade_max_cfg : in sensor_value; -- umidade_max_pct da cultura
        
        -- Saídas: graus de pertinência (0-100)
        grau_mb         : out membership_degree; -- Muito Baixa
        grau_b          : out membership_degree; -- Baixa
        grau_i          : out membership_degree; -- Ideal
        grau_a          : out membership_degree; -- Alta
        grau_ma         : out membership_degree  -- Muito Alta
    );
end entity fuzzifier_umidade;

architecture behavioral of fuzzifier_umidade is
    -- Funções auxiliares para calcular pertinência triangular/trapezoidal
    -- Simplificado para demonstração. Em VHDL real, seria lógica combinacional.
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
    -- Estes pontos seriam dinâmicos com base em umidade_min_cfg e umidade_max_cfg
    -- Para Alface: umidade_min_pct = 40, umidade_max_pct = 80

    -- Muito Baixa: (0, 0, 30)
    grau_mb <= calc_triangular(to_integer(umidade_in), 0, 0, 30);
    -- Baixa: (20, 35, 50)
    grau_b  <= calc_triangular(to_integer(umidade_in), 20, 35, 50);
    -- Ideal: (40, 60, 80, 90) -- Trapezoidal
    grau_i  <= calc_trapezoidal(to_integer(umidade_in), 40, 60, 80, 90);
    -- Alta: (70, 85, 95)
    grau_a  <= calc_triangular(to_integer(umidade_in), 70, 85, 95);
    -- Muito Alta: (80, 100, 100)
    grau_ma <= calc_triangular(to_integer(umidade_in), 80, 100, 100);

end architecture behavioral;