# Whole-Body Diffusion Generator

Face-guided full-body portrait generation using **IP-Adapter FaceID** + **SDXL**, served via **Modal** serverless GPU.

This is a modernised replacement for [Whole-body-GAN-generator](../Whole-body-GAN-generator), built in 2022 with StyleGAN-Human + ReStyle + InsetGAN.

---

## What changed and why

| | Old (2022) | New (2026) |
|---|---|---|
| **Model** | StyleGAN-Human + ReStyle encoder + InsetGAN joint optimisation | IP-Adapter FaceID + SDXL (single forward pass) |
| **Face encoding** | dlib alignment → ReStyle pSp (5 iterative refinement passes) | insightface ArcFace embedding (one call) |
| **Inference time** | ~3–5 min (InsetGAN optimisation loop) | ~15–25 sec (30 DDIM steps) |
| **Serving** | Colab notebook + ngrok tunnel + Firebase Storage relay | Modal serverless GPU endpoint (stable HTTPS URL) |
| **iOS integration** | Upload to Firebase → poll for result | Direct `multipart/form-data` POST, PNG response |
| **Identity fidelity** | Good (limited by GAN latent space) | Better (ArcFace embedding conditions the UNet directly) |

---

## How it works

```
Input face photo
      │
      ▼
insightface ArcFace  ──►  512-dim identity embedding
      │
      ▼
IP-Adapter FaceID        injects embedding into SDXL cross-attention
      │
      ▼
SDXL UNet (30 DDIM steps, 768 × 1024)
      │
      ▼
Full-body portrait PNG
      │
      ▼
Modal web endpoint  ──►  stable HTTPS URL, called directly from iOS
```

---

## Project layout

```
whole-body-diffusion-generator/
├── pipeline.py        # Face embedding extraction + IP-Adapter + SDXL inference
├── app.py             # Modal deployment (GPU class + web endpoint)
├── example_client.py  # Python client example
└── requirements.txt
```

---

## Setup

### 1. Install dependencies

```bash
pip install -r requirements.txt
```

### 2. Install Modal CLI and authenticate

```bash
pip install modal
modal setup        # opens browser for one-time auth
```

### 3. Deploy

```bash
modal deploy app.py
```

Modal prints a URL like `https://your-username--whole-body-generator-generator-generate.modal.run`.
Copy it into `example_client.py` as `ENDPOINT_URL`.

The first deploy downloads SDXL and the IP-Adapter checkpoint (~7 GB total) into the Modal
volume — this happens once and is cached. Subsequent cold starts load from the volume.

---

## Usage

### Python client

```bash
python example_client.py face.jpg
python example_client.py face.jpg --prompt "full body, wearing a red dress" --seed 42
python example_client.py face.jpg --steps 50 --output result.png
```

### curl

```bash
curl -X POST https://your-endpoint.modal.run/generate \
  -F "face_image=@face.jpg" \
  -F "prompt=full body portrait, casual outfit, outdoor" \
  --output result.png
```

### iOS (Swift)

```swift
var request = URLRequest(url: URL(string: endpointURL)!)
request.httpMethod = "POST"
let boundary = UUID().uuidString
request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

var body = Data()
body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"face_image\"; filename=\"face.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
body.append(faceImageData)
body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
request.httpBody = body

URLSession.shared.dataTask(with: request) { data, _, _ in
    let resultImage = UIImage(data: data!)
}
```

---

## API reference

`POST /generate`

| Field | Type | Required | Description |
|---|---|---|---|
| `face_image` | file | yes | JPEG or PNG containing a face |
| `prompt` | string | no | Generation prompt (default: full body portrait…) |
| `negative_prompt` | string | no | What to avoid in the output |
| `seed` | integer | no | Fixed seed for reproducibility |
| `num_steps` | integer | no | DDIM steps (default: 30, range: 10–50) |

Returns: `image/png`, 768 × 1024 px

---

## Cost estimate (Modal)

Modal gives $30/month free credit. An A10G GPU costs ~$0.0013/sec.

| Scenario | Time | Cost |
|---|---|---|
| 30-step generation | ~20 sec | ~$0.026 |
| 50-step generation | ~30 sec | ~$0.039 |
| 100 requests/day | ~33 min GPU time | ~$2.60/day |

The container stays warm for 2 minutes after a request (configured in `app.py`), so burst traffic
avoids cold starts without keeping a GPU running idle all day.

---

## Models used

| Model | Source | Purpose |
|---|---|---|
| `stabilityai/stable-diffusion-xl-base-1.0` | HuggingFace | Base image generator |
| `h94/IP-Adapter-FaceID` (`ip-adapter-faceid_sdxl.bin`) | HuggingFace | Face identity conditioning |
| `buffalo_l` (insightface) | insightface | ArcFace face embedding |

All weights are downloaded automatically on first deploy into the Modal persistent volume.

---

## References

- [IP-Adapter](https://github.com/tencent-ailab/IP-Adapter) — Ye et al. (2023)
- [IP-Adapter FaceID](https://ip-adapter.github.io/FaceID/) — improved identity preservation
- [Stable Diffusion XL](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0)
- [insightface](https://github.com/deepinsight/insightface)
- [Modal](https://modal.com/docs)
