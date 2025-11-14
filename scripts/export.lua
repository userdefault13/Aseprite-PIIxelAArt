-- Export sprite sheet functionality

-- Export sprite as .ase file with JSON metadata
function exportAsAseprite(sprite, outputPath, metadata)
  if not sprite then
    app.alert("No sprite to export!")
    return false
  end
  
  -- Save as .ase file
  local success = pcall(function()
    sprite:saveCopyAs(outputPath)
  end)
  
  if not success then
    app.alert("Failed to export .ase file")
    return false
  end
    
  -- Generate and save JSON metadata
  local jsonMetadata = generateJsonMetadata(sprite, metadata)
  if jsonMetadata then
    local jsonPath = outputPath:match("(.+)%.[^%.]+$") .. ".json"
    saveMetadataJson(jsonMetadata, jsonPath)
  end
  
  return true
end

-- Export sprite as sprite sheet
function exportSpriteSheet(sprite, layout, padding, outputPath, metadata)
  if not sprite then
    app.alert("No sprite to export!")
    return false
  end
  
  -- Calculate sheet dimensions
  local spriteWidth = sprite.width
  local spriteHeight = sprite.height
  local frameCount = #sprite.frames
  
  local rows = layout.rows or 1
  local cols = layout.cols or frameCount
  
  if layout.type == "auto" then
    cols = math.ceil(math.sqrt(frameCount))
    rows = math.ceil(frameCount / cols)
  end
  
  local sheetWidth = cols * spriteWidth + (cols + 1) * padding
  local sheetHeight = rows * spriteHeight + (rows + 1) * padding
  
  -- Create sprite sheet
  local sheet = app.Sprite(sheetWidth, sheetHeight, sprite.colorMode)
  local sheetLayer = sheet:newLayer("Sprite Sheet")
  local sheetFrame = sheet:newFrame()
  
  -- Copy frames to sheet
  local frameIndex = 1
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      if frameIndex <= frameCount then
        local srcFrame = sprite.frames[frameIndex]
        local srcCel = sprite.layers[1]:cel(srcFrame)
        
        if srcCel then
          local srcImage = srcCel.image
          local destX = padding + col * (spriteWidth + padding)
          local destY = padding + row * (spriteHeight + padding)
          
          -- Create cel at position
          local destCel = sheetLayer:newCel(sheetFrame, srcImage:clone())
          destCel.position = Point(destX, destY)
        end
        
        frameIndex = frameIndex + 1
      end
    end
  end
  
  -- Export sheet as PNG
  local pngPath = outputPath:match("(.+)%.[^%.]+$") .. "_sheet.png"
  local success = pcall(function()
    sheet:saveCopyAs(pngPath)
  end)
  
  if not success then
    sheet:close()
    app.alert("Failed to export sprite sheet")
    return false
  end
  
  -- Generate metadata with frame positions
  local frameMetadata = {}
  frameIndex = 1
  for row = 0, rows - 1 do
    for col = 0, cols - 1 do
      if frameIndex <= frameCount then
        local destX = padding + col * (spriteWidth + padding)
        local destY = padding + row * (spriteHeight + padding)
        
        table.insert(frameMetadata, {
          frame = frameIndex,
          x = destX,
          y = destY,
          width = spriteWidth,
          height = spriteHeight
        })
        
        frameIndex = frameIndex + 1
      end
    end
  end
  
  local jsonMetadata = generateJsonMetadata(sprite, metadata)
  if jsonMetadata then
    jsonMetadata.spriteSheet = {
      image = pngPath,
      width = sheetWidth,
      height = sheetHeight,
      spriteWidth = spriteWidth,
      spriteHeight = spriteHeight,
      padding = padding,
      frames = frameMetadata
    }
    
    local jsonPath = outputPath:match("(.+)%.[^%.]+$") .. "_sheet.json"
    saveMetadataJson(jsonMetadata, jsonPath)
  end
  
  sheet:close()
  return true
end

-- Generate JSON metadata
function generateJsonMetadata(sprite, generationData)
  local metadata = {
    sprite = {
      width = sprite.width,
      height = sprite.height,
      colorMode = sprite.colorMode,
      frameCount = #sprite.frames
    },
    frames = {}
  }
  
  -- Add generation data if available
  if generationData then
    metadata.generation = generationData
  end
  
  -- Add sprite user data if available
  if sprite.data and sprite.data ~= "" then
    local success, spriteData = pcall(function()
      return json.decode(sprite.data)
    end)
    if success and spriteData then
      metadata.generation = spriteData
    end
  end
  
  -- Add frame information
  for i, frame in ipairs(sprite.frames) do
    table.insert(metadata.frames, {
      index = i,
      duration = frame.duration
    })
  end
  
  -- Add animation tags if present
  if sprite.tags then
    metadata.tags = {}
    for i, tag in ipairs(sprite.tags) do
      table.insert(metadata.tags, {
        name = tag.name,
        fromFrame = tag.fromFrame.frameNumber,
        toFrame = tag.toFrame.frameNumber,
        color = tag.color
      })
    end
  end
  
  return metadata
end

-- Save metadata JSON file
function saveMetadataJson(metadata, outputPath)
  local jsonStr = json.encode(metadata)
  
  local file = io.open(outputPath, "w")
  if not file then
    app.alert("Failed to save metadata JSON file")
    return false
  end
  
  file:write(jsonStr)
  file:close()
  
  return true
end

