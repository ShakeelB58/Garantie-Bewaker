# Architectuur GarantieBewaker

## Overzicht

```
garantiebewaker/
  mobile/     Flutter-app (iOS + Android), local-first
  backend/    Spring Boot REST API (Java 21, Maven, PostgreSQL)
  docs/       Architectuur, beslissingen, API-overzicht
  docker-compose.yml   Lokale PostgreSQL voor de backend
```

De **mobiele app werkt volledig zonder backend**. Aankopen, documenten en herinneringen staan
alleen op de telefoon (SQLite + app-private bestandsopslag). De backend is een zelfstandig,
getest onderdeel dat klaarstaat voor latere uitbreiding (accounts, back-up), maar in de MVP
**geen aankoopgegevens ontvangt**.

## Mobiele app (Flutter)

Feature-first structuur:

```
mobile/lib/
  main.dart                 Start de app binnen een Riverpod ProviderScope
  app/
    app.dart                MaterialApp.router, Nederlandse lokalisatie
    router.dart             GoRouter: tabbladen + schermen buiten de tabbladen
    shell_scaffold.dart     Onderste navigatiebalk
    theme/                  Design system (kleuren, afstanden, Material 3-thema)
  core/
    errors/                 Nederlandse foutmeldingen (userMessageFor)
    storage/                SQLite-database, migraties, klok- en id-providers
    utils/                  Datums en geldbedragen
    widgets/                Herbruikbare componenten (EmptyState, ErrorView)
    (notifications/, security/ volgen in fase 5)
  features/
    dashboard/              application/ (DashboardSummary), presentation/
    products/
      domain/               Product, ProductCategory, ProductInput + ProductValidator, ProductQuery
      data/                 ProductRepository (interface) + SqfliteProductRepository
      application/          Riverpod-providers (productsProvider, productQueryProvider)
      presentation/         Overzicht, detail, formulier, widgets
    settings/presentation/
    (documents/, receipt_scanner/, pdf_import/, reminders/ volgen in fase 3–5)
```

Laagindeling per feature:

- `presentation/`: widgets en Riverpod-providers voor schermstatus
- `domain/`: modellen en validatieregels, zonder Flutter-afhankelijkheden
- `application/`: Riverpod-providers die domein en data verbinden
- `data/`: repositories die SQLite en bestandsopslag afschermen van de UI

OCR, PDF-extractie en parsing worden losse services achter interfaces
(`ReceiptOcrService`, `PdfTextExtractionService`, `ReceiptParsingService`), zodat de parser
zonder telefoon te testen is.

## Backend (Spring Boot)

Package `nl.garantiebewaker`:

| Package    | Inhoud                                                | Status fase 1 |
|------------|-------------------------------------------------------|---------------|
| `config`   | Klok (UTC), OpenAPI-informatie                        | ✅ werkt      |
| `health`   | `GET /api/v1/health` + service met databasecontrole   | ✅ werkt      |
| `security` | Alles geweigerd behalve health en documentatie        | ✅ werkt      |
| `common`   | Gedeelde foutafhandeling, DTO-hulpmiddelen            | ⏳ later      |
| `users`    | Accounts en authenticatie                             | ⏳ alleen ontwerp |
| `products` | Server-side productgegevens (back-up/sync)            | ⏳ alleen ontwerp |
| `documents`| Veilige serveropslag van documenten                   | ⏳ alleen ontwerp |

Regels:

- REST-endpoints gebruiken DTO's; JPA-entiteiten worden nooit rechtstreeks teruggegeven.
- Het databaseschema komt uitsluitend uit Flyway (`ddl-auto: validate`).
- Tijdstippen worden in UTC opgeslagen (`TIMESTAMPTZ`, `hibernate.jdbc.time_zone=UTC`).
- Profielen: `local` (standaard, leest `../.env`) en `prod` (alles uit omgevingsvariabelen).

### Wat werkt en wat is voorbereid

| Endpoint                | Status |
|-------------------------|--------|
| `GET /api/v1/health`    | ✅ geïmplementeerd en getest. 200 als de database bereikbaar is, anders 503. |
| `GET /actuator/health`  | ✅ voor hosting/monitoring, zonder details. |
| `GET /v3/api-docs`, `/swagger-ui.html` | ✅ alleen in `local`; uit in `prod`. |
| Alle andere paden       | 🔒 geweigerd met 401. |

Zie [api-overzicht.md](api-overzicht.md) voor geplande endpoints. **Die bestaan nog niet.**

## Gegevensstromen in de MVP

```
Camera / bestanden / deelmenu ──▶ app-private opslag ──▶ OCR/PDF op het toestel
                                                         │
                                                         ▼
                                        controleformulier (gebruiker bevestigt)
                                                         │
                                                         ▼
                                       SQLite op het toestel + lokale meldingen
```

Er gaat in de MVP geen aankoopinformatie naar de backend of naar diensten van derden.
