export default function CircularGauge({
  value=0, min=0, max=100, unit="", color="#10b981", label=""
}) {
  const size=120, stroke=12, r=(size-stroke)/2, c=2*Math.PI*r;
  const clamp=(v)=>Math.max(min,Math.min(max,v));
  const pct=((clamp(value)-min)/(max-min))*100, dash=(pct/100)*c;

  return (
    <div className="gauge-wrap">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size/2} cy={size/2} r={r} stroke="rgba(255,255,255,.08)" strokeWidth={stroke} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={color} strokeWidth={stroke} fill="none"
                strokeLinecap="round" strokeDasharray={`${dash} ${c-dash}`}
                transform={`rotate(-90 ${size/2} ${size/2})`} />
        <text x="50%" y="50%" dominantBaseline="middle" textAnchor="middle" fill="#e6edf5"
              style={{fontWeight:800,fontSize:22}}>
          {Math.round(value)}{unit && <tspan fontSize="12" dx="2">{unit}</tspan>}
        </text>
      </svg>
      <div className="gauge-label">{label}</div>
    </div>
  );
}
