package nl.garantiebewaker.health;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health", description = "Beschikbaarheid van de API")
public class HealthController {

    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @GetMapping
    @Operation(summary = "Controleer of de API en de database beschikbaar zijn")
    @ApiResponse(responseCode = "200", description = "API en database zijn beschikbaar")
    @ApiResponse(responseCode = "503", description = "De database is niet bereikbaar")
    public ResponseEntity<HealthResponse> health() {
        HealthResponse response = healthService.check();
        HttpStatus httpStatus =
                response.status() == HealthStatus.UP ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;
        return ResponseEntity.status(httpStatus).body(response);
    }
}
