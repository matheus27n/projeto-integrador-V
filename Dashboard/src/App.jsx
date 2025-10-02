import { useEffect, useMemo, useState } from "react";

// --- Firestore (somente histórico/eventos) ---
import { db } from "./firebase";
import {
  collection,
  query,
  orderBy,
  limit,
  onSnapshot,
  // where,   // se quiser filtrar direto no servidor (ver comentário abaixo)
} from "firebase/firestore";

// --- Componentes UI ---
import Layout from "./components/Layout";
import AreaHistory from "./components/AreaHistory";
import DataTable from "./components/DataTable";
import StatusPanel from "./components/StatusPanel";
import StatusTiles from "./components/StatusTiles";

// --- ESP32 (tempo real somente para tiles) ---
import { useEspTelemetry } from "./hooks/useEspTelemetry";

const MAX_POINTS_DB = 200;

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");

  // ===== 1) TEMPO REAL (ESP32) — apenas KPIs/Tiles e notificações =====
  const { data: esp, error: espError } = useEspTelemetry();
  const tempAmbiente = esp?.temp_c ?? 0;
  const luzRaw = esp?.ldr_raw ?? 0;
  const SOIL_MAX = 4095;
  const soilPctLive = useMemo(() => {
    if (!esp) return 0;
    if (typeof esp.soil_pct === "number") return esp.soil_pct;
    return Math.round(((SOIL_MAX - (esp.soil_raw ?? 0)) / SOIL_MAX) * 100);
  }, [esp]);
  const bombaOnLive = false; // se desejar, envie no JSON do ESP

  // ===== 2) FIRESTORE — histórico/tabela (ex.: quando a bomba liga) =====
  const [rowsDb, setRowsDb] = useState([]);

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");

    // A) Se você grava TODOS os registros e só quer exibir os que dispararam irrigação:
    //    deixe a query sem "where" e filtre no cliente (garante que funciona sem index extra).
    const q = query(col, orderBy("ts", "desc"), limit(MAX_POINTS_DB));

    // B) Se você quer filtrar no servidor apenas "bomba = ON", habilite o where abaixo
    //    e crie o índice no Firestore quando ele pedir no console.
    // const q = query(
    //   col,
    //   where("pump_state", "==", "ON"),
    //   orderBy("ts", "desc"),
    //   limit(MAX_POINTS_DB)
    // );

    const unsub = onSnapshot(q, (snap) => {
      const arr = [];
      snap.forEach((doc) => {
        const d = doc.data();
        // se estiver usando a opção A, filtra aqui:
        const consider =
          d.pump_state === "ON" || (d.pump_ms ?? 0) > 0; // ajuste sua regra
        if (!consider) return;

        arr.push({
          id: doc.id,
          ts: d.ts?.toDate ? d.ts.toDate() : new Date(d.ts),
          soil: Number(d.soil_raw ?? d.soil ?? 0), // mantém "raw" para o gráfico
          tempC: Number(d.temp_c ?? 0),
          humAir: Number(d.hum_air ?? 0),
          light: Number(d.light_raw ?? d.light ?? 0),
          pump: (d.pump_state ?? "OFF") === "ON",
          rule: d.rule_id ?? "-",
          dur_ms: Number(d.pump_ms ?? 0),
        });
      });
      // invertemos para cronológico crescente
      setRowsDb(arr.reverse());
    });

    return () => unsub();
  }, [deviceId]);

  const latestDb = rowsDb.at(-1);

  return (
    <Layout deviceId={deviceId} onChangeDevice={setDeviceId} onSeed={() => {}}>
      {/* ===== LINHA 1: gráfico (HISTÓRICO do Firestore) + painel direito ===== */}
      <div className="grid cols-12">
        <div className="span-8">
          {/* Usa SOMENTE dados vindos do Firestore */}
          <AreaHistory rows={rowsDb} title="Histórico de Umidade do Solo (raw)" />
        </div>

        <div className="span-4">
          <div className="panel">
            <h3>Notificações</h3>
            <ul className="notif">
              <li>
                Conexão: <b>{espError ? "OFFLINE" : "ONLINE"}</b>
                {espError && <span style={{ color: "#f87171" }}> — {espError}</span>}
              </li>
              <li>
                Último evento registrado:{" "}
                {latestDb ? latestDb.ts.toLocaleString() : "—"}
              </li>
              <li>
                Umidade do ar (últ):{" "}
                {latestDb ? Math.round(latestDb.humAir) : "—"}%
              </li>
            </ul>

            <div className="panel-sep" />

            <h3 style={{ marginTop: 8 }}>Status</h3>
            <StatusPanel
              deviceId={deviceId}
              perfil="Rosa"
              local="Sala"
              pumpOn={latestDb?.pump ?? false}
              lastTs={latestDb?.ts}
            />
          </div>
        </div>
      </div>

      {/* ===== LINHA 2: TILES (TEMPO REAL do ESP32) ===== */}
      <div className="grid cols-12">
        <div className="span-12">
          <StatusTiles
            tempAmbiente={tempAmbiente}
            umidadeSolo={soilPctLive}
            luzRaw={luzRaw}
            bombaOn={bombaOnLive}
          />
        </div>
      </div>

      {/* ===== LINHA 3: Tabela (somente Firestore) ===== */}
      <div className="grid cols-12">
        <div className="span-7">
          <DataTable rows={rowsDb} />
        </div>

        <div className="span-5">
          <div className="panel">
            <h3>Consumo de Água por Planta</h3>
            <p className="muted">
              Gráfico de pizza opcional (somatório por perfil/planta). Podemos
              implementar depois.
            </p>
          </div>
        </div>
      </div>
    </Layout>
  );
}
