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

type Props = {
  rows?: Row[];
  sortField?: keyof Row;
  sortOrder?: "asc" | "desc";
  onSortChange?: (field: keyof Row) => void;
  sortable?: boolean;
};

export default function DataTable({
  rows = [],
  sortField,
  sortOrder,
  onSortChange,
  sortable = true,
}: Props) {
  const renderSortButton = (field: keyof Row) => {
    if (!sortable) return null;

    const active = sortField === field;
    const arrow = !active ? "↕" : sortOrder === "asc" ? "▲" : "▼";

    return (
      <button
        onClick={() => onSortChange?.(field)}
        className={`sort-btn ${active ? "active" : ""}`}
        title={`Ordenar por ${field}`}
      >
        {arrow}
      </button>
    );
  };

  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            <th>
              Data/Hora {renderSortButton("ts")}
            </th>
            <th>
              Solo {renderSortButton("soil")}
            </th>
            <th>
              Temp (°C) {renderSortButton("tempC")}
            </th>
            <th>
              Umid (%) {renderSortButton("humAir")}
            </th>
            <th>
              Luz {renderSortButton("light")}
            </th>
            <th>Bomba {renderSortButton("pump")}</th>
            <th>
              Tempo (ms) {renderSortButton("dur_ms")}
            </th>
            <th>Regra {renderSortButton("rule")}</th>
          </tr>
        </thead>
        <tbody>
          {rows.slice().map((r, i) => {
            const ts = r.ts ? new Date(r.ts) : null;
            return (
              <tr key={String(r.id ?? i)}>
                <td>{ts ? ts.toLocaleString() : "—"}</td>
                <td>{r.soil}</td>
                <td>{r.tempC?.toFixed(1)}</td>
                <td>{r.humAir}</td>
                <td>{r.light}</td>
                <td>{r.pump ? "ON" : "OFF"}</td>
                <td>{r.dur_ms}</td>
                <td>{r.rule}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

