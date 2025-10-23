import { useEffect, useRef, useState } from "react";
import { getTelemetry } from "../api/esp";

const POLL = Number(import.meta.env.VITE_ESP_POLL_MS ?? 1000);
const COOLDOWN_MS = 5 * 60 * 1000; 

export function useEspTelemetry(logErrorToState) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  const lastErrorRef = useRef({
    tipo: null,
    timestamp: 0,
  });

  const isFetching = useRef(false);

  const isCooldownActive = (tipo) => {
    const now = Date.now();
    return (
      lastErrorRef.current.tipo === tipo &&
      now - lastErrorRef.current.timestamp < COOLDOWN_MS
    );
  };

  useEffect(() => {
    let timer = null;

    const tick = async () => {
      if (isFetching.current) return;
      isFetching.current = true;

      try {
        const telemetry = await getTelemetry();
        setData(telemetry);
        setError(null);
      } catch (e) {
        const rawMsg = e?.message || "Erro desconhecido ao obter dados do ESP32";
        let userMsg = rawMsg;
        let tipoErro = "outro";
        if (
          rawMsg.toLowerCase().includes("esp32 offline") ||
          rawMsg.toLowerCase().includes("failed to fetch") ||
          rawMsg.toLowerCase().includes("network") ||
          rawMsg.toLowerCase().includes("falha de conexão")
        ) {
          tipoErro = "esp_offline";
          userMsg =
            "Não foi possível conectar ao ESP32. Verifique se ele está ligado e na mesma rede Wi-Fi.";
        } else if (rawMsg.toLowerCase().includes("timeout")) {
          tipoErro = "timeout";
          userMsg =
            "A comunicação com o ESP32 demorou demais e foi interrompida.";
        } else if (rawMsg.toLowerCase().includes("json")) {
          tipoErro = "parse_error";
          userMsg =
            "Os dados recebidos do ESP32 estão em formato inválido (JSON malformado).";
        } else if (rawMsg.toLowerCase().includes("cors")) {
          tipoErro = "cors_error";
          userMsg =
            "Falha de comunicação com o ESP32 devido a restrições de CORS. Verifique a configuração do servidor.";
        }
        setError(userMsg);
        if (!isCooldownActive(tipoErro)) {
          if (typeof logErrorToState === "function") {
            logErrorToState("useEspTelemetry", userMsg, {
              tipoErro,
              rawError: rawMsg,
            });
          }
          lastErrorRef.current = { tipo: tipoErro, timestamp: Date.now() };
          console.warn(`[LOG ERROR] ${tipoErro}: ${userMsg}`);
        } else {
          console.info(`[Cooldown ativo] Ignorando erro repetido: ${userMsg}`);
        }
      } finally {
        isFetching.current = false;
      }
    };

    tick();
    timer = setInterval(tick, POLL);

    return () => {
      if (timer) clearInterval(timer);
    };
  }, []);

  return { data, error };
}
