import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Filler, Tooltip, Legend
} from "chart.js";
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Filler, Tooltip, Legend);

export default function AreaHistory({ rows }) {
  const labels = rows.map(r => r.ts.toLocaleTimeString());
  const data = {
    labels,
    datasets: [
      {
        label: "Umidade do Solo (raw)",
        data: rows.map(r => r.soil_raw),
        borderColor: "#34d399",
        backgroundColor: "rgba(52,211,153,.12)",
        tension: .35,
        fill: true,
        pointRadius: 2,
      },
    ]
  };
  const options = {
    maintainAspectRatio:false,
    plugins:{
      legend:{labels:{color:"#9fb1c7"}}
    },
    scales:{
      x:{ticks:{color:"#70839c"}, grid:{color:"rgba(255,255,255,.04)"}},
      y:{ticks:{color:"#70839c"}, grid:{color:"rgba(255,255,255,.04)"}}
    }
  };
  return (
    <div className="panel" style={{height:340}}>
      <h3>Histórico de Umidade do Solo (raw)</h3>
      <div style={{height:270}}><Line data={data} options={options}/></div>
    </div>
  );
}
