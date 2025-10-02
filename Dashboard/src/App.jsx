import { useEffect, useMemo, useState } from "react";
import Layout from "./components/Layout";
import AreaHistory from "./components/AreaHistory";
import DataTable from "./components/DataTable";
import StatusPanel from "./components/StatusPanel";
import StatusTiles from "./components/StatusTiles";
import { useEspTelemetry } from "./hooks/useEspTelemetry";

const MAX_POINTS = 200;

export default function App() {
  const deviceId = "esp32-01";
  const { data, error } = useEspTelemetry();
  const [rows, setRows] = useState([]);

  useEffect(() => {
    if (!data) return;
    const ts = new Date();
    setRows((prev) => {
      const next = [
        ...prev,
        {
          id: ts.getTime(),
          ts,
          soil: Number(data?.soil_raw ?? 0),
          tempC: Number(data?.temp_c ?? 0),
          humAir: Number(data?.humid ?? 0),
          light: Number(data?.ldr_raw ?? 0),
          pump: false,
          rule: "-",
          dur_ms: 0,
        },
      ];
      return next.length > MAX_POINTS ? next.slice(-MAX_POINTS) : next;
    });
  }, [data]);

  const latest = rows.at(-1);

  const SOIL_MAX = 4095;
  const soilPct = useMemo(() => {
    if (!data) return 0;
    if (typeof data.soil_pct === "number") return data.soil_pct;
    return Math.round(((SOIL_MAX - (data.soil_raw ?? 0)) / SOIL_MAX) * 100);
  }, [data]);

  const tempAmbiente = data?.temp_c ?? 0;
  const luzRaw = data?.ldr_raw ?? 0;
  const bombaOn = false; // traga no JSON do ESP se quiser

  return (
    <Layout deviceId={deviceId} onChangeDevice={() => {}} onSeed={() => {}}>
      {/* LINHA 1: gráfico + notificações+status (no mesmo painel) */}
      <div className="grid cols-12">
        <div className="span-8">
          <AreaHistory rows={rows} />
        </div>

        <div className="span-4">
          <div className="panel">
            <h3>Notificações</h3>
            <ul className="notif">
              <li>
                Conexão: <b>{error ? "OFFLINE" : "ONLINE"}</b>
                {error && <span style={{ color: "#f87171" }}> — {error}</span>}
              </li>
              <li>Última leitura: {latest ? latest.ts.toLocaleString() : "—"}</li>
              <li>Umidade do ar (últ): {data ? Math.round(Number(data.humid ?? 0)) : "—"}%</li>
            </ul>

            <div className="panel-sep" />

            <h3 style={{ marginTop: 8 }}>Status</h3>
            <StatusPanel
              deviceId={deviceId}
              perfil="Rosa"
              local="Sala"
              pumpOn={bombaOn}
              lastTs={latest?.ts}
            />
          </div>
        </div>
      </div>

      {/* LINHA 2: 4 tiles */}
      <div className="grid cols-12">
        <div className="span-12">
          <StatusTiles
            tempAmbiente={tempAmbiente}
            umidadeSolo={soilPct}
            luzRaw={luzRaw}
            bombaOn={bombaOn}
          />
        </div>
      </div>

      {/* LINHA 3: tabela + placeholder */}
      <div className="grid cols-12">
        <div className="span-7">
          <DataTable rows={rows} />
        </div>
        <div className="span-5">
          <div className="panel">
            <h3>Consumo de Água por Planta</h3>
            <p className="muted">Gráfico de pizza opcional (somatório por perfil/planta).</p>
          </div>
        </div>
      </div>
    </Layout>
  );
}
