# Google Play: aanvraag productietoegang (concept)

*Opgesteld 8-11-2026. Invullen ná minstens 14 dagen gesloten test met 12 of meer aangemelde
testers (Play Console → Dashboard → "Productietoegang aanvragen").*

De antwoorden staan in het Engels; Google beoordeelt aanvragen wereldwijd. Nederlands mag ook.
**Alles tussen [vierkante haken] vul je zelf in met wat er echt gebeurd is.** Verzin geen
feedback: Google kan doorvragen, en een eerlijk kort antwoord is beter dan een mooi verzonnen
antwoord.

---

## Deel 1: over je gesloten test

**How easy was it to recruit testers for your app?**
Kies eerlijk. Het kostte enkele dagen en herinneringen om er 12 te krijgen, dus waarschijnlijk:
*Neither easy nor difficult* of *Difficult*.

**Describe the engagement you received from testers during your closed test.**

> [AANTAL] testers (friends, family and acquaintances, invited via WhatsApp and a Google Group)
> installed Bonvrij on their own Android phones and kept it for the whole test period. They
> added their own purchases, scanned paper receipts with the camera, imported PDF invoices
> from their email and set warranty reminders. During the test they received four updates
> (versions 1.1.0 to 1.3.0) through the Play Store. [EVENTUEEL: X testers scanned receipts
> from stores such as …]

**Provide a summary of the feedback that you received from testers. Include how you
collected the feedback.**

> We collected feedback through WhatsApp messages and short conversations, asking three
> questions: what was easy, what was difficult, and what was missing.
> Main points:
> - [FEEDBACK 1, bijv. "het formulier vond ik druk"]
> - [FEEDBACK 2]
> - [FEEDBACK 3]

---

## Deel 2: over je app

**Who is the intended audience of your app?**

> Consumers who want to keep receipts, invoices and warranty dates of their purchases in one
> place, for warranty claims, returns and insurance. Mainly in the Netherlands and Belgium,
> and English-speaking users.

**Describe how your app provides value to users.**

> Bonvrij keeps proofs of purchase safe on the user's own phone. Users scan a receipt or
> import a PDF invoice; the app reads the store, date and price on the device (no server, no
> account) and the user checks everything before saving. Users enter their own warranty end
> date and get a reminder on the date they choose, so they don't miss a warranty or return
> period. They can store model and serial numbers (useful for warranty claims and insurance),
> export all data as a ZIP and restore it on a new phone. No ads and no tracking.

**How many installs do you expect your app to have in your first year?**
Kies eerlijk; voor een nieuwe app zonder reclamebudget waarschijnlijk: *0–10K*.

---

## Deel 3: klaar voor productie

**What changes did you make to your app based on what you learned during your closed
test?**

> During the test we released four updates:
> - 1.1.0: English language support and recognition of English receipts and invoices
>   (pounds and dollars).
> - 1.2.0: a model number field; model and serial number fields are hidden for categories
>   where they are not useful (clothing, furniture).
> - 1.3.0: restoring a backup on a new phone, a monthly backup reminder, a calmer product
>   form (fewer labels, examples inside the fields) and quick picks for the warranty period
>   (1, 2, 3 or 5 years).
> [EVENTUEEL: koppel een wijziging aan feedback van een tester, bijv. "Testers found the form
> busy, so we simplified it in 1.3.0."]

**How did you decide that your app is ready for production?**

> All core features worked for our testers on different Android phones without crashes
> reported in the Play Console. The app has automated tests that run on every change
> (analysis, unit and widget tests), and the same app has been available on the Apple App
> Store since November 2026. The privacy policy (bonvrij.nl/privacy) and data safety section
> are complete and match how the app works.

---

## Vóór het indienen controleren

- [ ] Minstens 14 dagen aaneengesloten 12 of meer aangemelde testers (Dashboard).
- [ ] Play Console → **Kwaliteit → Android Vitals**: geen of weinig crashes. Zo niet: eerst laten
      oplossen en "no crashes" weglaten.
- [ ] Feedback van testers ingevuld (geen [haken] meer).
- [ ] Release-opmerkingen klaar voor de productierelease.
- [ ] Landen kiezen voor productie (Productie → Landen/regio's).
