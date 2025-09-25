import { useEffect, useMemo, useState } from "react";
import { db } from "./firebase";
import { collection, query, orderBy, limit, onSnapshot, addDoc } from "firebase/firestore";

import Layout from "./components/Layout";
import StatCard from "./components/Statcard";
import CircularGauge from "./components/CircularGauge";
import AreaHistory from "./components/AreaHistory";
import DataTable from "./components/DataTable";

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");
  const [rows, setRows] = useState([]);
  const latest = rows.at(-1);

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    const q = query(col, orderBy("ts", "desc"), limit(200));
    const unsub = onSnapshot(q, snap => {
      const arr=[];
      snap.forEach(doc=>{
        const d=doc.data();
        arr.push({
          ts: d.ts?.toDate? d.ts.toDate() : new Date(d.ts),
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

  // Gauges (ajuste faixas conforme sensores)
  const SOIL_MAX = 1023; // se usa 12-bit ADC: 4095
  const soilPct = Math.round(((SOIL_MAX - (latest?.soil_raw ?? 0)) / SOIL_MAX) * 100); // exemplo: inverso
  const tempNow = latest?.temp_c ?? 0;
  const humNow  = latest?.hum_air ?? 0;
  const lightNow= latest?.light_raw ?? 0;
  const pump    = latest?.pump_state ?? "OFF";

  async function seedOne() {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    await addDoc(col, {
      ts: new Date(),
      soil_raw: 400 + Math.floor(Math.random()*300),
      temp_c: +(22 + Math.random()*6).toFixed(1),
      hum_air: +(45 + Math.random()*20).toFixed(0),
      light_raw: 1000 + Math.floor(Math.random()*2000),
      pump_state: Math.random()>0.7 ? "ON" : "OFF",
      pump_ms: Math.random()>0.7 ? 8000 : 0,
      rule_id: Math.floor(Math.random()*4)+1
    });
  }

  return (
    <Layout deviceId={deviceId} onChangeDevice={setDeviceId} onSeed={seedOne}>
      {/* linha 1: gráfico + notificações (placeholder) */}
      <div className="grid grid-2">
        <AreaHistory rows={rows} />
        <div className="panel">
          <h3>Notificações</h3>
          <ul style={{margin:0, padding:"2px 14px", lineHeight:1.8, color:"#9fb1c7"}}>
            <li>Conexão estável com {deviceId}.</li>
            <li>Última leitura: {latest ? latest.ts.toLocaleString() : "—"}</li>
            <li>Bomba: <b style={{color: pump==="ON" ? "#34d399" : "#cbd5e1"}}>{pump}</b></li>
          </ul>
        </div>
      </div>

      {/* linha 2: gauges e cards */}
      <div className="grid grid-3">
        <div className="panel">
          <h3>Indicadores</h3>
          <div className="gauges">
            <CircularGauge value={tempNow} min={0} max={50} unit="°C" color="#06b6d4" label="Temp. Solo"/>
            <CircularGauge value={humNow} min={0} max={100} unit="%" color="#10b981" label="Umidade do Ar"/>
            <CircularGauge value={soilPct} min={0} max={100} unit="%" color="#84cc16" label="Umidade do Solo"/>
            <CircularGauge value={lightNow} min={0} max={4095} unit="" color="#f59e0b" label="Luz (raw)"/>
          </div>
        </div>

        <StatCard icon="🌡️" color="cyan"  value={`${(tempNow||0).toFixed?.(1) ?? tempNow} °C`} label="Temp. Solo (última)"/>
        <StatCard icon="💧"  color="green" value={`${humNow||0}%`} label="Umidade do ar (última)"/>
      </div>

      {/* linha 3: tabela + (placeholder) pizza consumo */}
      <div className="grid grid-2">
        <DataTable rows={rows} />
        <div className="panel">
          <h3>Consumo de Água por Planta</h3>
          <p style={{color:"#9fb1c7"}}>Gráfico de pizza opcional (somatório por perfil/planta). Podemos implementar depois.</p>
        </div>
      </div>
    </Layout>
  );
}
