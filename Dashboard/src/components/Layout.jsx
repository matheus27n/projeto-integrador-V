import Sidebar from "./Sidebar";
import Topbar from "./Topbar";

export default function Layout({ deviceId, onChangeDevice, onSeed, children }) {
  return (
    <div className="app">
      <Sidebar />
      <Topbar deviceId={deviceId} onChangeDevice={onChangeDevice} onSeed={onSeed} />
      <main className="content">{children}</main>
    </div>
  );
}
