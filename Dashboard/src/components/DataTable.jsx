export default function DataTable({ rows }) {
  return (
    <div className="panel">
      <h3>Tabela de Dados</h3>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Data/Hora</th><th>Solo</th><th>Temp (°C)</th><th>Umid (%)</th>
              <th>Luz</th><th>Bomba</th><th>Tempo (ms)</th><th>Regra</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r,i)=>(
              <tr key={i}>
                <td>{r.ts.toLocaleString()}</td>
                <td>{r.soil_raw}</td>
                <td>{r.temp_c.toFixed?.(1) ?? r.temp_c}</td>
                <td>{r.hum_air}</td>
                <td>{r.light_raw}</td>
                <td><span className={`badge ${r.pump_state==="ON"?"on":"off"}`}>{r.pump_state}</span></td>
                <td>{r.pump_ms}</td>
                <td>{r.rule_id}</td>
              </tr>
            ))}
            {rows.length===0 && <tr><td colSpan={8} style={{color:"#9fb1c7"}}>Sem dados.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
