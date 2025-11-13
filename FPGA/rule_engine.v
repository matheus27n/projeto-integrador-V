// Arquivo: rule_engine.v
// Objetivo: Aplica as regras "SE... ENTÃO..." usando Min (AND) e Max (OR)
module rule_engine (
    // Entradas: Graus de pertinência dos sensores
    input wire [7:0] solo_seco, solo_medio, solo_umido,
    input wire [7:0] luz_fraca, luz_media, luz_forte,
    input wire [7:0] nivel_baixo, nivel_medio, nivel_alto,

    // Saídas: Decisão de irrigação
    output reg [7:0] irrigar_pouco,
    output reg [7:0] irrigar_medio,
    output reg [7:0] irrigar_muito
);

    // Fios internos para o resultado de cada regra
    // Nomenclatura: R_Condicao1_Condicao2
    reg [7:0] r_solo_seco_luz_forte;
    reg [7:0] r_solo_seco_luz_fraca;
    reg [7:0] r_solo_umido;
    // ... adicionar mais regras conforme necessário

    always @* begin
        // --- EXEMPLO DE REGRAS (Lógica MAMDANI) ---
        // Operador MÍNIMO (AND) é usado para combinar condições

        // Regra 1: Se Solo Seco E Luz Forte -> Irrigar MUITO
        // (Usa operador ternário para fazer o Mínimo: a < b ? a : b)
        r_solo_seco_luz_forte = (solo_seco < luz_forte) ? solo_seco : luz_forte;

        // Regra 2: Se Solo Seco E Luz Fraca -> Irrigar MEDIO
        r_solo_seco_luz_fraca = (solo_seco < luz_fraca) ? solo_seco : luz_fraca;

        // Regra 3: Se Solo Úmido -> Irrigar POUCO (independente da luz)
        r_solo_umido = solo_umido; 
        
        // --- AGREGACÃO (Lógica OR / MAX) ---
        // Decidir a saída final pegando o valor MÁXIMO das regras que apontam para ela
        
        // Saída: Irrigar MUITO
        irrigar_muito = r_solo_seco_luz_forte; 
        
        // Saída: Irrigar MEDIO
        irrigar_medio = r_solo_seco_luz_fraca;

        // Saída: Irrigar POUCO
        irrigar_pouco = r_solo_umido;
    end
endmodule