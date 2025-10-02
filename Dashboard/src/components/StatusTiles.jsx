export default function StatusTiles({ tempAmbiente, umidadeSolo, luzRaw, bombaOn }) {
  return (
    <div className="status-tiles-wrap">
      <Tile
        icon="🌡️" className="green" title="Temp. Ambiente"
        value={Number.isFinite(Number(tempAmbiente)) ? `${Number(tempAmbiente).toFixed(1)} °C` : "—"}
      />
      <Tile
        icon="💧" className="cyan" title="Umidade do Solo"
        value={Number.isFinite(Number(umidadeSolo)) ? `${Number(umidadeSolo).toFixed(0)} %` : "—"}
      />
      <Tile
        icon="💡" className="amber" title="Luz"
        value={Number.isFinite(Number(luzRaw)) ? String(luzRaw) : "—"}
      />
      <Tile
        icon="⚙️" className="slate" title="Status Bomba"
        value={bombaOn ? "LIGADA" : "DESLIGADA"}
      />
    </div>
  );
}

function Tile({ icon, title, value, className }) {
  return (
    <div className="tile">
      <div className={`tile-icon ${className}`}>{icon}</div>
      <div className="tile-body">
        <div className="tile-title">{title}</div>
        <div className="tile-value">{value}</div>
      </div>
    </div>
  );
}
