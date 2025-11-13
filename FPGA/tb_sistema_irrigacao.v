`timescale 1ns/1ps

module tb_sistema_catalogo;

    // --- Sinais de Teste ---
    reg        clk;
    reg        rst_n;
    
    // Entradas de Controle e Sensores
    reg  [4:0] tb_planta_id;
    reg  [7:0] tb_solo;
    reg  [7:0] tb_luz;
    reg  [7:0] tb_temp;
    reg  [7:0] tb_nivel;

    // Saídas Observadas
    wire [15:0] tb_tempo_ms;
    wire        tb_alerta;

    // --- Instanciação do Sistema Completo ---
    sistema_irrigacao DUT (
        .clk(clk),
        .rst_n(rst_n),
        .selecao_planta_id(tb_planta_id),
        .sensor_solo(tb_solo),
        .sensor_luz(tb_luz),
        .sensor_temp(tb_temp),
        .sensor_nivel(tb_nivel),
        .cmd_tempo_bomba_ms(tb_tempo_ms),
        .alerta_nivel_baixo(tb_alerta)
    );

    // Clock de 50MHz
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // --- TASK: Função Auxiliar para Rodar Testes ---
    // Isso evita repetir código e deixa o teste organizado
    task testar_cenario;
        input [4:0] id;
        input [7:0] solo, luz, temp, nivel;
        input [8*20:1] nome_planta; // String para log
        begin
            // Configura entradas
            tb_planta_id = id;
            tb_solo  = solo;
            tb_luz   = luz;
            tb_temp  = temp;
            tb_nivel = nivel;
            
            // Espera processar (Clock + Estabilização)
            #100;
            
            // Imprime relatório no console
            $display("PLANTA: %0s (ID %0d)", nome_planta, id);
            $display("   Ambiente -> Solo: %0d | Luz: %0d | Temp: %0d | Nivel: %0d", solo, luz, temp, nivel);
            $display("   RESULTADO -> Tempo Bomba: %0d ms | Alerta: %b", tb_tempo_ms, tb_alerta);
            $display("---------------------------------------------------------------");
        end
    endtask

    // --- O ROTEIRO DE TESTES ---
    initial begin
        $display("=== INICIO DOS TESTES DE CATALOGO E SEGURANCA ===\n");
        
        rst_n = 0; #50; rst_n = 1; #50;

        // ------------------------------------------------------------
        // CENÁRIO 1: O Dilesma "Solo 25" (Alface vs Cactos)
        // Ambos recebem umidade 25. 
        // Para Alface (Min 40), isso é SECO. Para Cactos (Min 10), isso é ÚMIDO.
        // ------------------------------------------------------------
        
        // Teste A: Alface (ID 0)
        // umidade_min: 40, tempo_max: 30000
        testar_cenario(5'd0, 25, 60, 25, 80, "ALFACE");

        // Teste B: Cactos (ID 19)
        // umidade_min: 10, tempo_max: 5000
        testar_cenario(5'd19, 25, 90, 30, 80, "CACTOS");


        // ------------------------------------------------------------
        // CENÁRIO 2: Trava de Segurança (Safe-Bomb)
        // Nível da água cai para 10% (O limite é 15%)
        // ------------------------------------------------------------
        $display("\n>> TESTANDO TRAVA DE SEGURANCA (NIVEL BAIXO) <<");
        
        // Vamos usar Milho (ID 4) que bebe muita água
        // Solo 10 (Muito seco) -> Deveria ligar a bomba no máximo...
        // MAS o nível do tanque está em 10.
        testar_cenario(5'd4, 10, 90, 25, 10, "MILHO (SEM AGUA)");


        // ------------------------------------------------------------
        // CENÁRIO 3: Onda de Calor (Sensor de Temperatura)
        // Solo não está crítico, mas está muito quente (45°C).
        // ------------------------------------------------------------
        $display("\n>> TESTANDO COMPENSACAO TERMICA <<");
        
        // Tomate (ID 1). Solo 50 (Razoável), mas Temp 45 (Quente).
        testar_cenario(5'd1, 50, 80, 45, 100, "TOMATE (CALOR)");
        
        // Comparação: Mesmo solo, mas temperatura amena (20°C)
        testar_cenario(5'd1, 50, 80, 20, 100, "TOMATE (FRIO)");

        #100;
        $display("=== FIM DA SIMULACAO ===");
        $stop;
    end

endmodule