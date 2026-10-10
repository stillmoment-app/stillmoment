---
name: android-lockscreen-media-verification
description: How to check Android lock screen media controls, the notification and headset keys on the emulator via adb (keyguard, dumpsys, seek)
metadata:
  type: feedback
---

The emulator AVDs have the keyguard turned off (`locksettings get-disabled` = true). `input keyevent 26` then shows no lock screen at all. For lock screen screenshots use `locksettings set-disabled false`, and set it back to `true` afterwards. With the keyguard on, the screen turns off again after about 10 s, so run wake (`keyevent 224`) and tap in two quick separate calls.

Evidence without screenshots: `dumpsys media_session` (session, PlaybackState with position/state, metadata title and teacher), `dumpsys activity services <pkg>` (isForeground), `dumpsys notification --noredact | grep pkg=`, `dumpsys audio | grep "MediaPlayer u/pid"` (state:started/paused). Headset key: `input keyevent 85`. Seek: swipe across the lock screen progress bar, then check the position in media_session against the in-app player.

Importing an MP3: `adb push` to /sdcard/Download, send `MEDIA_SCANNER_SCAN_FILE`, get the id with `content query --uri content://media/external/audio/media`, then `am start -a VIEW -t audio/mpeg -d content://media/external/audio/media/<id> --grant-read-uri-permission -n <pkg>/com.stillmoment.MainActivity`. A trim set in the import dialog was not saved (as of 2026-10-10). Set the trim via the edit dialog instead: swipe right from x=250, not from the edge, because the edge swipe is the back gesture.

**Why:** android-094 cost a lot of time finding these paths. [[shared-emulator-parallel-agents]]
**How to apply:** For any Android ticket that touches the lock screen, notification or media session.
