// Arquivo: sistema_irrigacao.v
// Sistema Completo com Catálogo, Temperatura e Trava de Nível

module sistema_irrigacao (
    input  wire        clk,
    input  wire        rst_n,
    
    // --- Interface de Controle (Vem do ESP32/Dashboard) ---
    input  wire [4:0]  selecao_planta_id, // Qual planta estamos cuidando?

    // --- Sensores ---
    input  wire [7:0]  sensor_solo,
    input  wire [7:0]  sensor_luz,
    input  wire [7:0]  sensor_temp,     // Sensor de temperatura (0..100 C)
    input  wire [7:0]  sensor_nivel,    // Nível do reservatório (0..100 %)

    // --- Saídas ---
    output reg  [15:0] cmd_tempo_bomba_ms, // Tempo final em ms
    output reg         alerta_nivel_baixo  // Sinal para o ESP32 (Safe-Bomb)
);

    // ====================================================================
    // 1. BUSCAR DADOS NO CATÁLOGO (ROM)
    // ====================================================================
    wire [7:0]  ref_umid_min, ref_umid_max;
    wire [7:0]  ref_luz_min,  ref_luz_max;
    wire [15:0] ref_tempo_max;
    wire [7:0]  ref_nivel_seg;

    plant_catalog banco_dados (
        .plant_id       (selecao_planta_id),
        // Saídas do catálogo
        .umid_min       (ref_umid_min),
        .umid_max       (ref_umid_max),
        .luz_min        (ref_luz_min),
        .luz_max        (ref_luz_max),
        .tempo_max_ms   (ref_tempo_max),
        .nivel_min_seg  (ref_nivel_seg)
    );

    // ====================================================================
    // 2. FUZZIFICAÇÃO ADAPTATIVA (Dynamic)
    // ====================================================================

    // --- BLOCO: SOLO (Umidade) ---
    wire [7:0] g_solo_seco, g_solo_medio, g_solo_umido;
    wire [7:0] centro_umid = (ref_umid_min + ref_umid_max) / 2; // Calcula a Média Aritmética para definir o PICO exato do triângulo

    mf_tri fuzz_solo_seco (
        .valor_entrada    (sensor_solo),
        .p_inicio         (8'd0),          // Fixo 0
        .p_pico           (8'd0),          // Fixo 0
        .p_fim            (ref_umid_min),  // Dinâmico
        .grau_pertinencia (g_solo_seco)
    );
    
    mf_tri fuzz_solo_medio (
        .valor_entrada    (sensor_solo),
        .p_inicio         (ref_umid_min),  // Dinâmico
        .p_pico           (centro_umid),   // Calculado
        .p_fim            (ref_umid_max),  // Dinâmico
        .grau_pertinencia (g_solo_medio)
    );
    
    mf_tri fuzz_solo_umido (
        .valor_entrada    (sensor_solo),
        .p_inicio         (ref_umid_max),  // Dinâmico
        .p_pico           (8'd100),        // Fixo 100
        .p_fim            (8'd100),        // Fixo 100
        .grau_pertinencia (g_solo_umido)
    );

    // --- BLOCO: LUZ ---
    wire [7:0] g_luz_fraca, g_luz_media, g_luz_forte;
    wire [7:0] centro_luz = (ref_luz_min + ref_luz_max) / 2;

    mf_tri fuzz_luz_fraca (
        .valor_entrada    (sensor_luz),
        .p_inicio         (8'd0),
        .p_pico           (8'd0),
        .p_fim            (ref_luz_min),
        .grau_pertinencia (g_luz_fraca)
    );

    mf_tri fuzz_luz_media (
        .valor_entrada    (sensor_luz),
        .p_inicio         (ref_luz_min),
        .p_pico           (centro_luz),
        .p_fim            (ref_luz_max),
        .grau_pertinencia (g_luz_media)
    );

    mf_tri fuzz_luz_forte (
        .valor_entrada    (sensor_luz),
        .p_inicio         (ref_luz_max),
        .p_pico           (8'd100),
        .p_fim            (8'd100),
        .grau_pertinencia (g_luz_forte)
    );

    // --- BLOCO: TEMPERATURA (Genérico 0..50°C) ---
    wire [7:0] g_temp_fria, g_temp_ideal, g_temp_quente;

    mf_tri fuzz_temp_fria (
        .valor_entrada    (sensor_temp),
        .p_inicio         (8'd0),
        .p_pico           (8'd0),
        .p_fim            (8'd20),
        .grau_pertinencia (g_temp_fria)
    );

    mf_tri fuzz_temp_ideal (
        .valor_entrada    (sensor_temp),
        .p_inicio         (8'd15),
        .p_pico           (8'd25),
        .p_fim            (8'd35),
        .grau_pertinencia (g_temp_ideal)
    );

    mf_tri fuzz_temp_quente (
        .valor_entrada    (sensor_temp),
        .p_inicio         (8'd30),
        .p_pico           (8'd50),
        .p_fim            (8'd50),
        .grau_pertinencia (g_temp_quente)
    );

    // ====================================================================
    // 3. MOTOR DE REGRAS ATUALIZADO
    // ====================================================================
    wire [7:0] acao_irrigar_pouco, acao_irrigar_medio, acao_irrigar_muito;
    
    rule_engine_v2 cerebro_avancado (
        // Entradas (Antecedentes)
        .solo_seco      (g_solo_seco), 
        .solo_medio     (g_solo_medio), 
        .solo_umido     (g_solo_umido),
        
        .luz_fraca      (g_luz_fraca), 
        .luz_media      (g_luz_media), 
        .luz_forte      (g_luz_forte),
        
        .temp_fria      (g_temp_fria), 
        .temp_ideal     (g_temp_ideal), 
        .temp_quente    (g_temp_quente),
        
        // Saídas (Consequentes)
        .irrigar_pouco  (acao_irrigar_pouco),
        .irrigar_medio  (acao_irrigar_medio),
        .irrigar_muito  (acao_irrigar_muito)
    );

    // ====================================================================
    // 4. DEFUZZIFICAÇÃO E CÁLCULO DE TEMPO
    // ====================================================================
    wire [15:0] percentual_potencia; // 0 a 100%
    
    defuzz_logic conversor (
        .clk             (clk), 
        .rst_n           (rst_n),
        .grau_pouco      (acao_irrigar_pouco),
        .grau_medio      (acao_irrigar_medio),
        .grau_muito      (acao_irrigar_muito),
        .tempo_irrigacao (percentual_potencia) // Saída 0..100
    );

    // ====================================================================
    // 5. TRAVA DE SEGURANÇA E SAÍDA FINAL
    // ====================================================================
    reg [31:0] calculo_final; // 32 bits para multiplicação
    
    // Início do Estágio 5 (Síncrono)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_tempo_bomba_ms <= 0;
            alerta_nivel_baixo <= 0;
        end else begin
            // --- Lógica Safe-Bomb ---
            // Verifica se nível está abaixo da referência de segurança do catálogo
            if (sensor_nivel < ref_nivel_seg) begin 
                // MODO EMERGÊNCIA: Corta a bomba
                cmd_tempo_bomba_ms <= 0;
                alerta_nivel_baixo <= 1;
            end else begin
                // MODO NORMAL
                alerta_nivel_baixo <= 0;
                
                // Cálculo: (Percentual * Tempo_Maximo_Planta) / 100
                // Ex: 50% * 30000ms = 15000ms
                // ALFACE
                calculo_final = (percentual_potencia * ref_tempo_max) / 100;
                
                cmd_tempo_bomba_ms <= calculo_final[15:0];
            end
        end
    end

endmodule