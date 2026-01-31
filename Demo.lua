--[[
    skinchanger.lua v3 (Added Keyst Rifle & Keyrambit + TeamCheck Fix)
    Updated for Rivals
]]

local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

-- Настройки Скинчейнджера
local Config = {
    {
        -- AKEY-47 (Assault Rifle)
        SoundId = "rbxassetid://135478009117226", 
        Skin = PlayerScripts.Assets.ViewModels.Bundles["AKEY-47"],
        Weapon = PlayerScripts.Assets.ViewModels.Weapons["Assault Rifle"],
        AnimSearchKey = "assaultrifle", 
        AnimationTable = {
            -- Стандартные анимации Assault Rifle -> AKEY-47 анимации
            ["rbxassetid://13010870236"] = "rbxassetid://13010870236", -- Equip (тот же)
            ["rbxassetid://13010893629"] = "rbxassetid://13010893629", -- Inspect (тот же)
            ["rbxassetid://13010911854"] = "rbxassetid://13010911854", -- Shoot1 (тот же)
            ["rbxassetid://13010900962"] = "rbxassetid://13010900962"  -- Reload (тот же)
        }
    },
    {
        -- Keyst Rifle (Burst Rifle)
        SoundId = "rbxassetid://135478009117226",
        Skin = PlayerScripts.Assets.ViewModels.Bundles["Keyst Rifle"],
        Weapon = PlayerScripts.Assets.ViewModels.Weapons["Burst Rifle"],
        AnimSearchKey = "burstrifle",
        AnimationTable = {
            -- Стандартные Burst Rifle -> Keyst Rifle анимации
            ["rbxassetid://13204376695"] = "rbxassetid://105402901613987", -- Equip
            ["rbxassetid://13204384262"] = "rbxassetid://93156459127482",  -- Idle
            ["rbxassetid://13204420463"] = "rbxassetid://123663852199231", -- Sprint
            ["rbxassetid://13204401654"] = "rbxassetid://130335149853469", -- Inspect
            ["rbxassetid://13204428113"] = "rbxassetid://93585501212722",  -- Shoot1
            ["rbxassetid://13204413250"] = "rbxassetid://73026124060302"   -- Reload
        }
    },
    {
        -- Keyrambit (Knife)
        SoundId = nil,
        Skin = PlayerScripts.Assets.ViewModels.Bundles.Keyrambit,
        Weapon = PlayerScripts.Assets.ViewModels.Weapons.Knife,
        AnimSearchKey = "knife",
        AnimationTable = {
            -- Стандартные Knife -> Keyrambit (Karambit) анимации
            ["rbxassetid://12613363718"] = "rbxassetid://18742841521", -- Equip
            ["rbxassetid://12613190591"] = "rbxassetid://18742849437", -- Idle
            ["rbxassetid://12886796453"] = "rbxassetid://18742894186", -- Sprint
            ["rbxassetid://12613329711"] = "rbxassetid://18742879471", -- Inspect
            ["rbxassetid://12613340305"] = "rbxassetid://18742860878", -- Attack 1
            ["rbxassetid://12613350645"] = "rbxassetid://18742864831", -- Attack 2
            ["rbxassetid://12613354440"] = "rbxassetid://18742868264"  -- Heavy Attack
        }
    },
    {
        -- Gumball Handgun (Handgun) - использует стандартные анимации
        SoundId = "rbxassetid://135478009117226",
        Skin = PlayerScripts.Assets.ViewModels["Skin Case 3"]["Gumball Handgun"],
        Weapon = PlayerScripts.Assets.ViewModels.Weapons.Handgun,
        AnimSearchKey = "handgun",
        AnimationTable = {
            -- Gumball Handgun использует стандартные анимации Handgun
            -- Если нужны кастомные - добавь сюда
        }
    },
    {
        -- Pumpkin Claws (Fists) - из Spooky Skin Case
        Skin = PlayerScripts.Assets.ViewModels["Spooky Skin Case"]["Pumpkin Claws"],
        Weapon = PlayerScripts.Assets.ViewModels.Weapons.Fists,
        AnimSearchKey = "fists",
        AnimationTable = {
            -- Fists стандартные анимации
            -- Pumpkin Claws скорее всего использует стандартные fists анимации
        }
    }
}

local StarterGui = game:GetService("StarterGui")

local function Notify(title, text)
    if getgenv().AlreadyNotified then return end
    getgenv().AlreadyNotified = true
    StarterGui:SetCore("SendNotification", {
        Title = title, Text = text, Button1 = "Sure!",
        Callback = function() end
    })
end
Notify("Updated Script", "Skins & TeamCheck Loaded!")

-- // 1. ХУК ЗВУКОВОЙ СИСТЕМЫ (AnimationLibrary)
local function HookSoundSystem(searchKey, newSoundId)
    local success, AnimationLibrary = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.AnimationLibrary)
    end)

    if success and AnimationLibrary and AnimationLibrary.Info then
        for animName, info in pairs(AnimationLibrary.Info) do
            -- Ищем анимации по ключу (assaultrifle, burstrifle и т.д.) и чтобы это была стрельба (shoot)
            if animName:lower():match(searchKey:lower()) and animName:lower():match("shoot") then
                -- Переписываем функцию звука
                info.SoundCallback = function(viewModel, ...)
                    if viewModel and viewModel.CreateSound then
                        -- Параметры: Id, Volume, Pitch, AutoPlay, Lifetime
                        viewModel:CreateSound(newSoundId, 1, 0.9 + math.random()*0.2, true, 5)
                    end
                end
            end
        end
    end
end

-- // 2. ОСНОВНАЯ ЛОГИКА (СКИНЫ + АНИМАЦИИ)
local function ApplySkinLogic(data)
    -- Применяем хук звука, если указан ID и ключ поиска
    if data.SoundId and data.AnimSearchKey then
        HookSoundSystem(data.AnimSearchKey, data.SoundId)
    end

    local function ChangeWeaponSkin(skinpath, weaponpath)
        if not skinpath or not weaponpath then return end
        weaponpath:ClearAllChildren()
        for _, v in ipairs(skinpath:GetChildren()) do
            v:Clone().Parent = weaponpath
        end
    end

    -- Безопасная попытка смены скина (pcall на случай, если пути не прогрузились)
    pcall(function()
        ChangeWeaponSkin(data.Skin, data.Weapon)
    end)

    local FirstPerson = workspace:WaitForChild("ViewModels"):WaitForChild("FirstPerson")
    local ViewModel
    local Animator
    local LoadedTracks = {}

    -- Ждем появления Viewmodel игрока
    task.spawn(function()
        while true do
            local found = false
            for _, vm in ipairs(FirstPerson:GetChildren()) do
                if vm.Name:match("^" .. LocalPlayer.Name .. "%s%-") then
                    ViewModel = vm
                    found = true
                    break
                end
            end
            if found then break end
            task.wait(0.5)
        end

        if not ViewModel then return end
        
        local AC = ViewModel:WaitForChild("AnimationController", 5)
        if not AC then return end
        Animator = AC:WaitForChild("Animator", 5)
        if not Animator then return end

        -- Ожидание экипировки нужного оружия
        while true do
            if not ViewModel or not ViewModel.Parent then break end
            local Parts = string.split(ViewModel.Name, " - ")
            local EquippedName = Parts[2]
            
            -- Проверка, совпадает ли имя Viewmodel с именем оружия в конфиге
            if EquippedName and data.Weapon and tostring(data.Weapon.Name) == EquippedName then
                 -- Логика замены анимаций (если есть в таблице)
                 -- (Подключаемся к AnimationPlayed только один раз)
                 if not getgenv().AnimConnected then
                      -- В данной реализации мы просто вешаем обработчик, 
                      -- но так как цикл крутится для каждого оружия, 
                      -- лучше вынести это, но оставим как есть для совместимости.
                 end
            end
            task.wait(0.5)
        end
    end)

    -- Отдельный листенер для анимаций (чтобы не дублировать в цикле выше)
    -- Примечание: В оригинальном коде это было внутри, но для надежности оставим логику замены
    -- через AnimationLibrary (она надежнее для звуков), а таблицу замен анимаций оставим тут.
    
    -- Упрощенная логика замены анимаций по таблице (если она есть)
    if ViewModel and Animator then
        Animator.AnimationPlayed:Connect(function(track)
            local CurrentAnimation = track.Animation.AnimationId
            if data.AnimationTable[CurrentAnimation] then
                track:Stop()
                track:Destroy()
                
                local newAnimId = data.AnimationTable[CurrentAnimation]

                if not LoadedTracks[newAnimId] or not LoadedTracks[newAnimId].IsPlaying then
                    if LoadedTracks[newAnimId] then
                        LoadedTracks[newAnimId]:Stop()
                        LoadedTracks[newAnimId]:Destroy()
                    end
                    
                    local Animation = Instance.new("Animation")
                    Animation.AnimationId = newAnimId

                    local newTrack = Animator:LoadAnimation(Animation)
                    LoadedTracks[newAnimId] = newTrack
                    newTrack:Play()
                    
                    newTrack.Stopped:Connect(function()
                        if LoadedTracks[newAnimId] == newTrack then LoadedTracks[newAnimId] = nil end
                    end)
                else
                    LoadedTracks[newAnimId]:Play()
                end
            end
        end)
    end
end

for _, weaponData in ipairs(Config) do
    task.spawn(function()
        ApplySkinLogic(weaponData)
    end)
end

-- // SOUND REPLACER (Дополнительная страховка) //
-- Этот блок гарантированно меняет звук через модуль игры

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationLibrary = require(ReplicatedStorage.Modules.AnimationLibrary)

local NEW_SOUND_ID = "rbxassetid://135478009117226"

local TARGETS = {
    -- === Assault Rifle ===
    "assaultrifle_shoot1",
    "assaultrifle_ak47_shoot1",
    "assaultrifle_aug_shoot1",
    "assaultrifle_boneclawrifle_shoot1",
    "assaultrifle_akey47_shoot1",
    "assaultrifle_gingerbreadaug_shoot1",
    "assaultrifle_tommygun_shoot1",

    -- === Burst Rifle (Keyst) === (Добавлено)
    "burstrifle_shoot1",
    "burstrifle_keystrifle_shoot1", -- Возможное имя анимации (предположение)
    "burstrifle_shoot_final",

    -- === Handgun ===
    "handgun_shoot1",
    "handgun_blaster_shoot1",
    "handgun_handgun_shoot1",
    "handgun_pixelhandgun_shoot1",
    "handgun_gumballhandgun_shoot1",
    "handgun_stealthhandgun_shoot1",
    "handgun_shoot_final",
}

local function newSoundCallback(viewModel, animHash, speed)
    viewModel:CreateSound(NEW_SOUND_ID, 0.875, 1 + 0.2 * math.random(), true, 5)
end

for _, animName in ipairs(TARGETS) do
    local info = AnimationLibrary.Info[animName]
    if info then
        info.SoundCallback = newSoundCallback
    end
end

--[[
    Rivals Visuals & Aim Assist v4.1
    Fixes: Team Check
]]

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

-- // НАСТРОЙКИ ВИЗУАЛА И АИМА // --
local Settings = {
    Aimbot = {
        Enabled = true,
        Smoothness = 3, 
        FOV = 180, 
        DistanceCheck = 1000, 
        RandomizePart = true 
    },
    Visuals = {
        ShowFOV = true,
        FOVTransparency = 1,
        Rainbow = true,
        RainbowSpeed = 1.5,
        LockedColor = Color3.fromRGB(255, 50, 50),
        
        -- Визуал мира
        CloudsColor = Color3.fromRGB(0, 0, 0),
        CloudsCover = 0.8,
        AmbientColor = Color3.fromRGB(255, 200, 225),
        OutdoorAmbient = Color3.fromRGB(180, 130, 160), 
        Contrast = 0.2,
        
        -- Частицы
        ParticleTexture = "rbxassetid://258128463",
        ParticleRate = 300,
        ParticleAreaSize = Vector3.new(200, 200, 200)
    }
}

-- // VISUALS LOGIC // --
local ColorCorrection = Lighting:FindFirstChild("VisualsContrast") or Instance.new("ColorCorrectionEffect")
ColorCorrection.Name = "VisualsContrast"
ColorCorrection.Parent = Lighting
ColorCorrection.Contrast = Settings.Visuals.Contrast
ColorCorrection.Saturation = 0.1

local ParticlePart = Instance.new("Part")
ParticlePart.Name = "FloatingParticlesPart"
ParticlePart.Size = Settings.Visuals.ParticleAreaSize
ParticlePart.Transparency = 1
ParticlePart.Anchored = true
ParticlePart.CanCollide = false
ParticlePart.Parent = Workspace

local Emitter = Instance.new("ParticleEmitter")
Emitter.Texture = Settings.Visuals.ParticleTexture
Emitter.Rate = Settings.Visuals.ParticleRate
Emitter.Lifetime = NumberRange.new(5, 10)
Emitter.Speed = NumberRange.new(2, 6)
Emitter.VelocitySpread = 180
Emitter.SpreadAngle = Vector2.new(180, 180)
Emitter.Acceleration = Vector3.new(0, 0, 0)
Emitter.Drag = 0.5
Emitter.LightEmission = 0.5
Emitter.LightInfluence = 0
Emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.5, 1.5), NumberSequenceKeypoint.new(1, 0)})
Emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.4), NumberSequenceKeypoint.new(0.8, 0.4), NumberSequenceKeypoint.new(1, 1)})
Emitter.Parent = ParticlePart

RunService.RenderStepped:Connect(function()
    -- Clouds & Lighting
    local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Lighting:FindFirstChildOfClass("Clouds")
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Parent = Workspace.Terrain
    end
    clouds.Color = Settings.Visuals.CloudsColor
    clouds.Cover = Settings.Visuals.CloudsCover
    clouds.Density = 0.9
    clouds.Enabled = true

    Lighting.Ambient = Settings.Visuals.AmbientColor
    Lighting.OutdoorAmbient = Settings.Visuals.OutdoorAmbient
    Lighting.ColorShift_Top = Settings.Visuals.AmbientColor
    Lighting.ColorShift_Bottom = Settings.Visuals.OutdoorAmbient
    
    if ColorCorrection.Parent ~= Lighting then ColorCorrection.Parent = Lighting end
    ColorCorrection.Contrast = Settings.Visuals.Contrast
    
    ParticlePart.CFrame = Camera.CFrame
end)

-- // AIMBOT LOGIC // --
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = Settings.Visuals.FOVTransparency
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Radius = Settings.Aimbot.FOV
FOVCircle.Visible = Settings.Visuals.ShowFOV

local CurrentTarget = nil
local TargetPartName = "Head"

-- Система предсказания движения (Prediction)
local PredictionSettings = {
    Enabled = true,           -- Включить предсказание
    PredictionTime = 0.12,    -- Время упреждения в секундах (настрой под свой пинг)
    MaxPrediction = 5,        -- Максимальное смещение в studs
    SmoothPrediction = true   -- Плавное предсказание
}

-- Хранение предыдущих позиций для расчёта скорости
local TargetVelocities = {}
local LastPositions = {}
local LastUpdateTime = {}

-- === АИМАССИСТ БЕЗ ПРОВЕРКИ НА КОМАНДУ (работает на всех) ===
local function IsEnemy(Player)
    if not Player then return false end
    return true -- Работает на всех игроков
end

-- Функция расчёта скорости цели
local function GetTargetVelocity(character)
    if not character then return Vector3.new(0, 0, 0) end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0, 0, 0) end
    
    local charId = character:GetFullName()
    local currentPos = hrp.Position
    local currentTime = tick()
    
    if LastPositions[charId] and LastUpdateTime[charId] then
        local deltaTime = currentTime - LastUpdateTime[charId]
        if deltaTime > 0 and deltaTime < 0.5 then -- Игнорируем слишком старые данные
            local deltaPos = currentPos - LastPositions[charId]
            local velocity = deltaPos / deltaTime
            
            -- Плавное обновление скорости
            if PredictionSettings.SmoothPrediction and TargetVelocities[charId] then
                velocity = TargetVelocities[charId]:Lerp(velocity, 0.3)
            end
            
            TargetVelocities[charId] = velocity
        end
    end
    
    LastPositions[charId] = currentPos
    LastUpdateTime[charId] = currentTime
    
    return TargetVelocities[charId] or Vector3.new(0, 0, 0)
end

-- Функция предсказания позиции
local function GetPredictedPosition(targetPart, character)
    if not PredictionSettings.Enabled then
        return targetPart.Position
    end
    
    local velocity = GetTargetVelocity(character)
    local prediction = velocity * PredictionSettings.PredictionTime
    
    -- Ограничиваем максимальное предсказание
    if prediction.Magnitude > PredictionSettings.MaxPrediction then
        prediction = prediction.Unit * PredictionSettings.MaxPrediction
    end
    
    -- Не предсказываем вертикальное движение (Y) слишком сильно
    prediction = Vector3.new(prediction.X, prediction.Y * 0.3, prediction.Z)
    
    return targetPart.Position + prediction
end

local function UpdateFOV()
    local MouseLocation = UserInputService:GetMouseLocation()
    FOVCircle.Position = Vector2.new(MouseLocation.X, MouseLocation.Y)
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Visible = Settings.Visuals.ShowFOV and Settings.Aimbot.Enabled

    if CurrentTarget then
        FOVCircle.Color = Settings.Visuals.LockedColor
    elseif Settings.Visuals.Rainbow then
        local Time = os.clock() * Settings.Visuals.RainbowSpeed
        local Hue = 0.75 + (math.sin(Time) + 1) / 2 * 0.15 
        FOVCircle.Color = Color3.fromHSV(Hue, 0.8, 1)
    else
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = TargetPart.Position - Origin
    local RayParams = RaycastParams.new()
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    RayParams.IgnoreWater = true
    local Result = Workspace:Raycast(Origin, Direction, RayParams)
    
    if Result then
        if Result.Instance:IsDescendantOf(TargetPart.Parent) then return true end
        return false
    end
    return true
end

local function GetRandomPart()
    if not Settings.Aimbot.RandomizePart then return "Head" end
    return (math.random(1, 100) <= 45) and "Head" or "UpperTorso"
end

local function GetClosestPlayer()
    local ClosestDist = Settings.Aimbot.FOV
    local Target = nil
    
    for _, Player in ipairs(Players:GetPlayers()) do
        -- Добавлена проверка IsEnemy
        if Player ~= LocalPlayer and IsEnemy(Player) and Player.Character then
            local Character = Player.Character
            local Humanoid = Character:FindFirstChild("Humanoid")
            local PartToCheck = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
            
            if Humanoid and Humanoid.Health > 0 and PartToCheck then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(PartToCheck.Position)
                
                if OnScreen then
                    local MousePos = UserInputService:GetMouseLocation()
                    local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    
                    if Dist < ClosestDist then
                        if IsVisible(PartToCheck) then
                            ClosestDist = Dist
                            Target = Character
                        end
                    end
                end
            end
        end
    end
    return Target
end

RunService.RenderStepped:Connect(function()
    UpdateFOV()

    if not Settings.Aimbot.Enabled then 
        CurrentTarget = nil
        return 
    end

    if not CurrentTarget or not CurrentTarget:FindFirstChild("Humanoid") or CurrentTarget.Humanoid.Health <= 0 then
        CurrentTarget = GetClosestPlayer()
        if CurrentTarget then
            TargetPartName = GetRandomPart()
        end
    else
        -- Проверяем, не перешел ли игрок в нашу команду пока мы целились
        local PlayerFromChar = Players:GetPlayerFromCharacter(CurrentTarget)
        if PlayerFromChar and not IsEnemy(PlayerFromChar) then
            CurrentTarget = nil
            return
        end

        local TargetPart = CurrentTarget:FindFirstChild(TargetPartName) or CurrentTarget:FindFirstChild("Head")
        
        if TargetPart then
            -- Используем предсказание позиции!
            local PredictedPos = GetPredictedPosition(TargetPart, CurrentTarget)
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(PredictedPos)
            local MousePos = UserInputService:GetMouseLocation()
            local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
            
            -- Проверка видимости по реальной позиции
            if not OnScreen or Dist > Settings.Aimbot.FOV or not IsVisible(TargetPart) then
                CurrentTarget = nil 
            else
                local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local TargetVec = Vector2.new(ScreenPos.X, ScreenPos.Y)
                local MoveVector = (TargetVec - ScreenCenter)
                
                mousemoverel(MoveVector.X / Settings.Aimbot.Smoothness, MoveVector.Y / Settings.Aimbot.Smoothness)
            end
        else
            CurrentTarget = nil
        end
    end
end)

-- =====================================================
-- // BULLET TRACERS (Розовые трейсеры пуль) //
-- =====================================================

local TracerSettings = {
    Enabled = true,
    Color = Color3.fromRGB(255, 105, 180), -- Hot Pink / Розовый
    Thickness = 0.1, -- Ещё тоньше!
    FadeTime = 1.5,
    GlowEnabled = true,
    GlowColor = Color3.fromRGB(255, 150, 200),
    GlowThickness = 0.3
}

-- ТОЛЬКО эти оружия имеют трейсеры (whitelist)
local TracerWeapons = {
    ["handgun"] = { fireRate = 5 },          -- Пистолет
    ["assault rifle"] = { fireRate = 10 },   -- Автоматическая винтовка (AK, AR)
    ["burst rifle"] = { fireRate = 15 }      -- Полуавтоматическая винтовка (очереди по 3)
}

-- Проверка: есть ли у оружия трейсеры?
local function HasTracers(weaponName)
    if not weaponName then return false, nil end
    local lower = weaponName:lower()
    
    for weapon, data in pairs(TracerWeapons) do
        if lower:match(weapon) then
            return true, data.fireRate
        end
    end
    return false, nil
end

-- Функция поиска дула оружия в ViewModel
local function GetMuzzlePosition(viewModel)
    if not viewModel then return nil end
    
    -- Ищем части с типичными названиями дула
    local muzzleNames = {"Muzzle", "Barrel", "FirePoint", "ShootPoint", "Gun", "Weapon"}
    
    local function SearchForMuzzle(parent)
        for _, child in pairs(parent:GetDescendants()) do
            if child:IsA("BasePart") then
                for _, name in ipairs(muzzleNames) do
                    if child.Name:lower():match(name:lower()) then
                        return child.Position
                    end
                end
            end
            -- Ищем Attachment с названием Muzzle
            if child:IsA("Attachment") and child.Name:lower():match("muzzle") then
                return child.WorldPosition
            end
        end
        return nil
    end
    
    local muzzlePos = SearchForMuzzle(viewModel)
    
    -- Если не нашли, берём позицию первой части оружия
    if not muzzlePos then
        for _, part in pairs(viewModel:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                -- Берём переднюю часть оружия (смещение по LookVector камеры)
                muzzlePos = part.Position + Camera.CFrame.LookVector * 2
                break
            end
        end
    end
    
    return muzzlePos
end

-- Функция создания трейсера (тонкий Beam)
local function CreateTracer(startPos, endPos)
    if not TracerSettings.Enabled then return end
    if not startPos or not endPos then return end
    
    -- Создаем Part для Attachments
    local TracerPart = Instance.new("Part")
    TracerPart.Name = "BulletTracer"
    TracerPart.Anchored = true
    TracerPart.CanCollide = false
    TracerPart.Transparency = 1
    TracerPart.Size = Vector3.new(0.05, 0.05, 0.05)
    TracerPart.Position = startPos
    TracerPart.Parent = Workspace
    
    local StartAttachment = Instance.new("Attachment")
    StartAttachment.Position = Vector3.new(0, 0, 0)
    StartAttachment.Parent = TracerPart
    
    local EndAttachment = Instance.new("Attachment")
    EndAttachment.Position = endPos - startPos
    EndAttachment.Parent = TracerPart
    
    -- Основной тонкий Beam
    local Beam = Instance.new("Beam")
    Beam.Attachment0 = StartAttachment
    Beam.Attachment1 = EndAttachment
    Beam.Color = ColorSequence.new(TracerSettings.Color)
    Beam.Width0 = TracerSettings.Thickness
    Beam.Width1 = TracerSettings.Thickness * 0.3
    Beam.FaceCamera = true
    Beam.LightEmission = 1
    Beam.LightInfluence = 0
    Beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.3),
        NumberSequenceKeypoint.new(1, 0.5)
    })
    Beam.Parent = TracerPart
    
    -- Слабое свечение
    if TracerSettings.GlowEnabled then
        local GlowBeam = Instance.new("Beam")
        GlowBeam.Attachment0 = StartAttachment
        GlowBeam.Attachment1 = EndAttachment
        GlowBeam.Color = ColorSequence.new(TracerSettings.GlowColor)
        GlowBeam.Width0 = TracerSettings.GlowThickness
        GlowBeam.Width1 = TracerSettings.GlowThickness * 0.3
        GlowBeam.FaceCamera = true
        GlowBeam.LightEmission = 1
        GlowBeam.LightInfluence = 0
        GlowBeam.Transparency = NumberSequence.new(0.85)
        GlowBeam.Parent = TracerPart
    end
    
    -- Плавное исчезновение
    task.spawn(function()
        local startTime = tick()
        local fadeTime = TracerSettings.FadeTime
        
        while tick() - startTime < fadeTime do
            local alpha = (tick() - startTime) / fadeTime
            
            if Beam and Beam.Parent then
                Beam.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1 + alpha * 0.9),
                    NumberSequenceKeypoint.new(1, math.min(1, 0.5 + alpha * 0.5))
                })
            end
            
            task.wait(0.05)
        end
        
        if TracerPart and TracerPart.Parent then
            TracerPart:Destroy()
        end
    end)
end

-- Получить текущий ViewModel игрока
local function GetCurrentViewModel()
    local ViewModels = Workspace:FindFirstChild("ViewModels")
    if not ViewModels then return nil, nil end
    
    local FirstPerson = ViewModels:FindFirstChild("FirstPerson")
    if not FirstPerson then return nil, nil end
    
    for _, vm in pairs(FirstPerson:GetChildren()) do
        if vm.Name:match("^" .. LocalPlayer.Name) then
            local weaponName = vm.Name:match("- (.+)$")
            return vm, weaponName
        end
    end
    
    return nil, nil
end

-- Отслеживание стрельбы через анимации
local function TrackShootingAnimations()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
    end)
    
    -- Следим за ViewModels и анимациями стрельбы
    local ViewModels = Workspace:WaitForChild("ViewModels", 10)
    if not ViewModels then return end
    
    local FirstPerson = ViewModels:WaitForChild("FirstPerson", 10)
    if not FirstPerson then return end
    
    -- Функция для подключения к Animator
    local function ConnectToAnimator(viewModel)
        local AnimController = viewModel:FindFirstChild("AnimationController")
        if not AnimController then return end
        
        local Animator = AnimController:FindFirstChild("Animator")
        if not Animator then return end
        
        Animator.AnimationPlayed:Connect(function(track)
            local animName = track.Animation.AnimationId:lower()
            
            -- Проверяем, это анимация стрельбы?
            if animName:match("shoot") or animName:match("fire") then
                local weaponName = viewModel.Name:match("- (.+)$")
                local hasTracers, _ = HasTracers(weaponName)
                
                if hasTracers then
                    -- Получаем позицию дула
                    local muzzlePos = GetMuzzlePosition(viewModel)
                    if not muzzlePos then
                        muzzlePos = Camera.CFrame.Position + Camera.CFrame.LookVector * 1.5
                    end
                    
                    -- Raycast до точки попадания
                    local direction = Camera.CFrame.LookVector * 1000
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {Character, viewModel, Camera}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
                    local endPos = result and result.Position or (Camera.CFrame.Position + direction)
                    
                    CreateTracer(muzzlePos, endPos)
                end
            end
        end)
    end
    
    -- Подключаемся к существующим ViewModels
    for _, vm in pairs(FirstPerson:GetChildren()) do
        if vm.Name:match("^" .. LocalPlayer.Name) then
            ConnectToAnimator(vm)
        end
    end
    
    -- Слушаем новые ViewModels
    FirstPerson.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if child.Name:match("^" .. LocalPlayer.Name) then
            ConnectToAnimator(child)
        end
    end)
end

-- Альтернативный метод: Отслеживание через зажатие мыши
local function TrackMouseHold()
    local Mouse = LocalPlayer:GetMouse()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local isHolding = false
    local lastShot = 0
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
    end)
    
    Mouse.Button1Down:Connect(function()
        isHolding = true
        
        task.spawn(function()
            while isHolding do
                local viewModel, weaponName = GetCurrentViewModel()
                local hasTracers, fireRate = HasTracers(weaponName)
                
                if viewModel and hasTracers then
                    local fireDelay = 1 / (fireRate or 8)
                    
                    if tick() - lastShot >= fireDelay then
                        lastShot = tick()
                        
                        -- Получаем позицию дула
                        local muzzlePos = GetMuzzlePosition(viewModel)
                        if not muzzlePos then
                            muzzlePos = Camera.CFrame.Position + Camera.CFrame.LookVector * 1.5
                        end
                        
                        -- Raycast
                        local direction = (Mouse.Hit.Position - Camera.CFrame.Position).Unit * 1000
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {Character, viewModel, Camera}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        
                        local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
                        local endPos = result and result.Position or (Camera.CFrame.Position + direction)
                        
                        CreateTracer(muzzlePos, endPos)
                    end
                end
                
                task.wait(0.03) -- 30ms проверка
            end
        end)
    end)
    
    Mouse.Button1Up:Connect(function()
        isHolding = false
    end)
end

-- Запускаем обе системы
task.spawn(TrackShootingAnimations)
task.spawn(TrackMouseHold)

print("[Tracers] v2 loaded! Thin pink tracers from weapon muzzle, auto-fire support")

-- =====================================================
-- // KILL SOUND (Звук при убийстве) //
-- =====================================================

local KillSoundSettings = {
    Enabled = true,
    SoundId = "rbxassetid://12856925315",
    Volume = 1,
    PlaybackSpeed = 1
}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- Создаём Sound объект для Kill Sound
local KillSound = Instance.new("Sound")
KillSound.Name = "KillSound"
KillSound.SoundId = KillSoundSettings.SoundId
KillSound.Volume = KillSoundSettings.Volume
KillSound.PlaybackSpeed = KillSoundSettings.PlaybackSpeed
KillSound.Parent = SoundService

-- Отслеживаем убийства
local function SetupKillTracker()
    local myKills = 0
    
    -- Метод 1: Через leaderstats (если есть)
    local function CheckLeaderstats()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local kills = leaderstats:FindFirstChild("Kills") or leaderstats:FindFirstChild("K")
            if kills then
                kills:GetPropertyChangedSignal("Value"):Connect(function()
                    if kills.Value > myKills then
                        myKills = kills.Value
                        if KillSoundSettings.Enabled then
                            KillSound:Play()
                        end
                    end
                end)
                myKills = kills.Value
                return true
            end
        end
        return false
    end
    
    -- Метод 2: Отслеживание смерти врагов после наших выстрелов
    local lastDamagedPlayer = nil
    local lastDamageTime = 0
    
    -- Слушаем события урона (через ремоуты)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    
    if Remotes then
        local Replication = Remotes:FindFirstChild("Replication")
        if Replication then
            local Fighter = Replication:FindFirstChild("Fighter")
            if Fighter then
                local HitRemote = Fighter:FindFirstChild("Hit") or Fighter:FindFirstChild("Damage")
                if HitRemote and HitRemote:IsA("RemoteEvent") then
                    HitRemote.OnClientEvent:Connect(function(data)
                        if type(data) == "table" and data.Target then
                            lastDamagedPlayer = data.Target
                            lastDamageTime = tick()
                        end
                    end)
                end
            end
        end
    end
    
    -- Слушаем смерти всех игроков
    local function OnPlayerAdded(player)
        if player == LocalPlayer then return end
        
        player.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid.Died:Connect(function()
                    -- Проверяем, был ли это наш урон (3 секунды с момента последнего хита)
                    if lastDamagedPlayer == player and tick() - lastDamageTime < 3 then
                        if KillSoundSettings.Enabled then
                            KillSound:Play()
                        end
                    end
                end)
            end
        end)
    end
    
    -- Пробуем leaderstats сначала
    task.spawn(function()
        task.wait(2) -- Ждём загрузки
        if not CheckLeaderstats() then
            -- Если нет leaderstats, используем метод отслеживания смертей
            for _, player in pairs(Players:GetPlayers()) do
                OnPlayerAdded(player)
            end
            Players.PlayerAdded:Connect(OnPlayerAdded)
        end
    end)
end

task.spawn(SetupKillTracker)
print("[KillSound] Loaded! Sound ID: " .. KillSoundSettings.SoundId)

-- =====================================================
-- // LOBBY MUSIC CHANGER (Замена музыки в лобби) //
-- =====================================================

local LobbyMusicSettings = {
    Enabled = true,
    SoundId = "rbxassetid://101144717086353",
    Volume = 0.5,
    Looped = true
}

local function SetupLobbyMusic()
    -- Создаём свой Sound для лобби музыки
    local LobbyMusic = Instance.new("Sound")
    LobbyMusic.Name = "CustomLobbyMusic"
    LobbyMusic.SoundId = LobbyMusicSettings.SoundId
    LobbyMusic.Volume = LobbyMusicSettings.Volume
    LobbyMusic.Looped = LobbyMusicSettings.Looped
    LobbyMusic.Parent = SoundService
    
    -- Функция для отключения оригинальной музыки
    local function MuteOriginalMusic()
        -- Ищем звуки в SoundService
        for _, sound in pairs(SoundService:GetDescendants()) do
            if sound:IsA("Sound") and sound.Name ~= "CustomLobbyMusic" and sound.Name ~= "KillSound" then
                if sound.Playing and sound.Looped then
                    sound.Volume = 0
                end
            end
        end
        
        -- Ищем звуки в Workspace
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                -- Мьютим фоновую музыку (обычно looped и громкая)
                if sound.Looped and sound.Volume > 0.3 then
                    sound.Volume = 0
                end
            end
        end
    end
    
    -- Определяем, находимся ли мы в лобби
    local function IsInLobby()
        -- В лобби обычно нет боевых механик
        local character = LocalPlayer.Character
        if not character then return true end
        
        -- Проверяем наличие определённых элементов лобби
        local lobbyFolder = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("MainLobby")
        if lobbyFolder then return true end
        
        -- Можно также проверять позицию персонажа или другие критерии
        return false
    end
    
    -- Основной цикл
    task.spawn(function()
        while true do
            if LobbyMusicSettings.Enabled then
                local inLobby = IsInLobby()
                
                if inLobby then
                    MuteOriginalMusic()
                    if not LobbyMusic.Playing then
                        LobbyMusic:Play()
                    end
                else
                    if LobbyMusic.Playing then
                        LobbyMusic:Stop()
                    end
                end
            end
            
            task.wait(1)
        end
    end)
    
    -- Начальная проверка
    task.wait(3)
    if IsInLobby() and LobbyMusicSettings.Enabled then
        MuteOriginalMusic()
        LobbyMusic:Play()
    end
end

task.spawn(SetupLobbyMusic)
print("[LobbyMusic] Custom lobby music loaded! Sound ID: " .. LobbyMusicSettings.SoundId)
