package nl.garantiebewaker;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Start de volledige applicatie tegen een echte PostgreSQL-container.
 *
 * <p>Vereist een draaiende Docker. Zonder Docker wordt deze test <b>overgeslagen</b> (niet als
 * geslaagd gerapporteerd): Maven toont hem dan als "Skipped".
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class PostgresIntegrationTest {

    @Container @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:17-alpine");

    @Autowired private MockMvc mockMvc;

    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void flywayMigratiesZijnToegepast() {
        Integer succesvol =
                jdbcTemplate.queryForObject(
                        "SELECT count(*) FROM flyway_schema_history WHERE version = '1' AND success = true",
                        Integer.class);
        assertThat(succesvol).isEqualTo(1);

        String baseline =
                jdbcTemplate.queryForObject(
                        "SELECT meta_value FROM app_metadata WHERE meta_key = 'schema_baseline'", String.class);
        assertThat(baseline).isEqualTo("fase-1");
    }

    @Test
    void healthMeldtDatabaseUp() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.database").value("UP"));
    }

    @Test
    void actuatorHealthIsBereikbaarZonderDetails() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.components").doesNotExist());
    }

    @Test
    void openApiDocumentatieBevatHealthEndpoint() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("/api/v1/health")));
    }
}
