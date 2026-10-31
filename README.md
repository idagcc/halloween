# Pumpkin Pop! for Mac

A fully offline Halloween carnival game for kids, built for an 86-inch 4K interactive display. Enter a first name and tap randomly appearing pumpkins and ghosts during a 60-second round. Orange pumpkins and ghosts score 10 points; golden pumpkins score 30.

## Run the Mac app

Download [Pumpkin-Pop-Mac.zip](https://github.com/idagcc/halloween/raw/refs/heads/main/dist/Pumpkin-Pop-Mac.zip), unzip it, and open **Pumpkin Pop.app**. You can move the app into Applications. It includes everything it needs and opens fullscreen automatically. No server, browser, account, or internet connection is required.

The app supports Apple Silicon and Intel Macs running macOS 13 or later. The development build is ad-hoc signed, not Apple notarized; macOS may require approval in Privacy & Security when opening a downloaded copy.

## Display and controls

- The game always stays **16:9**. Fullscreen on a 3840 × 2160 display fills the screen; other display shapes have dark bars.
- The Mac app stays fullscreen. The fullscreen button, toggle shortcut, and windowed launch mode have been removed.
- **F2** opens the admin panel (use **Fn–F2** if the keyboard uses F2 for brightness). Opening Admin pauses a round.
- Admin offers settings, audio/music, leaderboard export, and score clearing.
- **Escape** pauses/resumes gameplay. **Command–Q** quits the app.
- Grown-up settings offer Big/Extra big targets, Gentle/Speedy pace, and lower-half-only targets for easy reach.
- A regular TV cannot detect hits. Hands and soft balls require a compatible touchscreen overlay or interactive sensor that supplies touch or mouse input.

Names, settings, and scores stay on this Mac in the app's WebKit storage. The Mac app's scores are separate from scores in a web browser. The shell blocks remote navigation and network resources.

## Build locally

Install Xcode or the macOS Command Line Tools, plus Node.js for source checks. From the project folder:

```sh
python3 scripts/check-source.py
bash scripts/build-mac.sh
open "dist/Pumpkin Pop.app"
```

The build produces a universal `.app` and `dist/Pumpkin-Pop-Mac.zip`, generates its Dock icon locally, and verifies the ad-hoc signature. It does not download dependencies. `mac/PumpkinPop.swift` is the native AppKit/WebKit shell. `index.html` is the shared, self-contained game. The standalone HTML still works by opening it directly in a browser. GitHub Actions also builds a downloadable app artifact after pushes.

## Apple signing and notarization

Notarization requires a **Developer ID Application** certificate and its private key in this Mac's Keychain, from an Apple Developer Program team. An **Apple Development** certificate cannot replace it. Create or install the certificate through Xcode or your Apple Developer account.

Store notarization credentials locally with an interactive prompt:

```sh
xcrun notarytool store-credentials pumpkin-pop
```

Enter your Apple ID, developer Team ID, and an app-specific password when prompted. Do not put passwords, API keys, or signing certificates in this repository or chat.

Rebuild with the exact Developer ID Application identity shown by `security find-identity -v -p codesigning`, then submit:

```sh
MAC_SIGNING_IDENTITY='Developer ID Application: Your Developer Name (TEAMID)' bash scripts/build-mac.sh
bash scripts/notarize-mac.sh pumpkin-pop
```

The signing build enables hardened runtime and a secure timestamp. The notarization script requires a Developer ID signature, submits the archive to Apple, waits for acceptance, staples and validates the ticket, and checks Gatekeeper before repackaging the ZIP and updating its checksum. Submission reports stay in the ignored `.build/notarization/` folder. If the wait times out, check the saved submission ID with `notarytool info`/`wait` before submitting again.

Only publish a build as notarized after this script reports success. The existing 1.0.0 release remains ad-hoc signed until it is explicitly replaced with a verified notarized build. The regular GitHub Actions build remains ad-hoc signed and does not have access to your Apple credentials.

The mouse pointer stays hidden on every game screen, including Home, countdown,
gameplay, pause, results, and admin menus, even when a touchscreen sends mouse input.

LEADERBOARD AND MUSIC
Scores are saved locally under the storage key pumpkin-pop-records. The Mac
app and each browser keep separate scores; builds do not contain player data.
To remove test scores, open the trophy button on Home, choose Clear leaderboard,
then Delete all scores. This removes all scores on that device and cannot be undone.
Settings offers Halloween music: Off, Soft (default), or Normal. The original
minor-key tune loops continuously on Home, during rounds, while paused, and on
results, and works offline. The Mac app starts music when opened; browsers may
require a first tap or key press. Settings → Game audio mutes both music and sound effects.

EXPORT AND ADMIN
Press F2 (or Fn–F2) to open Admin. Choose Export leaderboard (CSV), then
choose a save location in the Mac save dialog. The file includes every saved
score (up to 50), with rank, name, score, round length, and UTC date.
Exporting preserves the leaderboard. The browser version downloads the CSV.
The Home trophy button also offers export. Admin is a keyboard shortcut, not a login.

IDLE RETURN
The pause button has been removed. Escape and F2 remain available for staff.
After one minute without touch, mouse movement/clicks, typing, or scrolling,
the game returns to Home and clears the player name. Saved scores are kept.
The idle timer also applies on results and admin screens. Automatic animations
and round transitions do not reset it. Background music keeps playing.
