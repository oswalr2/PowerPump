# PowerPump — Guía de lanzamiento al App Store

Tu lista de tareas, en orden. Lo que ya está hecho en código no aparece aquí.

> **v1 se lanza SIN el escáner de comida con IA** — así no dependes del
> Cloudflare Worker ni del crédito de Anthropic el día uno. El escáner y su
> proxy quedan en el código, listos para activar en una actualización futura
> (ver `CloudflareWorker/README.md`).

---

## Fase 1 — Cuenta de Apple (mayormente esperas)

- [ ] **Apple Developer Program**: inscríbete en https://developer.apple.com/programs/enroll
      ($99 USD/año). La aprobación puede tardar 24-48 h.
- [ ] Verifica el estado en https://developer.apple.com/account — cuando veas
      "App Store Connect" y "Certificates, Identifiers & Profiles", ya estás aprobado.

## Fase 2 — Publicar la política de privacidad (~10 min)

- [ ] Publica la web (`~/Desktop/PowerPump-Web/`) o `docs/privacy-policy.md`
      en una URL pública. Opción fácil: GitHub → Settings → Pages → activa
      Pages. La URL de privacidad la necesitas en la Fase 4.
- [ ] Guarda esa URL.

## Fase 3 — Probar en tu iPhone real (unos días de uso)

- [ ] Abre el proyecto en Xcode → en Signing & Capabilities selecciona tu
      equipo en los targets (el `DEVELOPMENT_TEAM` está vacío a propósito).
- [ ] Instala en tu iPhone (y Apple Watch si tienes) y úsala a diario:
      - Permisos de HealthKit, ubicación y cámara la primera vez
      - Un entrenamiento de gym completo (cerrando la app a mitad — debe restaurarse)
      - Una carrera/caminata con GPS (bloquea la pantalla — el tiempo y la ruta deben seguir)
      - Genera una **ruta con IA** y síguela en la calle (voz + trazado)
      - Un día de un programa guiado de caminar/correr
      - Registrar comidas y agua, escanear un código de barras
      - Cambiar el idioma del iPhone y navegar toda la app
      - Sincronización con el Watch
- [ ] Apunta cualquier error y me lo pasas para arreglarlo.

## Fase 4 — App Store Connect (~1 hora)

- [ ] https://appstoreconnect.apple.com → My Apps → "+" → New App
      - Bundle ID: `com.oswaldo.powerpump` · SKU: `powerpump`
- [ ] Copia el **Apple ID numérico** de la app (General Information)
      → pégalo en `SpartanBody/Core/Config.swift` → `appStoreID`
- [ ] Pega los textos de `docs/app-store-listing.md` en cada idioma
      (nombre, subtítulo, descripción, palabras clave, texto promocional)
- [ ] Pega la URL de tu política de privacidad
- [ ] **Cuestionario App Privacy** — respuestas para esta app:
      - Health & Fitness: **Collected — Linked to user: NO — Tracking: NO** (App Functionality)
      - Location: **Collected — Linked to user: NO — Tracking: NO** (App Functionality)
        — se usa para trazar rutas; no sale del dispositivo salvo el cálculo
        de indicaciones de Apple Maps
      - Identifiers, Photos, Contacts, y todo lo demás: **Not collected**
- [ ] Categoría: Health & Fitness · Clasificación de edad: 4+

## Fase 5 — Screenshots (~30 min)

- [ ] Ya tienes capturas en `~/Desktop/PowerPump-Screenshots/`. Apple pide
      tamaño 6.9" (iPhone 16/17 Pro Max) — con esas basta si activas
      "usar el mismo arte para todos los tamaños".
- [ ] Súbelas en App Store Connect por idioma (puedes reutilizar las mismas).

## Fase 6 — TestFlight y envío

- [ ] En Xcode: Product → Archive → Distribute App → App Store Connect.
      (Pasa `DEVELOPMENT_TEAM` en Signing si hace falta.)
- [ ] En App Store Connect → TestFlight: invita a 2-3 amigos, 1 semana de prueba.
- [ ] Corrige lo que salga (me pasas los errores).
- [ ] App Store → "Submit for Review". La revisión típica tarda 1-2 días.

---

## (Opcional, futuro) Activar el escáner de comida con IA

Cuando quieras añadirlo en una actualización:

1. Despliega el Worker siguiendo `CloudflareWorker/README.md`
   (`wrangler kv namespace create SCANS`, `wrangler secret put ANTHROPIC_API_KEY`,
   `wrangler deploy`).
2. Pega la URL en `SpartanBody/Core/Config.swift` → `scanProxyURL`.
3. Descomenta los dos botones del escáner (Dashboard y Nutrición) — busca el
   comentario "AI food scanner hidden for v1".
4. Añade el escáner a la política de privacidad y vuelve a enviar.

---

### Si Apple rechaza la app

No te asustes — es normal en el primer envío. Lee el motivo, y si es de
código me lo pasas; si es de metadata (textos, screenshots) se corrige en
App Store Connect sin subir build nuevo.
