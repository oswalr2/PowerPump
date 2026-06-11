# SpartanBody — Proxy del escáner de comida (Cloudflare Worker)

Este Worker guarda tu API key de Anthropic en el servidor (nunca dentro de la app)
y aplica el límite gratuito: **1 escaneo por semana por usuario**.

## Cómo desplegarlo (una sola vez, ~10 minutos)

1. **Crea una cuenta gratis** en https://dash.cloudflare.com (plan Free es suficiente).

2. **Instala wrangler** (la CLI de Cloudflare) — necesitas Node.js:
   ```sh
   npm install -g wrangler
   wrangler login
   ```

3. **Crea el almacén KV** (donde se guarda el contador semanal por usuario):
   ```sh
   cd CloudflareWorker
   wrangler kv namespace create SCANS
   ```
   El comando imprime un `id`. Cópialo y pégalo en `wrangler.toml`
   reemplazando `REEMPLAZA_CON_TU_KV_ID`.

4. **Guarda tu API key de Anthropic como secreto** (no queda en ningún archivo):
   ```sh
   wrangler secret put ANTHROPIC_API_KEY
   ```
   Pega tu key (sk-ant-...) cuando te la pida.

5. **Despliega:**
   ```sh
   wrangler deploy
   ```
   Al final imprime la URL del worker, por ejemplo:
   `https://spartanbody-scan.tu-subdominio.workers.dev`

6. **Conecta la app:** abre `SpartanBody/Core/Config.swift` y pon esa URL
   (con `/scan` al final) en `scanProxyURL`:
   ```swift
   static let scanProxyURL = "https://spartanbody-scan.tu-subdominio.workers.dev/scan"
   ```

## Para cambiar el límite semanal

Edita `WEEKLY_LIMIT` en `worker.js` y vuelve a correr `wrangler deploy`.

## Costos

- Cloudflare Workers + KV: **gratis** hasta 100,000 peticiones/día.
- API de Anthropic (Claude Haiku): ~$0.004 USD por escaneo →
  con 1 escaneo/semana por usuario: ~$0.02 USD/mes por usuario activo.
