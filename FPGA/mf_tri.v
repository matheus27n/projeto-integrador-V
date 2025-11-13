// Arquivo: mf_tri.v
// Objetivo: Calcula a pertinência triangular (0 a 255) sem usar functions.
module mf_tri (
    input  wire [7:0] valor_entrada, // Valor do sensor (0..100)
    input  wire [7:0] p_inicio,      // Ponto A (início da subida)
    input  wire [7:0] p_pico,        // Ponto B (pico)
    input  wire [7:0] p_fim,         // Ponto C (fim da descida)
    output reg  [7:0] grau_pertinencia // Saída µ (0..255)
);

    // Variáveis internas para cálculo de rampa
    reg [7:0] delta_subida;
    reg [7:0] delta_descida;
    reg [15:0] calculo_temp; // 16 bits para evitar overflow na multiplicação

    always @* begin
        // Caso 1: Valor fora do triângulo (EXEMPLO ALFACE)
        //Cenário: O sensor de umidade leu 30.
        //30 é menor ou igual a 40? SIM.
        //Resultado: grau_pertinencia = 0.
        if (valor_entrada <= p_inicio || valor_entrada >= p_fim) begin
            grau_pertinencia = 0;
        end 
        // Caso 2: Valor exato no pico
        else if (valor_entrada == p_pico) begin
            grau_pertinencia = 255;
        end 
        // Caso 3: Rampa de Subida (Esquerda)
        else if (valor_entrada < p_pico) begin
            // Lógica: (valor - inicio) * 255 / (pico - inicio)
            // Nota: Se (pico - inicio) for 0, usamos 1 para evitar divisão por zero
            //O Cálculo Real:Tamanho da Subida (Base):
            //p_pico - p_inicio = 60 - 40 = 20.
            // Quanto eu andei: valor_entrada - p_inicio = 50 - 40 = 10.
            // Regra de Três: Se 20 é o total (255), quanto vale 10?
            //Resultado: grau_pertinencia = 127 (Aprox. 50%).
            //Tradução: "Isso é 50% Ideal".
            delta_subida = (p_pico > p_inicio) ? (p_pico - p_inicio) : 1;
            calculo_temp = (valor_entrada - p_inicio) * 255;
            grau_pertinencia = calculo_temp / delta_subida;
        end 
        // Caso 4: Rampa de Descida (Direita)
        else begin
            // Lógica: (fim - valor) * 255 / (fim - pico)
            delta_descida = (p_fim > p_pico) ? (p_fim - p_pico) : 1;
            calculo_temp = (p_fim - valor_entrada) * 255;
            grau_pertinencia = calculo_temp / delta_descida;
        end
    end
endmodule