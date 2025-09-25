import React from "react";

type Props = {
  deviceId: string;
  perfil?: string;
  local?: string;
  pumpOn?: boolean;
  lastTs?: Date;
};

export default function StatusPanel({
  deviceId,
  perfil = "N/D",
  local = "N/D",
  pumpOn = false,
  lastTs,
}: Props) {
  const safeDate = lastTs ? lastTs.toLocaleString("pt-BR") : "—";
  return (
    <section className="panel">
      <div className="panel-header">
        <h3>Status</h3>
        <span className={`badge ${pumpOn ? "on" : "off"}`}>
          {pumpOn ? "BOMBA ON" : "BOMBA OFF"}
        </span>
      </div>

      <ul className="status-list">
        <li>
          <span className="muted">Dispositivo:</span>
          <b>{deviceId}</b>
        </li>
        <li>
          <span className="muted">Perfil:</span>
          <b>{perfil}</b>
        </li>
        <li>
          <span className="muted">Local:</span>
          <b>{local}</b>
        </li>
        <li>
          <span className="muted">Última leitura:</span>
          <b>{safeDate}</b>
        </li>
      </ul>
    </section>
  );
}
