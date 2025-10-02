type Props = {
  deviceId?: string;
  perfil?: string;
  local?: string;
  pumpOn?: boolean;
  lastTs?: Date | string | number | null;
};

export default function StatusPanel({
  deviceId,
  perfil,
  local,
  pumpOn,
  lastTs,
}: Props) {
  const ts = lastTs ? new Date(lastTs) : null;

  return (
    <ul className="status-list">
      <li>
        <span className="muted">Dispositivo:</span> <b>{deviceId ?? "-"}</b>
      </li>
      <li>
        <span className="muted">Perfil:</span> <b>{perfil ?? "-"}</b>
      </li>
      <li>
        <span className="muted">Local:</span> <b>{local ?? "-"}</b>
      </li>
      <li>
        <span className="muted">Última leitura:</span>{" "}
        <b>{ts ? ts.toLocaleString() : "—"}</b>
      </li>
      <li>
        <span className="muted">Bomba:</span>{" "}
        <span className={`badge ${pumpOn ? "on" : "off"}`}>
          {pumpOn ? "ON" : "OFF"}
        </span>
      </li>
    </ul>
  );
}
