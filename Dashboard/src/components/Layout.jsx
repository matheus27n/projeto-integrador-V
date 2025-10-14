import logoImg from "./data/ioterra.png";
export default function Layout({
  children,
  deviceId,
  onChangeDevice,
  onSeed,
  onPublish,
  publishLoading,
  activeMenu,
  setActiveMenu,
}) {

  const menuItems = [
    { key: "dashboard", label: "Dashboard" },
    { key: "catalogo", label: "Catálogo de Plantas" },
    { key: "historico", label: "Histórico" },
    { key: "configuracoes", label: "Configurações" },
    { key: "relatorios", label: "Relatórios" },
  ];

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <img src={logoImg} alt="Logo" className="logo" />
        </div>
        <nav className="nav">
          {menuItems.map(item => (
            <div
              key={item.key}
              className={`item ${activeMenu === item.key ? "active" : ""}`}
              onClick={() => setActiveMenu(item.key)}
            >
              {item.label}
            </div>
          ))}
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
