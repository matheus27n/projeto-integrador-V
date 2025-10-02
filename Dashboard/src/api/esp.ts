export type EspData = {
  soil_raw: number; soil_v?: number; soil_pct?: number;
  soil_dry?: number; soil_wet?: number;
  ldr_raw: number;  ldr_v?: number;  ldr_pct?: number;
  ldr_dark?: number; ldr_light?: number;
  temp_c?: number;   humid?: number;  dht_ok?: boolean;
};

const BASE = import.meta.env.VITE_ESP_BASE_URL;

export async function getTelemetry(): Promise<EspData> {
  const r = await fetch(`${BASE}/data`, { cache: "no-store" });
  if (!r.ok) throw new Error(`ESP32 offline (${r.status})`);
  return r.json();
}

export async function calibrate(type: "sd" | "sw" | "ld" | "ll") {
  const r = await fetch(`${BASE}/cal?type=${type}`);
  if (!r.ok) throw new Error("Falha ao calibrar");
  return r.text();
}
