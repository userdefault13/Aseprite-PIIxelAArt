-- AI Pixel Sprites - Main Extension Entry Point

-- Load utility, generator and export modules
local scriptPath = app.fs.filePath(SCRIPT_PATH) or app.fs.userConfigPath .. "/extensions/ai-pixel-sprites/scripts"
dofile(scriptPath .. "/utils.lua")
dofile(scriptPath .. "/generator.lua")
dofile(scriptPath .. "/export.lua")

-- Load environment variables
local env = loadEnvFile()
local defaultSDUrl = env.SD_API_URL or "http://127.0.0.1:7860"
local defaultSDKey = env.SD_API_KEY or ""

-- Main dialog for sprite generation
function showGenerateDialog()
  local dlg = Dialog("AI Pixel Sprites")
  
  -- Generation mode
  dlg:separator{ text = "Generation Mode" }
  local mode = dlg:combobox{
    id = "mode",
    label = "Mode:",
    option = "Single Sprite",
    options = {"Single Sprite", "Animation Frames", "Batch Generation"}
  }
  
  -- Prompt inputs
  dlg:separator{ text = "Prompt" }
  dlg:textarea{
    id = "prompt",
    label = "Prompt:",
    text = "pixel art sprite of a hero, 16 colors, retro SNES style",
    focus = true
  }
  
  dlg:textarea{
    id = "negativePrompt",
    label = "Negative Prompt:",
    text = "high resolution, detailed, realistic, 3d, blurry"
  }
  
  -- Dimensions
  dlg:separator{ text = "Dimensions" }
  dlg:number{
    id = "width",
    label = "Width:",
    text = "64"
  }
  
  dlg:number{
    id = "height",
    label = "Height:",
    text = "64"
  }
  
  -- SD Configuration
  dlg:separator{ text = "Stable Diffusion" }
  dlg:entry{
    id = "sdUrl",
    label = "SD Server URL:",
    text = defaultSDUrl
  }
  
  dlg:entry{
    id = "sdKey",
    label = "API Key (optional):",
    text = defaultSDKey
  }
  
  dlg:number{
    id = "steps",
    label = "Steps:",
    text = "20"
  }
  
  dlg:number{
    id = "cfgScale",
    label = "CFG Scale:",
    text = "7"
  }
  
  -- Animation specific options
  dlg:number{
    id = "frameCount",
    label = "Frame Count (Animation):",
    text = "4",
    visible = false
  }
  
  -- Batch specific options
  dlg:textarea{
    id = "batchPrompts",
    label = "Prompts (one per line):",
    text = "",
    visible = false
  }
  
  -- Buttons
  dlg:separator{ text = "Actions" }
  dlg:button{
    id = "generate",
    text = "Generate",
    onclick = function()
      local data = dlg.data
      dlg:close()
      handleGenerate(data)
    end
  }
  
  dlg:button{
    id = "cancel",
    text = "Cancel",
    onclick = function()
      dlg:close()
    end
  }
  
  -- Update visibility based on mode
  dlg:modify{
    id = "mode",
    onchange = function()
      local modeValue = dlg.data.mode
      dlg:modify{ id = "frameCount", visible = (modeValue == "Animation Frames") }
      dlg:modify{ id = "batchPrompts", visible = (modeValue == "Batch Generation") }
    end
  }
  
  dlg:show{ wait = false }
end

-- Handle generation based on mode
function handleGenerate(data)
  local prompt = data.prompt
  local negativePrompt = data.negativePrompt
  local width = tonumber(data.width) or 64
  local height = tonumber(data.height) or 64
  
  local sdConfig = {
    url = data.sdUrl or defaultSDUrl,
    api_key = data.sdKey or "",
    steps = tonumber(data.steps) or 20,
    cfg_scale = tonumber(data.cfgScale) or 7,
    sampler_name = "Euler a",
    seed = -1
  }
  
  local mode = data.mode or "Single Sprite"
  
  if mode == "Single Sprite" then
    generateSprite(prompt, negativePrompt, width, height, sdConfig)
    
  elseif mode == "Animation Frames" then
    local frameCount = tonumber(data.frameCount) or 4
    generateAnimation(prompt, frameCount, width, height, sdConfig)
    
  elseif mode == "Batch Generation" then
    local prompts = {}
    for line in (data.batchPrompts or ""):gmatch("[^\r\n]+") do
      if line and line ~= "" then
        table.insert(prompts, line)
      end
    end
    
    if #prompts > 0 then
      local sprites = generateBatch(prompts, width, height, sdConfig)
      if sprites and #sprites > 0 then
        app.alert("Generated " .. #sprites .. " sprites!")
      end
    else
      app.alert("Please enter at least one prompt for batch generation")
    end
  end
end

-- Export dialog
function showExportDialog()
  if not app.activeSprite then
    app.alert("Please open a sprite to export!")
    return
  end
  
  local dlg = Dialog("Export Sprite")
  
  dlg:separator{ text = "Export Options" }
  dlg:combobox{
    id = "exportType",
    label = "Export Type:",
    option = "Aseprite File (.ase)",
    options = {"Aseprite File (.ase)", "Sprite Sheet (PNG + JSON)"}
  }
  
  dlg:file{
    id = "outputPath",
    label = "Output Path:",
    filetypes = {".ase", ".png"},
    save = true
  }
  
  -- Sprite sheet options
  dlg:number{
    id = "sheetPadding",
    label = "Padding:",
    text = "2",
    visible = false
  }
  
  dlg:number{
    id = "sheetCols",
    label = "Columns:",
    text = "4",
    visible = false
  }
  
  dlg:button{
    id = "export",
    text = "Export",
    onclick = function()
      local data = dlg.data
      dlg:close()
      handleExport(data)
    end
  }
  
  dlg:button{
    id = "cancel",
    text = "Cancel",
    onclick = function()
      dlg:close()
    end
  }
  
  -- Update visibility based on export type
  dlg:modify{
    id = "exportType",
    onchange = function()
      local exportType = dlg.data.exportType
      local isSheet = (exportType == "Sprite Sheet (PNG + JSON)")
      dlg:modify{ id = "sheetPadding", visible = isSheet }
      dlg:modify{ id = "sheetCols", visible = isSheet }
    end
  }
  
  dlg:show{ wait = false }
end

-- Handle export
function handleExport(data)
  local sprite = app.activeSprite
  if not sprite then
    return
  end
  
  local outputPath = data.outputPath
  if not outputPath then
    app.alert("Please specify an output path")
    return
  end
  
  local exportType = data.exportType or "Aseprite File (.ase)"
  
  -- Get generation metadata
  local metadata = nil
  if sprite.data and sprite.data ~= "" then
    local success, spriteData = pcall(function()
      return json.decode(sprite.data)
    end)
    if success then
      metadata = spriteData
    end
  end
  
  if exportType == "Aseprite File (.ase)" then
    exportAsAseprite(sprite, outputPath, metadata)
    app.alert("Exported successfully!")
    
  elseif exportType == "Sprite Sheet (PNG + JSON)" then
    local padding = tonumber(data.sheetPadding) or 2
    local cols = tonumber(data.sheetCols) or 4
    local rows = math.ceil(#sprite.frames / cols)
    
    exportSpriteSheet(sprite, {
      type = "manual",
      rows = rows,
      cols = cols
    }, padding, outputPath, metadata)
    
    app.alert("Sprite sheet exported successfully!")
  end
end

-- Register extension
return {
  onMenuClick = function()
    showGenerateDialog()
  end
}

