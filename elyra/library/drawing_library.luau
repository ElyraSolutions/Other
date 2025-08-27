local success, result = pcall(function()
	local core_gui = game:GetService("CoreGui")
	local camera = workspace.CurrentCamera
	local drawing_ui = Instance.new("ScreenGui")
	drawing_ui.Name = "Drawing"
	drawing_ui.IgnoreGuiInset = true
	drawing_ui.DisplayOrder = 0x7fffffff
	drawing_ui.Parent = core_gui
	local drawing_index = 0
	local base_drawing_obj = setmetatable({
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
	local drawing_fonts_enum = {
		[0] = Font.fromEnum(Enum.Font.Roboto),
		[1] = Font.fromEnum(Enum.Font.Legacy),
		[2] = Font.fromEnum(Enum.Font.SourceSans),
		[3] = Font.fromEnum(Enum.Font.RobotoMono)
	}
	local function get_font_from_index(font_index)
		return drawing_fonts_enum[font_index] or drawing_fonts_enum[0]
	end
	local function convert_transparency(transparency)
		return math.clamp(1 - transparency, 0, 1)
	end
	local DrawingLib = {}
	DrawingLib.Fonts = {
		UI = 0,
		System = 1,
		Plex = 2,
		Monospace = 3
	}
	function DrawingLib.new(drawing_type)
		if type(drawing_type) ~= "string" then
			error("Invalid drawing type: expected string, got " .. type(drawing_type), 2)
		end
		drawing_type = drawing_type:lower()
		local valid_types = {line=true, text=true, circle=true, square=true, image=true, quad=true, triangle=true}
		if not valid_types[drawing_type] then
			error("Unsupported drawing type: " .. drawing_type, 2)
		end
		drawing_index += 1
		if drawing_type == "Line" then
			local line_obj = ({
				From = Vector2.zero,
				To = Vector2.zero,
				Thickness = 1
			} + base_drawing_obj)
			local line_frame = Instance.new("Frame")
			line_frame.Name = tostring(drawing_index)
			line_frame.AnchorPoint = Vector2.one * 0.5
			line_frame.BorderSizePixel = 0
			line_frame.BackgroundColor3 = line_obj.Color
			line_frame.Visible = line_obj.Visible
			line_frame.ZIndex = line_obj.ZIndex
			line_frame.BackgroundTransparency = convert_transparency(line_obj.Transparency)
			line_frame.Size = UDim2.new()
			line_frame.Parent = drawing_ui
			local cached_distance = 0
			local cached_center_x = 0
			local cached_center_y = 0
			local cached_theta = 0
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if line_obj[index] == nil then return end
					if index == "From" then
						local direction_x = line_obj.To.X - value.X
						local direction_y = line_obj.To.Y - value.Y
						cached_center_x = (line_obj.To.X + value.X) * 0.5
						cached_center_y = (line_obj.To.Y + value.Y) * 0.5
						cached_distance = math.sqrt(direction_x * direction_x + direction_y * direction_y)
						cached_theta = math.deg(math.atan2(direction_y, direction_x))
						line_frame.Position = UDim2.fromOffset(cached_center_x, cached_center_y)
						line_frame.Rotation = cached_theta
						line_frame.Size = UDim2.fromOffset(cached_distance, line_obj.Thickness)
					elseif index == "To" then
						local direction_x = value.X - line_obj.From.X
						local direction_y = value.Y - line_obj.From.Y
						cached_center_x = (value.X + line_obj.From.X) * 0.5
						cached_center_y = (value.Y + line_obj.From.Y) * 0.5
						cached_distance = math.sqrt(direction_x * direction_x + direction_y * direction_y)
						cached_theta = math.deg(math.atan2(direction_y, direction_x))
						line_frame.Position = UDim2.fromOffset(cached_center_x, cached_center_y)
						line_frame.Rotation = cached_theta
						line_frame.Size = UDim2.fromOffset(cached_distance, line_obj.Thickness)
					elseif index == "Thickness" then
						line_frame.Size = UDim2.fromOffset(cached_distance, value)
					elseif index == "Visible" then
						line_frame.Visible = value
					elseif index == "ZIndex" then
						line_frame.ZIndex = value
					elseif index == "Transparency" then
						line_frame.BackgroundTransparency = convert_transparency(value)
					elseif index == "Color" then
						line_frame.BackgroundColor3 = value
					end
					line_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							line_frame:Destroy()
							line_obj.Remove(self)
							return line_obj:Remove()
						end
					end
					return line_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "Text" then
			local text_obj = ({
				Text = "",
				Font = DrawingLib.Fonts.UI,
				Size = 0,
				Position = Vector2.zero,
				Center = false,
				Outline = false,
				OutlineColor = Color3.new()
			} + base_drawing_obj)
			local text_label = Instance.new("TextLabel")
			local ui_stroke = Instance.new("UIStroke")
			local cached_bounds_x = 0
			local cached_bounds_y = 0
			text_label.Name = tostring(drawing_index)
			text_label.AnchorPoint = Vector2.one * 0.5
			text_label.BorderSizePixel = 0
			text_label.BackgroundTransparency = 1
			text_label.Visible = text_obj.Visible
			text_label.TextColor3 = text_obj.Color
			text_label.TextTransparency = convert_transparency(text_obj.Transparency)
			text_label.ZIndex = text_obj.ZIndex
			text_label.FontFace = get_font_from_index(text_obj.Font)
			text_label.TextSize = text_obj.Size
			ui_stroke.Thickness = 1
			ui_stroke.Enabled = text_obj.Outline
			ui_stroke.Color = text_obj.Color
			text_label.Parent = drawing_ui
			ui_stroke.Parent = text_label
			local bounds_connection = text_label:GetPropertyChangedSignal("TextBounds"):Connect(function()
				local bounds = text_label.TextBounds
				cached_bounds_x = bounds.X
				cached_bounds_y = bounds.Y
				text_label.Size = UDim2.fromOffset(cached_bounds_x, cached_bounds_y)
				local offset_x = if text_obj.Center then 0 else cached_bounds_x * 0.5
				local offset_y = cached_bounds_y * 0.5
				text_label.Position = UDim2.fromOffset(text_obj.Position.X + offset_x, text_obj.Position.Y + offset_y)
			end)
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if text_obj[index] == nil then return end
					if index == "Text" then
						text_label.Text = value
					elseif index == "Font" then
						value = math.clamp(value, 0, 3)
						text_label.FontFace = get_font_from_index(value)
					elseif index == "Size" then
						text_label.TextSize = value
					elseif index == "Position" then
						local offset_x = if text_obj.Center then 0 else cached_bounds_x * 0.5
						local offset_y = cached_bounds_y * 0.5
						text_label.Position = UDim2.fromOffset(value.X + offset_x, value.Y + offset_y)
					elseif index == "Center" then
						local offset_x = if value then 0 else cached_bounds_x * 0.5
						local offset_y = cached_bounds_y * 0.5
						text_label.Position = UDim2.fromOffset(text_obj.Position.X + offset_x, text_obj.Position.Y + offset_y)
					elseif index == "Outline" then
						ui_stroke.Enabled = value
					elseif index == "OutlineColor" then
						ui_stroke.Color = value
					elseif index == "Visible" then
						text_label.Visible = value
					elseif index == "ZIndex" then
						text_label.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convert_transparency(value)
						text_label.TextTransparency = transparency
						ui_stroke.Transparency = transparency
					elseif index == "Color" then
						text_label.TextColor3 = value
					end
					text_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							bounds_connection:Disconnect()
							text_label:Destroy()
							ui_stroke:Destroy()
							text_obj.Remove(self)
							return text_obj:Remove()
						end
					elseif index == "TextBounds" then
						return Vector2.new(cached_bounds_x, cached_bounds_y)
					end
					return text_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "Circle" then
			local circle_obj = ({
				Radius = 0,
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false
			} + base_drawing_obj)
			local circle_frame = Instance.new("Frame")
			local ui_corner = Instance.new("UICorner")
			local ui_stroke = Instance.new("UIStroke")
			circle_frame.Name = tostring(drawing_index)
			circle_frame.AnchorPoint = Vector2.one * 0.5
			circle_frame.BorderSizePixel = 0
			circle_frame.BackgroundTransparency = if circle_obj.Filled then convert_transparency(circle_obj.Transparency) else 1
			circle_frame.BackgroundColor3 = circle_obj.Color
			circle_frame.Visible = circle_obj.Visible
			circle_frame.ZIndex = circle_obj.ZIndex
			ui_corner.CornerRadius = UDim.new(1, 0)
			circle_frame.Size = UDim2.fromOffset(0, 0)
			ui_stroke.Thickness = circle_obj.Thickness
			ui_stroke.Enabled = not circle_obj.Filled
			ui_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			circle_frame.Parent = drawing_ui
			ui_corner.Parent = circle_frame
			ui_stroke.Parent = circle_frame
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if circle_obj[index] == nil then return end
					if index == "Radius" then
						local radius = value * 2
						circle_frame.Size = UDim2.fromOffset(radius, radius)
					elseif index == "Position" then
						circle_frame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, 0.6, 0x7fffffff)
						ui_stroke.Thickness = value
					elseif index == "Filled" then
						circle_frame.BackgroundTransparency = if value then convert_transparency(circle_obj.Transparency) else 1
						ui_stroke.Enabled = not value
					elseif index == "Visible" then
						circle_frame.Visible = value
					elseif index == "ZIndex" then
						circle_frame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convert_transparency(value)
						circle_frame.BackgroundTransparency = if circle_obj.Filled then transparency else 1
						ui_stroke.Transparency = transparency
					elseif index == "Color" then
						circle_frame.BackgroundColor3 = value
						ui_stroke.Color = value
					end
					circle_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							circle_frame:Destroy()
							ui_corner:Destroy()
							ui_stroke:Destroy()
							circle_obj.Remove(self)
							return circle_obj:Remove()
						end
					end
					return circle_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "Square" then
			local square_obj = ({
				Size = Vector2.zero,
				Position = Vector2.zero,
				Thickness = 0.7,
				Filled = false
			} + base_drawing_obj)
			local square_frame = Instance.new("Frame")
			local ui_stroke = Instance.new("UIStroke")
			square_frame.Name = tostring(drawing_index)
			square_frame.BorderSizePixel = 0
			square_frame.BackgroundTransparency = if square_obj.Filled then convert_transparency(square_obj.Transparency) else 1
			square_frame.ZIndex = square_obj.ZIndex
			square_frame.BackgroundColor3 = square_obj.Color
			square_frame.Visible = square_obj.Visible
			ui_stroke.Thickness = square_obj.Thickness
			ui_stroke.Enabled = not square_obj.Filled
			ui_stroke.LineJoinMode = Enum.LineJoinMode.Miter
			square_frame.Parent = drawing_ui
			ui_stroke.Parent = square_frame
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if square_obj[index] == nil then return end
					if index == "Size" then
						square_frame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						square_frame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Thickness" then
						value = math.clamp(value, 0.6, 0x7fffffff)
						ui_stroke.Thickness = value
					elseif index == "Filled" then
						square_frame.BackgroundTransparency = if value then convert_transparency(square_obj.Transparency) else 1
						ui_stroke.Enabled = not value
					elseif index == "Visible" then
						square_frame.Visible = value
					elseif index == "ZIndex" then
						square_frame.ZIndex = value
					elseif index == "Transparency" then
						local transparency = convert_transparency(value)
						square_frame.BackgroundTransparency = if square_obj.Filled then transparency else 1
						ui_stroke.Transparency = transparency
					elseif index == "Color" then
						ui_stroke.Color = value
						square_frame.BackgroundColor3 = value
					end
					square_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							square_frame:Destroy()
							ui_stroke:Destroy()
							square_obj.Remove(self)
							return square_obj:Remove()
						end
					end
					return square_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "image" then
			local image_obj = ({
				Data = "",
				DataURL = "rbxassetid://0",
				Size = Vector2.zero,
				Position = Vector2.zero
			} + base_drawing_obj)
			local image_frame = Instance.new("ImageLabel")
			image_frame.Name = tostring(drawing_index)
			image_frame.BorderSizePixel = 0
			image_frame.ScaleType = Enum.ScaleType.Stretch
			image_frame.BackgroundTransparency = 1
			image_frame.Visible = image_obj.Visible
			image_frame.ZIndex = image_obj.ZIndex
			image_frame.ImageTransparency = convert_transparency(image_obj.Transparency)
			image_frame.ImageColor3 = image_obj.Color
			image_frame.Parent = drawing_ui
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if image_obj[index] == nil then return end
					if index == "Data" then
						if type(value) == "string" and value:match("^data:image") then
							image_frame.Image = value
						end
					elseif index == "DataURL" then
						image_frame.Image = value
					elseif index == "Size" then
						image_frame.Size = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Position" then
						image_frame.Position = UDim2.fromOffset(value.X, value.Y)
					elseif index == "Visible" then
						image_frame.Visible = value
					elseif index == "ZIndex" then
						image_frame.ZIndex = value
					elseif index == "Transparency" then
						image_frame.ImageTransparency = convert_transparency(value)
					elseif index == "Color" then
						image_frame.ImageColor3 = value
					end
					image_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							image_frame:Destroy()
							image_obj.Remove(self)
							return image_obj:Remove()
						end
					elseif index == "Data" then
						return image_frame.Image
					end
					return image_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "Quad" then
			local quad_obj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				PointD = Vector2.zero,
				Thickness = 1,
				Filled = false
			} + base_drawing_obj)
			local quad_frame = Instance.new("Frame")
			quad_frame.Name = tostring(drawing_index)
			quad_frame.BorderSizePixel = 0
			quad_frame.BackgroundTransparency = if quad_obj.Filled then convert_transparency(quad_obj.Transparency) else 1
			quad_frame.ZIndex = quad_obj.ZIndex
			quad_frame.BackgroundColor3 = quad_obj.Color
			quad_frame.Visible = quad_obj.Visible
			quad_frame.Parent = drawing_ui
			local line_points = {}
			line_points.A = DrawingLib.new("Line")
			line_points.B = DrawingLib.new("Line")
			line_points.C = DrawingLib.new("Line")
			line_points.D = DrawingLib.new("Line")
			local function update_quad_fill()
				if quad_obj.Filled then
					local min_x = math.min(quad_obj.PointA.X, quad_obj.PointB.X, quad_obj.PointC.X, quad_obj.PointD.X)
					local max_x = math.max(quad_obj.PointA.X, quad_obj.PointB.X, quad_obj.PointC.X, quad_obj.PointD.X)
					local min_y = math.min(quad_obj.PointA.Y, quad_obj.PointB.Y, quad_obj.PointC.Y, quad_obj.PointD.Y)
					local max_y = math.max(quad_obj.PointA.Y, quad_obj.PointB.Y, quad_obj.PointC.Y, quad_obj.PointD.Y)
					quad_frame.Position = UDim2.fromOffset(min_x, min_y)
					quad_frame.Size = UDim2.fromOffset(max_x - min_x, max_y - min_y)
					quad_frame.Visible = quad_obj.Visible
					for _, line in line_points do
						line.Visible = false
					end
				else
					quad_frame.Visible = false
					for _, line in line_points do
						line.Visible = quad_obj.Visible
					end
				end
			end
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if quad_obj[index] == nil then return end
					if index == "PointA" then
						line_points.A.From = value
						line_points.B.To = value
						update_quad_fill()
					elseif index == "PointB" then
						line_points.B.From = value
						line_points.C.To = value
						update_quad_fill()
					elseif index == "PointC" then
						line_points.C.From = value
						line_points.D.To = value
						update_quad_fill()
					elseif index == "PointD" then
						line_points.D.From = value
						line_points.A.To = value
						update_quad_fill()
					elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" or index == "Transparency" then
						for _, line in line_points do
							line[index] = value
						end
						if index == "Visible" then
							update_quad_fill()
						elseif index == "Color" then
							quad_frame.BackgroundColor3 = value
						elseif index == "ZIndex" then
							quad_frame.ZIndex = value
						elseif index == "Transparency" then
							quad_frame.BackgroundTransparency = if quad_obj.Filled then convert_transparency(value) else 1
						end
					elseif index == "Filled" then
						update_quad_fill()
					end
					quad_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							for _, line in line_points do
								line:Remove()
							end
							quad_frame:Destroy()
							quad_obj.Remove(self)
							return quad_obj:Remove()
						end
					end
					return quad_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		elseif drawing_type == "Triangle" then
			local triangle_obj = ({
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
				Thickness = 1,
				Filled = false
			} + base_drawing_obj)
			local triangle_frame = Instance.new("Frame")
			triangle_frame.Name = tostring(drawing_index)
			triangle_frame.BorderSizePixel = 0
			triangle_frame.BackgroundTransparency = if triangle_obj.Filled then convert_transparency(triangle_obj.Transparency) else 1
			triangle_frame.ZIndex = triangle_obj.ZIndex
			triangle_frame.BackgroundColor3 = triangle_obj.Color
			triangle_frame.Visible = triangle_obj.Visible
			triangle_frame.Parent = drawing_ui
			local line_points = {}
			line_points.A = DrawingLib.new("Line")
			line_points.B = DrawingLib.new("Line")
			line_points.C = DrawingLib.new("Line")
			local function update_triangle_fill()
				if triangle_obj.Filled then
					local min_x = math.min(triangle_obj.PointA.X, triangle_obj.PointB.X, triangle_obj.PointC.X)
					local max_x = math.max(triangle_obj.PointA.X, triangle_obj.PointB.X, triangle_obj.PointC.X)
					local min_y = math.min(triangle_obj.PointA.Y, triangle_obj.PointB.Y, triangle_obj.PointC.Y)
					local max_y = math.max(triangle_obj.PointA.Y, triangle_obj.PointB.Y, triangle_obj.PointC.Y)
					triangle_frame.Position = UDim2.fromOffset(min_x, min_y)
					triangle_frame.Size = UDim2.fromOffset(max_x - min_x, max_y - min_y)
					triangle_frame.Visible = triangle_obj.Visible
					for _, line in line_points do
						line.Visible = false
					end
				else
					triangle_frame.Visible = false
					for _, line in line_points do
						line.Visible = triangle_obj.Visible
					end
				end
			end
			return setmetatable({}, {
				__newindex = function(_, index, value)
					if triangle_obj[index] == nil then return end
					if index == "PointA" then
						line_points.A.From = value
						line_points.B.To = value
						update_triangle_fill()
					elseif index == "PointB" then
						line_points.B.From = value
						line_points.C.To = value
						update_triangle_fill()
					elseif index == "PointC" then
						line_points.C.From = value
						line_points.A.To = value
						update_triangle_fill()
					elseif index == "Thickness" or index == "Visible" or index == "Color" or index == "ZIndex" or index == "Transparency" then
						for _, line in line_points do
							line[index] = value
						end
						if index == "Visible" then
							update_triangle_fill()
						elseif index == "Color" then
							triangle_frame.BackgroundColor3 = value
						elseif index == "ZIndex" then
							triangle_frame.ZIndex = value
						elseif index == "Transparency" then
							triangle_frame.BackgroundTransparency = if triangle_obj.Filled then convert_transparency(value) else 1
						end
					elseif index == "Filled" then
						update_triangle_fill()
					end
					triangle_obj[index] = value
				end,
				__index = function(self, index)
					if index == "Remove" or index == "Destroy" then
						return function()
							for _, line in line_points do
								line:Remove()
							end
							triangle_frame:Destroy()
							triangle_obj.Remove(self)
							return triangle_obj:Remove()
						end
					end
					return triangle_obj[index]
				end,
				__tostring = function() return "DrawingObject" end
			})
		end
	end
	return DrawingLib
end)
if not success then
	return function() error("DrawingLib initialization failed: " .. tostring(result), 2) end
end
return result
