#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>

// ===== Wi-Fi =====
const char* WIFI_SSID = "Apto.202";
const char* WIFI_PASS = "27112000";

// ===== Pinos (ADC1 para funcionar com Wi-Fi) =====
const int PIN_SOIL   = 34;     // Umidade do solo (ADC1)
const int PIN_LDR    = 35;     // LDR (ADC1)
const int PIN_DHT    = 22;     // DHT22 (digital)
const int PIN_WATER  = 39;     // Nível d'água (ADC1, somente entrada)

// ===== DHT22 =====
#define DHTTYPE DHT22
DHT dht(PIN_DHT, DHTTYPE);

// ===== Calibração =====
// Solo / LDR (seu projeto atual)
int SOIL_DRY  = 4095;
int SOIL_WET  = 1200;
int LDR_DARK  = 381;
int LDR_LIGHT = 737;

// Nível d'água (calibre com /cal?type=we e /cal?type=wf)
int WATER_EMPTY = 300;   // leitura com reservatório vazio (ajustar na calibração)
int WATER_FULL  = 2200;  // leitura com reservatório cheio (ajustar na calibração)

// ===== ADC =====
const float VREF = 3.3f;
const int   ADCMAX = 4095;

WebServer server(80);

// ---------- helpers ----------
int readAvg(int pin, uint8_t n=16){
  uint32_t acc=0;
  for(uint8_t i=0;i<n;i++){ acc += analogRead(pin); delay(2); }
  return acc / n;
}
float rawToV(int raw){ return (raw * VREF) / ADCMAX; }

// EMA: suaviza a leitura (alpha% controla a rapidez; 25% = resposta rápida)
int emaInt(int prev, int curr, uint8_t alpha_percent = 25){
  return ( (int)prev * (100 - alpha_percent) + (int)curr * alpha_percent ) / 100;
}

// Mapeamento 0..100% com auto-detecção de direção (inverte se cheio < vazio)
int mapPctSmart(int raw, int emptyRef, int fullRef){
  if (fullRef == emptyRef) return 0;
  long pct;
  if (fullRef > emptyRef) {
    pct = ( (long)raw - emptyRef ) * 100L / ( (long)fullRef - emptyRef );
  } else { // curva invertida
    pct = ( (long)emptyRef - raw ) * 100L / ( (long)emptyRef - fullRef );
  }
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return (int)pct;
}

// ---------- CORS ----------
void sendCORS(){
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}
void handleOptions(){ sendCORS(); server.send(204); }

// ---------- página local ----------
const char INDEX_HTML[] PROGMEM = R"HTML(
<!doctype html><meta charset="utf-8"/><title>ESP32</title>
<p>OK. Endpoint de dados em <code>/data</code></p>
<p>Calibração: <code>/cal?type=we</code> (vazio), <code>/cal?type=wf</code> (cheio)</p>
)HTML";

void handleIndex(){ sendCORS(); server.send_P(200,"text/html",INDEX_HTML); }

// cache DHT
float lastTemp=NAN,lastHum=NAN; unsigned long lastDhtMs=0;

void handleData(){
  // ===== Solo / Luz (ADC1)
  int soilRaw = readAvg(PIN_SOIL);
  int ldrRaw  = readAvg(PIN_LDR);
  float soilV = rawToV(soilRaw);
  float ldrV  = rawToV(ldrRaw);
  int soilPct = mapPctSmart(soilRaw, SOIL_DRY, SOIL_WET);   // usa smart p/ robustez
  int ldrPct  = mapPctSmart(ldrRaw,  LDR_DARK, LDR_LIGHT);  // idem

  // ===== DHT (2s cache)
  bool dhtOk=false;
  if (millis()-lastDhtMs>=2000){
    float h=dht.readHumidity(), t=dht.readTemperature();
    if(!isnan(h)&&!isnan(t)&&h>=0&&h<=100&&t>-40&&t<85){ lastHum=h; lastTemp=t; dhtOk=true; }
    lastDhtMs=millis();
  } else if(!isnan(lastHum)&&!isnan(lastTemp)) dhtOk=true;

  // ===== Nível d'água (ANALÓGICO em GPIO39) com EMA + mapeamento inteligente
  static int waterRawEma = 0;                 // memória da EMA (inicia em 0)
  int   waterRaw = readAvg(PIN_WATER, 24);    // média de N amostras
  waterRawEma    = emaInt(waterRawEma, waterRaw, 25); // 25% = resposta rápida
  float waterV   = rawToV(waterRawEma);
  int   waterPct = mapPctSmart(waterRawEma, WATER_EMPTY, WATER_FULL);

  // ===== JSON
  char buf[768];
  snprintf(buf,sizeof(buf),
    "{"
      "\"soil_raw\":%d,\"soil_v\":%.3f,\"soil_pct\":%d,\"soil_dry\":%d,\"soil_wet\":%d,"
      "\"ldr_raw\":%d,\"ldr_v\":%.3f,\"ldr_pct\":%d,\"ldr_dark\":%d,\"ldr_light\":%d,"
      "\"temp_c\":%.1f,\"humid\":%.0f,\"dht_ok\":%s,"
      "\"water_raw\":%d,\"water_v\":%.3f,\"water_pct\":%d,"
      "\"water_empty\":%d,\"water_full\":%d"
    "}",
    soilRaw,soilV,soilPct,SOIL_DRY,SOIL_WET,
    ldrRaw,ldrV,ldrPct,LDR_DARK,LDR_LIGHT,
    dhtOk?lastTemp:NAN,dhtOk?lastHum:NAN,dhtOk?"true":"false",
    waterRawEma,waterV,waterPct,
    WATER_EMPTY,WATER_FULL
  );
  sendCORS();
  server.send(200,"application/json",buf);
}

void handleCal(){
  String t = server.hasArg("type")?server.arg("type"):"";
  if      (t=="sd") SOIL_DRY    = readAvg(PIN_SOIL);
  else if (t=="sw") SOIL_WET    = readAvg(PIN_SOIL);
  else if (t=="ld") LDR_DARK    = readAvg(PIN_LDR);
  else if (t=="ll") LDR_LIGHT   = readAvg(PIN_LDR);
  else if (t=="we") WATER_EMPTY = readAvg(PIN_WATER);  // vazio
  else if (t=="wf") WATER_FULL  = readAvg(PIN_WATER);  // cheio

  sendCORS();
  server.send(200,"text/plain","OK");
}

void setup(){
  Serial.begin(115200); delay(200);

  // ADC configuração
  analogSetWidth(12);
  analogSetPinAttenuation(PIN_SOIL,  ADC_11db);
  analogSetPinAttenuation(PIN_LDR,   ADC_11db);
  analogSetPinAttenuation(PIN_WATER, ADC_11db); // amplitude até ~3.3V

  dht.begin();

  WiFi.mode(WIFI_STA);
  Serial.printf("Conectando a '%s'...\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  uint32_t t0=millis();
  while(WiFi.status()!=WL_CONNECTED && millis()-t0<15000){ delay(300); Serial.print('.'); }
  Serial.println();
  if(WiFi.status()==WL_CONNECTED){ Serial.print("IP: "); Serial.println(WiFi.localIP()); }

  server.on("/",            HTTP_GET,      handleIndex);
  server.on("/data",        HTTP_GET,      handleData);
  server.on("/cal",         HTTP_GET,      handleCal);
  server.on("/data",        HTTP_OPTIONS,  handleOptions);
  server.on("/cal",         HTTP_OPTIONS,  handleOptions);
  server.begin();
  Serial.println("HTTP server: /, /data, /cal");
}

void loop(){ server.handleClient(); }
