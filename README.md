# TalkBoard

A picture-communication (AAC) board for a tablet. Tap a picture to hear the word; tap 🤟 for an ASL video.

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
- Settings: grid columns, voice and speed, categories, backup/restore.
- Data lives only on the tablet (IndexedDB). Save a backup after big changes.

After changing index.html, bump VERSION in sw.js so the tablet picks up the update.
