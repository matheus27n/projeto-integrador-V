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
        // CENÁRIO 1: O Dilema "Solo 25" (Alface vs Cactos)
        // ------------------------------------------------------------
        testar_cenario(5'd0, 25, 60, 25, 80, "ALFACE");
        testar_cenario(5'd19, 25, 90, 30, 80, "CACTOS");


        // ------------------------------------------------------------
        // CENÁRIO 2: Trava de Segurança (Safe-Bomb)
        // ------------------------------------------------------------
        $display("\n>> TESTANDO TRAVA DE SEGURANCA (NIVEL BAIXO) <<");
        testar_cenario(5'd4, 10, 90, 25, 10, "MILHO (SEM AGUA)");


        // ------------------------------------------------------------
        // CENÁRIO 3: Onda de Calor (Compensação Térmica)
        // ------------------------------------------------------------
        $display("\n>> TESTANDO COMPENSACAO TERMICA <<");
        testar_cenario(5'd1, 50, 80, 45, 100, "TOMATE (CALOR)");
        testar_cenario(5'd1, 50, 80, 20, 100, "TOMATE (FRIO)");
        
        // ------------------------------------------------------------
        // CENÁRIO 4: TESTE DE STRESS (EXEMPLO DA AULA)
        // Situação Crítica: Tomate + Seca Extrema + Calor + Luz Forte
        // Esperado: Tempo próximo do máximo (~21.000ms a 25.000ms)
        // ------------------------------------------------------------
        $display("\n>> TESTE FINAL: CENARIO CRITICO (TRACE DE EXECUCAO) <<");
        testar_cenario(5'd1, 10, 80, 40, 80, "TOMATE (CRITICO)");

        #100;
        $display("=== FIM DA SIMULACAO ===");
        $stop;
    end

endmodule