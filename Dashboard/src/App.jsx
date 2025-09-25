// src/App.jsx
import { useEffect, useState } from "react";
import { db } from "./firebase";
import {
  collection,
  query,
  orderBy,
  limit,
  onSnapshot,
  addDoc,
} from "firebase/firestore";

import Layout from "./components/Layout";
import AreaHistory from "./components/AreaHistory";
import DataTable from "./components/DataTable";
import StatusPanel from "./components/StatusPanel";
import StatusTiles from "./components/StatusTiles";

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");
  const [rows, setRows] = useState([]);
  const latest = rows.at(-1);

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    const q = query(col, orderBy("ts", "desc"), limit(200));
    const unsub = onSnapshot(q, (snap) => {
      const arr = [];
      snap.forEach((doc) => {
        const d = doc.data();
        arr.push({
          ts: d.ts?.toDate ? d.ts.toDate() : new Date(d.ts),
          soil_raw: d.soil_raw ?? 0,
          temp_c: d.temp_c ?? 0,
          hum_air: d.hum_air ?? 0,
          light_raw: d.light_raw ?? 0,
          pump_state: d.pump_state ?? "OFF",
          pump_ms: d.pump_ms ?? 0,
          rule_id: d.rule_id ?? 0,
        });
      });
      setRows(arr.reverse());
    });
    return () => unsub();
  }, [deviceId]);

  // KPIs
  const SOIL_MAX = 1023; // se o ADC for 12-bit, use 4095
  const soilPct = Math.round(
    ((SOIL_MAX - (latest?.soil_raw ?? 0)) / SOIL_MAX) * 100
  );
  const tempAmbiente = latest?.temp_c ?? 0;
  const humNow = latest?.hum_air ?? 0; // ainda usamos na Notificação
  const luzRaw = latest?.light_raw ?? 0;
  const bombaOn = (latest?.pump_state ?? "OFF") === "ON";

  async function seedOne() {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    await addDoc(col, {
      ts: new Date(),
      soil_raw: 400 + Math.floor(Math.random() * 300),
      temp_c: +(22 + Math.random() * 6).toFixed(1),
      hum_air: +(45 + Math.random() * 20).toFixed(0),
      light_raw: 1000 + Math.floor(Math.random() * 2000),
      pump_state: Math.random() > 0.7 ? "ON" : "OFF",
      pump_ms: Math.random() > 0.7 ? 8000 : 0,
      rule_id: Math.floor(Math.random() * 4) + 1,
    });
  }

  return (
    <Layout deviceId={deviceId} onChangeDevice={setDeviceId} onSeed={seedOne}>
      {/* ===== LINHA 1: gráfico (8 col) + notificações (4 col) ===== */}
      <div className="grid cols-12">
        <div className="span-8">
          <AreaHistory rows={rows} />
        </div>

        <div className="span-4">
          <div className="panel">
            <h3>Notificações</h3>
            <ul className="notif">
              <li>
                Conexão estável com <b>{deviceId}</b>.
              </li>
              <li>Última leitura: {latest ? latest.ts.toLocaleString() : "—"}</li>
              <li>
                Bomba:{" "}
                <span className={`badge ${bombaOn ? "on" : "off"}`}>
                  {bombaOn ? "ON" : "OFF"}
                </span>
              </li>
              <li>Umidade do ar (últ.): {humNow || 0}%</li>
            </ul>
          </div>
        </div>
      </div>

      {/* ===== LINHA 2: cartões quadrados de status ===== */}
      <div className="grid cols-12">
        <div className="span-12">
          <StatusTiles
            tempAmbiente={tempAmbiente}
            umidadeSolo={soilPct}
            luzRaw={luzRaw}
            bombaOn={bombaOn}
          />
        </div>
      </div>

      {/* ===== LINHA 2.5: Painel de Status (opcional) ===== */}
      <div className="grid cols-12">
        <div className="span-4">
          <StatusPanel
            deviceId={deviceId}
            perfil="Rosa"
            local="Sala"
            pumpOn={bombaOn}
            lastTs={latest?.ts}
          />
        </div>
      </div>

      {/* ===== LINHA 3: Tabela (7 col) + Pizza placeholder (5 col) ===== */}
      <div className="grid cols-12">
        <div className="span-7">
          <DataTable rows={rows} />
        </div>

        <div className="span-5">
          <div className="panel">
            <h3>Consumo de Água por Planta</h3>
            <p className="muted">
              Gráfico de pizza opcional (somatório por perfil/planta). Podemos
              implementar depois.
            </p>
          </div>
        </div>
      </div>
    </Layout>
  );
}
