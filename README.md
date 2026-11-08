# TalkBoard

A picture-communication (AAC) board for a tablet. Tap a picture to hear the word; tap 🤟 for an ASL video.

**📖 Full instructions for parents and caregivers: [USER_GUIDE.md](USER_GUIDE.md)**

The rest of this file covers deploying and developing the app.

## Deploy
Static files, no build step. In this folder:
    npx vercel --prod
(or push to a GitHub repo and import it in Vercel).

## Install on the Android tablet
1. Open the Vercel URL in Chrome.
2. Menu ⋮ → "Add to Home screen" / "Install app". It opens full-screen and works offline.
3. Lock it: Settings → Security → App pinning (wording varies by brand) so he can't swipe out.
4. Make sure a voice is installed: Settings → Text-to-speech → Google, download English voice data.

## Using it
- Hold the 🔒 button for 2 seconds for parent mode. Tap any picture to edit, or + to add.
- Each picture can have a photo, a recorded voice, and a sign video (YouTube link with start/end, or your own clip).
- In parent mode, press-hold-drag a picture to swap spots, drop it on a category tab to move it there, or hover over a page arrow to flip pages.
- Settings: layout (pages or scrolling, rows, columns), hold-to-select time, tap cooldown, palm rejection, voice and speed, show/hide categories, backup/restore.
- Data lives only on the tablet (IndexedDB). Save a backup after big changes.

After changing index.html, bump VERSION in sw.js so the tablet picks up the update.

## Android app (for Samsung Kids)
`android/` is a small standalone app that shows the TalkBoard site full-screen, uses Android's own
text-to-speech voices, and works offline. It doesn't depend on Chrome, so it can be added to Samsung Kids.

- Built automatically by GitHub Actions (`.github/workflows/android.yml`) whenever `android/` changes,
  or on demand from the Actions tab → "Build Android app" → Run workflow.
- Needs two repo secrets: `KEYSTORE_B64` (base64 of the signing key) and `KEYSTORE_PASSWORD`.
  Keep the key file safe: updates must be signed with the same key or Android refuses to install them.
- Latest APK: https://github.com/bparker2311/talkboard/releases/latest/download/TalkBoard.apk
- The app loads the live site, so changes to index.html reach it without a new APK.
- The app keeps its own storage, separate from Chrome. Move a board over with Save backup / Restore.

## Cloud sync (Supabase)
Optional sync between devices, using a Supabase project.
- Run `supabase/setup.sql` once in the Supabase SQL editor. It creates one table (row level security on, no policies, so the public key can't read it directly) and three functions that only work with a board's sync code. Only a SHA-256 hash of each code is stored.
- The project URL and publishable key are in `index.html` (`SB_URL`, `SB_KEY`). Both are public by design. Never put the service-role key in the app.
- Each device keeps a local copy and syncs with version numbers: uploads a few seconds after a change, checks for a newer version on open, and asks the user to choose when both sides changed.
