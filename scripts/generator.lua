-- Stable Diffusion sprite generator

-- Utils are loaded via dofile in main.lua

-- Generate a single sprite from prompt
function generateSprite(prompt, negativePrompt, width, height, sdConfig)
  if not app.activeSprite then
    app.alert("Please open or create a sprite first!")
    return nil
  end
  
  -- Call SD API
  local imageData = callStableDiffusionAPI(prompt, negativePrompt, width, height, sdConfig)
  if not imageData then
    return nil
  end
  
  -- Import image into Aseprite
  local success, sprite = pcall(function()
    return importImageData(imageData, width, height, {
      prompt = prompt,
      negativePrompt = negativePrompt,
      width = width,
      height = height,
      model = sdConfig.model or "unknown",
      steps = sdConfig.steps or 20,
      cfgScale = sdConfig.cfg_scale or 7
    })
  end)
  
  if not success or not sprite then
    handleError("Failed to import generated image", tostring(sprite))
    return nil
  end
  
  return sprite
end

-- Generate animation frames
function generateAnimation(basePrompt, frameCount, width, height, sdConfig)
  if not app.activeSprite then
    app.alert("Please open or create a sprite first!")
    return nil
  end
  
  local frames = {}
  local poses = {"front", "side", "back", "3/4 view"}
  
  for i = 1, frameCount do
    local posePrompt = basePrompt
    if frameCount > 1 then
      local poseIndex = ((i - 1) % #poses) + 1
      posePrompt = basePrompt .. ", " .. poses[poseIndex] .. " view, frame " .. i .. "/" .. frameCount
    end
    
    app.alert("Generating frame " .. i .. "/" .. frameCount .. "...")
    
    local imageData = callStableDiffusionAPI(posePrompt, sdConfig.negativePrompt or "", width, height, sdConfig)
    if imageData then
      table.insert(frames, {
        imageData = imageData,
        prompt = posePrompt,
        frameNumber = i
      })
    end
  end
  
  if #frames == 0 then
    handleError("Failed to generate animation frames")
    return nil
  end
  
  -- Create sprite with animation frames
  local sprite = app.activeSprite
  local newSprite = app.Sprite(width, height, sprite.colorMode)
  
  for i, frame in ipairs(frames) do
    local newFrame = newSprite:newFrame()
    importImageDataToSprite(newSprite, frame.imageData, width, height, i == 1)
  end
  
  -- Apply color quantization
  app.command.ColorQuantization{
    colors = 16,
    withAlpha = true
  }
  
  app.refresh()
  return newSprite
end

-- Generate multiple sprites in batch
function generateBatch(prompts, width, height, sdConfig)
  if type(prompts) == "string" then
    -- Split by newlines if single string
    local promptList = {}
    for line in prompts:gmatch("[^\r\n]+") do
      table.insert(promptList, line)
    end
    prompts = promptList
  end
  
  local sprites = {}
  
  for i, prompt in ipairs(prompts) do
    if prompt and prompt ~= "" then
      app.alert("Generating sprite " .. i .. "/" .. #prompts .. "...")
      
      local imageData = callStableDiffusionAPI(prompt, sdConfig.negativePrompt or "", width, height, sdConfig)
      if imageData then
        table.insert(sprites, {
          imageData = imageData,
          prompt = prompt,
          index = i
        })
      end
    end
  end
  
  return sprites
end

-- Call Stable Diffusion API
function callStableDiffusionAPI(prompt, negativePrompt, width, height, sdConfig)
  local url = sdConfig.url or "http://127.0.0.1:7860"
  local endpoint = url .. "/sdapi/v1/txt2img"
  
  -- Build prompt with pixel art modifiers
  local fullPrompt = prompt .. ", pixel art, low resolution, retro SNES sprite, 16 colors"
  local fullNegativePrompt = (negativePrompt or "") .. ", high resolution, detailed, realistic, 3d"
  
  -- Prepare payload for Automatic1111 API
  local payload = json.encode{
    prompt = fullPrompt,
    negative_prompt = fullNegativePrompt,
    width = width,
    height = height,
    steps = sdConfig.steps or 20,
    cfg_scale = sdConfig.cfg_scale or 7,
    sampler_name = sdConfig.sampler_name or "Euler a",
    seed = sdConfig.seed or -1,
    n_iter = 1,
    batch_size = 1
  }
  
  -- Make HTTP request
  local headers = {
    "Content-Type: application/json"
  }
  
  if sdConfig.api_key and sdConfig.api_key ~= "" then
    table.insert(headers, "Authorization: Bearer " .. sdConfig.api_key)
  end
  
  app.alert("Generating sprite... This may take 10-30 seconds.")
  
  local result = httpRequest("POST", endpoint, headers, payload)
  
  if not result then
    handleError("Failed to connect to Stable Diffusion server", "Check if the server is running at " .. url)
    return nil
  end
  
  if result.status ~= 200 then
    local errorMsg = "Stable Diffusion API error: " .. (result.status or "unknown")
    if result.body then
      local errorResp = json.decode(result.body)
      if errorResp and errorResp.error then
        errorMsg = errorMsg .. "\n" .. errorResp.error
      end
    end
    handleError(errorMsg, "Check your SD server configuration")
    return nil
  end
  
  -- Parse response
  local response = json.decode(result.body)
  if not response or not response.images or not response.images[1] then
    handleError("Invalid response from Stable Diffusion API")
    return nil
  end
  
  -- Decode base64 image
  local b64Data = response.images[1]
  local imageData = base64_decode(b64Data)
  
  return imageData
end

-- Import image data into Aseprite
function importImageData(imageData, width, height, metadata)
  -- Save to temporary file
  local tempDir = app.fs.userConfigPath .. "/temp"
  app.fs.makeDirectory(tempDir)
  local tempFile = tempDir .. "/sd_generated_" .. os.time() .. ".png"
  
  local file = io.open(tempFile, "wb")
  if not file then
    handleError("Failed to create temporary file")
    return nil
  end
  
  file:write(imageData)
  file:close()
  
  -- Load image into Aseprite
  local success, loadedSprite = pcall(function()
    return app.open(tempFile)
  end)
  
  if not success or not loadedSprite then
    handleError("Failed to load generated image")
    if tempFile then os.remove(tempFile) end
    return nil
  end
  
  -- Copy to active sprite
  local srcLayer = loadedSprite.layers[1]
  local srcCel = srcLayer and srcLayer:cel(loadedSprite.frames[1])
  local srcImage = srcCel and srcCel.image
  if not srcImage then
    loadedSprite:close()
    if tempFile then os.remove(tempFile) end
    handleError("Invalid image format")
    return nil
  end
  
  -- Create new layer in active sprite
  local newLayer = app.activeSprite:newLayer("AI Generated")
  local newCel = newLayer:newCel(app.activeSprite.frames[1], srcImage:clone())
  
  -- Store metadata in user data
  if metadata then
    app.activeSprite.data = json.encode(metadata)
  end
  
  -- Apply color quantization
  app.command.ColorQuantization{
    colors = 16,
    withAlpha = true
  }
  
  -- Cleanup
  loadedSprite:close()
  os.remove(tempFile)
  
  app.refresh()
  return app.activeSprite
end

-- Import image data to specific sprite
function importImageDataToSprite(sprite, imageData, width, height, isFirstFrame)
  -- Save to temporary file
  local tempDir = app.fs.userConfigPath .. "/temp"
  app.fs.makeDirectory(tempDir)
  local tempFile = tempDir .. "/sd_generated_" .. os.time() .. ".png"
  
  local file = io.open(tempFile, "wb")
  if not file then
    return false
  end
  
  file:write(imageData)
  file:close()
  
  -- Load and copy
  local success, loadedSprite = pcall(function()
    return app.open(tempFile)
  end)
  
  if success and loadedSprite then
    local srcImage = loadedSprite.layers[1].cel.image
    if srcImage then
      if isFirstFrame then
        local layer = sprite:newLayer("AI Generated")
        layer:newCel(sprite.frames[1], srcImage:clone())
      else
        local layer = sprite.layers[1]
        layer:newCel(sprite.frames[#sprite.frames], srcImage:clone())
      end
    end
    loadedSprite:close()
  end
  
  os.remove(tempFile)
  return success
end

