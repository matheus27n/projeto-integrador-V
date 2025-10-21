#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>
#include <Preferences.h>

/* ======== CONFIG Wi-Fi ======== */
#define ENABLE_AP_FALLBACK 0          // 1 = ativa AP+STA (fallback), 0 = só STA
const char* WIFI_SSID = "Apto.202";
const char* WIFI_PASS = "27112000";

// AP fallback (se habilitado acima)
const char* AP_SSID = "IrrigacaoESP";
const char* AP_PASS = "12345678";

/* ======== PINAGEM ======== */
const int PIN_SOIL   = 34;   // Umidade do solo (ADC1)
const int PIN_LDR    = 35;   // LDR (ADC1)
const int PIN_DHT    = 22;   // DHT22
const int PIN_WATER  = 39;   // Nível d'água (ADC1)

/* ======== RELÉ / BOMBA ========
   ATENÇÃO: Módulos comuns são ATIVOS-BAIXO.
   LOW  => relé energizado (fecha NO->COM) => LIGA a bomba
   HIGH => relé desenergizado               => DESLIGA a bomba
*/
const int PUMP_PIN = 26;

/* ======== DHT ======== */
#define DHTTYPE DHT22
DHT dht(PIN_DHT, DHTTYPE);

/* ======== Calibração (defaults) ======== */
// Solo / LDR
int SOIL_DRY  = 4095;
int SOIL_WET  = 1200;
int LDR_DARK  = 381;
int LDR_LIGHT = 737;
// Nível d'água
int WATER_EMPTY = 300;
int WATER_FULL  = 2200;

/* ======== ADC ======== */
const float VREF   = 3.3f;
const int   ADCMAX = 4095;

/* ======== Servidor ======== */
WebServer server(80);

/* ======== NVS (Preferences) ======== */
Preferences prefs;
const char* NVS_NS = "calib";

/* ======== Helpers ======== */
int readAvg(int pin, uint8_t n=16){
  uint32_t acc=0; for(uint8_t i=0;i<n;i++){ acc += analogRead(pin); delay(2); }
  return acc / n;
}
float rawToV(int raw){ return (raw * VREF) / ADCMAX; }

// EMA p/ nível de água
int emaInt(int prev, int curr, uint8_t alpha_percent = 25){
  return ( (int)prev*(100-alpha_percent) + (int)curr*alpha_percent ) / 100;
}

// 0..100% respeitando direção
int mapPctSmart(int raw, int emptyRef, int fullRef){
  if (fullRef == emptyRef) return 0;
  long pct;
  if (fullRef > emptyRef) pct = ((long)raw - emptyRef) * 100L / ((long)fullRef - emptyRef);
  else                    pct = ((long)emptyRef - raw) * 100L / ((long)emptyRef - fullRef);
  if (pct < 0) pct = 0; if (pct > 100) pct = 100;
  return (int)pct;
}

/* ======== Fuzzy – pertinências triangulares (0..255) ======== */
uint8_t tri_mu(uint8_t x, uint8_t a, uint8_t b, uint8_t c){
  if (x<=a || x>=c) return 0;
  if (x==b) return 255;
  if (x>b)  return (uint8_t)(((int)c - x) * 255 / ((int)c - b));
  return (uint8_t)(((int)x - a) * 255 / ((int)b - a));
}

/* ======== DHT cache ======== */
float lastTemp=NAN, lastHum=NAN; unsigned long lastDhtMs=0;

/* ======== Parâmetros de decisão ======== */
const int WATER_MIN_PCT = 15;    // fail-safe
const int SOIL_ON_TH    = 65;    // liga ≤65% (sua calibração atual)
const int SOIL_OFF_TH   = 70;    // desliga ≥70%
const int PUMP_MAX_MS   = 20000; // teto de segurança (20 s)

/* ======== Estado ======== */
bool pump_on = false;     // estado lógico desejado
int  pump_ms_sug = 0;     // último tempo sugerido (ms) pelo Sugeno
int  rule_id     = 0;     // regra dominante (1..8)

/* ======== Avaliador Sugeno 0-ordem (R1..R8) ======== */
int ruleSugenoMs(uint8_t dry_low, uint8_t dry_med, uint8_t dry_high,
                 uint8_t t_frio, uint8_t t_agrad, uint8_t t_quente,
                 uint8_t l_escuro, uint8_t l_nublado, uint8_t l_sol,
                 int &rule_id_out)
{
  const int R1=20000, R2=16000, R3=12000, R4=8000, R5=0, R6=0, R7=6000, R8=4000;
  auto umin = [](uint8_t a,uint8_t b){ return a<b?a:b; };
  auto umax = [](uint8_t a,uint8_t b){ return a>b?a:b; };
  auto min3 = [&](uint8_t a,uint8_t b,uint8_t c){ return umin(a, umin(b,c)); };

  uint8_t w1 = min3(dry_high, t_quente, l_sol);
  uint8_t w2 = umin(dry_high, umax(t_quente, t_agrad));
  uint8_t w3 = min3(dry_med, t_quente, l_sol);
  uint8_t w4 = umin(dry_med, umax(t_quente, t_agrad));
  uint8_t w5 = dry_low;
  uint8_t w6 = umin(t_frio, l_escuro);
  uint8_t w7 = umin(dry_high, l_escuro);
  uint8_t w8 = umin(dry_med, l_escuro);

  uint32_t num =
    (uint32_t)w1*R1 + (uint32_t)w2*R2 + (uint32_t)w3*R3 + (uint32_t)w4*R4 +
    (uint32_t)w5*R5 + (uint32_t)w6*R6 + (uint32_t)w7*R7 + (uint32_t)w8*R8;
  uint32_t den = (uint32_t)w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8;

  uint8_t ws[8]={w1,w2,w3,w4,w5,w6,w7,w8};
  int     ms[8]={R1,R2,R3,R4,R5,R6,R7,R8};
  uint8_t maxw=0; int rid=0;
  for(int i=0;i<8;i++){ if(ws[i]>maxw){ maxw=ws[i]; rid=i+1; } }
  rule_id_out = (maxw==0?0:rid);

  if (den==0) return 0;
  int sug = (int)(num/den);
  if (sug > PUMP_MAX_MS) sug = PUMP_MAX_MS;
  if (sug < 0) sug = 0;
  return sug;
}

/* ======== RELÉ helpers (ativo-baixo) ======== */
inline void relayOn()  { digitalWrite(PUMP_PIN, LOW);  } // energiza relé => NO fecha
inline void relayOff() { digitalWrite(PUMP_PIN, HIGH); } // desenergiza relé

/* ======== CORS ======== */
void sendCORS(){
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}
void handleOptions(){ sendCORS(); server.send(204); }

/* ======== Página simples ======== */
const char INDEX_HTML[] PROGMEM = R"HTML(
<!doctype html><meta charset="utf-8"/><title>ESP32</title>
<p>Endpoints:</p>
<ul>
  <li>/data</li>
  <li>/cal?type=sd|sw|ld|ll|we|wf</li>
  <li>/cal?save | /cal?load | /cal?reset | /cal?show</li>
  <li>/pump?on=1|0</li>
  <li>/net</li>
</ul>
)HTML";
void handleIndex(){ sendCORS(); server.send_P(200,"text/html",INDEX_HTML); }

/* ======== Persistência ======== */
void saveCalToNVS(){
  prefs.begin(NVS_NS, false);
  prefs.putInt("SOIL_DRY",  SOIL_DRY);
  prefs.putInt("SOIL_WET",  SOIL_WET);
  prefs.putInt("LDR_DARK",  LDR_DARK);
  prefs.putInt("LDR_LIGHT", LDR_LIGHT);
  prefs.putInt("W_EMPTY",   WATER_EMPTY);
  prefs.putInt("W_FULL",    WATER_FULL);
  prefs.end();
}
bool loadCalFromNVS(){
  prefs.begin(NVS_NS, true);
  bool has = prefs.isKey("SOIL_DRY");
  if (has){
    SOIL_DRY   = prefs.getInt("SOIL_DRY",  SOIL_DRY);
    SOIL_WET   = prefs.getInt("SOIL_WET",  SOIL_WET);
    LDR_DARK   = prefs.getInt("LDR_DARK",  LDR_DARK);
    LDR_LIGHT  = prefs.getInt("LDR_LIGHT", LDR_LIGHT);
    WATER_EMPTY= prefs.getInt("W_EMPTY",   WATER_EMPTY);
    WATER_FULL = prefs.getInt("W_FULL",    WATER_FULL);
  }
  prefs.end();
  return has;
}
void resetCalNVS(){
  prefs.begin(NVS_NS, false);
  prefs.clear();
  prefs.end();
}

/* ======== /net (diagnóstico) ======== */
void handleNet(){
  char b[256];
  snprintf(b,sizeof(b),
    "{\"sta_ip\":\"%s\",\"ap_ip\":\"%s\",\"clients\":%d}",
    WiFi.localIP().toString().c_str(),
    WiFi.softAPIP().toString().c_str(),
    WiFi.softAPgetStationNum());
  sendCORS(); server.send(200,"application/json",b);
}

/* ======== /data ======== */
void handleData(){
  // Solo e Luz (raw + %)
  int soilRaw = readAvg(PIN_SOIL);
  int ldrRaw  = readAvg(PIN_LDR);

  float soilV = rawToV(soilRaw);
  float ldrV  = rawToV(ldrRaw);

  int soilPct = mapPctSmart(soilRaw, SOIL_DRY, SOIL_WET);   // 0..100 (umidade)
  int ldrPct  = mapPctSmart(ldrRaw,  LDR_DARK, LDR_LIGHT);  // 0..100 (luz)

  // DHT (cache 2 s)
  bool dhtOk=false;
  if (millis()-lastDhtMs>=2000){
    float h=dht.readHumidity(), t=dht.readTemperature();
    if(!isnan(h)&&!isnan(t)&&h>=0&&h<=100&&t>-40&&t<85){ lastHum=h; lastTemp=t; dhtOk=true; }
    lastDhtMs=millis();
  } else if(!isnan(lastHum)&&!isnan(lastTemp)) dhtOk=true;

  // Nível d'água (EMA + %)
  static int waterRawEma = 0;
  int   waterRaw = readAvg(PIN_WATER, 24);
  waterRawEma    = emaInt(waterRawEma, waterRaw, 25);
  float waterV   = rawToV(waterRawEma);
  int   waterPct = mapPctSmart(waterRawEma, WATER_EMPTY, WATER_FULL);

  // Fuzzy (as mesmas pertinências que você já usava)
  uint8_t dry = (uint8_t)constrain(100 - soilPct, 0, 100);
  uint8_t t   = (uint8_t)constrain((int)round(dhtOk? lastTemp : 25.0f), 0, 50);
  uint8_t lz  = (uint8_t)constrain(ldrPct, 0, 100);

  uint8_t dry_low  = tri_mu(dry, 0,10,30);
  uint8_t dry_med  = tri_mu(dry, 35,50,65);
  uint8_t dry_high = tri_mu(dry, 70,90,100);

  uint8_t t_frio   = tri_mu(t, 0,10,15);
  uint8_t t_agrad  = tri_mu(t, 18,23,28);
  uint8_t t_quente = tri_mu(t, 28,35,45);

  uint8_t l_escuro = tri_mu(lz, 0,5,15);
  uint8_t l_nubl   = tri_mu(lz, 40,50,60);
  uint8_t l_sol    = tri_mu(lz, 70,85,100);

  rule_id     = 0;
  pump_ms_sug = ruleSugenoMs(dry_low,dry_med,dry_high,
                             t_frio,t_agrad,t_quente,
                             l_escuro,l_nubl,l_sol,
                             rule_id);

  // Histerese + fail-safe água
  bool water_ok = (waterPct >= WATER_MIN_PCT);
  if (!pump_on) {
    if (soilPct <= SOIL_ON_TH && water_ok) pump_on = true;
  } else {
    if (soilPct >= SOIL_OFF_TH || !water_ok) pump_on = false;
  }

  // Saída física (ATIVO-BAIXO)
  if (pump_on) relayOn(); else relayOff();

  // JSON
  char buf[1150];
  snprintf(buf,sizeof(buf),
    "{"
      "\"soil_raw\":%d,\"soil_v\":%.3f,\"soil_pct\":%d,\"soil_dry\":%d,\"soil_wet\":%d,"
      "\"ldr_raw\":%d,\"ldr_v\":%.3f,\"ldr_pct\":%d,\"ldr_dark\":%d,\"ldr_light\":%d,"
      "\"temp_c\":%.1f,\"humid\":%.0f,\"dht_ok\":%s,"
      "\"water_raw\":%d,\"water_v\":%.3f,\"water_pct\":%d,"
      "\"water_empty\":%d,\"water_full\":%d,"
      "\"pump_on\":%s,\"pump_ms_sug\":%d,\"rule_id\":%d"
    "}",
    soilRaw,soilV,soilPct,SOIL_DRY,SOIL_WET,
    ldrRaw,ldrV,ldrPct,LDR_DARK,LDR_LIGHT,
    dhtOk?lastTemp:NAN,dhtOk?lastHum:NAN,dhtOk?"true":"false",
    waterRawEma,waterV,waterPct,
    WATER_EMPTY,WATER_FULL,
    pump_on? "true":"false", pump_ms_sug, rule_id
  );
  sendCORS(); server.send(200,"application/json",buf);
}

/* ======== /cal ======== */
void handleCal(){
  String t = server.hasArg("type")?server.arg("type"):"";

  // Calibrações “rápidas” pela leitura atual
  if      (t=="sd") SOIL_DRY    = readAvg(PIN_SOIL);
  else if (t=="sw") SOIL_WET    = readAvg(PIN_SOIL);
  else if (t=="ld") LDR_DARK    = readAvg(PIN_LDR);
  else if (t=="ll") LDR_LIGHT   = readAvg(PIN_LDR);
  else if (t=="we") WATER_EMPTY = readAvg(PIN_WATER);
  else if (t=="wf") WATER_FULL  = readAvg(PIN_WATER);

  // Persistência
  else if (t=="save"){ saveCalToNVS(); sendCORS(); server.send(200,"text/plain","SAVED"); return; }
  else if (t=="load"){ bool ok=loadCalFromNVS();  sendCORS(); server.send(200,"text/plain", ok?"LOADED":"NO_DATA"); return; }
  else if (t=="reset"){ resetCalNVS();            sendCORS(); server.send(200,"text/plain","RESET"); return; }
  else if (t=="show"){
    char b[256];
    snprintf(b,sizeof(b),
      "{\"soil_dry\":%d,\"soil_wet\":%d,\"ldr_dark\":%d,\"ldr_light\":%d,\"water_empty\":%d,\"water_full\":%d}",
      SOIL_DRY,SOIL_WET,LDR_DARK,LDR_LIGHT,WATER_EMPTY,WATER_FULL
    );
    sendCORS(); server.send(200,"application/json",b);
    return;
  }

  sendCORS(); server.send(200,"text/plain","OK");
}

/* ======== /pump (manual) ======== */
void handlePump(){
  bool on = server.hasArg("on") && server.arg("on")=="1";
  if (on){ pump_on = true; relayOn(); }
  else   { pump_on = false; relayOff(); }
  sendCORS(); server.send(200,"text/plain", on?"ON":"OFF");
}

/* ======== Wi-Fi ======== */
void printNet(){
  Serial.printf("STA IP:%s  GW:%s  MASK:%s  RSSI:%d\n",
    WiFi.localIP().toString().c_str(),
    WiFi.gatewayIP().toString().c_str(),
    WiFi.subnetMask().toString().c_str(),
    WiFi.RSSI());
  Serial.printf("AP  IP:%s  CH:%d  Clients:%d\n",
    WiFi.softAPIP().toString().c_str(),
    WiFi.channel(),
    WiFi.softAPgetStationNum());
}

void setup(){
  Serial.begin(115200); delay(200);
  analogSetWidth(12);
  analogSetPinAttenuation(PIN_SOIL,  ADC_11db);
  analogSetPinAttenuation(PIN_LDR,   ADC_11db);
  analogSetPinAttenuation(PIN_WATER, ADC_11db);
  dht.begin();

  pinMode(PUMP_PIN, OUTPUT);
  relayOff(); // garante DESLIGADO (ativo-baixo)

  bool loaded = loadCalFromNVS();
  Serial.printf("Calib loaded from NVS? %s\n", loaded ? "YES" : "NO");

#if ENABLE_AP_FALLBACK
  WiFi.mode(WIFI_AP_STA);
#else
  WiFi.mode(WIFI_STA);
#endif

  Serial.printf("Conectando a '%s'...\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  uint32_t t0=millis();
  while(WiFi.status()!=WL_CONNECTED && millis()-t0<15000){ delay(300); Serial.print('.'); }
  Serial.println();

  if(WiFi.status()==WL_CONNECTED){
    Serial.print("STA IP: "); Serial.println(WiFi.localIP());
  } else {
    Serial.println("STA falhou (timeout).");
  }

#if ENABLE_AP_FALLBACK
  // Sobe AP sempre, como fallback
  bool ok = WiFi.softAP(AP_SSID, AP_PASS);
  Serial.printf("AP %s (%s) %s  IP:%s\n",
    AP_SSID, AP_PASS, ok ? "UP" : "FAIL", WiFi.softAPIP().toString().c_str());
  printNet();
#endif

  // Rotas
  server.on("/",            HTTP_GET,      [](){ sendCORS(); server.send_P(200,"text/html",INDEX_HTML); });
  server.on("/data",        HTTP_GET,      handleData);
  server.on("/cal",         HTTP_GET,      handleCal);
  server.on("/pump",        HTTP_GET,      handlePump);
  server.on("/net",         HTTP_GET,      handleNet);

  server.on("/data",        HTTP_OPTIONS,  handleOptions);
  server.on("/cal",         HTTP_OPTIONS,  handleOptions);
  server.on("/pump",        HTTP_OPTIONS,  handleOptions);
  server.on("/net",         HTTP_OPTIONS,  handleOptions);

  server.begin();
  Serial.println("HTTP server: /, /data, /cal, /pump, /net");
}

void loop(){ server.handleClient(); }
