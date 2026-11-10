/**
 * Static colour orbs painted behind the liquid-glass panels (see `.glass-backdrop` in app.css).
 * Decorative only: hidden from assistive tech, never receives pointer events, and turned off
 * when the user prefers reduced transparency.
 */
export function GlassBackdrop() {
    return (
        <div className="glass-backdrop" aria-hidden="true">
            <span />
            <span />
            <span />
        </div>
    );
}
