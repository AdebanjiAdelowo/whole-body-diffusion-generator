"""
Modal deployment: serverless GPU endpoint for whole-body generation.

Deploy:
    modal deploy app.py

Call:
    POST <endpoint_url>
    Body: multipart/form-data
        face_image  (required) — JPEG or PNG of a person's face
        prompt      (optional) — custom generation prompt
        seed        (optional) — integer for reproducibility
        num_steps   (optional) — inference steps, default 30
"""

import io
from typing import Optional
import modal
from fastapi import UploadFile, File, Form
from fastapi.responses import Response

app = modal.App("whole-body-generator")

container_image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install(["libgl1-mesa-glx", "libglib2.0-0", "libsm6", "libxext6", "git"])
    .pip_install(
        "torch==2.4.0",
        "torchvision==0.19.0",
        "diffusers==0.30.3",
        "transformers==4.44.2",
        "accelerate==0.33.0",
        "insightface>=0.7.3",
        "onnxruntime-gpu",
        "git+https://github.com/tencent-ailab/IP-Adapter.git",
        "einops",
        "huggingface_hub",
        "safetensors",
        "Pillow",
        "numpy",
        "fastapi[standard]",
        "python-multipart",
    )
    .add_local_file("pipeline.py", "/app/pipeline.py")
)

model_volume = modal.Volume.from_name("whole-body-models", create_if_missing=True)


@app.cls(
    gpu="A10G",
    image=container_image,
    volumes={"/models": model_volume},
    scaledown_window=120,
)
@modal.concurrent(max_inputs=4)
class Generator:
    @modal.enter()
    def load(self):
        import sys
        sys.path.insert(0, "/app")
        from pipeline import load_pipeline
        self.ip_model, self.face_analyzer = load_pipeline(model_dir="/models")

    @modal.fastapi_endpoint(method="POST")
    async def generate(
        self,
        face_image: UploadFile = File(...),
        prompt: Optional[str] = Form(None),
        seed: Optional[int] = Form(None),
        num_steps: int = Form(30),
    ):
        import sys
        from PIL import Image
        sys.path.insert(0, "/app")
        from pipeline import generate as run_generate

        image_bytes = await face_image.read()
        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

        kwargs = dict(num_steps=num_steps, seed=seed)
        if prompt:
            kwargs["prompt"] = prompt

        result = run_generate(self.ip_model, self.face_analyzer, pil_image, **kwargs)

        buf = io.BytesIO()
        result.save(buf, format="PNG")
        return Response(content=buf.getvalue(), media_type="image/png")
