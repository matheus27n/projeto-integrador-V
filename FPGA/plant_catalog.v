// Arquivo: plant_catalog.v
// Objetivo: Banco de dados das plantas (ROM) baseado no JSON.
module plant_catalog (
    input  wire [4:0]  plant_id,      // ID da planta (0 a 26)
    
    // Saídas de Parâmetros para os Fuzzifiers
    output reg  [7:0]  umid_min,      // Referência "Seco" acaba aqui
    output reg  [7:0]  umid_max,      // Referência "Úmido" começa aqui
    output reg  [7:0]  luz_min,
    output reg  [7:0]  luz_max,
    output reg  [15:0] tempo_max_ms,  // Tempo base da bomba em ms
    output reg  [7:0]  nivel_min_seg  // Nível mínimo de segurança (15%)
);

    always @* begin
        // Padrão de segurança (15% do JSON)
        nivel_min_seg = 15; 

        case (plant_id)
            // - Alface
            5'd0:  begin umid_min=40; umid_max=80; luz_min=50; luz_max=80; tempo_max_ms=30000; end
            // - Tomate
            5'd1:  begin umid_min=35; umid_max=75; luz_min=80; luz_max=100; tempo_max_ms=25000; end
            // - Cenoura
            5'd2:  begin umid_min=35; umid_max=75; luz_min=70; luz_max=100; tempo_max_ms=25000; end
            // - Feijão
            5'd3:  begin umid_min=30; umid_max=70; luz_min=70; luz_max=100; tempo_max_ms=25000; end
            // - Milho
            5'd4:  begin umid_min=30; umid_max=75; luz_min=90; luz_max=100; tempo_max_ms=30000; end
            // - Morango
            5'd5:  begin umid_min=40; umid_max=80; luz_min=60; luz_max=90; tempo_max_ms=25000; end
            // - Melancia
            5'd6:  begin umid_min=30; umid_max=75; luz_min=85; luz_max=100; tempo_max_ms=28000; end
            // - Batata
            5'd7:  begin umid_min=35; umid_max=75; luz_min=70; luz_max=100; tempo_max_ms=25000; end
            // - Mandioca
            5'd8:  begin umid_min=25; umid_max=65; luz_min=80; luz_max=100; tempo_max_ms=20000; end
            // - Pimentão
            5'd9:  begin umid_min=35; umid_max=75; luz_min=70; luz_max=100; tempo_max_ms=25000; end
            // - Couve
            5'd10: begin umid_min=45; umid_max=85; luz_min=60; luz_max=90; tempo_max_ms=20000; end
            // - Repolho
            5'd11: begin umid_min=40; umid_max=80; luz_min=60; luz_max=90; tempo_max_ms=25000; end
            // - Bananeira
            5'd12: begin umid_min=35; umid_max=75; luz_min=80; luz_max=100; tempo_max_ms=30000; end
            // - Café
            5'd13: begin umid_min=30; umid_max=70; luz_min=60; luz_max=90; tempo_max_ms=20000; end
            // - Laranja
            5'd14: begin umid_min=30; umid_max=75; luz_min=85; luz_max=100; tempo_max_ms=25000; end
            // - Limão
            5'd15: begin umid_min=30; umid_max=75; luz_min=85; luz_max=100; tempo_max_ms=25000; end
            // - Uva
            5'd16: begin umid_min=25; umid_max=65; luz_min=80; luz_max=100; tempo_max_ms=20000; end
            // - Gramado
            5'd17: begin umid_min=40; umid_max=80; luz_min=60; luz_max=100; tempo_max_ms=30000; end
            // - Rosa
            5'd18: begin umid_min=35; umid_max=75; luz_min=70; luz_max=100; tempo_max_ms=25000; end
            // - Cactos
            5'd19: begin umid_min=10; umid_max=40; luz_min=90; luz_max=100; tempo_max_ms=5000; end
            // - Suculenta
            5'd20: begin umid_min=10; umid_max=40; luz_min=70; luz_max=100; tempo_max_ms=5000; end
            // - Dracena
            5'd21: begin umid_min=25; umid_max=65; luz_min=40; luz_max=70; tempo_max_ms=15000; end
            // - Espada-de-São-Jorge
            5'd22: begin umid_min=10; umid_max=45; luz_min=30; luz_max=80; tempo_max_ms=7000; end
            // - Begônia
            5'd23: begin umid_min=40; umid_max=75; luz_min=40; luz_max=70; tempo_max_ms=20000; end
            // - Violeta
            5'd24: begin umid_min=40; umid_max=80; luz_min=30; luz_max=60; tempo_max_ms=15000; end
            // - Hera
            5'd25: begin umid_min=35; umid_max=75; luz_min=40; luz_max=80; tempo_max_ms=20000; end
            
            // Default (Segurança)
            default: begin umid_min=50; umid_max=50; luz_min=50; luz_max=50; tempo_max_ms=0; end
        endcase
    end
endmodule