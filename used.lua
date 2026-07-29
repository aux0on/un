local table_insert = table.insert
local table_find = table.find
local math_abs = math.abs

local Maid = {}
Maid.__index = Maid

function Maid.new() 
    return setmetatable({_tasks = {}, _destroyed = false}, Maid) 
end

function Maid:GiveTask(task)
    if self._destroyed then
        self:_cleanupTask(task)
        return
    end
    table_insert(self._tasks, task)
    return task
end

function Maid:GiveTasks(...)
    for _, task in ipairs({...}) do
        self:GiveTask(task)
    end
end

function Maid:_cleanupTask(task)
    local taskType = typeof(task)
    if taskType == "RBXScriptConnection" then
        task:Disconnect()
    elseif taskType == "Instance" then
        task:Destroy()
    elseif taskType == "function" then
        task()
    elseif taskType == "table" and type(task.Destroy) == "function" then
        task:Destroy()
    end
end

function Maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do
        self:_cleanupTask(task)
    end
    self._tasks = {}
end

function Maid:Destroy() 
    self:DoCleaning() 
end

local RootMaid = Maid.new()

local shared = odh_shared_plugins
if shared.game_name ~= "Murder Mystery 2" then return end

local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    MarketplaceService = game:GetService("MarketplaceService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    Debris = game:GetService("Debris"),
    VirtualUser = game:GetService("VirtualUser"),
    Stats = game:GetService("Stats"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService")
}

local LocalPlayer = Services.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlaceId, JobId = game.PlaceId, game.JobId

local __INSERT = table.insert
local __PCLR = Color3.new
local __RGB = Color3.fromRGB
local __UD2 = UDim2.new
local __UD = UDim.new
local __V2 = Vector2.new

local function getfserv(s)
    local ok, svc = pcall(function() return game:GetService(s) end)
    if ok and svc then return svc end
    ok, svc = pcall(function() return game:FindService(s) end)
    if ok and svc then return svc end
    return game[s]
end

local __RS   = getfserv("RunService")
local __UIS  = getfserv("UserInputService")
local __PLRS = getfserv("Players")
local __TS   = getfserv("TweenService")

local muteButtonSounds = false

local function UpdateAllButtonSounds()
    local volume = muteButtonSounds and 0 or 0.5
    for id, btn in pairs(BindableButtons.Buttons) do
        local sound = btn:FindFirstChild("Sound")
        if sound then
            sound.Volume = volume
        end
    end
end

local BindableButtons = {Buttons = {}, Maids = {}, Count = 0}

local __SHAPES = {
    [0] = "rbxassetid://86221076925479",
    [1] = "rbxassetid://96242665417546",
    [2] = "rbxassetid://97129189935336",
    [3] = "rbxassetid://76165862027868",
    [4] = "rbxassetid://125868092127496"
}

local __NORMAL_COLOR = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   __PCLR(0.133333, 0.827451, 0.494118)),
    ColorSequenceKeypoint.new(0.6, __PCLR(0.231373, 0.509804, 0.498039)),
    ColorSequenceKeypoint.new(1,   __PCLR(0.501961, 0.501961, 0.501961))
})

local function bind_safecallback(callback)
    if not callback then return end
    local ok, err = xpcall(callback, function(e) return debug.traceback(e) end)
    if not ok then warn("[BIND ERROR] " .. tostring(err)) end
end

local function Bind_GetStorage()
    local parent = gethui and gethui()
    if not parent or typeof(parent) ~= "Instance" then
        parent = getfserv("CoreGui")
    end
    if not parent or typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    if typeof(parent) ~= "Instance" then
        parent = __PLRS.LocalPlayer:WaitForChild("PlayerGui")
    end

    local sg = parent:FindFirstChild("@bindstorage")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "@bindstorage"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        pcall(function() sg.ScreenInsets = Enum.ScreenInsets.None end)
        sg.Parent = parent
    end
    return sg
end

local function Bind_MakeDraggable(gui, maid, ripple, sound, clickFunc)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false
    
    maid:GiveTask(gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, gui.Position
            hasMoved = false
            sound:Play()
            local absPos = gui.AbsolutePosition
            ripple.Position = __UD2(0, input.Position.X - absPos.X, 0, input.Position.Y - absPos.Y)
            ripple.Size = __UD2(0, 0, 0, 0)
            ripple.BackgroundTransparency = 0.5
            ripple.Visible = true
            __TS:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = __UD2(0, 45, 0, 45),
                BackgroundTransparency = 1
            }):Play()

            local rel
            rel = __UIS.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == input.UserInputType then
                    dragging = false
                    if not hasMoved then
                        bind_safecallback(clickFunc)
                    end
                    rel:Disconnect()
                end
            end)
        end
    end))
    
    maid:GiveTask(gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    
    maid:GiveTask(__UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 7 then hasMoved = true end
            local screen = gui.Parent.AbsoluteSize
            gui.Position = __UD2(startPos.X.Scale + (delta.X / screen.X), 0, startPos.Y.Scale + (delta.Y / screen.Y), 0)
        end
    end))
end

function BindableButtons.AddBButton(id, text, clickFunc)
    if BindableButtons.Buttons[id] then return end
    
    local buttonMaid = Maid.new()
    local camera = workspace.CurrentCamera
    local screen = camera.ViewportSize
    local buttonSizeY = 0.11
    local widthScale = buttonSizeY * (screen.Y / screen.X)
    local xPos = 0.1 + ((BindableButtons.Count % 8) * (widthScale + 0.005))
    local yPos = 0.9 - (math.floor(BindableButtons.Count / 8) * (buttonSizeY + 0.015))

    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = id
    ImageButton.Size = __UD2(widthScale, 0, buttonSizeY, 0)
    ImageButton.Position = __UD2(xPos, 0, yPos, 0)
    ImageButton.AnchorPoint = __V2(0.5, 0.5)
    ImageButton.Image = __SHAPES[0]
    ImageButton.BackgroundTransparency = 1
    ImageButton.BorderSizePixel = 0
    ImageButton.ClipsDescendants = false
    ImageButton.AutoButtonColor = false
    ImageButton.Parent = Bind_GetStorage()
    buttonMaid:GiveTask(ImageButton)

    local TextLabel = Instance.new("TextLabel", ImageButton)
    TextLabel.Name = "@Text"
    TextLabel.Size = __UD2(0.8, 0, 0.8, 0)
    TextLabel.Position = __UD2(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = __V2(0.5, 0.5)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Font = Enum.Font.Jura
    TextLabel.Text = text
    TextLabel.TextColor3 = __PCLR(1, 1, 1)
    TextLabel.TextSize = 10
    TextLabel.TextWrapped = true
    TextLabel.ZIndex = 3

    local Aspect = Instance.new("UIAspectRatioConstraint", ImageButton)
    Aspect.AspectRatio = 1
    Aspect.AspectType = Enum.AspectType.ScaleWithParentSize

    local Stroke = Instance.new("UIGradient", ImageButton)
    Stroke.Name = "@Stroke"
    Stroke.Color = __NORMAL_COLOR

    local ripple = Instance.new("Frame")
    ripple.Name = "@ripple"
    ripple.BackgroundColor3 = __RGB(0, 155, 255)
    ripple.BackgroundTransparency = 0.5
    ripple.Size = __UD2(0, 0, 0, 0)
    ripple.AnchorPoint = __V2(0.5, 0.5)
    ripple.Visible = false
    ripple.ZIndex = 2
    ripple.Parent = ImageButton
    Instance.new("UICorner", ripple).CornerRadius = __UD(1, 0)

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://3868133279"
    sound.Volume = muteButtonSounds and 0 or 0.5
    sound.Parent = ImageButton

    Bind_MakeDraggable(ImageButton, buttonMaid, ripple, sound, clickFunc)
    buttonMaid:GiveTask(__RS.RenderStepped:Connect(function()
        Stroke.Rotation = (Stroke.Rotation + 1) % 360
    end))

    BindableButtons.Buttons[id] = ImageButton
    BindableButtons.Maids[id] = buttonMaid
    BindableButtons.Count = BindableButtons.Count + 1
    return ImageButton
end

function BindableButtons.DeleteBButton(id)
    if BindableButtons.Maids[id] then
        BindableButtons.Maids[id]:Destroy()
        BindableButtons.Maids[id] = nil
        BindableButtons.Buttons[id] = nil
    end
end

local function GetSafeGuiRoot()
    local success, result = pcall(function() 
        return gethui() 
    end)
    if success and result and typeof(result) == "Instance" then
        return result
    end
    return Services.CoreGui
end

local function Notify(title, text, duration)
    Services.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 2})
end

local hiddenGui = Instance.new("ScreenGui")
hiddenGui.Name = "HiddenGui"
hiddenGui.ResetOnSpawn = false
hiddenGui.IgnoreGuiInset = true
hiddenGui.Parent = GetSafeGuiRoot()
RootMaid:GiveTask(hiddenGui)

local aboutSection = shared.AddSection("About")
aboutSection:AddParagraph("Reset Player", "Plugin Made by @lzzzx")

aboutSection:AddToggle("Mute Button SFX", function(bool)
    muteButtonSounds = bool
    UpdateAllButtonSounds()
end)

do
    local resetSection = shared.AddSection("Reset")
    local flingSelPlr, flingActive = nil, true
    local selectedPlayers = {}
    local whitelist = {}
    local flingButtonSize = 0.11
    local clickFlingEnabled = false
    local flingAuraEnabled = false
    local auraStuds = 15
    local maids = {autoSheriff=nil, autoMurderer=nil, loopPlr=nil, loopAll=nil, clickFling=nil, flingAura=nil}
    local buttonToggles = {Sheriff=false, Murderer=false, Player=false}
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local function isWhitelisted(player)
        return whitelist[player.UserId] == true
    end

    local isResetting = false
    local currentResetConnection = nil

    local function touch(a, b)
        pcall(function()
            firetouchinterest(a, b, 0)
            firetouchinterest(a, b, 1)
        end)
    end

    local function fullyRestoreCharacter(character, savedData)
        if not character or not savedData then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        humanoid.PlatformStand = false
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.Velocity = Vector3.zero
        rootPart.RotVelocity = Vector3.zero
        rootPart.CFrame = savedData.cframe
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end

    local function resetPlayer(TargetPlayer)
        if not TargetPlayer then return false end
        if isResetting then return false end
        if isWhitelisted(TargetPlayer) then return false end
        if TargetPlayer == LocalPlayer then return false end

        local Character = LocalPlayer.Character
        if not Character then return false end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart
        local TCharacter = TargetPlayer.Character
        if not (Character and Humanoid and RootPart and TCharacter) then return false end

        local TRootPart = TCharacter:FindFirstChild("HumanoidRootPart")
        local THead = TCharacter:FindFirstChild("Head")
        if not TRootPart then return false end

        isResetting = true

        local savedData = { cframe = RootPart.CFrame }
        Humanoid.PlatformStand = true

        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, -50000, 0)
        bv.Parent = RootPart

        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 1000000
        bg.Parent = RootPart

        local originalDestroyHeight = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = -100000

        local startTime = tick()
        local resetDuration = 1.5

        currentResetConnection = RunService.Heartbeat:Connect(function()
            if tick() - startTime > resetDuration or not TargetPlayer.Character or not TRootPart.Parent then
                Workspace.FallenPartsDestroyHeight = originalDestroyHeight
                bv:Destroy()
                bg:Destroy()
                fullyRestoreCharacter(Character, savedData)
                if currentResetConnection then
                    currentResetConnection:Disconnect()
                    currentResetConnection = nil
                end
                isResetting = false
                return
            end

            if TRootPart and TRootPart.Parent and Character and Character.Parent then
                local headPos = THead and THead.Position or (TRootPart.Position + Vector3.new(0, 2.5, 0))
                RootPart.CFrame = CFrame.new(headPos)
                RootPart.AssemblyLinearVelocity = Vector3.new(0, -50000, 0)
                RootPart.AssemblyAngularVelocity = Vector3.new(7500, 7500, 7500)

                for i = 1, 5 do
                    touch(RootPart, TRootPart)
                    if THead then touch(RootPart, THead) end
                end
                pcall(sethiddenproperty, RootPart, "PhysicsRepRootPart", TRootPart)
            end
        end)

        return true
    end

    local function isPlayerSelected(player)
        for _, selected in ipairs(selectedPlayers) do
            if selected.UserId == player.UserId then
                return true
            end
        end
        return false
    end

    local function findSheriff()
        local success, roleData = pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in pairs(roleData) do
                if data.Role == "Sheriff" and not data.Killed and not data.Dead then
                    local p = Players:FindFirstChild(playerName)
                    if p and p ~= LocalPlayer and not isWhitelisted(p) then return p end
                end
            end
        end
        return nil
    end

    local function findMurderer()
        local success, roleData = pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer()
            end
        end)
        if success and roleData then
            for playerName, data in pairs(roleData) do
                if data.Role == "Murderer" and not data.Killed and not data.Dead then
                    local p = Players:FindFirstChild(playerName)
                    if p and p ~= LocalPlayer and not isWhitelisted(p) then return p end
                end
            end
        end
        return nil
    end

    local function hasGun(player)
        local character = player.Character
        if not character then return false end
        
        local tools = player.Backpack:GetChildren()
        for _, tool in ipairs(tools) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or 
               tool.Name:lower():find("revolver") or tool.Name:lower():find("shotgun") or
               tool.Name:lower():find("rifle") or tool.Name:lower():find("weapon")) then
                return true
            end
        end
        
        local characterTools = character:GetChildren()
        for _, tool in ipairs(characterTools) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or 
               tool.Name:lower():find("revolver") or tool.Name:lower():find("shotgun") or
               tool.Name:lower():find("rifle") or tool.Name:lower():find("weapon")) then
                return true
            end
        end
        
        return false
    end

    local function findSheriffWithFallback()
        local sheriff = findSheriff()
        if sheriff then return sheriff end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not isWhitelisted(player) and hasGun(player) then
                return player
            end
        end
        
        return nil
    end

    RootMaid:GiveTask(function()
        for _, m in pairs(maids) do if m then m:Destroy() end end
        if currentResetConnection then currentResetConnection:Disconnect() end
        isResetting = false
    end)

    resetSection:AddButton("Reset Sheriff", function()
        local target = findSheriffWithFallback()
        if target then resetPlayer(target) else Notify("Error", "No Sheriff Found", 3) end
    end)

    resetSection:AddButton("Reset Murderer", function()
        local murderer = findMurderer()
        if murderer then resetPlayer(murderer) else Notify("Error", "No Murderer Found", 3) end
    end)

    resetSection:AddButton("Reset All", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isWhitelisted(p) then
                resetPlayer(p)
                task.wait(0.2)
            end
        end
    end)

    resetSection:AddPlayerDropdown("Reset Player", function(p)
        flingSelPlr = p
        if p and p ~= LocalPlayer and not isWhitelisted(p) then resetPlayer(p) end
    end)

    resetSection:AddPlayerDropdown("Select Players", function(p)
        if p and p ~= LocalPlayer and not isPlayerSelected(p) then
            table.insert(selectedPlayers, p)
        end
    end)

    resetSection:AddButton("Clear Selected Players", function()
        selectedPlayers = {}
    end)

    local function createAutoFling(name, findFunc)
        resetSection:AddToggle("Auto Reset "..name, function(enabled)
            if maids["auto"..name] then maids["auto"..name]:Destroy() end
            
            if enabled then
                maids["auto"..name] = Maid.new()
                local thread = task.spawn(function()
                    while true do
                        task.wait(1)
                        local target = findFunc()
                        if target then
                            resetPlayer(target)
                            task.wait(3)
                        end
                    end
                end)
                maids["auto"..name]:GiveTask(function() task.cancel(thread) end)
            end
        end)
    end

    createAutoFling("Sheriff", findSheriffWithFallback)
    createAutoFling("Murderer", findMurderer)

    local buttonConfigs = {
        {name="Sheriff", text="RS", findFunc=findSheriffWithFallback, id="reset_sheriff"},
        {name="Murderer", text="RM", findFunc=findMurderer, id="reset_murderer"},
        {name="Player", text="RP", findFunc=function() return flingSelPlr end, id="reset_player"}
    }
    
    for _, cfg in ipairs(buttonConfigs) do
        resetSection:AddToggle("Enable "..cfg.text.." Button", function(enabled)
            buttonToggles[cfg.name] = enabled
            
            if enabled then
                BindableButtons.AddBButton(cfg.id, cfg.text, function()
                    local target = cfg.findFunc()
                    if target then
                        resetPlayer(target)
                    else
                        Notify("Error", "No "..cfg.name.." Found", 3)
                    end
                end)
                local btn = BindableButtons.Buttons[cfg.id]
                if btn then
                    local screen = workspace.CurrentCamera.ViewportSize
                    btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
                end
            else
                BindableButtons.DeleteBButton(cfg.id)
            end
        end)
        
        resetSection:AddSlider(cfg.name.." Button Size", 5, 25, 11, function(value)
            flingButtonSize = value / 100
            local btn = BindableButtons.Buttons[cfg.id]
            if btn then
                local screen = workspace.CurrentCamera.ViewportSize
                btn.Size = __UD2(flingButtonSize * (screen.Y / screen.X), 0, flingButtonSize, 0)
            end
        end)
    end

    resetSection:AddPlayerDropdown("Add to Whitelist", function(p)
        if p and p ~= LocalPlayer then
            whitelist[p.UserId] = true
        end
    end)

    resetSection:AddButton("Clear Whitelist", function()
        whitelist = {}
    end)

    resetSection:AddToggle("Loop Reset Player(s)", function(s)
        if maids.loopPlr then maids.loopPlr:Destroy() end
        
        if s then
            maids.loopPlr = Maid.new()
            local thread = task.spawn(function()
                while true do
                    if flingSelPlr and flingSelPlr.Parent and not isWhitelisted(flingSelPlr) then
                        resetPlayer(flingSelPlr)
                        task.wait(3)
                    end
                    
                    for _, player in ipairs(selectedPlayers) do
                        if player and player.Parent and not isWhitelisted(player) then
                            resetPlayer(player)
                            task.wait(0.2)
                        end
                    end
                    task.wait(1)
                end
            end)
            maids.loopPlr:GiveTask(function() task.cancel(thread) end)
        end
    end)

    resetSection:AddToggle("Loop Reset All", function(s)
        if maids.loopAll then maids.loopAll:Destroy() end
        
        if s then
            maids.loopAll = Maid.new()
            local thread = task.spawn(function()
                while true do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and not isWhitelisted(p) then
                            local started = resetPlayer(p)
                            if started then
                                local timeout = tick() + 3
                                while isResetting and tick() < timeout do
                                    task.wait(0.1)
                                end
                                if isResetting then
                                    isResetting = false
                                    if currentResetConnection then
                                        currentResetConnection:Disconnect()
                                        currentResetConnection = nil
                                    end
                                end
                            end
                            task.wait(0.2)
                        end
                    end
                    task.wait(0.5)
                end
            end)
            maids.loopAll:GiveTask(function() 
                task.cancel(thread)
                isResetting = false
                if currentResetConnection then
                    currentResetConnection:Disconnect()
                    currentResetConnection = nil
                end
            end)
        else
            if maids.loopAll then
                maids.loopAll:Destroy()
                maids.loopAll = nil
            end
            isResetting = false
            if currentResetConnection then
                currentResetConnection:Disconnect()
                currentResetConnection = nil
            end
        end
    end)

    resetSection:AddToggle("Click Reset", function(enabled)
        clickFlingEnabled = enabled
        
        if maids.clickFling then maids.clickFling:Destroy() end
        
        if enabled then
            maids.clickFling = Maid.new()
            
            local function onMouseClick(input, processed)
                if processed then return end
                
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = LocalPlayer:GetMouse()
                    local target = mouse.Target
                    
                    if target then
                        local character = target:FindFirstAncestorWhichIsA("Model")
                        if character then
                            local player = Players:GetPlayerFromCharacter(character)
                            if player and player ~= LocalPlayer and not isWhitelisted(player) then
                                resetPlayer(player)
                            end
                        end
                    end
                end
            end
            
            if UserInputService.TouchEnabled then
                maids.clickFling:GiveTask(UserInputService.TouchTap:Connect(onMouseClick))
            end
            
            maids.clickFling:GiveTask(UserInputService.InputBegan:Connect(onMouseClick))
        end
    end)

    resetSection:AddToggle("Reset Aura", function(enabled)
        flingAuraEnabled = enabled
        
        if maids.flingAura then maids.flingAura:Destroy() end
        
        if enabled then
            maids.flingAura = Maid.new()
            local thread = task.spawn(function()
                while flingAuraEnabled do
                    task.wait(0.5)
                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if rootPart then
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer and not isWhitelisted(player) then
                                local targetChar = player.Character
                                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                                
                                if targetRoot and rootPart then
                                    local distance = (rootPart.Position - targetRoot.Position).Magnitude
                                    if distance <= auraStuds then
                                        resetPlayer(player)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            maids.flingAura:GiveTask(function() task.cancel(thread) end)
        end
    end)

    resetSection:AddSlider("Aura Studs", 5, 50, 15, function(value)
        auraStuds = value
    end)
end

shared.Notify("Reset Player Successfully Loaded!", 5)

RootMaid:GiveTasks(
    function()
        for id, _ in pairs(BindableButtons.Buttons) do
            BindableButtons.DeleteBButton(id)
        end
    end
)
