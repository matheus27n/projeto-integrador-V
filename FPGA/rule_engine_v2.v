// Arquivo: rule_engine_v2.v
// --------------------------------------------------------------------------------
// Módulo responsável por cruzar os dados difusos e decidir a intensidade da ação.
// --------------------------------------------------------------------------------

module rule_engine_v2 (
    input wire [7:0] solo_seco, solo_medio, solo_umido,
    input wire [7:0] luz_fraca, luz_media, luz_forte,
    input wire [7:0] temp_fria, temp_ideal, temp_quente, 

    output reg [7:0] irrigar_pouco,
    output reg [7:0] irrigar_medio,
    output reg [7:0] irrigar_muito
);
    reg [7:0] r1, r2, r3, r4;

    always @* begin
        // ============================================================
        // PARTE 1: AVALIAÇÃO DAS REGRAS (Lógica AND / MIN)
        // O Hardware compara dois valores e deixa passar o MENOR.
        // ============================================================

        // Regra 1: EMERGÊNCIA (Seco + Calor)
        // Lógica: IF (Solo_Seco < Temp_Quente) r1 = Solo_Seco, ELSE r1 = Temp_Quente
        r1 = (solo_seco < temp_quente) ? solo_seco : temp_quente;
        // EXEMPLO PRÁTICO:
        // Se Solo Seco = 200 (Muito Seco) e Temp Quente = 50 (Pouco Quente).
        // O resultado r1 será 50.
        // O QUE ISSO MUDA? Essa regra diz "Não estamos numa EMERGÊNCIA térmica grave", 
        // então ela contribui pouco (força 50) para a decisão de irrigar muito.

        // Regra 2: NECESSIDADE BÁSICA (Só Seco)
        // Lógica: Passagem direta (Não tem comparação, o valor passa direto)
        r2 = solo_seco; 
        // EXEMPLO PRÁTICO:
        // Se Solo Seco = 200.
        // O resultado r2 será 200.
        // O QUE ISSO MUDA? Essa é a regra dominante. Mesmo que não esteja calor (R1 fraca),
        // a planta precisa de água só porque a terra está seca.

        // Regra 3: COMPENSAÇÃO DE CALOR (Médio + Calor)
        // Lógica: IF (Solo_Medio < Temp_Quente) r3 = Solo_Medio, ELSE r3 = Temp_Quente
        r3 = (solo_medio < temp_quente) ? solo_medio : temp_quente;
        // EXEMPLO PRÁTICO:
        // Se Solo Médio = 255 (Perfeito) e Temp Quente = 100 (Calor Moderado).
        // O resultado r3 será 100.
        // O QUE ISSO MUDA? Isso cria uma força de nível "Médio" (100). O sistema vai
        // pensar: "O solo está bom, mas por causa do calor, vou jogar uma agua (média)".

        // Regra 4: ECONOMIA (Só Úmido)
        // Lógica: Passagem direta
        r4 = solo_umido;

        // ============================================================
        // PARTE 2: AGREGAÇÃO DE RESULTADOS (Lógica OR / MAX)
        // O Hardware compara as regras e deixa passar a MAIOR (Quem grita mais alto)
        // ============================================================
        
        // Decisão: IRRIGAR MUITO 
        // Temos dois motivos para isso: Emergência (r1=50) ou Seca Básica (r2=200).
        // Lógica: IF (r2 > r1) Saida = r2, ELSE Saida = r1
        irrigar_muito = r1; 
        if (r2 > irrigar_muito) irrigar_muito = r2; 
        // RESULTADO DO EXEMPLO:
        // Compara 50 vs 200. O vencedor é 200.
        // CONSEQUÊNCIA: O fio 'irrigar_muito' sai com força 200 para o Defuzzifier.
        // O Defuzzifier vai olhar isso e ligar a bomba com força".

        // Decisão: IRRIGAR MÉDIO
        // Só a regra 3 pediu isso.
        irrigar_medio = r3; // Valor = 100 (do exemplo acima)
        // CONSEQUÊNCIA: O Defuzzifier recebe força 100 para "Médio" e 200 para "Muito".
        // A média vai ficar entre os dois, mas puxando mais para o Muito.

        // Decisão: IRRIGAR POUCO
        // Só a regra 4 pediu isso.
        irrigar_pouco = r4; // Valor = 0
    end
endmodule