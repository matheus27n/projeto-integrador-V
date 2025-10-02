
import { useEffect, useMemo, useState, useRef } from "react";
import Toast from "./components/Toast";
import WaterPie from "./components/WaterPie";


// Firestore
import { db } from "./firebase";
import {
  collection,
  query,
  orderBy,
  limit,
  onSnapshot,
  addDoc,
  serverTimestamp,
} from "firebase/firestore";

// UI
import Layout from "./components/Layout";
import AreaHistory from "./components/AreaHistory";
import DataTable from "./components/DataTable";
import StatusPanel from "./components/StatusPanel";
import StatusTiles from "./components/StatusTiles";

// ESP32 tempo real (apenas para tiles/notificações)
import { useEspTelemetry } from "./hooks/useEspTelemetry";

const MAX_POINTS_DB = 200;
const WATER_MIN_PCT = 5; // limiar para alerta

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");

  // ===== 1) ESP32 tempo real — somente tiles/notificações
  const { data: esp, error: espError } = useEspTelemetry();
  const SOIL_MAX = 4095;

  const soilPctLive = useMemo(() => {
    if (!esp) return 0;
    if (typeof esp.soil_pct === "number") return esp.soil_pct;
    return Math.round(((SOIL_MAX - (esp.soil_raw ?? 0)) / SOIL_MAX) * 100);
  }, [esp]);

  const tempAmbiente = esp?.temp_c ?? 0;
  const luzRaw = esp?.ldr_raw ?? 0;
  const bombaOnLive = false; // envie no JSON do ESP para refletir aqui, se quiser
  const waterNowPct = typeof esp?.water_pct === "number" ? esp.water_pct : null;

  // ===== Toast/Banner de nível d'água baixo (<5%)
  const [lowLevelToast, setLowLevelToast] = useState(false);
  const lastWaterOkRef = useRef(true);

  useEffect(() => {
    if (waterNowPct == null) return;
    const ok = waterNowPct >= WATER_MIN_PCT;
    const lastOk = lastWaterOkRef.current;
    // dispara quando cruza de OK -> LOW
    if (lastOk && !ok) setLowLevelToast(true);
    lastWaterOkRef.current = ok;
  }, [waterNowPct]);

  // ===== 2) Firestore — histórico e tabela (irrigação OU publicação manual)
  const [rowsDb, setRowsDb] = useState([]);

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    const q = query(col, orderBy("ts", "desc"), limit(MAX_POINTS_DB));

    const unsub = onSnapshot(q, (snap) => {
      const arr = [];
      snap.forEach((doc) => {
        const d = doc.data();

        // Mostrar: quando a bomba ligou OU quando foi uma publicação manual
        const consider =
          d.pump_state === "ON" || (d.pump_ms ?? 0) > 0 || d.source === "manual";
        if (!consider) return;

        arr.push({
          id: doc.id,
          ts: d.ts?.toDate ? d.ts.toDate() : new Date(d.ts),
          soil: Number(d.soil_raw ?? d.soil ?? 0), // mantém raw no gráfico
          tempC: Number(d.temp_c ?? 0),
          humAir: Number(d.hum_air ?? 0),
          light: Number(d.light_raw ?? d.light ?? 0),
          pump: (d.pump_state ?? "OFF") === "ON",
          rule: d.source === "manual" ? "MANUAL" : (d.rule_id ?? "-"),
          dur_ms: Number(d.pump_ms ?? 0),
          source: d.source ?? null,
        });
      });
      setRowsDb(arr.reverse()); // cronológico crescente
    });

    return () => unsub();
  }, [deviceId]);

  const latestDb = rowsDb.at(-1);

  // ===== 3) Publicar manualmente a leitura atual do ESP =====
  const [publishing, setPublishing] = useState(false);
  const lastPubRef = useRef(0);

  async function publishNow() {
    if (!esp) {
      alert("Sem leitura do ESP no momento.");
      return;
    }
    if (publishing) return;

    // cooldown simples (evita spam acidental)
    if (Date.now() - lastPubRef.current < 2000) return;

    setPublishing(true);
    try {
      const col = collection(db, "devices", deviceId, "measurements");
      const payload = {
        ts: serverTimestamp(), // timestamp do servidor
        soil_raw: Math.round(esp.soil_raw ?? 0),
        soil_pct: Math.round(esp.soil_pct ?? soilPctLive),
        temp_c: Number(esp.temp_c ?? 0),
        hum_air: Math.round(esp.humid ?? 0),
        light_raw: Math.round(esp.ldr_raw ?? 0),

        pump_state: bombaOnLive ? "ON" : "OFF",
        pump_ms: 0,
        rule_id: 0,

        // etiqueta para aparecer no histórico mesmo sem irrigação
        source: "manual",
      };
      const ref = await addDoc(col, payload);
      lastPubRef.current = Date.now();
      console.log("Publicado docId:", ref.id, payload);
    } catch (e) {
      console.error(e);
      alert("Falha ao publicar leitura.");
    } finally {
      setPublishing(false);
    }
  }

  return (
    <Layout
      deviceId={deviceId}
      onChangeDevice={setDeviceId}
      onPublish={publishNow}
      publishLoading={publishing}
      onSeed={() => {}}
    >
      {/* ===== Linha 1: Gráfico (Firestore) + Painel direito ===== */}
      <div className="grid cols-12">
        <div className="span-8">
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
              {/* Nível d'água em tempo real (não vai para o BD) */}
              <li>
                Nível da água (agora):{" "}
                <b
                  style={{
                    color:
                      waterNowPct != null && waterNowPct < WATER_MIN_PCT
                        ? "#f87171"
                        : "#e6edf5",
                  }}
                >
                  {waterNowPct != null ? `${waterNowPct}%` : "—"}
                </b>
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

      {/* ===== Linha 2: Tiles (tempo real do ESP32) ===== */}
      <div className="grid cols-12">
        <div className="span-12">
          <StatusTiles
            tempAmbiente={tempAmbiente}
            umidadeSolo={soilPctLive}
            luzRaw={luzRaw}
            bombaOn={bombaOnLive}
            waterPct={waterNowPct}  // <<< novo tile de nível d'água
          />
        </div>
      </div>

      {/* ===== Linha 3: Tabela (Firestore) ===== */}
      <div className="grid cols-12">
        <div className="span-7">
          <DataTable rows={rowsDb.slice(-6)} />
        </div>
        {/* <div className="span-5">
          <div className="panel">
            <h3>Consumo de Água por Planta</h3>
            <p className="muted">
              Gráfico de pizza opcional (somatório por perfil/planta). Podemos
              implementar depois.
            </p>
          </div>
        </div> */}
      </div>

      {/* ===== Banner/Toast de nível d'água baixo ===== */}
      <Toast
        show={lowLevelToast}
        title="Nível de água baixo"
        message={`Reservatório em ${waterNowPct ?? "—"}%. Reabasteça para evitar falhas na irrigação.`}
        onClose={() => setLowLevelToast(false)}
      />
    </Layout>
  );
}
