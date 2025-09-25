export default function StatCard({ icon, color="green", value, label }) {
  return (
    <div className="stat">
      <div className={`icon ${color}`}>{icon}</div>
      <div>
        <div className="value">{value}</div>
        <div className="label">{label}</div>
      </div>
    </div>
  );
}
