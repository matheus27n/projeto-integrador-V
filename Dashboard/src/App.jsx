import { useEffect, useMemo, useState } from "react";
import { db } from "./firebase";
import {
  collection, query, orderBy, limit, onSnapshot, addDoc
} from "firebase/firestore";
import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend
} from "chart.js";
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend);

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");
  const [rows, setRows] = useState([]);
  const [seeding, setSeeding] = useState(false); // para desabilitar botão durante a gravação

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    const q = query(col, orderBy("ts", "desc"), limit(200));
    const unsub = onSnapshot(q, (snap) => {
      const r = [];
      snap.forEach((doc) => {
        const d = doc.data();
        const ts = d.ts?.toDate ? d.ts.toDate() : new Date(d.ts);
        r.push({
          ts,
          soil_raw: d.soil_raw ?? 0,
          temp_c: d.temp_c ?? 0,
          hum_air: d.hum_air ?? 0,
          light_raw: d.light_raw ?? 0,
          pump_state: d.pump_state ?? "OFF",
          pump_ms: d.pump_ms ?? 0,
          rule_id: d.rule_id ?? 0,
        });
      });
      setRows(r.reverse());
    });
    return () => unsub();
  }, [deviceId]);

  const chartData = useMemo(() => ({
    labels: rows.map(r => r.ts.toLocaleString()),
    datasets: [
      { label: "Umidade do solo (raw)", data: rows.map(r => r.soil_raw) },
    ]
  }), [rows]);

  // === UMA simulação por clique ===
  async function seedOne() {
    if (!deviceId || seeding) return;
    setSeeding(true);
    try {
      const col = collection(db, "devices", deviceId, "measurements");
      await addDoc(col, {
        ts: new Date(),                        // ou use serverTimestamp() se preferir
        soil_raw: 560 + Math.floor(Math.random() * 120),
        temp_c: 22 + Math.random() * 5,
        hum_air: 50 + Math.random() * 15,
        light_raw: 2200 + Math.floor(Math.random() * 1500),
        pump_state: Math.random() > 0.7 ? "ON" : "OFF",
        pump_ms: Math.random() > 0.7 ? 8000 : 0,
        rule_id: Math.floor(Math.random() * 4) + 1
      });
    } finally {
      setSeeding(false);
    }
  }

  return (
    <div style={{ padding: 16, fontFamily: "system-ui, sans-serif" }}>
      <header style={{ display: "flex", gap: 12, alignItems: "center", marginBottom: 8 }}>
        <h2>🌱 Dashboard – Irrigação</h2>
        <label>
          ID do Dispositivo:&nbsp;
          <input value={deviceId} onChange={e => setDeviceId(e.target.value)} />
        </label>
        <button onClick={seedOne} disabled={seeding}>
          {seeding ? "Gerando..." : "Gerar 1 leitura"}
        </button>
      </header>

      <div style={{ display: "grid", gap: 12, gridTemplateColumns: "1fr 1fr" }}>
        <div style={{ border: "1px solid #ddd", borderRadius: 8, padding: 12 }}>
          <h3>Histórico (últimas 200 leituras)</h3>
          {rows.length === 0 && (
            <p style={{ opacity: .7 }}>Sem dados para “{deviceId}”. Clique em <b>Gerar dados de teste</b> ou insira leituras em <code>devices/{deviceId}/measurements</code>.</p>
          )}
          <Line data={chartData} options={{ animation: false, responsive: true }} />
        </div>

        <div style={{ border: "1px solid #ddd", borderRadius: 8, padding: 12 }}>
          <h3>Tabela</h3>
          <div style={{ maxHeight: 420, overflow: "auto" }}>
            <table width="100%" style={{ borderCollapse: "collapse", fontSize: 14 }}>
              <thead>
                <tr>
                  {["Data/Hora","Solo","Temp (°C)","Umid (%)","Luz","Bomba","Tempo (ms)","Regra"].map(h => (
                    <th key={h} style={{ textAlign: "left", borderBottom: "1px solid #eee", padding: 6 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={i} style={{ borderBottom: "1px solid #f3f3f3" }}>
                    <td style={{ padding: 6 }}>{r.ts.toLocaleString()}</td>
                    <td style={{ padding: 6 }}>{r.soil_raw}</td>
                    <td style={{ padding: 6 }}>{r.temp_c.toFixed(1)}</td>
                    <td style={{ padding: 6 }}>{r.hum_air.toFixed?.(0) ?? r.hum_air}</td>
                    <td style={{ padding: 6 }}>{r.light_raw}</td>
                    <td style={{ padding: 6 }}>{r.pump_state}</td>
                    <td style={{ padding: 6 }}>{r.pump_ms}</td>
                    <td style={{ padding: 6 }}>{r.rule_id}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
