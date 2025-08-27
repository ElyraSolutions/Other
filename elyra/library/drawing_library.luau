-- // 7:32:06

local success, DrawingLib = pcall(function()
	local coreGui = game:GetService("CoreGui")
	local camera = workspace.CurrentCamera
	local drawingUI = Instance.new("ScreenGui")
	drawingUI.Name = "Drawing"
	drawingUI.IgnoreGuiInset = true
	drawingUI.DisplayOrder = 0x7fffffff
	drawingUI.Parent = coreGui
	local drawingIndex = 0
	local baseDrawingObj = setmetatable({
		Visible = true,
		ZIndex = 0,
		Transparency = 1,
		Color = Color3.new(),
		Remove = function(self)
			setmetatable(self, nil)
		end,
		Destroy = function(self)
			setmetatable(self, nil)
		end
	}, {
		__add = function(t1, t2)
			local result = table.clone(t1)
			for index, value in t2 do
				result[index] = value
			end
			return result
		end
	})
	local drawingFontsEnum = {
		[0] = Font.fromEnum(Enum.Font.Roboto),
		[1] = Font.fromEnum(Enum.Font.Legacy),
		[2] = Font.fromEnum(Enum.Font.SourceSans),
		[3] = Font.fromEnum(Enum.Font.RobotoMono)
	}
	local function getFontFromIndex(fontIndex)
		return drawingFontsEnum[fontIndex] or drawingFontsEnum[0]
	end
	local function convertTransparency(transparency)
		return math.clamp(1 - transparency, 0, 1)
	end
	local DrawingLib = {}
	DrawingLib.Fonts = {
		UI = 0,
		System = 1,
		Plex = 2,
		Monospace = 3
	}
	function DrawingLib.new(drawingType)
		if type(drawingType) ~= "string" then
			error("Invalid drawing type: expected string, got " .. type(drawingType), 2)
		end
		drawingIndex += 1
		if drawingType == "Line" then
			local lineObj = ({
				From = Vector2.zero,
				To = Vector2.zero,
				Thickness = 1
			} + baseDrawingObj)
			local lineFrame = Instance.new("Frame")
			lineFrame.Name = tostring(drawingIndex)
			lineFrame.AnchorPoint = Vector2.one * 0.5
			lineFrame.BorderSizePixel = 0
			lineFrame.BackgroundColor3 = lineObj.Color
			lineFrame.Visible = lineObj.Visible
			lineFrame.ZIndex = lineObj.ZIndex
			lineFrame.BackgroundTransparency = convertTransparency(lineObj.Transparency)
			lineFrame.Size = UDim2.new()
			lineFrame.Parent = drawingUI
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if lineObj[index] == nil then return end
					if index == "From" then
						local direction = lineObj.To - value
						local center = (lineObj.To + value) / 2
						local distance = direction.Magnitude
						local theta = math.deg(math.atan2(direction.Y, direction.X))
						lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
						lineFrame.Rotation = theta
						lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
					elseif index == "To" then
						local direction = value - lineObj.From
						local center = (value + lineObj.From) / 2
						local distance = direction.Magnitude
						local theta = math.deg(math.atan2(direction.Y, direction.X))
						lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
						lineFrame.Rotation = theta
						lineFrame.Size = UDim2.fromOffset(distance, lineObj.Thickness)
					elseif index == "Thickness" then
						local distance = (lineObj.To - lineObj.From).Magnitude
						lineFrame.Size = UDim2.fromOffset(distance, value)
					elseif index == "Visible" then
						lineFrame.Visible = value
					elseif index == "ZIndex" then
						lineFrame.ZIndex = value
					elseif index == "Transparency" then
						lineFrame.BackgroundTransparency = convertTransparency(value)
					elseif index == "Color" then
						lineFrame.BackgroundColor3 = value
					end
					lineObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							lineFrame:Destroy()
							lineObj.Remove(self)
							return lineObj:Remove()
						end
					end
					return lineObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Text" then
			local textObj = ({
				Text = "",
				Font = DrawingLib.Fonts.UI,
				Size = 0,
				Position = Vector2.zero,
				Center = false,
				Outline = false,
				OutlineColor = Color3.new()
			} + baseDrawingObj)
			local textLabel = Instance.new("TextLabel")
			local uiStroke = Instance.new("UIStroke")
			textLabel.Name = tostring(drawingIndex)
			textLabel.AnchorPoint = Vector2.one * 0.5
			textLabel.BorderSizePixel = 0
			textLabel.BackgroundTransparency = 1
			textLabel.Visible = textObj.Visible
			textLabel.TextColor3 = textObj.Color
			textLabel.TextTransparency = convertTransparency(textObj.Transparency)
			textLabel.ZIndex = textObj.ZIndex
			textLabel.FontFace = getFontFromIndex(textObj.Font)
			textLabel.TextSize = textObj.Size
			uiStroke.Thickness = 1
			uiStroke.Enabled = textObj.Outline
			uiStroke.Color = textObj.OutlineColor
			textLabel.Parent = drawingUI
			uiStroke.Parent = textLabel
			local function updatePosition()
				local textBounds = textLabel.TextBounds
				local offset = textBounds / 2
				textLabel.Size = UDim2.fromOffset(textBounds.X, textBounds.Y)
				textLabel.Position = UDim2.fromOffset(textObj.Position.X + (if not textObj.Center then offset.X else 0), textObj.Position.Y + offset.Y)
			end
			textLabel:GetPropertyChangedSignal("TextBounds"):Connect(updatePosition)
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if textObj[index] == nil then return end
					if index == "Text" then
						textLabel.Text = value
					elseif index == "Font" then
						value = math.clamp(value, 0, 3)
						textLabel.FontFace = getFontFromIndex(value)
					elseif index == "Size" then
						textLabel.TextSize = value
					elseif index == "Position" then
						local offset = textLabel.TextBounds / 2
						textLabel.Position = UDim2.fromOffset(value.X + (if not textObj.Center then offset.X else 0), value.Y + offset.Y)
					elseif index == "Center" then
						local offset = textLabel.TextBounds / 2
						textLabel.Position = UDim2.fromOffset(textObj.Position.X + (if not value then offset.X else 0), textObj.Position.Y + offset.Y)
					elseif index == "Outline" then
						uiStroke.Enabled = value
					elseif index == "OutlineColor" then
						uiStroke.Color = value
					elseif index == "Visible" then
						textLabel.Visible = value
					elseif index == "ZIndex" then
						textLabel.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)
						textLabel.TextTransparency = transparency
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						textLabel.TextColor3 = value
					end
					textObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							textLabel:Destroy()
							uiStroke:Destroy()
							textObj.Remove(self)
							return textObj:Remove()
						end
					elseif index == "TextBounds" then
						return textLabel.TextBounds
					end
					return textObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Circle" then
			local circleObj = ({
				Radius = 0,
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false
			} + baseDrawingObj)
			local circleFrame = Instance.new("Frame")
			local uiCorner = Instance.new("UICorner")
			local uiStroke = Instance.new("UIStroke")
			circleFrame.Name = tostring(drawingIndex)
			circleFrame.AnchorPoint = Vector2.one * 0.5
			circleFrame.BorderSizePixel = 0
			circleFrame.BackgroundTransparency = if circleObj.Filled then convertTransparency(circleObj.Transparency) else 1
			circleFrame.BackgroundColor3 = circleObj.Color
			circleFrame.Visible = circleObj.Visible
			circleFrame.ZIndex = circleObj.ZIndex
			uiCorner.CornerRadius = UDim.new(1, 0)
			circleFrame.Size = UDim2.fromOffset(circleObj.Radius * 2, circleObj.Radius * 2)
			uiStroke.Thickness = circleObj.Thickness
			uiStroke.Enabled = not circleObj.Filled
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			circleFrame.Parent = drawingUI
			uiCorner.Parent = circleFrame
			uiStroke.Parent = circleFrame
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if circleObj[index] == nil then return end
					if index == "Radius" then
						local radius = value * 2
						circleFrame.Size = UDim2.fromOffset(radius, radius)
					elseif index == "Position" then
						circleFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, 0.6, 0x7fffffff)
						uiStroke.Thickness = value
					elseif index == "Filled" then
						circleFrame.BackgroundTransparency = if value then convertTransparency(circleObj.Transparency) else 1
						uiStroke.Enabled = not value
					elseif index == "Visible" then
						circleFrame.Visible = value
					elseif index == "ZIndex" then
						circleFrame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)
						circleFrame.BackgroundTransparency = if circleObj.Filled then transparency else 1
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						circleFrame.BackgroundColor3 = value
						uiStroke.Color = value
					end
					circleObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							circleFrame:Destroy()
							uiCorner:Destroy()
							uiStroke:Destroy()
							circleObj.Remove(self)
							return circleObj:Remove()
						end
					end
					return circleObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Square" then
			local squareObj = ({
				Size = Vector2.zero,
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false
			} + baseDrawingObj)
			local squareFrame = Instance.new("Frame")
			local uiStroke = Instance.new("UIStroke")
			squareFrame.Name = tostring(drawingIndex)
			squareFrame.BorderSizePixel = 0
			squareFrame.BackgroundTransparency = if squareObj.Filled then convertTransparency(squareObj.Transparency) else 1
			squareFrame.ZIndex = squareObj.ZIndex
			squareFrame.BackgroundColor3 = squareObj.Color
			squareFrame.Visible = squareObj.Visible
			uiStroke.Thickness = squareObj.Thickness
			uiStroke.Enabled = not squareObj.Filled
			uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
			squareFrame.Parent = drawingUI
			uiStroke.Parent = squareFrame
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if squareObj[index] == nil then return end
					if index == "Size" then
						squareFrame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						squareFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, 0.6, 0x7fffffff)
						uiStroke.Thickness = value
					elseif index == "Filled" then
						squareFrame.BackgroundTransparency = if value then convertTransparency(squareObj.Transparency) else 1
						uiStroke.Enabled = not value
					elseif index == "Visible" then
						squareFrame.Visible = value
					elseif index == "ZIndex" then
						squareFrame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convertTransparency(value)
						squareFrame.BackgroundTransparency = if squareObj.Filled then transparency else 1
						uiStroke.Transparency = transparency
					elseif index == "Color" then
						uiStroke.Color = value
						squareFrame.BackgroundColor3 = value
					end
					squareObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							squareFrame:Destroy()
							uiStroke:Destroy()
							squareObj.Remove(self)
							return squareObj:Remove()
						end
					end
					return squareObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Image" then
			local imageObj = ({
				Data = "",
				DataURL = "rbxassetid://0",
				Size = Vector2.zero,
				Position = Vector2.zero
			} + baseDrawingObj)
			local imageFrame = Instance.new("ImageLabel")
			imageFrame.Name = tostring(drawingIndex)
			imageFrame.BorderSizePixel = 0
			imageFrame.ScaleType = Enum.ScaleType.Stretch
			imageFrame.BackgroundTransparency = 1
			imageFrame.Visible = imageObj.Visible
			imageFrame.ZIndex = imageObj.ZIndex
			imageFrame.ImageTransparency = convertTransparency(imageObj.Transparency)
			imageFrame.ImageColor3 = imageObj.Color
			imageFrame.Parent = drawingUI
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if imageObj[index] == nil then return end
					if index == "Data" then
						if type(value) == "string" and value:match("^data:image") then
							imageFrame.Image = value
						end
					elseif index == "DataURL" then
						imageFrame.Image = value
					elseif index == "Size" then
						imageFrame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						imageFrame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Visible" then
						imageFrame.Visible = value
					elseif index == "ZIndex" then
						imageFrame.ZIndex = value
					elseif index == "Transparency" then
						imageFrame.ImageTransparency = convertTransparency(value)
					elseif index == "Color" then
						imageFrame.ImageColor3 = value
					end
					imageObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							imageFrame:Destroy()
							imageObj.Remove(self)
							return imageObj:Remove()
						end
					elseif index == "Data" then
						return imageFrame.Image
					end
					return imageObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Quad" then
			local quadObj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				PointD = Vector2.zero,
				Thickness = 1,
				Filled = false
			} + baseDrawingObj)
			local quadFrame = Instance.new("Frame")
			quadFrame.Name = tostring(drawingIndex)
			quadFrame.BorderSizePixel = 0
			quadFrame.BackgroundTransparency = if quadObj.Filled then convertTransparency(quadObj.Transparency) else 1
			quadFrame.ZIndex = quadObj.ZIndex
			quadFrame.BackgroundColor3 = quadObj.Color
			quadFrame.Visible = quadObj.Visible and quadObj.Filled
			quadFrame.Parent = drawingUI
			local linePoints = {}
			linePoints.A = DrawingLib.new("Line")
			linePoints.B = DrawingLib.new("Line")
			linePoints.C = DrawingLib.new("Line")
			linePoints.D = DrawingLib.new("Line")
			local function updateQuadFill()
				if quadObj.Filled then
					local minX = math.min(quadObj.PointA.X, quadObj.PointB.X, quadObj.PointC.X, quadObj.PointD.X)
					local maxX = math.max(quadObj.PointA.X, quadObj.PointB.X, quadObj.PointC.X, quadObj.PointD.X)
					local minY = math.min(quadObj.PointA.Y, quadObj.PointB.Y, quadObj.PointC.Y, quadObj.PointD.Y)
					local maxY = math.max(quadObj.PointA.Y, quadObj.PointB.Y, quadObj.PointC.Y, quadObj.PointD.Y)
					quadFrame.Position = UDim2.fromOffset(minX, minY)
					quadFrame.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
					quadFrame.Visible = quadObj.Visible
					for _, line in linePoints do
						line.Visible = false
					end
				else
					quadFrame.Visible = false
					for _, line in linePoints do
						line.Visible = quadObj.Visible
					end
				end
			end
			updateQuadFill()
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if quadObj[index] == nil then return end
					if index == "PointA" then
						linePoints.A.From = value
						linePoints.B.To = value
						updateQuadFill()
					elseif index == "PointB" then
						linePoints.B.From = value
						linePoints.C.To = value
						updateQuadFill()
					elseif index == "PointC" then
						linePoints.C.From = value
						linePoints.D.To = value
						updateQuadFill()
					elseif index == "PointD" then
						linePoints.D.From = value
						linePoints.A.To = value
						updateQuadFill()
					elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" or index == "Transparency" then
						for _, line in linePoints do
							line[index] = value
						end
						if index == "Visible" then
							updateQuadFill()
						elseif index == "Color" then
							quadFrame.BackgroundColor3 = value
						elseif index == "ZIndex" then
							quadFrame.ZIndex = value
						elseif index == "Transparency" then
							quadFrame.BackgroundTransparency = if quadObj.Filled then convertTransparency(value) else 1
						end
					elseif index == "Filled" then
						updateQuadFill()
					end
					quadObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							for _, line in linePoints do
								line:Remove()
							end
							quadFrame:Destroy()
							quadObj.Remove(self)
							return quadObj:Remove()
						end
					end
					return quadObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		elseif drawingType == "Triangle" then
			local triangleObj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				Thickness = 1,
				Filled = false
			} + baseDrawingObj)
			local triangleFrame = Instance.new("Frame")
			triangleFrame.Name = tostring(drawingIndex)
			triangleFrame.BorderSizePixel = 0
			triangleFrame.BackgroundTransparency = if triangleObj.Filled then convertTransparency(triangleObj.Transparency) else 1
			triangleFrame.ZIndex = triangleObj.ZIndex
			triangleFrame.BackgroundColor3 = triangleObj.Color
			triangleFrame.Visible = triangleObj.Visible and triangleObj.Filled
			triangleFrame.Parent = drawingUI
			local linePoints = {}
			linePoints.A = DrawingLib.new("Line")
			linePoints.B = DrawingLib.new("Line")
			linePoints.C = DrawingLib.new("Line")
			local function updateTriangleFill()
				if triangleObj.Filled then
					local minX = math.min(triangleObj.PointA.X, triangleObj.PointB.X, triangleObj.PointC.X)
					local maxX = math.max(triangleObj.PointA.X, triangleObj.PointB.X, triangleObj.PointC.X)
					local minY = math.min(triangleObj.PointA.Y, triangleObj.PointB.Y, triangleObj.PointC.Y)
					local maxY = math.max(triangleObj.PointA.Y, triangleObj.PointB.Y, triangleObj.PointC.Y)
					triangleFrame.Position = UDim2.fromOffset(minX, minY)
					triangleFrame.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
					triangleFrame.Visible = triangleObj.Visible
					for _, line in linePoints do
						line.Visible = false
					end
				else
					triangleFrame.Visible = false
					for _, line in linePoints do
						line.Visible = triangleObj.Visible
					end
				end
			end
			updateTriangleFill()
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if triangleObj[index] == nil then return end
					if index == "PointA" then
						linePoints.A.From = value
						linePoints.B.To = value
						updateTriangleFill()
					elseif index == "PointB" then
						linePoints.B.From = value
						linePoints.C.To = value
						updateTriangleFill()
					elseif index == "PointC" then
						linePoints.C.From = value
						linePoints.A.To = value
						updateTriangleFill()
					elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" or index == "Transparency" then
						for _, line in linePoints do
							line[index] = value
						end
						if index == "Visible" then
							updateTriangleFill()
						elseif index == "Color" then
							triangleFrame.BackgroundColor3 = value
						elseif index == "ZIndex" then
							triangleFrame.ZIndex = value
						elseif index == "Transparency" then
							triangleFrame.BackgroundTransparency = if triangleObj.Filled then convertTransparency(value) else 1
						end
					elseif index == "Filled" then
						updateTriangleFill()
					end
					triangleObj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							for _, line in linePoints do
								line:Remove()
							end
							triangleFrame:Destroy()
							triangleObj.Remove(self)
							return triangleObj:Remove()
						end
					end
					return triangleObj[index]
				end,
				__tostring = function() return "Drawing" end
			})
		end
		error("Invalid drawing type: " .. drawingType, 2)
	end
	return DrawingLib
end)
if not success then
	return function() error("DrawingLib initialization failed: " .. tostring(DrawingLib), 2) end
end
return DrawingLib
