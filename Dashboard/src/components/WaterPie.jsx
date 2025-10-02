// src/components/WaterPie.jsx
import {
  PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer,
} from "recharts";

/**
 * props:
 * - rows: array vindo do Firestore (mesmo usado em DataTable)
 * - flowLpm: vazão da bomba em L/min (default 1.6)
 * - groupBy: "rule" | "month" | "all"
 * - palette: opcional array de cores
 * - title: string do cabeçalho
 */
export default function WaterPie({
  rows = [],
  flowLpm = 1.6,
  groupBy = "rule",
  palette = ["#34d399","#22d3ee","#fbbf24","#60a5fa","#f472b6","#f97316","#a78bfa","#4ade80"],
  title = "Consumo de Água",
}) {
  // soma litros de cada linha: apenas quando houve irrigação (pump_ms > 0)
  const liters = (ms) => (Number(ms || 0) / 60000) * Number(flowLpm || 0);

  let groups = {};

  if (groupBy === "rule") {
    // por regra (Rule/FPGA): 1,2,3,... ou "MANUAL"
    rows.forEach(r => {
      if (!r) return;
      const key = r.rule ?? "-";
      const l = liters(r.dur_ms);
      if (l > 0) groups[key] = (groups[key] || 0) + l;
    });
  } else if (groupBy === "month") {
    // por mês/ano (ex.: "10/2025")
    rows.forEach(r => {
      if (!r?.ts) return;
      const d = new Date(r.ts);
      const key = `${String(d.getMonth()+1).padStart(2,"0")}/${d.getFullYear()}`;
      const l = liters(r.dur_ms);
      if (l > 0) groups[key] = (groups[key] || 0) + l;
    });
  } else {
    // tudo em um só (total)
    const total = rows.reduce((acc, r) => acc + liters(r?.dur_ms), 0);
    groups["Total"] = total;
  }

  // monta data para o gráfico
  const data = Object.entries(groups)
    .map(([name, value]) => ({ name: String(name), value: Number(value.toFixed(2)) }))
    .filter(d => d.value > 0);

  const totalLiters = data.reduce((a, b) => a + b.value, 0);

  return (
    <div className="panel">
      <div className="panel-header">
        <h3>{title}</h3>
        <small className="muted">
          {totalLiters.toFixed(2)} L • vazão {flowLpm} L/min
        </small>
      </div>

      {data.length === 0 ? (
        <p className="muted">Sem irrigação registrada ainda.</p>
      ) : (
        <div style={{ width: "100%", height: 280 }}>
          <ResponsiveContainer>
            <PieChart>
              <Pie
                data={data}
                dataKey="value"
                nameKey="name"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={2}
              >
                {data.map((_, i) => (
                  <Cell key={i} fill={palette[i % palette.length]} />
                ))}
              </Pie>
              <Tooltip
                formatter={(v) => [`${Number(v).toFixed(2)} L`, "Consumo"]}
                labelFormatter={(l) => `Grupo: ${l}`}
              />
              <Legend verticalAlign="bottom" height={36} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      )}

      <p className="muted" style={{marginTop: 6}}>
        Dica: ajuste a vazão (L/min) conforme sua bomba para aproximar do real.
      </p>
    </div>
  );
}
