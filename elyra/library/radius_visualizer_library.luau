-- // developed for elyra
-- // 0.0.0.2
--!native

local library = {}
library.__index = library
library.instances = {}
library.connection = nil

local game                          = game
local get_service                   = game.GetService
local find_first_child_of_class     = game.FindFirstChildOfClass
local color3_rgb                    = Color3.fromRGB
local vector2_new                   = Vector2.new
local vector3_new                   = Vector3.new
local run_service                   = get_service(game, "RunService")
local workspace                     = find_first_child_of_class(game, "Workspace")
local camera                        = workspace.CurrentCamera
local world_to_viewport             = camera.WorldToViewportPoint

function library.new()
    local self = setmetatable({}, library)
    self.Radius = 25
    self.Segments = 24
    self.Color = color3_rgb(255, 255, 255)
    self.Thickness = 2
    self.Transparency = 1
    self.Rotation = 0
    self.Position = nil
    self.Visible = false
    self.UpdateRate = 1/60
    self.lines = {}
    self.destroyed = false
    self.last_segment_count = 24
    self.last_update = 0
    for i = 1, self.Segments do
        local line = Drawing.new("Line")
        line.Thickness = self.Thickness
        line.Transparency = self.Transparency
        line.Visible = false
        table.insert(self.lines, line)
    end
    table.insert(library.instances, self)
    if not library.connection then
        library.start()
    end
    return self
end

function library:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    for _, line in ipairs(self.lines) do
        if line and line.Remove then
            line:Remove()
        end
    end
    self.lines = {}
    for i = #library.instances, 1, -1 do
        if library.instances[i] == self then
            table.remove(library.instances, i)
            break
        end
    end
    if #library.instances == 0 and library.connection then
        library.connection:Disconnect()
        library.connection = nil
    end
end

function library.update()
    local current_time = tick()
    for i = #library.instances, 1, -1 do
        local visualizer = library.instances[i]
        if visualizer.destroyed then
            table.remove(library.instances, i)
            continue
        end
        if not visualizer.Visible then
            for _, line in ipairs(visualizer.lines) do
                line.Visible = false
            end
            continue
        end
        if current_time - visualizer.last_update < visualizer.UpdateRate then continue end
        visualizer.last_update = current_time
        if not visualizer.Position then
            for _, line in ipairs(visualizer.lines) do
                line.Visible = false
            end
        else
            if visualizer.Segments ~= visualizer.last_segment_count then
                for _, line in ipairs(visualizer.lines) do
                    line:Remove()
                end
                visualizer.lines = {}
                for i = 1, visualizer.Segments do
                    local line = Drawing.new("Line")
                    line.Thickness = visualizer.Thickness
                    line.Transparency = visualizer.Transparency
                    line.Color = visualizer.Color
                    line.Visible = false
                    table.insert(visualizer.lines, line)
                end
                visualizer.last_segment_count = visualizer.Segments
            end
            local angle_step = (math.pi * 2) / visualizer.Segments
            local rotation_offset = math.rad(visualizer.Rotation)
            for i = 1, #visualizer.lines do
                local angle_1 = angle_step * (i - 1) + rotation_offset
                local angle_2 = angle_step * i + rotation_offset
                local position_x_1 = visualizer.Position.X + math.cos(angle_1) * visualizer.Radius
                local position_z_1 = visualizer.Position.Z + math.sin(angle_1) * visualizer.Radius
                local position_x_2 = visualizer.Position.X + math.cos(angle_2) * visualizer.Radius
                local position_z_2 = visualizer.Position.Z + math.sin(angle_2) * visualizer.Radius
                local position_1 = vector3_new(position_x_1, visualizer.Position.Y, position_z_1)
                local position_2 = vector3_new(position_x_2, visualizer.Position.Y, position_z_2)
                local screen_position_1, on_screen_1 = world_to_viewport(camera, position_1)
                local screen_position_2, on_screen_2 = world_to_viewport(camera, position_2)
                if on_screen_1 or on_screen_2 then
                    visualizer.lines[i].From = vector2_new(screen_position_1.X, screen_position_1.Y)
                    visualizer.lines[i].To = vector2_new(screen_position_2.X, screen_position_2.Y)
                    visualizer.lines[i].Color = visualizer.Color
                    visualizer.lines[i].Thickness = visualizer.Thickness
                    visualizer.lines[i].Transparency = visualizer.Transparency
                    visualizer.lines[i].Visible = true
                else
                    visualizer.lines[i].Visible = false
                end
            end
        end
    end
end

function library.start()
    library.connection = run_service.RenderStepped:Connect(function()
        library.update()
    end)
end

return library
