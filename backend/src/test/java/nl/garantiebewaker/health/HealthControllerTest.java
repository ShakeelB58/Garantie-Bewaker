package nl.garantiebewaker.health;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import nl.garantiebewaker.security.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/** Controller- en beveiligingstest zonder database. */
@WebMvcTest(HealthController.class)
@Import(SecurityConfig.class)
class HealthControllerTest {

    @Autowired private MockMvc mockMvc;

    @MockitoBean private HealthService healthService;

    @Test
    void healthGeeft200AlsAllesWerkt() throws Exception {
        when(healthService.check())
                .thenReturn(new HealthResponse(HealthStatus.UP, HealthStatus.UP, "0.1.0", "2026-10-18T21:00:00Z"));

        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.database").value("UP"))
                .andExpect(jsonPath("$.version").value("0.1.0"))
                .andExpect(jsonPath("$.checkedAt").value("2026-10-18T21:00:00Z"));
    }

    @Test
    void healthGeeft503AlsDatabaseNietBereikbaarIs() throws Exception {
        when(healthService.check())
                .thenReturn(new HealthResponse(HealthStatus.DOWN, HealthStatus.DOWN, "0.1.0", "2026-10-18T21:00:00Z"));

        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.status").value("DOWN"))
                .andExpect(content().string(not(containsString("jdbc"))))
                .andExpect(content().string(not(containsString("password"))));
    }

    @Test
    void healthIsAlleenLeesbaar() throws Exception {
        mockMvc.perform(post("/api/v1/health")).andExpect(status().isUnauthorized());
    }

    @Test
    void nietGeimplementeerdeEndpointsZijnAfgeschermd() throws Exception {
        mockMvc.perform(get("/api/v1/products")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/users/me")).andExpect(status().isUnauthorized());
    }
}
