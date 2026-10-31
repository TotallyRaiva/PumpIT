<p align="center">
  <img src="docs/assets/icon.png" width="128" height="128" alt="PumpIT App Icon" style="border-radius: 28px;" />
</p>

<h1 align="center">PumpIT — Smart Fuel Tracker Germany (iOS)</h1>

<p align="center">
  <strong><a href="https://totallyraiva.github.io/PumpIT/">🌐 Website (EN / DE)</a></strong> &bull;
  <strong><a href="https://totallyraiva.github.io/PumpIT/privacy.html">🔒 Privacy Policy / Datenschutz</a></strong> &bull;
  <strong><a href="https://totallyraiva.github.io/PumpIT/support.html">💬 Support &amp; FAQ</a></strong>
</p>

---

## 🇬🇧 English Overview

**PumpIT** is a native iOS 17+ application written in **SwiftUI** and **SwiftData** for tracking real-time fuel prices (**Super E5**, **Super E10**, and **Diesel**) across Germany using official **MTS-K / Tankerkönig** data.

### Key Features
- **Interactive Price Map & Sorted List:** Custom capsule price pins on Apple MapKit + one-tap toggle to a list view highlighting the cheapest open station (`BEST` badge).
- **24-Hour Price Trend & Smart Timing:** Local on-device `SwiftData` history tracks the 24h lowest price for each station and provides fueling window recommendations.
- **Multi-App Navigation:** Instant turn-by-turn routing handoff to **Apple Maps**, **Google Maps**, or **Waze**.
- **Germany-Wide City Search:** Search any German city or region via `MKLocalSearch` or use quick-jump chips (Nürnberg, München, Berlin, Frankfurt, Hamburg, Köln).
- **Privacy-First & Keychain Secured:** No tracking, no ads, and hardware-backed iOS Keychain storage for custom Tankerkönig API keys.

### Getting Started
1. Clone the repository and open `PumpIT.xcodeproj` in Xcode.
2. *(Optional)* Copy `PumpIT/Secrets.plist.example` to `PumpIT/Secrets.plist` and insert your free API key from [creativecommons.tankerkoenig.de](https://creativecommons.tankerkoenig.de) (or configure it at runtime in the app's Settings screen).
3. Build and run on an iOS 17.0+ Simulator or device.

---

## 🇩🇪 Deutsche Projektübersicht

**PumpIT** ist eine native iOS 17+ App auf Basis von **SwiftUI** und **SwiftData**, mit der Sie Echtzeit-Spritpreise (**Super E5**, **Super E10** und **Diesel**) in ganz Deutschland über die offizielle **MTS-K / Tankerkönig-Schnittstelle** vergleichen können.

### Funktionen
- **Interaktive Preiskarte & Listenansicht:** Übersichtliche Preis-Pins auf Apple MapKit sowie eine sortierbare Listenansicht mit `BEST`-Markierung für die günstigste geöffnete Tankstelle.
- **24h-Preistrend & Tankempfehlung:** Lokale `SwiftData`-Speicherung ermittelt den 24-Stunden-Tiefstpreis jeder Tankstelle und empfiehlt den optimalen Tankzeitpunkt.
- **Direkt-Navigation:** Starten Sie die Routenführung mit einem Fingertipp in **Apple Karten**, **Google Maps** oder **Waze**.
- **Deutschlandweite Stadtsuche:** Suchen Sie beliebige Städte oder Regionen in Deutschland über `MKLocalSearch` oder nutzen Sie die Direktwahl-Chips.
- **Datenschutz & Keychain-Sicherheit:** Keine Werbe- oder Analyse-Tracker; benutzerdefinierte API-Schlüssel werden sicher in der iOS-Keychain gespeichert.

---

## License & Data Attribution
Fuel price data is provided by **[Tankerkönig](https://creativecommons.tankerkoenig.de)** under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license, sourced from the official *Markttransparenzstelle für Kraftstoffe (MTS-K)*.
