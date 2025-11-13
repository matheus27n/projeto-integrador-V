# 🌱 Sistema de Irrigação Residencial Inteligente com FPGA e IoT

Este projeto faz parte do **Projeto Integrador V** do curso de **Engenharia de Computação - UNIPAMPA (Campus Bagé)**.  
Nosso objetivo é desenvolver um sistema de irrigação inteligente para plantas residenciais, integrando **sensores**, **ESP32** e um **FPGA** como coprocessador para tomada de decisão em tempo real.

---

## 📌 Objetivo do Projeto
Automatizar o cuidado com plantas em ambientes residenciais (vasos, jardineiras, varandas, pequenas estufas), garantindo:
- Uso eficiente da água 💧
- Redução de desperdícios
- Conforto e praticidade ao usuário
- Potencial escalabilidade para cenários agrícolas de pequeno porte

---

## 🏗️ Arquitetura do Sistema
Fluxo principal:

### Componentes principais:
- **ESP32**: leitura dos sensores, comunicação com FPGA via UART/SPI, interface com dashboard.
- **FPGA (DE0-Nano/DE10-Lite)**: execução da lógica fuzzy, histerese e temporização mínima.
- **Sensores**:
  - Umidade do solo (capacitivo v1.2)
  - Temperatura e umidade do ar (DHT22)
  - Sensor de luz (LDR)
  - Sensor de nível da água
- **Atuadores**:
  - Relé de estado sólido
  - Mini bomba d’água / sistema de gotejamento
- **Dashboard**:
  - Interface web/app simples
  - Exibição de dados em tempo real
  - Histórico básico (CSV/JSON no ESP32)
  - Ajuste de parâmetros

---

## 🤖 Lógica de Controle
### Implementada no **FPGA**:
- **Histerese**: evita chaveamentos rápidos da bomba.
- **Temporização mínima**: garante ciclos de irrigação completos.
- **Lógica Fuzzy Simplificada**:
  - Entradas: umidade do solo, temperatura, umidade do ar
  - Saída: tempo/nível de irrigação
  - Regras linguísticas (ex.: "solo seco + clima quente → irrigar bastante")

### Executada no **ESP32**:
- Aquisição de sensores
- Armazenamento local em CSV/JSON (LittleFS)
- Comunicação serial com o FPGA
- Disponibilização de dados via interface web

---

## 📊 Backlog do Projeto (Resumo)

### IP1 – Fundamentos e MVP
- [x] Definição de sensores/atuadores
- [ ] Configuração inicial ESP32 + FPGA
- [ ] Banco de dados local (JSON/CSV)
- [ ] Dashboard básico com dados brutos
- [ ] MVP funcional com uma planta

### IP2 – Robustez
- [ ] Implementação da histerese e temporização mínima no FPGA
- [ ] Histórico no dashboard
- [ ] Controle fuzzy inicial validado
- [ ] Testes comparativos (fuzzy vs limiar fixo)

### IP3 – Expansão
- [ ] Lógica fuzzy completa (3 entradas)
- [ ] Perfis de plantas no dashboard
- [ ] Sistema multi-planta
- [ ] Validação final e documentação

---

## ✅ Requisitos

### Requisitos Funcionais (RF)
- RF-01: Medir umidade do solo em tempo real  
- RF-02: Medir temperatura e umidade do ar  
- RF-03: Medir luminosidade ambiente  
- RF-04: Medir nível da água no reservatório  
- RF-05: Acionar bomba de irrigação via FPGA  
- RF-06: Controlar irrigação baseada em lógica fuzzy  
- RF-07: Aplicar histerese para evitar chaveamento rápido  
- RF-08: Implementar temporização mínima da bomba  
- RF-09: Exibir dados em dashboard web  
- RF-10: Registrar histórico local em JSON/CSV  
- RF-11: Permitir ajuste de parâmetros básicos pelo usuário  
- RF-12: Validar sistema com uma planta no MVP  

### Requisitos Não Funcionais (RNF)
- RNF-01: Sistema deve ser **resiliente a falhas de rede** (buffer local no ESP32)  
- RNF-02: Latência da decisão < 1 segundo (FPGA determinístico)  
- RNF-03: Persistência mínima de 7 dias de dados no ESP32 (LittleFS)  
- RNF-04: Interface web responsiva e acessível via smartphone  
- RNF-05: Componentes elétricos com isolamento adequado para uso doméstico  
- RNF-06: Consumo energético reduzido (avaliar uso de bateria/fonte solar futura)  

---

## 📚 Tecnologias Utilizadas
- **Hardware**: ESP32, FPGA (DE0-Nano/DE10-Lite), sensores (DHT22, capacitivo, LDR, nível de água)
- **Linguagens**:
  - VHDL/Verilog → FPGA (controle fuzzy e histerese)
  - C++ (Arduino/PlatformIO) → ESP32
  - Python (opcional) → dashboard/gráficos
- **Armazenamento**: LittleFS (CSV/JSON no ESP32)
- **Dashboard**: WebServer no ESP32 (HTML/CSS/JS simples)

---

## 📷 Rich Picture
O diagrama conceitual (rich picture) está disponível no diretório `/docs/` e representa:
- Usuário e app (interface)
- Nuvem/dados
- Prototipagem física (ESP32 + FPGA + sensores + atuadores)

---

## 🔗 Links Importantes
- **GitHub do Projeto**: [link aqui]  
- **Jira Board**: [link aqui]  
- **Documentação em LaTeX/Overleaf**: `/docs/documentacao.tex`

---

## 👥 Equipe
- Matheus Fagundes de Oliveira  
- Thalys Lemos Correa  
- Eduardo Ritta Martins  

Orientadores:  
- Prof. Julio S. Domingues Jr.  
- Prof. Carlos Michel Betemps  
- Prof. Bruno (colaborador)

---

## 📅 Cronograma (simplificado)
- **Agosto/Setembro**: Definição e IP1 (MVP com uma planta)  
- **Outubro**: IP2 (robustez e fuzzy inicial)  
- **Novembro/Dezembro**: IP3 (expansão multi-planta, validação final)

---

## 📖 Referências
- Aulas de Projeto Integrador V (UNIPAMPA):contentReference[oaicite:0]{index=0}:contentReference[oaicite:1]{index=1}:contentReference[oaicite:2]{index=2}  
- Medeiros, P. H. S. (2018). *Sistema de Irrigação Automatizado para Plantas Caseiras*. Monografia – UFOP:contentReference[oaicite:3]{index=3}  
- Zadeh, L. (1965). *Fuzzy Sets*. Information and Control.  

---
