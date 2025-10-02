import { useEffect, useRef, useState } from "react";
import { getTelemetry } from "../api/esp";

const POLL = Number(import.meta.env.VITE_ESP_POLL_MS ?? 1000);

export function useEspTelemetry() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const timer = useRef(null);

  useEffect(() => {
    const tick = async () => {
      try { setData(await getTelemetry()); setError(null); }
      catch (e) { setError(e?.message || "erro"); }
    };
    tick();
    timer.current = window.setInterval(tick, POLL);
    return () => { if (timer.current !== null) window.clearInterval(timer.current); };
  }, []);

  return { data, error };
}
