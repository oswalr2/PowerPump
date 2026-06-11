# SpartanBody — Guía de lanzamiento al App Store

Tu lista de tareas, en orden. Lo que ya está hecho en código no aparece aquí.

---

## Fase 1 — Cuentas (1 día, mayormente esperas)

- [ ] **Apple Developer Program**: inscríbete en https://developer.apple.com/programs/
      ($99 USD/año). La aprobación puede tardar 24-48 h.
- [ ] **Cloudflare**: crea una cuenta gratis en https://dash.cloudflare.com

## Fase 2 — Desplegar el proxy del escáner (~15 min)

Sigue `CloudflareWorker/README.md` paso a paso:

- [ ] `npm install -g wrangler` y `wrangler login`
- [ ] `cd CloudflareWorker && wrangler kv namespace create SCANS`
      → pega el `id` que imprime en `wrangler.toml`
- [ ] `wrangler secret put ANTHROPIC_API_KEY` → pega tu key de Anthropic
      (créala en https://console.anthropic.com → API Keys)
- [ ] `wrangler deploy` → copia la URL que imprime
- [ ] Abre `SpartanBody/Core/Config.swift` y pega la URL en `scanProxyURL`
      (debe terminar en `/scan`)
- [ ] Prueba el escáner en el simulador con una foto de comida

## Fase 3 — Publicar la política de privacidad (~10 min)

- [ ] Publica `docs/privacy-policy.md` en una URL pública. Opción fácil:
      sube el repo a GitHub → Settings → Pages → activa Pages sobre la
      carpeta `/docs`. La URL quedará como
      `https://TU-USUARIO.github.io/SpartanBody/privacy-policy`
- [ ] Guarda esa URL — la necesitas en la Fase 5

## Fase 4 — Probar en tu iPhone real (1-2 semanas de uso)

- [ ] Abre el proyecto en Xcode → selecciona tu equipo en
      Signing & Capabilities (los 3 targets)
- [ ] Instala en tu iPhone (y Apple Watch si tienes) y úsala a diario:
      - Permisos de HealthKit y cámara la primera vez
      - Un entrenamiento completo (con la app cerrándose a mitad — debe restaurarse)
      - Registrar comidas y agua, escanear una foto
      - Cambiar el idioma del iPhone a español y navegar toda la app
      - Sincronización con el Watch
- [ ] Apunta cualquier error y me lo pasas para arreglarlo

## Fase 5 — App Store Connect (~1 hora)

- [ ] https://appstoreconnect.apple.com → My Apps → "+" → New App
      - Bundle ID: el del proyecto · SKU: `spartanbody`
- [ ] Copia el **Apple ID numérico** de la app (General Information)
      → pégalo en `Config.swift` → `appStoreID`
- [ ] Pega los textos de `docs/app-store-listing.md` en cada idioma
      (nombre, subtítulo, descripción, palabras clave, texto promocional)
- [ ] Pega la URL de tu política de privacidad
- [ ] **Cuestionario App Privacy** — respuestas para esta app:
      - Health & Fitness data: **Collected — Linked to user: NO — Tracking: NO**
        (App Functionality only)
      - Photos: **Not collected** (las fotos se procesan, no se almacenan;
        si el revisor pregunta, explica que no se retienen)
      - Identifiers: **Not collected** (el ID anónimo no identifica al usuario)
      - Todo lo demás: **Not collected**
- [ ] Categoría: Health & Fitness · Clasificación de edad: 4+

## Fase 6 — Screenshots (~1 hora)

- [ ] En el simulador (iPhone 16 Pro Max y iPhone SE) toma capturas de:
      Dashboard, entrenamiento activo, nutrición, escáner, progreso, Watch
      (Cmd+S guarda la captura). Apple pide 6.9" y 6.5"; con el Pro Max basta
      si activas "usar el mismo arte".
- [ ] Súbelas en App Store Connect por idioma (puedes usar las mismas)

## Fase 7 — TestFlight y envío

- [ ] En Xcode: Product → Archive → Distribute App → App Store Connect
- [ ] En App Store Connect → TestFlight: invita a 2-3 amigos, 1 semana de prueba
- [ ] Corrige lo que salga (me pasas los errores)
- [ ] App Store → "Submit for Review". La revisión típica tarda 1-2 días.

---

### Si Apple rechaza la app

No te asustes — es normal en el primer envío. Lee el motivo, y si es de
código me lo pasas; si es de metadata (textos, screenshots) se corrige en
App Store Connect sin subir build nuevo.
