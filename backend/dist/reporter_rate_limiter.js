/**
 * Rate limiter por reporter (anonymousDayId) para evitar que una sola
 * instalación inunde la API con reportes comunitarios.
 *
 * Usa ventanas fijas de 1 minuto. Cada anonymousDayId tiene un límite
 * independiente; el límite global por IP (fastify-rate-limit) sigue activo
 * como capa adicional.
 */
export class ReporterRateLimiter {
    maxPerWindow;
    windowMs;
    buckets = new Map();
    constructor({ maxPerWindow = 5, windowMs = 60_000 } = {}) {
        this.maxPerWindow = maxPerWindow;
        this.windowMs = windowMs;
    }
    /// Devuelve true si el reporter puede hacer un reporte ahora; false si está limitado.
    allow(anonymousDayId) {
        const now = Date.now();
        const bucket = this.buckets.get(anonymousDayId);
        if (!bucket || now - bucket.windowStart >= this.windowMs) {
            this.buckets.set(anonymousDayId, { count: 1, windowStart: now });
            return true;
        }
        if (bucket.count >= this.maxPerWindow)
            return false;
        bucket.count++;
        return true;
    }
    /** Limpia buckets expirados para no crecer la memoria indefinidamente. */
    gc() {
        const now = Date.now();
        for (const [id, bucket] of this.buckets) {
            if (now - bucket.windowStart >= this.windowMs) {
                this.buckets.delete(id);
            }
        }
    }
}
