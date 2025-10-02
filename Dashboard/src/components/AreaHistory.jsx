import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid, Legend, Line
} from "recharts";

export default function AreaHistory({ rows = [], title = "Histórico" }) {
  const data = rows.map((r, i) => ({
    idx: i + 1,
    soil: Number(r?.soil ?? 0),
  }));

  return (
    <>
      <div className="panel-header">
        <h3>{title}</h3>
      </div>
      <div style={{ width: "100%", height: 300 }}>
        <ResponsiveContainer>
          <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="cSoil" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.45}/>
                <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid stroke="rgba(255,255,255,.06)" />
            <XAxis dataKey="idx" tick={{ fill: "#9fb1c7", fontSize: 12 }} />
            <YAxis tick={{ fill: "#9fb1c7", fontSize: 12 }} />
            <Tooltip contentStyle={{ background: "#0f1621", border: "1px solid rgba(255,255,255,.06)" }}/>
            <Legend />
            <Area type="monotone" dataKey="soil" name="Umidade do Solo (raw)" stroke="#10b981" fill="url(#cSoil)" />
            <Line type="monotone" dataKey="soil" stroke="#34d399" dot={false} name="Linha" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </>
  );
}
