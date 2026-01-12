# Zero Trust Network Access mit Docker

Willkommen zum Praxis-Workshop! In diesem Lab implementieren wir eine moderne Sicherheitsarchitektur. Anstatt klassische VPNs und Port-Forwarding zu nutzen, werden wir eine interne Anwendung über einen Cloudflare Tunnel veröffentlichen und mittels Zero Trust Policies absichern.

## Lernziele

- Unterschied zwischen Perimeter-Sicherheit und Zero Trust verstehen
- Docker-basierten "Hidden Service" bereitstellen (ohne offene Ports)
- Cloudflare Tunnel zur sicheren Veröffentlichung einrichten
- Zugriffsregeln basierend auf Identität und Geografie konfigurieren
- Sicherheits-Header (JWT) im Browser analysieren

## Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installiert und laufend
- Aktives [Cloudflare Konto](https://dash.cloudflare.com/sign-up) (Free Tier reicht aus)
- Eine Domain, die über Cloudflare verwaltet wird (aktive DNS-Zone)

## Architektur

```
┌─────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   Browser   │─────▶│  Cloudflare Edge │─────▶│  Docker Host    │
│  (Student)  │ TLS  │  (Access Policy) │Tunnel│  ┌───────────┐  │
└─────────────┘      └──────────────────┘      │  │cloudflared│  │
                            │                  │  └─────┬─────┘  │
                     ✓ Identity Check          │        │        │
                     ✓ Geo Check               │  ┌─────▼─────┐  │
                     ✓ JWT Injection           │  │internal-app│  │
                                               │  └───────────┘  │
                                               └─────────────────┘
```

**Wichtig:** Es werden keine Ports geöffnet! Der Traffic fliesst ausschliesslich über den ausgehenden Tunnel.

---

## Schritt 1: Cloudflare Tunnel vorbereiten

Wir nutzen das Cloudflare "Zero Trust Dashboard" zur Konfiguration.

1. Melden Sie sich im [Zero Trust Dashboard](https://one.dash.cloudflare.com/) an
2. Navigieren Sie zu **Networks** > **Tunnels**
3. Klicken Sie auf **Create a tunnel**
4. Wählen Sie **Cloudflared** als Connector-Typ und klicken Sie **Next**
5. Geben Sie dem Tunnel einen Namen (z.B. `lab-tunnel-01`) und klicken Sie **Save tunnel**
6. Im Fenster "Install and run a connector":
   - Wählen Sie oben **Docker** als Betriebssystem
   - Suchen Sie im angezeigten Befehl nach dem Token (beginnt mit `eyJhIjoi...`)
   - **Kopieren Sie nur den Token-String** in die Zwischenablage

---

## Schritt 2: Docker Umgebung starten

### 2.1 System prüfen (optional)

```bash
# Linux/Mac
./scripts/check.sh

# Windows PowerShell
.\scripts\check.ps1
```

### 2.2 Token konfigurieren

Erstellen Sie eine `.env` Datei im Projektordner:

```bash
# Kopieren Sie das Template
cp .env.example .env

# Öffnen Sie die Datei und fügen Sie Ihr Token ein
# Die Datei sollte so aussehen:
# TUNNEL_TOKEN=eyJhIjoiYWJj...
```

### 2.3 Container starten

```bash
docker compose up -d
```

### 2.4 Status prüfen

```bash
# Container-Status
docker compose ps

# Tunnel-Logs (Ctrl+C zum Beenden)
docker compose logs -f tunnel
```

Sie sollten Meldungen sehen wie:
```
Connection... registered connIndex=0 location=ZRH
```

Das bedeutet: Der Tunnel ist aktiv und mit der Cloudflare Edge verbunden!

---

## Schritt 3: Routing und Zugriffsschutz

Der Tunnel steht, aber Cloudflare weiss noch nicht wohin der Traffic soll. Wir konfigurieren jetzt **gleichzeitig** das Routing und den Zugriffsschutz.

### 3.1 Public Hostname erstellen

1. Gehen Sie zurück zum Cloudflare Dashboard (wo Sie das Token kopiert haben)
2. Klicken Sie auf **Next** (unten)
3. Im Tab **Public Hostnames** klicken Sie **Add a public hostname**
4. Füllen Sie das Formular aus:

| Feld | Wert |
|------|------|
| Subdomain | `secure` (oder ein Name Ihrer Wahl) |
| Domain | Ihre Domain aus der Liste |
| Service Type | `HTTP` |
| URL | `internal-app:80` |

5. Klicken Sie **Save hostname**

### 3.2 Access Policy erstellen

**Wichtig:** Erstellen Sie die Policy SOFORT, bevor Sie die URL testen!

1. Navigieren Sie zu **Access** > **Applications**
2. Klicken Sie **Add an application**
3. Wählen Sie **Self-hosted**
4. Konfiguration:

| Feld | Wert |
|------|------|
| Application name | `Lab Internal App` |
| Session Duration | `24 hours` |
| Application domain | `secure.ihre-domain.com` (exakt wie oben) |

5. Klicken Sie **Next**
6. Policy erstellen:

| Feld | Wert |
|------|------|
| Policy Name | `Allow Team` |
| Action | `Allow` |

7. Unter **Configure rules**:
   - **Selector:** `Emails`
   - **Value:** Ihre E-Mail-Adresse

8. Optional - Geo-Blocking hinzufügen:
   - Klicken Sie **+ Add require**
   - **Selector:** `Country`
   - **Value:** `Germany` (oder Ihr aktuelles Land)

9. Klicken Sie **Next** und dann **Add application**

---

## Schritt 4: Verifizierung

1. Öffnen Sie ein **Inkognito/Privates Fenster** im Browser
2. Rufen Sie `https://secure.ihre-domain.com` auf
3. Sie sollten den **Cloudflare Access Login** sehen
4. Geben Sie Ihre E-Mail-Adresse ein
5. Prüfen Sie Ihren Posteingang auf den **6-stelligen Code** (OTP)
6. Geben Sie den Code ein

### Erfolgs-Check

Nach dem Login sehen Sie die Ausgabe der `whoami`-App. Suchen Sie nach:

```
Cf-Access-Jwt-Assertion: eyJhbGciOiJSUzI1...
```

**Das ist der Beweis!** Cloudflare hat Ihre Identität geprüft und diesen kryptografischen Token an die App weitergeleitet. Die App weiss nun wer Sie sind - ohne eigene Login-Datenbank.

---

## Aufräumen

### Lokale Umgebung stoppen

```bash
docker compose down
```

### Cloudflare Dashboard aufräumen

1. **Access** > **Applications** > Ihre App löschen
2. **Networks** > **Tunnels** > Ihren Tunnel löschen

---

## Troubleshooting

Bei Problemen siehe [FEHLERSUCHE.md](FEHLERSUCHE.md).

**Häufige Probleme:**
- 502 Bad Gateway → URL im Dashboard prüfen (`internal-app:80` nicht `localhost`)
- Container startet nicht → Token in `.env` prüfen
- Keine OTP E-Mail → Spam-Ordner prüfen

---

## Weiterführende Informationen

- [Cloudflare Zero Trust Dokumentation](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [traefik/whoami auf Docker Hub](https://hub.docker.com/r/traefik/whoami)
