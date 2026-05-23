"""
Core inference pipeline: face embedding extraction + IP-Adapter FaceID + SDXL.

Replaces the old ReStyle → InsetGAN chain with a single forward pass.
"""

import io
import torch
import numpy as np
from pathlib import Path
from PIL import Image
from huggingface_hub import hf_hub_download



def load_face_analyzer():
    from insightface.app import FaceAnalysis

    analyzer = FaceAnalysis(
        name="buffalo_l",
        providers=["CUDAExecutionProvider", "CPUExecutionProvider"],
    )
    analyzer.prepare(ctx_id=0, det_size=(640, 640))
    return analyzer


def extract_face_embedding(analyzer, image: Image.Image) -> torch.Tensor:
    img_array = np.array(image.convert("RGB"))
    faces = analyzer.get(img_array)
    if not faces:
        raise ValueError("No face detected. Provide an image with a clearly visible face.")
    # Pick the largest detected face
    face = max(faces, key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]))
    return torch.from_numpy(face.normed_embedding).unsqueeze(0)


def load_pipeline(model_dir: str = "/models"):
    from diffusers import StableDiffusionXLPipeline, DDIMScheduler
    from ip_adapter.ip_adapter_faceid import IPAdapterFaceIDXL

    model_dir = Path(model_dir)
    model_dir.mkdir(parents=True, exist_ok=True)

    faceid_ckpt = model_dir / "ip-adapter-faceid_sdxl.bin"
    if not faceid_ckpt.exists():
        print("Downloading IP-Adapter FaceID checkpoint...")
        hf_hub_download(
            repo_id="h94/IP-Adapter-FaceID",
            filename="ip-adapter-faceid_sdxl.bin",
            local_dir=str(model_dir),
        )

    print("Loading SDXL base model...")
    pipe = StableDiffusionXLPipeline.from_pretrained(
        "stabilityai/stable-diffusion-xl-base-1.0",
        torch_dtype=torch.float16,
        use_safetensors=True,
        variant="fp16",
    )
    pipe.scheduler = DDIMScheduler.from_config(pipe.scheduler.config)
    pipe.to("cuda")

    print("Attaching IP-Adapter FaceID...")
    ip_model = IPAdapterFaceIDXL(pipe, str(faceid_ckpt), "cuda")

    face_analyzer = load_face_analyzer()

    return ip_model, face_analyzer


def generate(
    ip_model,
    face_analyzer,
    face_image: Image.Image,
    prompt: str = (
        "full body portrait of a person, standing, photorealistic, "
        "high quality, professional photo, studio lighting"
    ),
    negative_prompt: str = (
        "blurry, low quality, deformed, ugly, bad anatomy, cropped, "
        "missing limbs, extra limbs, watermark, text"
    ),
    num_steps: int = 30,
    guidance_scale: float = 7.5,
    faceid_scale: float = 0.8,
    seed: int = None,
) -> Image.Image:
    face_emb = extract_face_embedding(face_analyzer, face_image)

    if seed is not None:
        torch.manual_seed(seed)

    images = ip_model.generate(
        prompt=prompt,
        negative_prompt=negative_prompt,
        faceid_embeds=face_emb,
        scale=faceid_scale,
        num_inference_steps=num_steps,
        guidance_scale=guidance_scale,
        width=768,
        height=1024,
    )
    return images[0]
