package nl.garantiebewaker.health;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class HealthServiceTest {

    private static final Clock FIXED_CLOCK =
            Clock.fixed(Instant.parse("2026-10-18T21:00:00.123Z"), ZoneOffset.UTC);

    private DataSource dataSource;
    private HealthService service;

    @BeforeEach
    void setUp() {
        dataSource = mock(DataSource.class);
        service = new HealthService(dataSource, FIXED_CLOCK, "1.2.3");
    }

    @Test
    void geeftUpAlsDatabaseVerbindingGeldigIs() throws SQLException {
        Connection connection = mock(Connection.class);
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.isValid(anyInt())).thenReturn(true);

        HealthResponse response = service.check();

        assertThat(response.status()).isEqualTo(HealthStatus.UP);
        assertThat(response.database()).isEqualTo(HealthStatus.UP);
        assertThat(response.version()).isEqualTo("1.2.3");
        assertThat(response.checkedAt()).isEqualTo("2026-10-18T21:00:00Z");
        verify(connection).close();
    }

    @Test
    void geeftDownAlsVerbindingOngeldigIs() throws SQLException {
        Connection connection = mock(Connection.class);
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.isValid(anyInt())).thenReturn(false);

        assertThat(service.check().status()).isEqualTo(HealthStatus.DOWN);
        verify(connection).close();
    }

    @Test
    void geeftDownAlsDatabaseNietBereikbaarIs() throws SQLException {
        when(dataSource.getConnection()).thenThrow(new SQLException("host db.intern onbereikbaar"));

        HealthResponse response = service.check();

        assertThat(response.status()).isEqualTo(HealthStatus.DOWN);
        assertThat(response.database()).isEqualTo(HealthStatus.DOWN);
    }
}
