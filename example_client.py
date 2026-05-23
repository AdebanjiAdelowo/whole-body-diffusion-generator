"""
Example client: call the deployed Modal endpoint.

Usage:
    python example_client.py face.jpg
    python example_client.py face.jpg --prompt "full body, wearing a suit" --seed 42
"""

import argparse
import io
import sys
import requests
from PIL import Image

ENDPOINT_URL = "https://your-modal-endpoint.modal.run/generate"  # replace after `modal deploy`


def generate_full_body(
    face_image_path: str,
    prompt: str = None,
    seed: int = None,
    num_steps: int = 30,
    endpoint: str = ENDPOINT_URL,
) -> Image.Image:
    with open(face_image_path, "rb") as f:
        content_type = "image/png" if face_image_path.endswith(".png") else "image/jpeg"
        files = {"face_image": (face_image_path, f, content_type)}
        data = {"num_steps": str(num_steps)}
        if prompt:
            data["prompt"] = prompt
        if seed is not None:
            data["seed"] = str(seed)

        response = requests.post(endpoint, files=files, data=data, timeout=120)

    response.raise_for_status()
    return Image.open(io.BytesIO(response.content))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("image", help="Path to face image (JPEG or PNG)")
    parser.add_argument("--prompt", default=None)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--output", default="output.png")
    parser.add_argument("--endpoint", default=ENDPOINT_URL)
    args = parser.parse_args()

    print(f"Sending {args.image} to {args.endpoint}...")
    result = generate_full_body(args.image, args.prompt, args.seed, args.steps, args.endpoint)
    result.save(args.output)
    print(f"Saved to {args.output}")
