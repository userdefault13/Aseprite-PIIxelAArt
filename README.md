# AI Pixel Sprites - Aseprite Extension

Generate pixel art sprites using free Stable Diffusion directly in Aseprite.

## Features

- Generate pixel art sprites from text prompts
- Create animation frames with pose variations
- Batch generation from multiple prompts
- Export as .ase files with JSON metadata
- Export sprite sheets with metadata
- Support for local Stable Diffusion servers (Automatic1111)
- Optional cloud API support

## Installation

1. Copy this extension to your Aseprite extensions folder:
   - **macOS**: `~/Library/Application Support/Aseprite/extensions/`
   - **Windows**: `%APPDATA%\Aseprite\extensions\`
   - **Linux**: `~/.config/aseprite/extensions/`

2. Create a `.env` file in the extension directory (copy from `.env.example`):
   ```bash
   SD_API_URL=http://127.0.0.1:7860
   SD_API_KEY=
   ```

3. Restart Aseprite

4. Access via `Edit > Extensions > AI Pixel Sprites`

## Requirements

- Aseprite (latest version)
- Stable Diffusion server (Automatic1111) running locally or cloud API access
- Internet connection (if using cloud API)

## Setup Stable Diffusion

### Local Setup (Recommended)

1. Install [Automatic1111 Web UI](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
2. Start the server: `python webui.py`
3. Default URL: `http://127.0.0.1:7860`
4. Install pixel art models (optional but recommended):
   - Pixel Art Diffusion
   - Pixel Sprite Generator

### Cloud Setup

1. Get API key from your Stable Diffusion service
2. Update `.env` with your API URL and key
3. Ensure the service supports the Automatic1111 API format

## Usage

### Single Sprite Generation

1. Open or create a sprite in Aseprite
2. Go to `Edit > Extensions > AI Pixel Sprites`
3. Enter your prompt (e.g., "pixel art hero sprite, 16 colors")
4. Set dimensions (default: 64x64)
5. Click "Generate"

### Animation Frames

1. Select "Animation Frames" mode
2. Enter base prompt
3. Set frame count
4. Each frame will have different pose variations

### Batch Generation

1. Select "Batch Generation" mode
2. Enter multiple prompts (one per line)
3. All sprites will be generated sequentially

### Export

1. Generate or open a sprite
2. Use export dialog to save as:
   - `.ase` file with JSON metadata
   - Sprite sheet (PNG + JSON) with frame positions

## Configuration

Edit `.env` file in the extension directory:

```
SD_API_URL=http://127.0.0.1:7860  # Your SD server URL
SD_API_KEY=                        # Optional API key for cloud services
```

## Troubleshooting

- **Connection Error**: Ensure Stable Diffusion server is running and accessible
- **Slow Generation**: Local SD generation takes 10-30 seconds per image
- **Quality Issues**: Adjust steps and CFG scale in the dialog
- **Import Errors**: Ensure Aseprite can write to temp directory

## License

MIT License

