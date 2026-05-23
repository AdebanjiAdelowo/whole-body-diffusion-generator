# Setup Guide — Whole Body Diffusion Generator

---

## Part 1 — Deploy the backend (your Mac, ~10 min)

**Step 1: Install Modal**
```bash
pip3 install modal
```

**Step 2: Create a free Modal account and authenticate**

Go to [modal.com](https://modal.com) → sign up (free, no credit card needed) → then run:
```bash
modal setup
```
This opens a browser, you click "Approve", done.

**Step 3: Go to the project folder**
```bash
cd /Users/adebanjiadelowo/Documents/GitHub/whole-body-diffusion-generator
```

**Step 4: Deploy**
```bash
modal deploy app.py
```
This takes ~5 minutes the first time — it builds the container, downloads SDXL + IP-Adapter (~7 GB) into the Modal volume. You'll see a URL printed at the end like:
```
https://yourname--whole-body-generator-generator-generate.modal.run
```
**Copy that URL.**

---

## Part 2 — Build the iOS app (Xcode, ~10 min)

**Step 5: Open Xcode → File → New → Project**

- Choose **iOS → App**
- Product Name: `WholBodyGenerator`
- Interface: **SwiftUI**
- Language: **Swift**
- Uncheck "Include Tests"
- Save it somewhere (e.g. Desktop)

**Step 6: Delete the two auto-generated files**

In the Xcode left panel, right-click `ContentView.swift` → Delete → Move to Trash.
Do the same for `WholBodyGeneratorApp.swift`.

**Step 7: Add the project's Swift files**

In Finder, go to:
```
/Users/adebanjiadelowo/Documents/GitHub/whole-body-diffusion-generator/ios/WholBodyGenerator/
```
Select all 4 `.swift` files → drag them into Xcode's left panel onto the project folder → tick **"Copy items if needed"** → Add.

**Step 8: Paste your Modal URL**

In Xcode, open `APIClient.swift`, find line 10:
```swift
private let endpointURL = "https://your-modal-endpoint.modal.run/generate"
```
Replace it with your URL from Step 4 (keep `/generate` at the end).

**Step 9: Add photo library permission**

Click your project name at the top of the left panel → select your **target** → **Info** tab → click the `+` at the bottom of the list → add:

| Key | Value |
|---|---|
| Privacy - Photo Library Usage Description | Select a face photo to generate a full-body portrait |

**Step 10: Run on your iPhone**

- Plug in your iPhone via USB
- In the top bar of Xcode, click the device selector (where it says iPhone simulator) → select your iPhone
- Xcode will ask you to trust your developer account on the phone → on iPhone go to **Settings → General → VPN & Device Management** → tap your Apple ID → Trust
- Press **⌘R** to build and run

---

## Part 3 — Use the app

1. Open the app on your iPhone
2. Tap the photo card → pick a face photo from your camera roll
3. Optionally type a prompt (e.g. "wearing a black suit")
4. Tap **Generate Full Body**
5. Wait ~20 seconds → result appears
6. Tap **Save / Share** to save to Photos

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `modal deploy` fails on missing package | Run `pip3 install -r requirements.txt` first |
| Xcode says "No account" | Xcode → Settings → Accounts → add your Apple ID |
| App crashes on launch | Make sure all 4 `.swift` files are added and the old generated files are deleted |
| "No face detected" error | Use a photo where the face is clearly visible and well-lit |
