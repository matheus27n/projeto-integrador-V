export default function Toast({
  show,
  title,
  message,
  onClose,
  variant = "banner", // "banner" (topo) ou "box" (canto)
}) {
  if (!show) return null;

  return (
    <div className={`toast ${variant}`} role="alert">
      <div className="toast-inner">
        <strong className="toast-title">{title}</strong>
        <span className="toast-msg">{message}</span>
        <button className="toast-close" onClick={onClose} aria-label="Fechar">✕</button>
      </div>
    </div>
  );
}
