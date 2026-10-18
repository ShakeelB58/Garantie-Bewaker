# API-overzicht

Basis-URL: `/api/v1`

## Geïmplementeerd

### `GET /api/v1/health`

Voorbeeldantwoord (200):

```json
{
  "status": "UP",
  "database": "UP",
  "version": "0.1.0-SNAPSHOT",
  "checkedAt": "2026-10-18T21:00:00Z"
}
```

Als de database niet bereikbaar is: HTTP 503 met `"status": "DOWN"`.
Het antwoord bevat nooit hostnamen, gebruikersnamen of foutdetails.

## Gepland: NIET geïmplementeerd

> Deze endpoints bestaan nog niet en zijn op dit moment geblokkeerd (401).
> Ze worden pas gebouwd nadat accounts, autorisatie en gegevensisolatie zijn ontworpen
> en getest (zie fase 7 in de masterprompt).

| Methode | Pad                                   | Doel |
|---------|---------------------------------------|------|
| POST    | `/api/v1/auth/register`               | Account aanmaken |
| POST    | `/api/v1/auth/login`                  | Inloggen, token ontvangen |
| GET     | `/api/v1/users/me`                    | Eigen accountgegevens |
| DELETE  | `/api/v1/users/me`                    | Account en alle servergegevens verwijderen |
| GET     | `/api/v1/products`                    | Eigen producten (back-up/sync) |
| PUT     | `/api/v1/products/{id}`               | Product opslaan of bijwerken |
| DELETE  | `/api/v1/products/{id}`               | Product verwijderen |
| POST    | `/api/v1/products/{id}/documents`     | Versleuteld document uploaden |
| GET     | `/api/v1/documents/{id}`              | Document downloaden |
| DELETE  | `/api/v1/documents/{id}`              | Document verwijderen |
