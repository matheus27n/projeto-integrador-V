// Arquivo: defuzz_logic.v
// Objetivo: Calcula média ponderada e limita saída
module defuzz_logic (
    input wire        clk,
    input wire        rst_n,
    input wire [7:0]  grau_pouco,  
    input wire [7:0]  grau_medio,  
    input wire [7:0]  grau_muito, 
    output reg [15:0] tempo_irrigacao // Saída final em "unidades de tempo"
);

    reg [31:0] numerador;
    reg [15:0] denominador;
    reg [15:0] resultado_raw;

    // Pesos 
    localparam P_POUCO = 15;
    localparam P_MEDIO = 50;
    localparam P_MUITO = 85;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tempo_irrigacao <= 0;
        end else begin
            // 1. Calcular Numerador e Denominador
            numerador   = (grau_pouco * P_POUCO) + (grau_medio * P_MEDIO) + (grau_muito * P_MUITO);
            denominador = grau_pouco + grau_medio + grau_muito;

            // 2. Divisão (Protegida contra divisão por zero)
            if (denominador == 0) 
                resultado_raw = 0;
            else 
                resultado_raw = numerador / denominador; //Média Ponderada

            // 3. Pós-Processo
            // Se for muito pouco tempo (ex: < 5), nem liga a bomba para não queimar
            if (resultado_raw < 5)
                tempo_irrigacao <= 0;
            else if (resultado_raw > 100)
                tempo_irrigacao <= 100;
            else
                tempo_irrigacao <= resultado_raw;
        end
    end
endmodule