package nl.garantiebewaker.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;

/**
 * Beveiliging voor fase 1.
 *
 * <p>Er zijn nog geen accounts. Daarom is alles standaard <b>geweigerd</b>, behalve de healthcheck en
 * de API-documentatie. Nieuwe endpoints zijn dus pas bereikbaar nadat er bewust authenticatie en
 * autorisatie voor is ontworpen (zie docs/architectuur.md).
 */
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Stateless JSON-API zonder cookies of formulieren: CSRF-bescherming is niet van toepassing.
                .csrf(csrf -> csrf.disable())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .httpBasic(basic -> basic.disable())
                .formLogin(form -> form.disable())
                .logout(logout -> logout.disable())
                .exceptionHandling(e -> e.authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/api/v1/health", "/actuator/health").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui.html", "/swagger-ui/**").permitAll()
                        .requestMatchers("/error").permitAll()
                        .anyRequest().denyAll());
        return http.build();
    }

    /**
     * Er zijn nog geen gebruikers. Deze bean voorkomt dat Spring Boot een standaardgebruiker met een
     * gegenereerd wachtwoord aanmaakt en dat wachtwoord in de log zet.
     */
    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            throw new UsernameNotFoundException("Accounts zijn nog niet geïmplementeerd");
        };
    }
}
