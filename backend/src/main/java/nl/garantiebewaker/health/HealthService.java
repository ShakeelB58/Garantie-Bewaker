package nl.garantiebewaker.health;

import java.sql.Connection;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import javax.sql.DataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/** Controleert of de API en de database bereikbaar zijn. */
@Service
public class HealthService {

    private static final Logger log = LoggerFactory.getLogger(HealthService.class);
    private static final int DB_VALIDATION_TIMEOUT_SECONDS = 2;

    private final DataSource dataSource;
    private final Clock clock;
    private final String version;

    public HealthService(
            DataSource dataSource, Clock clock, @Value("${app.version:onbekend}") String version) {
        this.dataSource = dataSource;
        this.clock = clock;
        this.version = version;
    }

    public HealthResponse check() {
        HealthStatus database = checkDatabase();
        Instant now = Instant.now(clock).truncatedTo(ChronoUnit.SECONDS);
        return new HealthResponse(database, database, version, now.toString());
    }

    private HealthStatus checkDatabase() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(DB_VALIDATION_TIMEOUT_SECONDS) ? HealthStatus.UP : HealthStatus.DOWN;
        } catch (Exception e) {
            // Alleen het type fout loggen: de melding kan hostnamen of gebruikersnamen bevatten.
            log.warn("Databasecontrole mislukt ({})", e.getClass().getSimpleName());
            return HealthStatus.DOWN;
        }
    }
}
