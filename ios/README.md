# iOS App: Whole Body Generator

SwiftUI app: pick a face photo → tap Generate → see the full-body portrait.

Calls the Modal endpoint directly over HTTPS: no Firebase, no polling.

---

## Requirements

- Xcode 15+
- iOS 16+ target
- The Modal backend deployed (`modal deploy app.py` from the project root)

---

## Setup (5 steps)

### 1. Create a new Xcode project

- Open Xcode → **File → New → Project**
- Choose **iOS → App**
- Product Name: `WholBodyGenerator`
- Interface: **SwiftUI**, Language: **Swift**
- Uncheck "Include Tests" (optional)

### 2. Replace the generated files

Delete `ContentView.swift` and `<ProjectName>App.swift` from the Xcode navigator,
then drag all four `.swift` files from this folder into the project:

```
WholBodyGeneratorApp.swift
ContentView.swift
GeneratorViewModel.swift
APIClient.swift
```

Make sure **"Copy items if needed"** is checked.

### 3. Set your endpoint URL

Open `APIClient.swift` and replace the placeholder:

```swift
private let endpointURL = "https://your-modal-endpoint.modal.run/generate"
//                         ↑ paste your Modal URL here
```

Your Modal URL is printed when you run `modal deploy app.py`.

### 4. Add Photo Library usage description

In Xcode, select your project → **Info** tab → add a new key:

| Key | Value |
|---|---|
| `Privacy - Photo Library Usage Description` | `Select a face photo to generate a full-body portrait` |

### 5. Build and run

Select an iPhone simulator or your device, press **⌘R**.

---

## How the app works

```
User picks face photo (PhotosPicker)
          │
          ▼
GeneratorViewModel.generate()
          │
          ▼
APIClient: multipart/form-data POST to Modal endpoint
          │
          ▼
Response: PNG bytes → UIImage
          │
          ▼
ResultCard displays image + share sheet
```

The network call has a 120-second timeout. Generation normally takes 15–25 seconds on an A10G.

---

## Customising the prompt

The text field in the app maps to the `prompt` field in the API. Leave it blank to use the
default (`full body portrait of a person, standing, photorealistic…`). Examples:

- `wearing a red dress, outdoor background`
- `business casual, office setting`
- `athletic wear, gym background`
