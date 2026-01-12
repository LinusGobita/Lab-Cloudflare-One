# Fehlersuche / Troubleshooting

Dieses Dokument hilft bei der Lösung häufiger Probleme im Zero Trust Lab.

---

## 502 Bad Gateway

### Symptom
Nach Aufruf der URL erscheint eine Cloudflare-Fehlerseite mit "502 Bad Gateway".

### Ursache
Der `cloudflared` Tunnel-Container kann den `internal-app` Container nicht erreichen.

### Lösung

1. **URL im Dashboard prüfen:**
   - Richtig: `http://internal-app:80`
   - Falsch: `http://localhost:80` oder `http://127.0.0.1:80`

2. **Netzwerk-Konfiguration prüfen:**
   ```bash
   docker compose ps
   ```
   Beide Container müssen `running` sein.

3. **Container im gleichen Netzwerk?**
   ```bash
   docker network inspect zt-lab-network
   ```
   Beide Container sollten gelistet sein.

4. **Container-Logs prüfen:**
   ```bash
   docker compose logs internal-app
   docker compose logs tunnel
   ```

---

## Token-Probleme / Container Restart Loop

### Symptom
Der Tunnel-Container startet alle paar Sekunden neu. In den Logs steht "Auth Error" oder "Token decoding failed".

### Ursache
Das Token wurde falsch kopiert (Leerzeichen, Zeilenumbrüche, unvollständig).

### Lösung

1. **Token in `.env` prüfen:**
   ```bash
   cat .env
   ```
   - Keine Leerzeichen vor/nach dem Token
   - Keine Anführungszeichen um das Token
   - Token beginnt mit `eyJ`

2. **Richtig:**
   ```
   TUNNEL_TOKEN=eyJhIjoiYWJjZGVm...
   ```

3. **Falsch:**
   ```
   TUNNEL_TOKEN="eyJhIjoiYWJjZGVm..."
   TUNNEL_TOKEN= eyJhIjoiYWJjZGVm...
   TUNNEL_TOKEN=eyJhIjoiYWJjZGVm...
   ```

4. **Neues Token generieren:**
   - Dashboard > Networks > Tunnels > Configure
   - Neues Token kopieren
   - `.env` aktualisieren
   - `docker compose restart tunnel`

---

## Keine OTP E-Mail erhalten

### Symptom
Nach Eingabe der E-Mail-Adresse kommt kein Bestätigungscode.

### Lösung

1. **Spam/Junk-Ordner prüfen**
   - Absender: `noreply@notify.cloudflare.com`

2. **E-Mail in Policy korrekt geschrieben?**
   - Dashboard > Access > Applications > Ihre App > Policies
   - Tippfehler sind häufig (z.B. `gmial.com` statt `gmail.com`)

3. **OTP aktiviert?**
   - Dashboard > Settings > Authentication
   - "One-time PIN" sollte aktiviert sein

4. **Alternative E-Mail testen**
   - Policy temporär auf andere E-Mail ändern

---

## Geo-Blocking / Access Denied

### Symptom
"Access Denied" Meldung, obwohl E-Mail korrekt eingegeben wurde.

### Ursache
Die IP-Geolocation erkennt ein anderes Land als in der Policy erlaubt.

### Lösung

1. **Eigenes Land prüfen:**
   - [who.is](https://who.is) oder [whatismyipaddress.com](https://whatismyipaddress.com)
   - Manche ISPs routen Traffic über andere Länder

2. **Policy anpassen:**
   - Dashboard > Access > Applications > Ihre App > Policies
   - Land ändern oder Geo-Regel temporär entfernen

3. **VPN ausschalten**
   - Falls ein VPN aktiv ist, wird ein anderes Land erkannt

---

## DNS-Fehler / Domain nicht erreichbar

### Symptom
Browser zeigt "DNS_PROBE_FINISHED_NXDOMAIN" oder "Server not found".

### Ursache
DNS-Änderungen brauchen Zeit zur Propagation.

### Lösung

1. **5 Minuten warten**
   - DNS-Updates brauchen manchmal Zeit

2. **Browser-Cache leeren:**
   - Chrome: `Ctrl+Shift+Delete` > "Cached images and files"
   - Oder Inkognito-Fenster verwenden

3. **DNS direkt prüfen:**
   ```bash
   nslookup secure.ihre-domain.com
   ```

4. **Cloudflare DNS Status:**
   - Dashboard > Ihre Domain > DNS
   - Prüfen ob Subdomain existiert (wird automatisch erstellt)

---

## Container startet nicht (Exit Code 1)

### Symptom
`docker compose ps` zeigt Container mit Status "Exited (1)".

### Lösung

1. **Logs prüfen:**
   ```bash
   docker compose logs tunnel
   docker compose logs internal-app
   ```

2. **Häufige Ursachen:**
   - `.env` Datei fehlt → `cp .env.example .env`
   - Token fehlt in `.env`
   - Docker Daemon läuft nicht

3. **Neustart versuchen:**
   ```bash
   docker compose down
   docker compose up -d
   ```

---

## Tunnel verbunden aber App nicht erreichbar

### Symptom
Logs zeigen "Connection registered" aber Browser zeigt Fehler.

### Lösung

1. **Public Hostname konfiguriert?**
   - Dashboard > Networks > Tunnels > Ihr Tunnel > Public Hostname
   - Muss mindestens einen Eintrag haben

2. **Service URL korrekt?**
   - Type: `HTTP`
   - URL: `internal-app:80`

3. **internal-app Container läuft?**
   ```bash
   docker compose ps internal-app
   ```

---

## Browser zeigt alte/gecachte Version

### Symptom
Änderungen im Dashboard scheinen keine Wirkung zu haben.

### Lösung

1. **Hard Refresh:**
   - Windows/Linux: `Ctrl+Shift+R`
   - Mac: `Cmd+Shift+R`

2. **Inkognito/Private Window**
   - Umgeht alle Caches

3. **Anderer Browser**
   - Zum Testen: Firefox, Safari, Edge

4. **Cookies löschen:**
   - Speziell Cloudflare-Cookies: `CF_Authorization`

---

## Allgemeine Diagnose-Befehle

```bash
# Container Status
docker compose ps

# Alle Logs
docker compose logs

# Nur Tunnel-Logs (live)
docker compose logs -f tunnel

# Netzwerk prüfen
docker network ls
docker network inspect zt-lab-network

# Container neu starten
docker compose restart

# Alles stoppen und neu starten
docker compose down && docker compose up -d

# Docker Compose Syntax prüfen
docker compose config
```

---

## Hilfe holen

Falls nichts hilft:

1. **Cloudflare Community:** [community.cloudflare.com](https://community.cloudflare.com)
2. **Docker Docs:** [docs.docker.com](https://docs.docker.com)
3. **Lehrer fragen:** Mit Screenshots und Fehlermeldungen
