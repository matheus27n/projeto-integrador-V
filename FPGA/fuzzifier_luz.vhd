--! Módulo Fuzzificador para Luminosidade
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fuzzy_definitions.all;

entity fuzzifier_luz is
    port (
        luz_in          : in sensor_value; -- Luminosidade atual (0-100)
        luz_min_cfg     : in sensor_value; -- luz_min da cultura
        luz_max_cfg     : in sensor_value; -- luz_max da cultura
        
        -- Saídas: graus de pertinência (0-100)
        grau_mb         : out membership_degree; -- Muito Baixa
        grau_b          : out membership_degree; -- Baixa
        grau_i          : out membership_degree; -- Ideal
        grau_a          : out membership_degree; -- Alta
        grau_ma         : out membership_degree  -- Muito Alta
    );
end entity fuzzifier_luz;

architecture behavioral of fuzzifier_luz is
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
    -- Estes pontos seriam dinâmicos com base em luz_min_cfg e luz_max_cfg
    -- Para Alface: luz_min = 50, luz_max = 80

    -- Muito Baixa: (0, 0, 40)
    grau_mb <= calc_triangular(to_integer(luz_in), 0, 0, 40);
    -- Baixa: (30, 45, 60)
    grau_b  <= calc_triangular(to_integer(luz_in), 30, 45, 60);
    -- Ideal: (50, 70, 80, 90) -- Trapezoidal
    grau_i  <= calc_trapezoidal(to_integer(luz_in), 50, 70, 80, 90);
    -- Alta: (75, 85, 95)
    grau_a  <= calc_triangular(to_integer(luz_in), 75, 85, 95);
    -- Muito Alta: (80, 100, 100)
    grau_ma <= calc_triangular(to_integer(luz_in), 80, 100, 100);

end architecture behavioral;