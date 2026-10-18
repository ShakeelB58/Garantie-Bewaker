package nl.garantiebewaker.health;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * Antwoord van {@code GET /api/v1/health}.
 *
 * <p>Bevat bewust geen configuratie, hostnamen, gebruikersnamen of foutdetails.
 */
@Schema(description = "Gezondheidsstatus van de GarantieBewaker-API")
public record HealthResponse(
        @Schema(description = "Totale status", example = "UP") HealthStatus status,
        @Schema(description = "Status van de databaseverbinding", example = "UP") HealthStatus database,
        @Schema(description = "Versie van de backend", example = "0.1.0-SNAPSHOT") String version,
        @Schema(description = "Moment van controle in UTC (ISO 8601)", example = "2026-10-18T21:00:00Z")
                String checkedAt) {}
