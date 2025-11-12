import { useEffect, useMemo, useState, useRef } from "react";
import Toast from "./components/Toast";
import LogoImp from "./components/data/import.png";
import LogoEdit from "./components/data/edit.png";
import LogoDel from "./components/data/remove.png";
import culturasJson from "./components/data/catalogo_culturas.json";
import log_errosJson from "./components/data/log_error.json";

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
import VisualizePerfil from "./components/VisualizePerfil";

import { useEspTelemetry } from "./hooks/useEspTelemetry";
import { calibrate } from "./api/esp";

const MAX_POINTS_DB = 200;
const WATER_MIN_PCT = 15; 

export default function App() {
  const [deviceId, setDeviceId] = useState("esp32-01");
  const [activeMenu, setActiveMenu] = useState("dashboard");
  const [sliderValues, setSliderValues] = useState({
    soil_min: 0,
    soil_maximun: 100,
    light_min: 0,
    light_max: 100,
    water_min: 15,
    bomb_time: 0,
    freq: 0,
  });
  const [editing, setEditing] = useState(null); 
  const [editForm, setEditForm] = useState({
    nome: "",
    umidade_min_pct: 0,
    umidade_max_pct: 0,
    luz_min: 0,
    luz_max: 100,
    agua_min_pct: 15,
    tempo_bomba_ms: 1000,
    intervalo_horas: 24,
  });
  const [log_error, setLogError] = useState([]);
  useEffect(() => {
    async function loadLog() {
      try {
        setLogError(log_errosJson);
      } catch (e) {
        console.error("Falha ao carregar log_error.json:", e);
      }
    }
    loadLog();
  }, []);

  const [culturas, setCulturas] = useState([]);
  const [importedCultura, setImportedCultura] = useState(null);
  useEffect(() => {
    async function loadCulturas (){
      try{
        setCulturas(culturasJson)
      } catch (e) {
        console.error("Falha ao carregar catalogo_culturas.json", e);
      }
    };
    loadCulturas();
  }, []);

  const { data: esp, error: espError } = useEspTelemetry();
  const SOIL_MAX = 4095;

  const soilPctLive = useMemo(() => {
    if (!esp) return 0;
    if (typeof esp.soil_pct === "number") return esp.soil_pct;
    return Math.round(((SOIL_MAX - (esp.soil_raw ?? 0)) / SOIL_MAX) * 100);
  }, [esp]);

  const tempAmbiente = esp?.temp_c ?? 0;
  const luzRaw = esp?.ldr_raw ?? 0;
  const bombaOnLive = !!esp?.pump_on; 
  const waterNowPct = typeof esp?.water_pct === "number" ? esp.water_pct : null;

  const pumpMsSug = esp?.pump_ms_sug ?? 0;
  const regraId   = esp?.rule_id ?? 0;

  const [lowLevelToast, setLowLevelToast] = useState(false);
  const lastWaterOkRef = useRef(true);

  useEffect(() => {
    if (waterNowPct == null) return;
    const ok = waterNowPct >= WATER_MIN_PCT;
    const lastOk = lastWaterOkRef.current;
    if (lastOk && !ok) setLowLevelToast(true);
    else if (!lastOk && ok) setLowLevelToast(false);
    lastWaterOkRef.current = ok;
  }, [waterNowPct]);

  const [rowsDb, setRowsDb] = useState([]);
  const [filterType, setFilterType] = useState("todos");
  const [sortField, setSortField] = useState("ts");
  const [sortOrder, setSortOrder] = useState("desc");

  useEffect(() => {
    if (!deviceId) return;
    const col = collection(db, "devices", deviceId, "measurements");
    const q = query(col, orderBy("ts", "desc"), limit(MAX_POINTS_DB));

    const unsub = onSnapshot(q, (snap) => {
      const arr = [];
      snap.forEach((doc) => {
        const d = doc.data();

        const consider =
          d.pump_state === "ON" || (d.pump_ms ?? 0) > 0 || d.source === "manual";
        if (!consider) return;

        arr.push({
          id: doc.id,
          ts: d.ts?.toDate ? d.ts.toDate() : new Date(d.ts),
          soil: Number(d.soil_raw ?? d.soil ?? 0), 
          tempC: Number(d.temp_c ?? 0),
          humAir: Number(d.hum_air ?? 0),
          light: Number(d.light_raw ?? d.light ?? 0),
          pump: (d.pump_state ?? "OFF") === "ON",
          rule: d.source === "manual" ? "MANUAL" : (d.rule_id ?? "-"),
          dur_ms: Number(d.pump_ms ?? 0),
          source: d.source ?? null,
          manual: d.source === "manual"
        });
      });
      setRowsDb(arr); 
    });

    return () => unsub();
  }, [deviceId]);

  const filteredRows = useMemo(() => {
    const now = new Date();

    if (filterType === "hoje") {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      return rowsDb.filter((r) => new Date(r.ts) >= start);
    }

    if (filterType === "semana") {
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay());
      startOfWeek.setHours(0, 0, 0, 0);

      return rowsDb.filter((r) => new Date(r.ts) >= startOfWeek);
    }

    if (filterType === "mes") {
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      return rowsDb.filter((r) => new Date(r.ts) >= startOfMonth);
    }

    return rowsDb; 
  }, [rowsDb, filterType]);

  const sortedRows = useMemo(() => {
    const arr = [...filteredRows];

    const getComparable = (row, field) => {
      const v = row?.[field];

      if (field === "ts") {
        const d = v ? new Date(v) : null;
        return d && !isNaN(d.getTime()) ? d.getTime() : -Infinity;
      }

      if (field === "rule" || field === "source") {
        if (typeof v === "string") {
          const lower = v.toLowerCase();
          if (lower === "manual" || lower === "man") return { type: "manual", val: 2 };
          if (lower === "-" || lower === "null") return { type: "empty", val: 0 };
          const n = Number(v);
          if (!Number.isNaN(n)) return { type: "number", val: n };
          return { type: "string", val: v };
        }
        if (typeof v === "number") return { type: "number", val: v };
        if (v === null || v === undefined) return { type: "empty", val: 0 };
        return { type: "unknown", val: String(v) };
      }

      if (typeof v === "boolean") return v ? 1 : 0;
      if (typeof v === "number") return v;
      if (typeof v === "string" && v.trim() !== "") {
        const n = Number(v);
        if (!Number.isNaN(n)) return n;
        return v.toLowerCase(); 
      }

      return -Infinity;
    };

    arr.sort((a, b) => {
      const dir = sortOrder === "asc" ? 1 : -1;
      const A = getComparable(a, sortField);
      const B = getComparable(b, sortField);

      if (sortField === "rule" || sortField === "source") {
        const typePriority = { empty: 0, number: 1, string: 1.5, manual: 2, unknown: 1.2 };
        const aType = A.type || "unknown";
        const bType = B.type || "unknown";

        if (typePriority[aType] !== typePriority[bType]) {
          return (typePriority[aType] - typePriority[bType]) * dir;
        }

        if (aType === "number" && bType === "number") {
          return (A.val - B.val) * dir;
        }

        if (A.val < B.val) return -1 * dir;
        if (A.val > B.val) return 1 * dir;
      } else {
        const aVal = A;
        const bVal = B;

        if (typeof aVal === "number" && typeof bVal === "number") {
          if (aVal < bVal) return -1 * dir;
          if (aVal > bVal) return 1 * dir;
        } else {
          const sa = String(aVal).toLowerCase();
          const sb = String(bVal).toLowerCase();
          if (sa < sb) return -1 * dir;
          if (sa > sb) return 1 * dir;
        }
      }

      const ta = a.ts ? new Date(a.ts).getTime() : 0;
      const tb = b.ts ? new Date(b.ts).getTime() : 0;
      return (ta - tb) * dir;
    });

    return arr;
  }, [filteredRows, sortField, sortOrder]);

  const latestDb = rowsDb.at(-1);

  const [publishing, setPublishing] = useState(false);
  const lastPubRef = useRef(0);

  async function publishNow() {
    if (!esp) return alert("Sem leitura do ESP no momento.");

    if (publishing || Date.now() - lastPubRef.current < 2000) return;

    setPublishing(true);
    await safeExec("publishNow", async () => {
      const col = collection(db, "devices", deviceId, "measurements");
      const payload = {
        ts: serverTimestamp(),
        soil_raw: Math.round(esp.soil_raw ?? 0),
        soil_pct: Math.round(esp.soil_pct ?? soilPctLive),
        temp_c: Number(esp.temp_c ?? 0),
        hum_air: Math.round(esp.humid ?? 0),
        light_raw: Math.round(esp.ldr_raw ?? 0),
        pump_state: bombaOnLive ? "ON" : "OFF",
        pump_ms: 0,
        rule_id: 0,
        source: "manual",
      };
      const ref = await addDoc(col, payload);
      lastPubRef.current = Date.now();
      console.log("Publicado docId:", ref.id, payload);
    });
    setPublishing(false);
  }

  const [calibrating, setCalibrating] = useState(false);
  const [calibMessage, setCalibMessage] = useState(null); 

  async function handleCalibrate(type) {
    setCalibrating(true);
    setCalibMessage(null);
    try {
      if (!type) throw new Error("Tipo de calibração não especificado.");
      const res = await calibrate(type);
      setCalibMessage({ type: "success", text: `Calibração '${type}' realizada: ${res}` });
    } catch (e) {
      console.error("Erro na calibração:", e);
      let userMsg;
      const msg = e?.message || "Erro desconhecido";
      if (msg.includes("network") || msg.includes("fetch")) {
        userMsg = `Falha de conexão ao calibrar '${type}'. Verifique a internet ou o dispositivo.`;
      } else if (msg.includes("timeout")) {
        userMsg = `A calibração '${type}' demorou demais e foi interrompida.`;
      } else if (msg.includes("não especificado")) {
        userMsg = `Nenhum tipo de calibração foi informado.`;
      } else {
        userMsg = `Falha na calibração '${type}': ${msg}`;
      }
      setCalibMessage({ type: "error", text: userMsg });
      try {
        logErrorToState("handleCalibrate", userMsg, { type, rawError: msg });
      } catch (err) {
        console.error("Falha ao registrar log de calibração:", err);
      }
    } finally {
      setCalibrating(false);
    }
  }

  async function safeExec(fonte, func) {
    try {
      await func();
    } catch (e) {
      logErrorToState(fonte, e.message, { stack: e.stack });
      console.error(`Erro em ${fonte}:`, e);
      alert(`Erro em ${fonte}: ${e.message}`);
    }
  }

  function logErrorToState(fonte, descricao, extra = {}) {
    try {
      setLogError((prev) => {
        const listaAnterior = Array.isArray(prev) ? prev : [];
        const novoErro = {
          id: prev.length + 1,
          data_hora: new Date().toLocaleString(),
          fonte,
          descricao: descricao?.toString() || "Erro desconhecido",
          ...extra,
        };
        console.warn(`[LOG ERROR] ${fonte}: ${descricao}`);
        return [...prev, novoErro];
      });
    } catch (e) {
      console.error("Falha ao registrar log no estado:", e);
    }
  }
  const { data, error } = useEspTelemetry(logErrorToState);

  useEffect(() => {
    const handleBeforeUnload = () => {
      if (log_error.length > 0) {
        const blob = new Blob([JSON.stringify(log_error, null, 2)], {
          type: "application/json",
        });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "log_error.json";
        a.click();
        URL.revokeObjectURL(url);
        console.log("Arquivo log_error.json salvo ao sair");
      }
    };
    window.addEventListener("beforeunload", handleBeforeUnload);
    return () => {
      window.removeEventListener("beforeunload", handleBeforeUnload);
    };
  }, [log_error]);

  return (
    <Layout
      deviceId={deviceId}
      onChangeDevice={setDeviceId}
      onPublish={publishNow}
      publishLoading={publishing}
      onSeed={() => {}}
      activeMenu={activeMenu}          
      setActiveMenu={setActiveMenu}    
    >
      {activeMenu === "dashboard" &&(
        <>
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
                  <li>Último evento registrado: {latestDb ? latestDb.ts.toLocaleString() : "—"}</li>
                  <li>Umidade do ar (últ): {latestDb ? Math.round(latestDb.humAir) : "—"}%</li>
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
                waterPct={waterNowPct}
              />
            </div>
          </div>

            <div className="grid cols-12">
              <div className="span-8">
                <DataTable rows={rowsDb.slice(0,10)} sortable={false} />
              </div>

              {/* Painel de Calibração */}
              <div className="span-4">
                <div className="panel" style={{textAlign: "center"}}>
                  <h3>Visualizar parâmetros de irrigação</h3>
                  <p className="muted">
                    Visualize os valores dos parâmetros de irrigação que estão sendo aplicados no sistema.
                  </p>

                  {/* Sliders */}
                  <div className="slider-group">
                    <h4>Umidade Mínima do Solo: {sliderValues.soil_min}%</h4>
                    <input
                      type="range"
                      min={0}
                      max={sliderValues.soil_maximun}
                      value={sliderValues.soil_min}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, soil_min: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          (sliderValues.soil_min / sliderValues.soil_maximun) * 100
                        }%, #e6edf5 ${(sliderValues.soil_min / sliderValues.soil_maximun) * 100}%, #e6edf5 100%)`,
                      }}
                    />

                    <h4>Umidade Máxima do Solo: {sliderValues.soil_maximun}%</h4>
                    <input
                      type="range"
                      min={sliderValues.soil_min}
                      max={100}
                      value={sliderValues.soil_maximun}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, soil_maximun: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          ((sliderValues.soil_maximun - sliderValues.soil_min) / (100 - sliderValues.soil_min)) * 100
                        }%, #e6edf5 ${((sliderValues.soil_maximun - sliderValues.soil_min) / (100 - sliderValues.soil_min)) * 100}%, #e6edf5 100%)`,
                      }}
                    />

                    <h4>Luz mínima permitida: {sliderValues.light_min}%</h4>
                    <input
                      type="range"
                      min={0}
                      max={sliderValues.light_max}
                      value={sliderValues.light_min}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, light_min: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          (sliderValues.light_min / sliderValues.light_max) * 100
                        }%, #e6edf5 ${(sliderValues.light_min / sliderValues.light_max) * 100}%, #e6edf5 100%)`,
                      }}
                    />

                    <h4>Luz máxima permitida: {sliderValues.light_max}%</h4>
                    <input
                      type="range"
                      min={sliderValues.light_min}
                      max={100}
                      value={sliderValues.light_max}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, light_max: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          ((sliderValues.light_max - sliderValues.light_min) / (100 - sliderValues.light_min)) * 100
                        }%, #e6edf5 ${((sliderValues.light_max - sliderValues.light_min) / (100 - sliderValues.light_min)) * 100}%, #e6edf5 100%)`,
                      }}
                    />

                    <h4>Nível mínimo da água do reservatório: {sliderValues.water_min}%</h4>
                    <input
                      type="range"
                      min={15}
                      max={50}
                      value={sliderValues.water_min}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, water_min: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          ((sliderValues.water_min - 15) / (50 - 15)) * 100
                        }%, #e6edf5 ${((sliderValues.water_min - 15) / (50 - 15)) * 100}%, #e6edf5 100%)`,
                      }}
                    />

                    <h4>Tempo de funcionamento da bomba: {sliderValues.bomb_time}s</h4>
                    <input
                      type="range"
                      min={0}
                      max={120}
                      value={sliderValues.bomb_time}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, bomb_time: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          ((sliderValues.bomb_time) / 120) * 100
                        }%, #e6edf5 ${((sliderValues.bomb_time) / 120) * 100}%, #e6edf5 100%)`,
                      }}
                    />
                    
                    <h4>Intervalo de irrigação: {sliderValues.freq}h</h4>
                    <input
                      type="range"
                      min={0}
                      max={168}
                      value={sliderValues.freq}
                      onChange={(e) =>
                        setSliderValues((prev) => ({ ...prev, freq: Number(e.target.value) }))
                      }
                      style={{
                        width: "80%",
                        height: "12px",
                        borderRadius: "6px",
                        outline: "none",
                        background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${
                          ((sliderValues.freq) / 168) * 100
                        }%, #e6edf5 ${((sliderValues.freq) / 168) * 100}%, #e6edf5 100%)`,
                      }}
                    />
                  </div>
                </div>
              </div>
            </div>
          </> 
        )}
      {activeMenu === "history" && (
        <div className="panel">
          <h3>Visualizar Histórico</h3>

          {/* ===== FILTROS ===== */}
          <div className="controls" style={{ display: "flex", gap: "1em" , marginTop:"1em" , marginBottom: "1em" }}>
            <label>
              Filtrar:
              <select style={{marginLeft : "1em"}} value={filterType} onChange={(e) => setFilterType(e.target.value)}>
                <option value="todos">Todos</option>
                <option value="hoje">Hoje</option>
                <option value="semana">Esta semana</option>
                <option value="mes">Este mês</option>
              </select>
            </label>
          </div>

          {/* ===== TABELA ===== */}
          <DataTable
            rows={sortedRows}
            sortField={sortField}
            sortOrder={sortOrder}
            sortable = {true}
            onSortChange={(field) => {
              if (sortField !== field) {
                setSortField(field);
                setSortOrder("asc");
              } else {
                setSortOrder(sortOrder === "asc" ? "desc" : "asc");
              }
            }}
          />
        </div>
      )}
      {activeMenu === "catalogo" && (
      <div className="panel">
        <h3>Catálogo de Plantas</h3>
        <p className="muted" style={{ marginBottom: 12 }}>
          Visualize os parâmetros cadastrados para cada cultura e importe o perfil desejado para o sistema.
        </p>

        <div style={{overflowX: "auto" }}>
          <table className="perfil-table">
            <thead>
              <tr>
                <th>Nome</th>
                <th>Kc</th>
                <th>ETc Média</th>
                <th>Lâmina (L/m²/dia)</th>
                <th>Umid. Mín (%)</th>
                <th>Umid. Máx (%)</th>
                <th>Luz Mín (%)</th>
                <th>Luz Máx (%)</th>
                <th>Tempo Bomba (s)</th>
                <th>Intervalo (h)</th>
                <th>Nível Mín. Água (%)</th>
                <th>Observações</th>
              </tr>
            </thead>

            <tbody>
              {culturas.map((cultura) => (
                <tr key={cultura.nome}>
                  <td className="bold">{cultura.nome}</td>
                  <td>{cultura.kc}</td>
                  <td>{cultura.etc_media}</td>
                  <td>{cultura.lamina_agua}</td>
                  <td>{cultura.umidade_min_pct}</td>
                  <td>{cultura.umidade_max_pct}</td>
                  <td>{cultura.luz_min}</td>
                  <td>{cultura.luz_max}</td>
                  <td>{cultura.tempo_bomba_ms / 1000}</td>
                  <td>{cultura.intervalo_horas}</td>
                  <td>{cultura.agua_min_pct}</td>
                  <td className="muted italic">
                    {cultura.observacoes || "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    )}
    {/* ===== Banner/Toast de nível d'água baixo ===== */}
      <Toast
        show={lowLevelToast}
        title="Nível de água baixo"
        message={`Reservatório em ${waterNowPct ?? "—"}%. Reabasteça para evitar falhas na irrigação.`}
        onClose={() => setLowLevelToast(false)}
      />
      {/* Toast para mensagens de calibração */}
      <Toast
        show={!!calibMessage}
        title={calibMessage?.type === "success" ? "Sucesso" : "Erro"}
        message={calibMessage?.text}
        onClose={() => setCalibMessage(null)}
        type={calibMessage?.type}
      />
      {activeMenu === "calibracao" && (
        <div className="panel">
          <h3>Calibração dos Sensores</h3>
          <p className="muted">
              Clique para calibrar os sensores
            </p>
            <div className="button-group">
              <h4>Solo</h4>
              <button onClick={() => handleCalibrate("sd")} disabled={calibrating}>Solo Seco</button>
              <button onClick={() => handleCalibrate("sw")} disabled={calibrating}>Solo Molhado</button>
              <h4>Luz</h4>
              <button onClick={() => handleCalibrate("ld")} disabled={calibrating}>Luz Escuro</button>
              <button onClick={() => handleCalibrate("ll")} disabled={calibrating}>Luz Sol</button>
              <h4>Água</h4>
              <button onClick={() => handleCalibrate("we")} disabled={calibrating}>Água Vazia</button>
              <button onClick={() => handleCalibrate("wf")} disabled={calibrating}>Água Cheia</button>
            </div>
            {calibMessage && (
              <p style={{ color: calibMessage.type === "error" ? "#f87171" : "#a7f3d0", marginTop: "10px" }}>
                {calibMessage.text}
              </p>
            )}
          </div>
      )}
      {activeMenu === "log_error" && (
        <div className="panel">
          <h3>Log de Erros</h3>
          <div style={{ overflowX: "auto" }}>
            <table className="perfil-table">
              <thead>
                <tr>
                  <th>Identificador</th>
                  <th>Data e Hora</th>
                  <th>Fonte</th>
                  <th>Descrição do Erro</th>
                </tr>
              </thead>

              <tbody>
                {log_error.length === 0 ? (
                  <tr>
                    <td colSpan="4" style={{ textAlign: "center", color: "#999" }}>
                      Nenhum erro registrado ainda.
                    </td>
                  </tr>
                ) : (
                  log_error.map((e) => (
                    <tr key={e.id}>
                      <td className="bold">{e.id}</td>
                      <td>{e.data_hora}</td>
                      <td>{e.fonte}</td>
                      <td className="muted italic">
                        {e.descricao || "—"}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </Layout>
  );
}
