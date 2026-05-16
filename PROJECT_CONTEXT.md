# Architecture

**Application iOS native** — portage de la PWA mesplantesrares.fr en Swift/SwiftUI.

- **Cible** : iOS 17+ (SwiftUI 5, SwiftData, Observation)
- **Distribution** : SideStore (re-signage automatique via VPN WireGuard)
- **Build** : GitHub Actions (runner macos-latest) → artefact IPA
- **Déploiement** : SideStore détecte l'IPA sur GitHub, le signe et l'installe
- **Debug** : libimobiledevice (idevicesyslog) via USB

# Stack technique

| Couche | Technologie | Pourquoi |
|---|---|---|
| UI | SwiftUI | Natif iOS, pas de bridge WebView |
| Navigation | NavigationStack + TabView | Équivalent hash routing PWA |
| State | @Observable (iOS 17) | MVVM sans Combine |
| Persistence | SwiftData | Équivalent IndexedDB, offline-first |
| Auth JWT | Keychain | Sécurisé, persistant après désinstallation (contrairement localStorage) |
| API calls | URLSession async/await | Équivalent fetch() |
| Cache | URLCache + SwiftData | Offline mode |
| Build | xcodebuild (GitHub Actions) | Compilation Mach-O distante |
| CI/CD | .github/workflows/build.yml | Runner macos-latest gratuit |

# Invariants

- API backend **non modifiée** — mêmes endpoints que la PWA
- Zero dépendance payante — Apple ID gratuit, GitHub Actions gratuit
- Offline-first : la file d'attente fonctionne sans connexion
- Design mobile-first, portrait uniquement
- Thème vert (#166534) identique à la PWA
- Navigation par onglets en bas (5 items max)
- Compatible iPhone (pas d'iPad design prioritaire)

# Modules (App iOS)

| Module | Fichier | Rôle |
|---|---|---|
| App Entry | `MesPlantesRaresApp.swift` | @main, TabView, NavigationStack |
| Models | `Models/Plant.swift` | SwiftData models (Plant, CareLog, User) |
| Models | `Models/CareAction.swift` | Enum des types de soins |
| API Service | `Services/APIClient.swift` | URLSession wrapper, JWT, endpoints |
| Auth Service | `Services/AuthService.swift` | Login/register/logout, Keychain |
| Offline Queue | `Services/OfflineQueue.swift` | File d'attente SwiftData |
| Home View | `Views/HomeView.swift` | Hero, stats, plantes publiques |
| Gallery View | `Views/GalleryView.swift` | Galerie par genre |
| Collection View | `Views/CollectionView.swift` | Liste plantes, recherche, filtres |
| Plant Detail | `Views/PlantDetailView.swift` | Fiche détaillée, historique soins |
| Care View | `Views/CareView.swift` | QR/NFC landing, boutons soins |
| Login View | `Views/LoginView.swift` | Connexion/inscription |
| Profile View | `Views/ProfileView.swift` | Profil utilisateur, déconnexion |
| Calendar View | `Views/CalendarView.swift` | Calendrier soins |
| Plant Card | `Components/PlantCardView.swift` | Carte plante réutilisable |
| Care Button | `Components/CareButtonView.swift` | Bouton action soin |
| Offline Banner | `Components/OfflineBanner.swift` | Bannière hors-ligne |

# API endpoints (identiques à la PWA)

```
GET  /api/public/stats
GET  /api/public/genera
GET  /api/public/plants/genus/:id
GET  /api/plants              (→ /users/:userId/plants)
GET  /api/plants/:id          (→ /users/:userId/plants/:id)
GET  /api/plants-status/:userId
POST /api/care-logs           (→ /users/:userId/plants/:plantId/carelog)
GET  /api/care-logs/:userId
POST /api/notes
GET  /api/qr-codes/token/:token
POST /api/auth/login
POST /api/auth/register
GET  /api/user/profile
PUT  /api/user/profile
```

# Flux de données

```
[App iOS SwiftUI] → URLSession → [API Fastify] → [MySQL]
       ↕
[SwiftData] (cache offline + file d'attente)
[Keychain] (JWT token)
[URLCache] (cache images HTTP)
```

# Décisions techniques

- **SwiftUI iOS 17+** : @Observable macro, NavigationStack, pas de UIKit
- **SwiftData** : persistance offline, pas besoin de CoreData manuel
- **Keychain** : JWT stocké de manière sécurisée (vs localStorage pour PWA)
- **Pas de Xcode local** : compilation via GitHub Actions uniquement
- **API_BASE** : https://mesplantesrares.fr/api configurable
- **Navigation** : TabView principal + NavigationStack par onglet

# Dépendances

- Aucune dépendance externe (pas de CocoaPods, SPM uniquement Apple frameworks)
- Swift standard library seulement

# Bugs connus

- Aucun (projet à construire)

# TODO

- [ ] Créer PROJECT_CONTEXT.md
- [ ] Initialiser dépôt Git
- [ ] Créer structure projet Swift
- [ ] Créer Models (Plant, CareLog, User, CareAction)
- [ ] Créer APIClient + AuthService
- [ ] Créer OfflineQueue
- [ ] Créer vues principales (Home, Gallery, Collection, PlantDetail, Care, Login, Profile)
- [ ] Créer composants réutilisables (PlantCard, CareButton, OfflineBanner)
- [ ] Créer workflow GitHub Actions
- [ ] Configurer SideStore + WireGuard
- [ ] Tester sur iPhone

# Historique synthétique

- 2026-05-16 : Analyse de la PWA existante — 20 pages, API Fastify, vanilla JS, IndexedDB
- 2026-05-16 : Décision de portage natif SwiftUI (pas WebView, pas React Native)
- 2026-05-16 : Création du squelette projet iOS + CI/CD
