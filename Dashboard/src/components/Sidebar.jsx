export default function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="brand">
        <div className="logo" />
        Irrigador automático IoT
      </div>

      <nav className="nav">
        <a className="item active" href="#">📊 Dashboard</a>
        <a className="item" href="#">🕓 Histórico</a>
        <a className="item" href="#">⚙️ Configurações</a>
        <a className="item" href="#">📄 Relatórios</a>
      </nav>
    </aside>
  );
}
