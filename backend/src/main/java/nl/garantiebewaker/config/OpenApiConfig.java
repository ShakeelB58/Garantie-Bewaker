package nl.garantiebewaker.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info =
                @Info(
                        title = "GarantieBewaker API",
                        version = "v1",
                        description =
                                "Fase 1: alleen de healthcheck is geïmplementeerd. "
                                        + "Endpoints voor producten, documenten en accounts bestaan nog niet."))
public class OpenApiConfig {}
