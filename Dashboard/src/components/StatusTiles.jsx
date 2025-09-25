// components/StatusTiles.jsx
import React from "react";

/**
 * Cartões quadrados de status para o dashboard.
 * Espera valores já prontos (ex.: umidadeSolo em %, luz em raw/LUX etc).
 */
export default function StatusTiles({
  tempAmbiente = 0,
  umidadeSolo = 0,
  luzRaw = 0,
  bombaOn = false,
}) {
  return (
    <section className="panel">
      <h3>Status</h3>

      <div className="tiles">
        {/* Temp. ambiente */}
        <div className="tile">
          <div className="tile-icon cyan">🌡️</div>
          <div className="tile-body">
            <div className="tile-title">Temp. ambiente</div>
            <div className="tile-value">
              {typeof tempAmbiente === "number"
                ? `${tempAmbiente.toFixed(1)} °C`
                : tempAmbiente}
            </div>
          </div>
        </div>

        {/* Umidade do solo */}
        <div className="tile">
          <div className="tile-icon green">🌱</div>
          <div className="tile-body">
            <div className="tile-title">Umidade do solo</div>
            <div className="tile-value">
              {typeof umidadeSolo === "number" ? `${umidadeSolo}%` : umidadeSolo}
            </div>
          </div>
        </div>

        {/* Luz */}
        <div className="tile">
          <div className="tile-icon amber">💡</div>
          <div className="tile-body">
            <div className="tile-title">Luz</div>
            <div className="tile-value">{luzRaw}</div>
          </div>
        </div>

        {/* Bomba */}
        <div className="tile">
          <div className={`tile-icon ${bombaOn ? "green" : "slate"}`}>⚙️</div>
          <div className="tile-body">
            <div className="tile-title">Bomba</div>
            <div className="tile-value">
              <span className={`badge ${bombaOn ? "on" : "off"}`}>
                {bombaOn ? "ON" : "OFF"}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
