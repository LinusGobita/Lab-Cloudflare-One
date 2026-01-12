# Lehrerhandbuch: Cloudflare Zero Trust Lab

## Modul-Übersicht

| | |
|---|---|
| **Thema** | Secure Access Service Edge (SASE) mit Docker und Cloudflare |
| **Zielgruppe** | Systemadministratoren, DevOps Engineers, IT-Techniker |
| **Dauer** | 60-90 Minuten (inkl. Theorie und Troubleshooting) |
| **Voraussetzungen** | Grundkenntnisse Docker, Netzwerk-Basics |

---

## Zeitplan

| Abschnitt | Zeit | Beschreibung |
|-----------|------|--------------|
| Theorie | 15 min | Zero Trust vs. VPN Paradigmenwechsel |
| Schritt 1-2 | 20 min | Tunnel + Docker Setup |
| Schritt 3 | 15 min | Routing + Policy Konfiguration |
| Schritt 4 | 20 min | Test, Verifizierung, Diskussion |
| Puffer | 20 min | Troubleshooting, Fragen |
| **Total** | **90 min** | |

---

## Didaktischer Hintergrund

Dieses Lab demonstriert den Paradigmenwechsel von **Netzwerksicherheit** (Firewalls, VPNs) zu **Applikationssicherheit** (Zero Trust).

### Schlüsselkonzepte für den Unterricht

#### 1. Inversion der Konnektivität
- Wir öffnen **keine Ports** am Router (kein Port Forwarding)
- Traffic fliesst durch einen **ausgehenden** Tunnel
- Der Server ist für Internet-Scanner (Shodan, Censys) unsichtbar

#### 2. Identität als neuer Perimeter
- Klassisch: "IP 192.168.x.x darf zugreifen"
- Zero Trust: "User X mit verifiziertem Gerät aus Land Y darf zugreifen"
- Die Firewall-Regel basiert auf **Identität**, nicht auf Netzwerk-Segmenten

#### 3. Micro-Segmentation
- Docker-Netzwerk `zero-trust-net` isoliert die Anwendung
- Selbst bei kompromittiertem Host ist die App im Container geschützt
- Zugriff nur auf **eine Anwendung**, nicht das ganze Netzwerk

---

## Vorbereitung vor dem Unterricht

### Checkliste

- [ ] Internet im Schulungsraum testen (WLAN/LAN)
- [ ] Cloudflare-Login testen
- [ ] Eigenen Demo-Tunnel vorbereiten (Fallback)
- [ ] Docker auf Schulungsrechnern verifizieren
- [ ] Dieses Repository auf einem Share bereitstellen

### Fallback-Plan

Falls Probleme auftreten:
1. **Demo-Modus:** Zeigen Sie Ihr vorbereitetes Setup via Screenshare
2. **Pair Programming:** Studenten arbeiten zu zweit
3. **Video-Alternative:** Aufgezeichnete Demo bereithalten

### Domain-Optionen für Studenten

Falls Studenten keine eigene Domain haben:
- Günstige `.de` Domain (ca. 5€/Jahr)
- Lehrer stellt Subdomains bereit (`student01.lab.example.com`)
- Cloudflare bietet auch `*.cfargotunnel.com` URLs (ohne Custom Domain)

---

## Häufige Fehler (Kurzversion)

| Problem | Schnelle Lösung |
|---------|-----------------|
| 502 Bad Gateway | URL prüfen: `http://internal-app:80` (nicht `localhost`) |
| Token ungültig | Token neu kopieren, Leerzeichen entfernen |
| Container restart | `docker compose logs tunnel` prüfen |
| Keine OTP Mail | Spam-Ordner, E-Mail in Policy korrekt? |
| Access Denied | Geo-Location auf [who.is](https://who.is) prüfen |

Ausführliche Lösungen: [FEHLERSUCHE.md](FEHLERSUCHE.md)

---

## Diskussionspunkte für Fortgeschrittene

Nutzen Sie Wartezeiten (z.B. während Container laden) für diese Themen:

### 1. Datenschutz (DSGVO)

**Frage:** "Cloudflare bricht die SSL-Verschlüsselung auf (TLS Termination). Ist das ein Problem?"

**Antwort:** Ja, technisch ist es ein "Man-in-the-Middle". Cloudflare muss den Traffic entschlüsseln, um das JWT zu prüfen. Für 99% der Firmen vertraut man dem Vendor (SOC2 Compliance). Für hochsensible Daten gibt es:
- Keyless SSL
- Data Localization Suite (Daten nur in EU-Rechenzentren)
- On-Premise Alternativen (z.B. Pomerium, Authentik)

### 2. Clientless vs. Client-based (WARP)

**Dieses Lab:** "Clientless" Ansatz (nur Browser)

**Für SSH, RDP, SMB:** WARP Client auf dem Laptop erforderlich, da diese Protokolle nicht nativ im Browser laufen.

### 3. Shadow IT Risiken

**Frage:** "Wie verhindert man, dass Mitarbeiter eigene Tunnel auf Firmenrechnern installieren?"

**Lösungen:**
- Deep Packet Inspection (DPI) blockiert `argotunnel.com`
- Software-Whitelisting (nur genehmigte Apps)
- Endpoint Detection and Response (EDR)

### 4. VPN vs. ZTNA Vergleich

| Feature | VPN | Zero Trust |
|---------|-----|------------|
| Trust Model | Perimeter (einmal drin = vertraut) | Identity (jede Anfrage prüfen) |
| Netzwerk | Ports offen (UDP 1194) | Keine offenen Ports |
| Granularität | Netzwerk-Level | Anwendungs-Level |
| Performance | Hairpinning über HQ | Edge-Routing |
| DDoS Schutz | Gateway-IP exponiert | Origin-IP versteckt |

---

## Token-Rotation

### Was tun wenn ein Token geleakt wurde?

1. **Sofort:** Im Dashboard unter **Networks** > **Tunnels** > **Configure**
2. Token regenerieren (neues Token erstellen)
3. Altes Token wird automatisch ungültig
4. Neues Token in `.env` eintragen
5. Container neu starten: `docker compose restart tunnel`

### Best Practices (Produktion)

- Tokens niemals in Git committen
- Secret Manager verwenden (HashiCorp Vault, AWS Secrets Manager)
- Rotation alle 90 Tage

---

## Erweiterungsmöglichkeiten

Für schnelle Studenten oder Folgeworkshops:

1. **Zweite App hinzufügen:** nginx mit Custom HTML
2. **Service Token:** Machine-to-Machine Auth ohne User Login
3. **WARP Client:** SSH-Zugang über Tunnel
4. **Terraform:** Infrastructure as Code für Tunnel + Policies
5. **Audit Logs:** Access-Logs im Dashboard analysieren

---

## Checkliste Abschluss

### Studenten

- [ ] `docker compose down` ausgeführt
- [ ] Application im Dashboard gelöscht
- [ ] Tunnel im Dashboard gelöscht

### Lehrer

- [ ] Alle Studenten haben aufgeräumt
- [ ] Feedback eingeholt
- [ ] Material für nächsten Durchlauf aktualisiert

---

## Ressourcen

- [Cloudflare Zero Trust Docs](https://developers.cloudflare.com/cloudflare-one/)
- [Zero Trust Architecture (NIST)](https://www.nist.gov/publications/zero-trust-architecture)
- [Docker Compose Referenz](https://docs.docker.com/compose/)
