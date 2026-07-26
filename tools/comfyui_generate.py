#!/usr/bin/env python3
"""Generate Dragonbound art assets through a local ComfyUI API."""

from __future__ import annotations

import argparse
import json
import os
import random
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QUEUE_PATH = ROOT / "data" / "art_queue.json"
CONFIG_PATH = ROOT / "config" / "comfyui.json"
RAW_DIR = ROOT / "art" / "generated" / "raw"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text())


def post_json(url: str, payload: dict, timeout: float = 30.0) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_json(url: str, timeout: float = 15.0) -> dict:
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_bytes(url: str, timeout: float = 30.0) -> bytes:
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return resp.read()


def find_asset(queue: dict, asset_id: str | None) -> dict:
    assets = queue.get("assets", [])
    if asset_id:
        for asset in assets:
            if asset.get("id") == asset_id:
                return asset
        raise SystemExit(f"No art asset with id '{asset_id}'.")
    for asset in assets:
        if asset.get("status") == "pending":
            return asset
    raise SystemExit("No pending art assets.")


def checkpoint_choices(object_info: dict) -> list[str]:
    loader = object_info.get("CheckpointLoaderSimple", {})
    required = loader.get("input", {}).get("required", {})
    ckpt = required.get("ckpt_name", [])
    if ckpt and isinstance(ckpt[0], list):
        return ckpt[0]
    return []


def combo_choices(object_info: dict, node_name: str, input_name: str) -> list[str]:
    node = object_info.get(node_name, {})
    required = node.get("input", {}).get("required", {})
    item = required.get(input_name, [])
    if item and isinstance(item[0], list):
        return item[0]
    if (
        isinstance(item, list)
        and len(item) > 1
        and isinstance(item[1], dict)
        and isinstance(item[1].get("options"), list)
    ):
        return item[1]["options"]
    return []


def build_workflow(asset: dict, config: dict, args: argparse.Namespace) -> dict:
    workflow_type = args.workflow or asset.get("workflow") or config.get("workflow", "checkpoint")
    if workflow_type in {"flux", "flux2"}:
        return build_flux2_workflow(asset, config, args)

    ckpt = args.checkpoint or asset.get("checkpoint") or config.get("checkpoint", "")
    if not ckpt:
        raise SystemExit(
            "No checkpoint configured. Run with --list-checkpoints, then set "
            "config/comfyui.json checkpoint or pass --checkpoint."
        )

    source_size = int(args.source_size or asset.get("source_size") or config.get("source_size", 512))
    source_width = int(asset.get("source_width", source_size))
    source_height = int(asset.get("source_height", source_size))
    seed = int(args.seed if args.seed is not None else random.randint(1, 2**31 - 1))
    prefix = f"{config.get('output_prefix', 'dragonbound')}_{asset['id']}"
    lora_name = asset.get("lora", config.get("lora", ""))
    lora_strength = float(asset.get("lora_strength", config.get("lora_strength", 0.0)))
    model_ref = ["1", 0]
    clip_ref = ["1", 1]

    workflow = {
        "1": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {"ckpt_name": ckpt},
        },
        "2": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": clip_ref, "text": asset["prompt"]},
        },
        "3": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": clip_ref, "text": asset.get("negative", "")},
        },
        "4": {
            "class_type": "EmptyLatentImage",
            "inputs": {
                "width": source_width,
                "height": source_height,
                "batch_size": int(args.batch_size),
            },
        },
        "5": {
            "class_type": "KSampler",
            "inputs": {
                "model": model_ref,
                "positive": ["2", 0],
                "negative": ["3", 0],
                "latent_image": ["4", 0],
                "seed": seed,
                "steps": int(args.steps or config.get("steps", 28)),
                "cfg": float(args.cfg or config.get("cfg", 7.0)),
                "sampler_name": args.sampler or config.get("sampler", "euler"),
                "scheduler": args.scheduler or config.get("scheduler", "normal"),
                "denoise": 1.0,
            },
        },
        "6": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["5", 0], "vae": ["1", 2]},
        },
        "7": {
            "class_type": "SaveImage",
            "inputs": {"images": ["6", 0], "filename_prefix": prefix},
        },
    }
    if lora_name and lora_strength > 0:
        workflow["8"] = {
            "class_type": "LoraLoader",
            "inputs": {
                "model": ["1", 0],
                "clip": ["1", 1],
                "lora_name": lora_name,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
            },
        }
        workflow["2"]["inputs"]["clip"] = ["8", 1]
        workflow["3"]["inputs"]["clip"] = ["8", 1]
        workflow["5"]["inputs"]["model"] = ["8", 0]
    return workflow


def build_flux2_workflow(asset: dict, config: dict, args: argparse.Namespace) -> dict:
    model_name = (
        args.model
        or asset.get("model")
        or config.get("model")
        or config.get("unet")
        or "flux-2-klein-4b-fp8.safetensors"
    )
    clip_name = args.clip or asset.get("clip") or config.get("clip") or "qwen_3_4b.safetensors"
    vae_name = args.vae or asset.get("vae") or config.get("vae") or "flux2-vae.safetensors"
    source_size = int(args.source_size or asset.get("source_size") or config.get("source_size", 512))
    source_width = int(asset.get("source_width", source_size))
    source_height = int(asset.get("source_height", source_size))
    seed = int(args.seed if args.seed is not None else random.randint(1, 2**31 - 1))
    prefix = f"{config.get('output_prefix', 'dragonbound')}_{asset['id']}"
    lora_name = asset.get("lora", config.get("lora", ""))
    lora_strength = float(asset.get("lora_strength", config.get("lora_strength", 0.0)))
    guidance = float(args.guidance or asset.get("guidance", config.get("guidance", 3.5)))

    workflow = {
        "1": {
            "class_type": "UNETLoader",
            "inputs": {
                "unet_name": model_name,
                "weight_dtype": asset.get("weight_dtype", config.get("weight_dtype", "fp8_e4m3fn")),
            },
        },
        "2": {
            "class_type": "CLIPLoader",
            "inputs": {
                "clip_name": clip_name,
                "type": asset.get("clip_type", config.get("clip_type", "flux2")),
            },
        },
        "3": {
            "class_type": "VAELoader",
            "inputs": {"vae_name": vae_name},
        },
        "4": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": ["2", 0], "text": asset["prompt"]},
        },
        "5": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": ["2", 0], "text": asset.get("negative", "")},
        },
        "6": {
            "class_type": "EmptyFlux2LatentImage",
            "inputs": {
                "width": source_width,
                "height": source_height,
                "batch_size": int(args.batch_size),
            },
        },
        "7": {
            "class_type": "KSampler",
            "inputs": {
                "model": ["1", 0],
                "positive": ["4", 0],
                "negative": ["5", 0],
                "latent_image": ["6", 0],
                "seed": seed,
                "steps": int(args.steps or config.get("steps", 20)),
                "cfg": float(args.cfg or config.get("cfg", 1.0)),
                "sampler_name": args.sampler or config.get("sampler", "euler"),
                "scheduler": args.scheduler or config.get("scheduler", "simple"),
                "denoise": 1.0,
            },
        },
        "8": {
            "class_type": "FluxGuidance",
            "inputs": {"conditioning": ["4", 0], "guidance": guidance},
        },
        "9": {
            "class_type": "FluxGuidance",
            "inputs": {"conditioning": ["5", 0], "guidance": guidance},
        },
        "10": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["7", 0], "vae": ["3", 0]},
        },
        "11": {
            "class_type": "SaveImage",
            "inputs": {"images": ["10", 0], "filename_prefix": prefix},
        },
    }
    workflow["7"]["inputs"]["positive"] = ["8", 0]
    workflow["7"]["inputs"]["negative"] = ["9", 0]
    if lora_name and lora_strength > 0:
        workflow["12"] = {
            "class_type": "LoraLoader",
            "inputs": {
                "model": ["1", 0],
                "clip": ["2", 0],
                "lora_name": lora_name,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
            },
        }
        workflow["4"]["inputs"]["clip"] = ["12", 1]
        workflow["5"]["inputs"]["clip"] = ["12", 1]
        workflow["7"]["inputs"]["model"] = ["12", 0]
    return workflow


def wait_for_outputs(base_url: str, prompt_id: str, timeout: float) -> list[dict]:
    deadline = time.time() + timeout
    history_url = f"{base_url}/history/{urllib.parse.quote(prompt_id)}"
    while time.time() < deadline:
        history = get_json(history_url)
        item = history.get(prompt_id)
        if item:
            status = item.get("status", {})
            if status.get("status_str") == "error":
                messages = status.get("messages", [])
                details = ""
                for message in reversed(messages):
                    if len(message) == 2 and message[0] == "execution_error":
                        error = message[1]
                        details = (
                            f"{error.get('node_type', 'node')} "
                            f"{error.get('node_id', '')}: "
                            f"{error.get('exception_message', '')}"
                        )
                        break
                raise SystemExit(f"ComfyUI generation failed for {prompt_id}. {details}".strip())
            outputs = item.get("outputs", {})
            images = []
            for output in outputs.values():
                images.extend(output.get("images", []))
            if images:
                return images
        time.sleep(1.0)
    raise SystemExit(f"Timed out waiting for ComfyUI prompt {prompt_id}.")


def download_first_image(base_url: str, image: dict, out_path: Path) -> None:
    params = urllib.parse.urlencode(
        {
            "filename": image["filename"],
            "subfolder": image.get("subfolder", ""),
            "type": image.get("type", "output"),
        }
    )
    data = get_bytes(f"{base_url}/view?{params}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(data)


def process_asset(raw_path: Path, output: Path, size: str) -> None:
    subprocess.run(
        [
            str(ROOT / "tools" / "process_pixel_asset.sh"),
            str(raw_path),
            str(output),
            size,
        ],
        cwd=ROOT,
        check=True,
    )


def save_queue(queue: dict) -> None:
    QUEUE_PATH.write_text(json.dumps(queue, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", help="ComfyUI URL, e.g. http://127.0.0.1:8188")
    parser.add_argument("--id", help="Generate a specific art_queue asset id")
    parser.add_argument("--checkpoint", help="ComfyUI checkpoint name")
    parser.add_argument("--workflow", choices=["checkpoint", "flux", "flux2"])
    parser.add_argument("--model", help="ComfyUI diffusion model/UNET name for FLUX workflows")
    parser.add_argument("--clip", help="ComfyUI text encoder name for FLUX workflows")
    parser.add_argument("--vae", help="ComfyUI VAE name for FLUX workflows")
    parser.add_argument("--list-checkpoints", action="store_true")
    parser.add_argument("--list-models", action="store_true")
    parser.add_argument("--check", action="store_true", help="Check API connection")
    parser.add_argument("--seed", type=int)
    parser.add_argument("--source-size", type=int)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--steps", type=int)
    parser.add_argument("--cfg", type=float)
    parser.add_argument("--guidance", type=float)
    parser.add_argument("--sampler")
    parser.add_argument("--scheduler")
    parser.add_argument("--no-process", action="store_true")
    parser.add_argument("--mark-done", action="store_true")
    parser.add_argument("--timeout", type=float, default=600.0)
    args = parser.parse_args()

    config = load_json(CONFIG_PATH)
    base_url = (
        args.url
        or os.environ.get("COMFYUI_URL")
        or config.get("url")
        or "http://127.0.0.1:8000"
    ).rstrip("/")

    try:
        stats = get_json(f"{base_url}/system_stats")
    except urllib.error.URLError as exc:
        raise SystemExit(
            f"Could not reach ComfyUI at {base_url}. Set COMFYUI_URL in your "
            f"shell or edit config/comfyui.json. Details: {exc}"
        )

    if args.check:
        print(f"Connected to ComfyUI: {base_url}")
        print(json.dumps(stats, indent=2)[:2000])
        return 0

    if args.list_checkpoints:
        object_info = get_json(f"{base_url}/object_info")
        choices = checkpoint_choices(object_info)
        if not choices:
            print("Connected, but no checkpoint choices were exposed.")
        else:
            print("Available checkpoints:")
            for choice in choices:
                print(f"- {choice}")
        return 0

    if args.list_models:
        object_info = get_json(f"{base_url}/object_info")
        print("Available ComfyUI models:")
        for label, node_name, input_name in [
            ("Checkpoints", "CheckpointLoaderSimple", "ckpt_name"),
            ("Diffusion models", "UNETLoader", "unet_name"),
            ("Text encoders", "CLIPLoader", "clip_name"),
            ("VAEs", "VAELoader", "vae_name"),
            ("LoRAs", "LoraLoader", "lora_name"),
        ]:
            choices = combo_choices(object_info, node_name, input_name)
            print(f"\n{label}:")
            if choices:
                for choice in choices:
                    print(f"- {choice}")
            else:
                print("- none")
        return 0

    queue = load_json(QUEUE_PATH)
    asset = find_asset(queue, args.id)
    workflow = build_workflow(asset, config, args)
    response = post_json(f"{base_url}/prompt", {"prompt": workflow})
    prompt_id = response["prompt_id"]
    print(f"Queued {asset['id']} in ComfyUI: {prompt_id}")

    images = wait_for_outputs(base_url, prompt_id, args.timeout)
    raw_path = RAW_DIR / f"{asset['id']}_raw.png"
    download_first_image(base_url, images[0], raw_path)
    print(f"Saved raw image: {raw_path}")

    if not args.no_process:
        output = ROOT / asset["output"]
        process_asset(raw_path, output, asset["size"])
        print(f"Installed game asset: {output}")

    if args.mark_done:
        asset["status"] = "done"
        asset["raw_output"] = str(raw_path.relative_to(ROOT))
        asset["generated_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        save_queue(queue)
        print(f"Marked {asset['id']} done in data/art_queue.json")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
