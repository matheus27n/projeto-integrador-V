export default function Topbar({ deviceId, onChangeDevice, onSeed }) {
  return (
    <header className="topbar">
      <div className="title">Painel de Irrigação</div>

      <div className="right">
        <input
          style={{
            background:"#111827", border:"1px solid rgba(255,255,255,.08)",
            color:"#e5e7eb", borderRadius:10, padding:"8px 10px", outline:"none"
          }}
          value={deviceId}
          onChange={(e)=>onChangeDevice?.(e.target.value)}
          placeholder="esp32-01"
        />
        <button className="btn secondary" onClick={onSeed}>Gerar 1 leitura</button>
        <button className="btn">Publicar</button>
      </div>
    </header>
  );
}
