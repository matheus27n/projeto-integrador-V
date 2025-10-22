
import { useEffect, useMemo, useState, useRef } from "react";
import Toast from "./components/Toast";
import WaterPie from "./components/WaterPie";
import LogoImp from "./components/data/import.png";
import LogoEdit from "./components/data/edit.png";
import LogoDel from "./components/data/remove.png";

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
  const [selectedPerfil,setSelectedPerfil] = useState(null);
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
  const [culturas, setCulturas] = useState([]);
  const [importedCultura, setImportedCultura] = useState(null);

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
        });
      });
      setRowsDb(arr.reverse()); 
    });

    return () => unsub();
  }, [deviceId]);

  const latestDb = rowsDb.at(-1);

  const [publishing, setPublishing] = useState(false);
  const lastPubRef = useRef(0);

  async function publishNow() {
    if (!esp) {
      alert("Sem leitura do ESP no momento.");
      return;
    }
    if (publishing) return;

    if (Date.now() - lastPubRef.current < 2000) return;

    setPublishing(true);
    try {
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
    } catch (e) {
      console.error(e);
      alert("Falha ao publicar leitura.");
    } finally {
      setPublishing(false);
    }
  }

  const [calibrating, setCalibrating] = useState(false);
  const [calibMessage, setCalibMessage] = useState(null); 

  async function handleCalibrate(type) {
    setCalibrating(true);
    setCalibMessage(null);

    try {
      let resultMessage = "";

      switch (type) {
        case "add": {
          const novaCultura = {
            nome: "Nova Cultura",
            kc: 0,
            etc_media: 0,
            lamina_agua: 0, 
            intervalo_horas: sliderValues.freq,
            umidade_min_pct: sliderValues.soil_min,
            umidade_max_pct: sliderValues.soil_maximun,
            luz_min: sliderValues.light_min,
            luz_max: sliderValues.light_max,
            tempo_bomba_ms: sliderValues.bomb_time * 1000, 
            agua_min_pct: sliderValues.water_min,
            observacoes: "",
          };

          setCulturas((prev) => [...prev, novaCultura]);
          resultMessage = "Nova cultura adicionada ao catálogo com os valores atuais dos sliders.";
          break;
        }

        case "save": {
          const blob = new Blob([JSON.stringify(culturas, null, 2)], {
            type: "application/json",
          });
          const url = URL.createObjectURL(blob);
          const a = document.createElement("a");
          a.href = url;
          a.download = "catalogo_culturas.json";
          a.click();
          resultMessage = "Catálogo salvo como arquivo JSON.";
          break;
        }
        case "load": {
          const input = document.createElement("input");
          input.type = "file";
          input.accept = ".json";

          input.onchange = async (e) => {
            const file = e.target.files[0];
            if (!file) return;

            const text = await file.text();
            const json = JSON.parse(text);

            if (Array.isArray(json)) {
              setCulturas(json);
              setImportedCultura(null); 
              setCalibMessage({ type: "success"});
            } else {
              setImportedCultura(json); 
              setCulturas(prev => [...prev, json]); 
              setCalibMessage({ type: "success"});
            }
          };
          input.click();
          return; 
        }
        case "reset": {
          setCulturas([]);
          setImportedCultura(null);
          setSliderValues({
            soil_min: 0,
            soil_maximun: 100,
            light_min: 0,
            light_max: 100,
            water_min: 15,
            bomb_time: 0,
            freq: 0,
          });
          resultMessage = "Catálogo e sliders foram resetados.";
          break;
        }
        default:
          throw new Error(`Tipo de calibração desconhecido: ${type}`);
      }

      setCalibMessage({ type: "success", text: resultMessage });
    } catch (e) {
      console.error("Erro na calibração:", e);
      setCalibMessage({
        type: "error",
        text: `Falha na ação '${type}': ${e.message}`,
      });
    } finally {
      setCalibrating(false);
    }
  }

  async function handleImport(cultura){
    setSliderValues({
      soil_min: cultura.umidade_min_pct,
      soil_maximun: cultura.umidade_max_pct,
      light_min: cultura.luz_min ?? 0,      
      light_max: cultura.luz_max ?? 100,   
      water_min: cultura.agua_min_pct,
      bomb_time: cultura.tempo_bomba_ms / 1000,
      freq: cultura.intervalo_horas
    });
    setImportedCultura(cultura);
  }

  async function handleEdit(cultura) {
    setEditing(cultura);
    setEditForm({
      nome: cultura.nome,
      kc: cultura.kc ?? 1.0,
      etc_media: cultura.etc_media ?? 1.0,
      lamina_agua: cultura.lamina_agua ?? 1.0,
      umidade_min_pct: cultura.umidade_min_pct,
      umidade_max_pct: cultura.umidade_max_pct,
      luz_min: cultura.luz_min ?? 0,
      luz_max: cultura.luz_max ?? 100,
      agua_min_pct: cultura.agua_min_pct,
      tempo_bomba_ms: cultura.tempo_bomba_ms,
      intervalo_horas: cultura.intervalo_horas,
      observacoes: cultura.observacoes ?? "",
    });
  }


  async function handleSaveEdit() {
    setCulturas((prev) =>
      prev.map((c) => (c === editing ? { ...c, ...editForm } : c))
    );

    setRowsDb((prev) =>
      prev.map((row) =>
        row.id === editing.id ? { ...row, ...editForm } : row
      )
    );

    if (importedCultura === editing) {
      setSliderValues({
        soil_min: editForm.umidade_min_pct,
        soil_maximun: editForm.umidade_max_pct,
        light_min: editForm.luz_min,
        light_max: editForm.luz_max,
        water_min: editForm.agua_min_pct,
        bomb_time: editForm.tempo_bomba_ms / 1000,
        freq: editForm.intervalo_horas,
      });
      setImportedCultura({ ...importedCultura, ...editForm });
    }

    setEditing(null);
    setCalibMessage({ type: "success", text: `Cultura "${editForm.nome}" atualizada.` });
  }

  async function handleDelete(cultura) {
    if (confirm(`Deseja realmente remover "${cultura.nome}"?`)) {
      setCulturas((prev) => prev.filter((c) => c !== cultura));

      setRowsDb((prev) => prev.filter((row) => row.id !== cultura.id));

      if (importedCultura === cultura) {
        setImportedCultura(null);
        setSliderValues({
          soil_min: 0,
          soil_maximun: 100,
          light_min: 0,
          light_max: 100,
          water_min: 15, 
          bomb_time: 0,
          freq: 0,
        });
      }

      setCalibMessage({ type: "success", text: `Cultura "${cultura.nome}" removida.` });
    }
  }

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
              {/* Tabela Firestore */}
              <div className="span-8">
                <DataTable rows={rowsDb.slice(-10)} />
              </div>

              {/* Painel de Calibração */}
              <div className="span-4">
                <div className="panel">
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


                  {/* Botões de calibração */}
                  <div className="button-group">
                    <h4>Ações</h4>
                    <button onClick={() => handleCalibrate("add")} disabled={calibrating}>
                      Adicionar no catálogo
                    </button>
                    <button onClick={() => handleCalibrate("save")} disabled={calibrating}>
                      Salvar catálogo
                    </button>
                    <button onClick={() => handleCalibrate("load")} disabled={calibrating}>
                      Carregar catálogo
                    </button>
                    <button onClick={() => handleCalibrate("reset")} disabled={calibrating}>
                      Limpar catálogo
                    </button>
                  </div>

                  {/* Mensagem de calibração */}
                  {calibMessage && (
                    <p
                      style={{
                        color: calibMessage.type === "error" ? "#f87171" : "#a7f3d0",
                        marginTop: "10px",
                      }}
                    >
                      {calibMessage.text}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </> 
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
                <th className="center">Ações</th>
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
                  <td className="center">
                    <button className="edit-btn" onClick={() => handleEdit(cultura)}
                    title="Clique para editar os parâmetros desta planta."
                    >
                      < img src={LogoEdit} style={{ width: "16px"}}/>
                    </button>
                    <button
                      className="import-btn"
                      onClick={() => handleImport(cultura)}
                      title="Clique para importar os parâmetros desta planta."
                    >
                      <img src={LogoImp} style={{ width: "16px" }} />
                    </button>
                    <button className="delete-btn" onClick={() => handleDelete(cultura)}
                      title="Clique para remover os parâmetros desta planta."
                      >
                        < img src={LogoDel} style={{ width: "16px"}}/>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    )}
    {editing && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>Editar Cultura: {editForm.nome}</h3>

            <label>Nome</label>
            <input
              type="text"
              value={editForm.nome}
              onChange={(e) => setEditForm({ ...editForm, nome: e.target.value })}
            />

            <label>Kc</label>
            <input
              type="number"
              step="0.01"
              value={editForm.kc}
              min={0}
              onChange={(e) => setEditForm({ ...editForm, kc: Number(e.target.value) })}
            />

            <label>ETc Média</label>
            <input
              type="number"
              step="0.01"
              value={editForm.etc_media}
              min={0}
              onChange={(e) => setEditForm({ ...editForm, etc_media: Number(e.target.value) })}
            />

            <label>Lâmina de água (L/m²/dia)</label>
            <input
              type="number"
              step="0.01"
              value={editForm.lamina_agua}
              min={0}
              onChange={(e) => setEditForm({ ...editForm, lamina_agua: Number(e.target.value) })}
            />

            <label>Umidade mínima (%)</label>
            <input
              type="number"
              value={editForm.umidade_min_pct}
              min={0}
              max={editForm.umidade_max_pct}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= 0 && val <= editForm.umidade_max_pct)
                  setEditForm({ ...editForm, umidade_min_pct: val });
              }}
            />

            <label>Umidade máxima (%)</label>
            <input
              type="number"
              value={editForm.umidade_max_pct}
              min={editForm.umidade_min_pct}
              max={100}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= editForm.umidade_min_pct && val <= 100)
                  setEditForm({ ...editForm, umidade_max_pct: val });
              }}
            />

            <label>Luz mínima (%)</label>
            <input
              type="number"
              value={editForm.luz_min}
              min={0}
              max={editForm.luz_max}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= 0 && val <= editForm.luz_max)
                  setEditForm({ ...editForm, luz_min: val });
              }}
            />

            <label>Luz máxima (%)</label>
            <input
              type="number"
              value={editForm.luz_max}
              min={editForm.luz_min}
              max={100}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= editForm.luz_min && val <= 100)
                  setEditForm({ ...editForm, luz_max: val });
              }}
            />

            <label>Água mínima (%)</label>
            <input
              type="number"
              value={editForm.agua_min_pct}
              min={15}
              max={50}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= 15 && val <= 50)
                  setEditForm({ ...editForm, agua_min_pct: val });
              }}
            />

            <label>Tempo da bomba (s)</label>
            <input
              type="number"
              value={editForm.tempo_bomba_ms}
              min={0}
              max={120}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= 0 && val <= 120)
                  setEditForm({ ...editForm, tempo_bomba_ms: val });
              }}
            />

            <label>Intervalo de irrigação (h)</label>
            <input
              type="number"
              value={editForm.intervalo_horas}
              min={0}
              max={168}
              onChange={(e) => {
                const val = Number(e.target.value);
                if (val >= 0 && val <= 168)
                  setEditForm({ ...editForm, intervalo_horas: val });
              }}
            />

            <label>Observações</label>
            <textarea
              value={editForm.observacoes}
              onChange={(e) => setEditForm({ ...editForm, observacoes: e.target.value })}
            />

            <div className="modal-actions">
              <button onClick={handleSaveEdit}>Salvar</button>
              <button onClick={() => setEditing(null)}>Cancelar</button>
            </div>
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
      {activeMenu === "historico" && (
        <div className="panel">
          <h3>Histórico</h3>
        </div>
      )}
      {activeMenu === "configuracoes" && (
        <div className="panel">
          <h3>Configurações</h3>
        </div>
      )}
      {activeMenu === "relatorios" && (
        <div className="panel">
          <h3>Relatórios</h3>
        </div>
      )}
    </Layout>
  );
}
