// src/components/StatusTiles.jsx
export default function StatusTiles({ tempAmbiente, umidadeSolo, luzRaw, bombaOn, waterPct }) {
  const waterIsLow = Number.isFinite(Number(waterPct)) && Number(waterPct) < 5;

  return (
    <div className="tiles">
      <Tile icon="🌡️" className="green" title="Temp. Ambiente"
        value={Number.isFinite(+tempAmbiente) ? `${(+tempAmbiente).toFixed(1)} °C` : "—"} />
      <Tile icon="💧" className="cyan" title="Umidade do Solo"
        value={Number.isFinite(+umidadeSolo) ? `${(+umidadeSolo).toFixed(0)} %` : "—"} />
      <Tile icon="💡" className="amber" title="Luz"
        value={Number.isFinite(+luzRaw) ? String(luzRaw) : "—"} />
      <Tile icon="⚙️" className="slate" title="Status Bomba"
        value={bombaOn ? "LIGADA" : "DESLIGADA"} />
      <Tile icon="🚰" className="cyan" title="Nível d'Água"
        value={
          Number.isFinite(+waterPct)
            ? <span style={{ color: waterIsLow ? "#f87171" : "#e6edf5" }}>
                {(+waterPct).toFixed(0)} %
              </span>
            : "—"
        } />
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
