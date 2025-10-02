export type Row = {
  id?: string | number;
  ts?: Date | string | number | null;
  soil?: number | null;
  tempC?: number | null;
  humAir?: number | null;
  light?: number | null;
  pump?: boolean | null;
  dur_ms?: number | null;
  rule?: number | string | null;
};

type Props = { rows?: Row[] };

export default function DataTable({ rows = [] }: Props) {
  return (
    <>
      <div className="panel-header">
        <h3>Tabela de Dados</h3>
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Data/Hora</th>
              <th>Solo</th>
              <th>Temp (°C)</th>
              <th>Umid (%)</th>
              <th>Luz</th>
              <th>Bomba</th>
              <th>Tempo (ms)</th>
              <th>Regra</th>
            </tr>
          </thead>
          <tbody>
            {(rows ?? []).slice().reverse().map((r, i) => {
              const tempC = Number(r?.tempC ?? 0);
              const hum = Math.round(Number(r?.humAir ?? 0));
              const soil = Number(r?.soil ?? 0);
              const light = Number(r?.light ?? 0);
              const pump = !!r?.pump;
              const ts = r?.ts ? new Date(r.ts) : null;

              return (
                <tr key={String(r?.id ?? i)}>
                  <td>{ts ? ts.toLocaleString() : "—"}</td>
                  <td>{soil}</td>
                  <td>{Number.isFinite(tempC) ? tempC.toFixed(1) : "—"}</td>
                  <td>{Number.isFinite(hum) ? hum : "—"}</td>
                  <td>{light}</td>
                  <td>{pump ? "ON" : "OFF"}</td>
                  <td>{Number(r?.dur_ms ?? 0)}</td>
                  <td>{r?.rule ?? "-"}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
}
