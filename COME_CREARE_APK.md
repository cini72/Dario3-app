# Istruzioni per Generare l'APK dell'app "Diario"

L'applicazione **Diario** è stata creata con tutte le funzionalità richieste:
- ✍️ **Scrittura appunti:** Campi testo con selezione testo completa, pulsanti rapidi per **Copia**, **Incolla**, **Seleziona tutto** e **Cancella**.
- 👤 **Dati personali / Contatti:** Indirizzo, Telefono (cliccabile per chiamata rapida) ed Email (cliccabile per invio email).
- 📷 **Foto:** Scatto in tempo reale tramite fotocamera o caricamento da galleria.
- 🎥 **Video:** Registrazione video con fotocamera o caricamento da galleria.
- 💾 **Salvataggio:** Persistenza locale automatica e sicura sul dispositivo.
- 📤 **Condivisione:** Condivisione nativa Android di note di testo, contatti e file multimediali (foto/video) con altre app (WhatsApp, Telegram, Gmail, ecc.).
- 🔍 **Ricerca:** Ricerca istantanea tra tutti gli appunti salvati.

---

## Come Compilare l'APK con Android Studio o da Terminale

### Metodo 1: Da Terminale (Veloce)
Apri il terminale (PowerShell o Prompt dei Comandi) nella cartella del progetto (`c:\Users\mesat\Desktop\lavatrice`) ed esegui:

1. Scarica i pacchetti e le dipendenze:
   ```bash
   flutter pub get
   ```

2. Compila il file APK:
   ```bash
   flutter build apk --release
   ```

3. Troverai il file `.apk` pronto da installare nel seguente percorso:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```
   Puoi trasferire questo file sul tuo smartphone Android (tramite cavo USB, WhatsApp Web, Drive o Telegram) e aprirlo per installare l'app.

---

### Metodo 2: Tramite Android Studio
1. Avvia **Android Studio**.
2. Clicca su **Open** e seleziona la cartella `c:\Users\mesat\Desktop\lavatrice`.
3. Assicurati che il plugin di Flutter sia installato in Android Studio.
4. Nel menu in alto, seleziona:
   `Build` > `Flutter` > `Build APK`.
5. Una volta completata la compilazione, comparirà un messaggio in basso con il link diretto alla cartella contenente il file `app-release.apk`.
