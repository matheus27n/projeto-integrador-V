export default function Layout({
  children,
  deviceId,
  onChangeDevice,
  onSeed,
  onPublish,
  publishLoading,
}) {
  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <div className="logo" />
          <span>Irrigador automático IoT</span>
        </div>
        <nav className="nav">
          <div className="item active">Dashboard</div>
          <div className="item">Histórico</div>
          <div className="item">Configurações</div>
          <div className="item">Relatórios</div>
        </nav>
      </aside>

      <header className="topbar">
        <div className="title">Painel de Irrigação</div>
        <div className="right">
          <select
            value={deviceId}
            onChange={(e) => onChangeDevice?.(e.target.value)}
            className="btn secondary"
            style={{ padding: "8px 10px", borderRadius: 10, border: "none" }}
          >
            <option value="esp32-01">esp32-01</option>
            <option value="esp32-02">esp32-02</option>
          </select>

          {onSeed && (
            <button className="btn secondary" onClick={onSeed}>
              Gerar 1 leitura
            </button>
          )}

          <button
            className="btn"
            onClick={onPublish}
            disabled={publishLoading}
            title="Publica a leitura atual dos sensores no Firestore"
          >
            {publishLoading ? "Publicando..." : "Publicar"}
          </button>
        </div>
      </header>

      <main className="content">{children}</main>
    </div>
  );
}
