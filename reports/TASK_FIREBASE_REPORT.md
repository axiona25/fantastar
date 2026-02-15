# TASK Firebase — Report integrazione Firebase

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Integrare **Firebase** nel progetto Flutter e nel backend:

- Firebase Core, Auth e Messaging nell’app Flutter.
- Inizializzazione Firebase in `main.dart`, configurazione FCM per push.
- Recupero password con **Firebase Phone Auth** (SMS reale).
- Registrazione token FCM sul backend e invio push su eventi (gol/risultati, asta, scambio).

---

## 2. Configurazione esistente

I file di credenziali erano già presenti:

- `backend/firebase-credentials.json`
- `frontend_mobile/ios/Runner/GoogleService-Info.plist`
- `frontend_mobile/android/app/google-services.json`

---

## 3. Funzionalità realizzate

### 3.1 Flutter: dipendenze e inizializzazione

- **pubspec.yaml:** Aggiunte `firebase_core`, `firebase_auth`, `firebase_messaging`.
- **firebase_options.dart:** Opzioni Android/iOS da `google-services.json` e `GoogleService-Info.plist` (progetto `fantastar-1a5bc`).
- **main.dart:** `main()` async; `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`; creazione `NotificationProvider` e `await setupFcm()` prima di `runApp`.

### 3.2 Firebase Messaging (FCM)

- **fcm_service.dart:** `setupFcm()` richiede permesso, ottiene token FCM, imposta `onMessage` e `onMessageOpenedApp` e notifica in-app tramite `NotificationProviderRef.addInApp(title, body)`.
- **notification_provider_ref.dart:** Riferimento statico a `NotificationProvider` e metodo `addInApp(title, body)` per mostrare notifiche ricevute a app aperta.
- **home_screen.dart:** In `initState` (post-frame) registra il token FCM con il backend (`authService.registerFcmToken`) e sottoscrive `onTokenRefresh` per ri-registrare.

### 3.3 Backend: registro FCM e push

- **Modello `FCMToken`:** Tabella `fcm_tokens` (user_id, token, created_at) con unique (user_id, token).
- **Migration:** `alembic/versions/g7b3c4d5e6f6_add_fcm_tokens.py` crea la tabella e indice su `user_id`.
- **POST /api/v1/auth/fcm-token:** Body `{ "fcm_token": "..." }`, utente autenticato; inserisce il token per l’utente corrente se non già presente.
- **push_service.py:**
  - `verify_firebase_id_token(id_token)`: verifica id token Firebase (es. Phone Auth) e restituisce il numero di telefono (`phone_number`); ritorna `None` se non valido.
  - `send_push_to_users(db, user_ids, title, body, data?)`: carica i token FCM degli utenti e invia tramite `firebase_admin.messaging.send_multicast`.
  - `send_push_to_tokens(tokens, title, body, data?)`: invio diretto a una lista di token.

### 3.4 Push su eventi

- **Asta (bid):** Dopo una nuova offerta, push a tutti i membri della lega (escluso l’offerente): titolo "Nuova offerta in asta", body con nome squadra offerente.
- **Asta (assign):** Dopo l’assegnazione del giocatore, push a tutti i membri della lega: "Asta conclusa" e dettaglio giocatore/squadra.
- **Scambio (proposta):** Quando viene proposta un’offerta di scambio, push al destinatario: "Nuova proposta di scambio".
- **Scambio (accettazione):** Quando una proposta viene accettata, push a chi ha proposto: "Scambio accettato".
- **Risultati live:** In `sync_matches._broadcast_live_updates`, dopo l’aggiornamento punteggi giornata, push a tutti gli utenti delle leghe coinvolte: "Risultato aggiornato" / "Controlla i punteggi della tua giornata!".

### 3.5 Recupero password con Firebase Phone Auth

- **Backend:** `forgot_password` (già esistente) restituisce anche `phone` (numero completo) quando l’utente ha un telefono associato, per consentire il flusso Phone Auth.
- **POST /api/v1/auth/verify-phone-reset:** Body `{ "id_token": "..." }`. Verifica l’id token Firebase (Phone Auth), trova l’utente per `phone_number` e restituisce un `reset_token` JWT per lo step successivo.
- **Flutter:**
  - **ForgotPasswordScreen** (`/forgot-password`): campo email → `forgotPassword(email)`; se la risposta contiene `phone`, chiama `FirebaseAuth.instance.verifyPhoneNumber(phone)` per inviare l’SMS; l’utente inserisce il codice → `signInWithCredential` → `getIdToken()` → `verifyPhoneReset(idToken)` → riceve `reset_token` → `FirebaseAuth.instance.signOut()` → navigazione a `/reset-password` con `extra: resetToken`.
  - **ResetPasswordScreen** (`/reset-password`): riceve `resetToken` da `state.extra`; campi nuova password e conferma → `resetPassword(resetToken, newPassword)` → redirect a `/login`.
- **LoginScreen:** Aggiunto link "Password dimenticata?" che porta a `/forgot-password`.
- **Routes:** Aggiunte `/forgot-password` e `/reset-password`; considerate come route “auth” (accessibili senza login) nel redirect del router.

---

## 4. File toccati / creati

### Backend

- `app/models/fcm_token.py` — Modello FCMToken.
- `app/models/__init__.py` — Export FCMToken.
- `app/schemas/user.py` — FcmTokenRequest, VerifyPhoneResetRequest; PasswordForgotResponse con `phone` opzionale.
- `app/api/v1/auth.py` — POST `/auth/fcm-token`, POST `/auth/verify-phone-reset`; forgot_password con `phone` in risposta.
- `app/services/firebase_otp_service.py` — Risposta `request_otp` con `phone` per il client.
- `app/services/push_service.py` — **Nuovo:** verify_firebase_id_token, send_push_to_users, send_push_to_tokens.
- `app/api/v1/auction.py` — Import push_service; dopo bid e dopo assign chiamata a `send_push_to_users`.
- `app/api/v1/market.py` — Import push_service; dopo trade-propose push al destinatario; dopo trade-respond (accept) push a chi ha proposto.
- `app/tasks/sync_matches.py` — Import FantasyTeam e push_service; in `_broadcast_live_updates` push "Risultato aggiornato" agli utenti delle leghe con giornate aggiornate.
- `alembic/versions/g7b3c4d5e6f6_add_fcm_tokens.py` — Migration tabella fcm_tokens.

### Flutter

- `pubspec.yaml` — firebase_core, firebase_auth, firebase_messaging.
- `lib/firebase_options.dart` — Opzioni da FlutterFire o da file esistenti.
- `lib/main.dart` — Inizializzazione Firebase, setupFcm, NotificationProvider.
- `lib/services/fcm_service.dart` — setupFcm, gestione messaggi e token.
- `lib/notification_provider_ref.dart` — Riferimento statico e addInApp.
- `lib/services/auth_service.dart` — registerFcmToken, forgotPassword, verifyOtp, verifyPhoneReset, resetPassword.
- `lib/screens/home/home_screen.dart` — Registrazione FCM token e onTokenRefresh.
- `lib/screens/auth/forgot_password_screen.dart` — **Nuovo:** flusso email → phone → Firebase SMS → verify-phone-reset → reset-password.
- `lib/screens/auth/reset_password_screen.dart` — **Nuovo:** nuova password con reset_token.
- `lib/screens/auth/login_screen.dart` — Link "Password dimenticata?".
- `lib/app/routes.dart` — Route `/forgot-password`, `/reset-password` e considerate nelle auth routes.

---

## 5. Come verificare

1. **Migration:** Eseguire `alembic upgrade head` nel backend per creare `fcm_tokens`.
2. **FCM token:** Login nell’app Flutter; in home il token viene registrato. Verificare con `POST /api/v1/auth/fcm-token` (autenticato) che il token venga salvato (o "Token già registrato").
3. **Recupero password:** Da login → "Password dimenticata?" → inserire email con telefono associato; verificare che venga mostrato il passo SMS; inserire il codice ricevuto; dopo verifica, impostare nuova password e tornare al login.
4. **Push su eventi:** Con almeno un device con token FCM registrato:
   - Asta: fare un’offerta o assegnare un giocatore e verificare la notifica sugli altri device della lega.
   - Scambio: proporre uno scambio e verificare la notifica al destinatario; accettare e verificare la notifica a chi ha proposto.
   - Risultati: eseguire sync partite live (o job che aggiorna punteggi) e verificare la notifica "Risultato aggiornato" per le leghe coinvolte.
5. **Firebase Admin:** Il backend usa `firebase-admin` (credenziali da `firebase-credentials.json` o variabile d’ambiente); `init_firebase()` è richiamato da push_service e da auth (verify_phone_reset).

---

## 6. Note

- **Phone Auth:** L’SMS reale è inviato da Firebase quando si usa `verifyPhoneNumber`; il backend non invia più SMS per il recupero password in questo flusso, ma continua a supportare il flusso OTP classico (`verify-otp`) se necessario.
- **Gol/eventi partita:** La push su "Risultato aggiornato" viene inviata a tutte le leghe che hanno quella giornata in calendario quando i punteggi live vengono aggiornati da `sync_live_matches`. Una push più mirata (solo chi ha un certo giocatore in rosa) richiederebbe il `player_id` negli eventi partita (attualmente non sempre disponibile dall’API).
- **FCM:** I messaggi in foreground sono gestiti in-app tramite `NotificationProviderRef`; in background la notifica è gestita dal sistema operativo.
