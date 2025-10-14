export default function VisualizePerfil({ perfil }) {
  if (!perfil) {
    return (
      <div className="panel">
        <h3>Perfil de Cultura</h3>
        <p className="muted">Selecione uma cultura para visualizar seus parâmetros.</p>
      </div>
    );
  }

  return (
    <div className="panel">
      <div className="panel-header">
        <h3>Perfil Selecionado: {perfil.nome}</h3>
      </div>

      <div className="panel-content">
        <table className="perfil-table" style={{ width: "100%", borderCollapse: "collapse" }}>
          <tbody>
            <tr>
              <td><b>Intervalo entre irrigações</b></td>
              <td>{perfil.intervalo_horas} h</td>
            </tr>
            <tr>
              <td><b>Nível mínimo de água</b></td>
              <td>{perfil.agua_min_pct} %</td>
            </tr>
            <tr>
              <td><b>Kc</b></td>
              <td>{perfil.kc}</td>
            </tr>
            <tr>
              <td><b>ETc Média</b></td>
              <td>{perfil.etc_media}</td>
            </tr>
            <tr>
              <td><b>Lâmina (L/m²/dia)</b></td>
              <td>{perfil.lamina_agua}</td>
            </tr>
            <tr>
              <td><b>Umidade Mínima (%)</b></td>
              <td>{perfil.umidade_min_pct}</td>
            </tr>
            <tr>
              <td><b>Umidade Máxima (%)</b></td>
              <td>{perfil.umidade_max_pct}</td>
            </tr>
            <tr>
              <td><b>Luz Mínima (%)</b></td>
              <td>{perfil.luz_min}</td>
            </tr>
            <tr>
              <td><b>Luz Máxima (%)</b></td>
              <td>{perfil.luz_max}</td>
            </tr>
            <tr>
              <td><b>Tempo Bomba (s)</b></td>
              <td>{perfil.tempo_bomba_ms / 1000}</td>
            </tr>
            {perfil.observacoes && (
              <tr>
                <td><b>Observações</b></td>
                <td>{perfil.observacoes}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
