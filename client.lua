-- Averion Client v4 (Self-Only Version)
-- Sistema focado em funções para o próprio usuário

-- ===== SERVICES =====
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')
local TextChatService = game:GetService('TextChatService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

-- ===== EXECUTOR HTTP =====
local http = http_request or syn.request or request
assert(http, 'HTTP executor não encontrado')

-- ===== EXECUTOR ID =====
getgenv().AVERION_EXECUTOR_ID = '{_currentExecutorId}'
local EXECUTOR_ID = getgenv().AVERION_EXECUTOR_ID
local BASE = 'https://averiondashboard-default-rtdb.firebaseio.com/executors/' .. EXECUTOR_ID

-- ===== LIMPA SESSÃO ANTIGA =====
pcall(function()
    http({
        Url = BASE .. '.json',
        Method = 'DELETE'
    })
end)

-- ===== HTTP HELPERS =====
local function httpPut(path, data)
    return http({
        Url = BASE .. path .. '.json',
        Method = 'PUT',
        Headers = {['Content-Type'] = 'application/json'},
        Body = HttpService:JSONEncode(data)
    })
end

local function httpPost(path, data)
    return http({
        Url = BASE .. path .. '.json',
        Method = 'POST',
        Headers = {['Content-Type'] = 'application/json'},
        Body = HttpService:JSONEncode(data)
    })
end

local function httpGet(path)
    return http({
        Url = BASE .. path .. '.json',
        Method = 'GET'
    })
end

-- ===== LOG =====
local function sendLog(msg, type)
    pcall(function()
        httpPost('/logs', {
            msg = msg,
            type = type or 'info',
            ts = os.time()
        })
    })
end

-- ===== HEARTBEAT =====
task.spawn(function()
    while true do
        pcall(function()
            httpPut('/status', {
                state = 'online',
                ts = os.time()
            })
        end)
        task.wait(5)
    end
end)

-- ===== PLAYER INFO SYNC =====
local function updateSelfInfo()
    local localPlayer = Players.LocalPlayer
    
    pcall(function()
        local char = localPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        local humanoid = char and char:FindFirstChildOfClass('Humanoid')
        
        local data = {
            Name = localPlayer.Name,
            DisplayName = localPlayer.DisplayName,
            UserId = localPlayer.UserId,
            AccountAge = localPlayer.AccountAge,
            Position = hrp and string.format('%.1f, %.1f, %.1f', 
                hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or '-',
            Health = humanoid and humanoid.Health or 0,
            MaxHealth = humanoid and humanoid.MaxHealth or 100,
            Team = localPlayer.Team and localPlayer.Team.Name or 'No Team',
            GameId = game.GameId,
            PlaceId = game.PlaceId,
            JobId = game.JobId
        }
        
        httpPut('/selfInfo', data)
    })
end

-- Update info every 2 seconds
task.spawn(function()
    while true do
        updateSelfInfo()
        task.wait(2)
    end
end)

-- ===== ATIVE FUNCTIONS (SELF-ONLY) =====
local activeFunctions = {
    esp = false,
    noclip = false,
    speed = false,
    fly = false,
    xray = false,
    aimbot = false,
    godmode = false,
    infiniteJump = false,
    antiAfk = false,
    autoFarm = false
}

local connections = {}

-- ===== FUNCTIONS IMPLEMENTATION =====

-- ESP (Only for yourself to see others)
local espHighlights = {}
local function startESP()
    activeFunctions.esp = true
    
    local function createESP(player)
        if player == Players.LocalPlayer then return end
        if not player.Character then return end
        
        local highlight = Instance.new('Highlight')
        highlight.Parent = player.Character
        highlight.Name = 'AverionESP'
        highlight.FillColor = Color3.fromRGB(255, 0, 60)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        espHighlights[player] = highlight
        
        -- Listen for character changes
        player.CharacterAdded:Connect(function(char)
            task.wait(1)
            if activeFunctions.esp then
                local newHighlight = Instance.new('Highlight')
                newHighlight.Parent = char
                newHighlight.Name = 'AverionESP'
                newHighlight.FillColor = Color3.fromRGB(255, 0, 60)
                newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                newHighlight.FillTransparency = 0.5
                newHighlight.OutlineTransparency = 0
                espHighlights[player] = newHighlight
            end
        end)
    end
    
    -- Create ESP for existing players
    for _, player in pairs(Players:GetPlayers()) do
        createESP(player)
    end
    
    -- Listen for new players
    connections.esp = {
        Players.PlayerAdded:Connect(function(player)
            createESP(player)
        end),
        
        Players.PlayerRemoving:Connect(function(player)
            if espHighlights[player] then
                espHighlights[player]:Destroy()
                espHighlights[player] = nil
            end
        end)
    }
    
    sendLog('👁️ ESP ativado (vê outros players)', 'success')
end

local function stopESP()
    activeFunctions.esp = false
    
    for player, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    espHighlights = {}
    
    if connections.esp then
        for _, conn in pairs(connections.esp) do
            conn:Disconnect()
        end
        connections.esp = nil
    end
    
    sendLog('👁️ ESP desativado', 'info')
end

-- NoClip (Walk through walls)
local function startNoClip()
    activeFunctions.noclip = true
    local localPlayer = Players.LocalPlayer
    
    connections.noclip = RunService.Stepped:Connect(function()
        if not activeFunctions.noclip or not localPlayer.Character then
            return
        end
        
        for _, part in pairs(localPlayer.Character:GetDescendants()) do
            if part:IsA('BasePart') then
                part.CanCollide = false
            end
        end
    end)
    
    sendLog('🚶 NoClip ativado (atravessa paredes)', 'success')
end

local function stopNoClip()
    activeFunctions.noclip = false
    
    if connections.noclip then
        connections.noclip:Disconnect()
        connections.noclip = nil
    end
    
    local localPlayer = Players.LocalPlayer
    if localPlayer.Character then
        for _, part in pairs(localPlayer.Character:GetDescendants()) do
            if part:IsA('BasePart') then
                part.CanCollide = true
            end
        end
    end
    
    sendLog('🚶 NoClip desativado', 'info')
end

-- Speed Hack
local originalWalkSpeed = 16
local function startSpeed(multiplier)
    multiplier = multiplier or 6
    activeFunctions.speed = true
    local localPlayer = Players.LocalPlayer
    
    connections.speed = RunService.Heartbeat:Connect(function()
        if not activeFunctions.speed or not localPlayer.Character then
            return
        end
        
        local humanoid = localPlayer.Character:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.WalkSpeed = originalWalkSpeed * multiplier
        end
    end)
    
    sendLog('⚡ Speed hack ativado (velocidade ' .. multiplier .. 'x)', 'success')
end

local function stopSpeed()
    activeFunctions.speed = false
    
    if connections.speed then
        connections.speed:Disconnect()
        connections.speed = nil
    end
    
    local localPlayer = Players.LocalPlayer
    if localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end
    
    sendLog('⚡ Speed hack desativado', 'info')
end

-- Fly
local function startFly()
    activeFunctions.fly = true
    local localPlayer = Players.LocalPlayer
    
    local bodyVelocity
    local flySpeed = 50
    
    -- Create BodyVelocity for flying
    local function setupFly()
        local character = localPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild('HumanoidRootPart')
        if not rootPart then return end
        
        bodyVelocity = Instance.new('BodyVelocity')
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
        bodyVelocity.P = 1000
        bodyVelocity.Parent = rootPart
    end
    
    -- Initial setup
    setupFly()
    
    -- Re-setup on respawn
    connections.flyRespawn = localPlayer.CharacterAdded:Connect(setupFly)
    
    -- Fly control
    connections.fly = RunService.Heartbeat:Connect(function()
        if not activeFunctions.fly or not localPlayer.Character then
            return
        end
        
        if not bodyVelocity or not bodyVelocity.Parent then
            setupFly()
            if not bodyVelocity then return end
        end
        
        -- Get camera vectors
        local camera = Workspace.CurrentCamera
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        
        -- Movement direction
        local direction = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        -- Apply velocity
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeed
        end
        
        bodyVelocity.Velocity = direction
    end)
    
    sendLog('🦅 Fly ativado (WASD + Space/Shift)', 'success')
end

local function stopFly()
    activeFunctions.fly = false
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if connections.fly then
        connections.fly:Disconnect()
        connections.fly = nil
    end
    
    if connections.flyRespawn then
        connections.flyRespawn:Disconnect()
        connections.flyRespawn = nil
    end
    
    sendLog('🦅 Fly desativado', 'info')
end

-- X-Ray (See through walls)
local function startXRay()
    activeFunctions.xray = true
    
    -- Make all parts semi-transparent
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA('BasePart') and part.Transparency < 0.9 then
            part.LocalTransparencyModifier = 0.8
        end
    end
    
    -- Keep new parts transparent
    connections.xray = {
        Workspace.DescendantAdded:Connect(function(part)
            if activeFunctions.xray and part:IsA('BasePart') then
                part.LocalTransparencyModifier = 0.8
            end
        end)
    }
    
    sendLog('🔍 X-Ray ativado (ve através das paredes)', 'success')
end

local function stopXRay()
    activeFunctions.xray = false
    
    -- Restore normal transparency
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA('BasePart') then
            part.LocalTransparencyModifier = 0
        end
    end
    
    if connections.xray then
        for _, conn in pairs(connections.xray) do
            conn:Disconnect()
        end
        connections.xray = nil
    end
    
    sendLog('🔍 X-Ray desativado', 'info')
end

-- Infinite Jump
local function startInfiniteJump()
    activeFunctions.infiniteJump = true
    local localPlayer = Players.LocalPlayer
    
    connections.infiniteJump = UserInputService.JumpRequest:Connect(function()
        if activeFunctions.infiniteJump and localPlayer.Character then
            local humanoid = localPlayer.Character:FindFirstChildOfClass('Humanoid')
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    
    sendLog('🦘 Infinite Jump ativado', 'success')
end

local function stopInfiniteJump()
    activeFunctions.infiniteJump = false
    
    if connections.infiniteJump then
        connections.infiniteJump:Disconnect()
        connections.infiniteJump = nil
    end
    
    sendLog('🦘 Infinite Jump desativado', 'info')
end

-- Anti-AFK
local function startAntiAFK()
    activeFunctions.antiAfk = true
    
    -- Prevent AFK by simulating input
    connections.antiAfk = RunService.Heartbeat:Connect(function()
        if activeFunctions.antiAfk then
            -- Simulate small camera movement
            local camera = Workspace.CurrentCamera
            if camera then
                camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(0.1), 0)
            end
        end
    end)
    
    sendLog('⏰ Anti-AFK ativado', 'success')
end

local function stopAntiAFK()
    activeFunctions.antiAfk = false
    
    if connections.antiAfk then
        connections.antiAfk:Disconnect()
        connections.antiAfk = nil
    end
    
    sendLog('⏰ Anti-AFK desativado', 'info')
end

-- Auto Click/Farm (if applicable)
local function startAutoClick()
    activeFunctions.autoFarm = true
    
    connections.autoFarm = RunService.Heartbeat:Connect(function()
        if not activeFunctions.autoFarm then return end
        
        -- This would need to be customized per game
        -- Example: Auto click if near an item
        local localPlayer = Players.LocalPlayer
        local character = localPlayer.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then return end
        
        -- This is a template - would need game-specific implementation
        -- For games with click-based farming
    end)
    
    sendLog('🤖 Auto Farm ativado (genérico)', 'success')
end

local function stopAutoClick()
    activeFunctions.autoFarm = false
    
    if connections.autoFarm then
        connections.autoFarm:Disconnect()
        connections.autoFarm = nil
    end
    
    sendLog('🤖 Auto Farm desativado', 'info')
end

-- ===== COMMAND PROCESSOR =====
local processed = {}

local function processCommand(id, cmd)
    if processed[id] then return end
    processed[id] = true
    
    sendLog('🎯 Comando recebido: ' .. (cmd.action or 'custom'), 'exec')
    
    if cmd.type == 'code' then
        -- Execute custom Lua code
        local func, err = loadstring(cmd.code)
        if func then
            local success, result = pcall(func)
            if success then
                sendLog('✅ Código executado com sucesso', 'success')
            else
                sendLog('❌ Erro na execução: ' .. tostring(result), 'error')
            end
        else
            sendLog('❌ Erro ao compilar: ' .. tostring(err), 'error')
        end
        
    elseif cmd.type == 'command' then
        local action = cmd.action
        local state = cmd.state or 'start'
        
        -- Self-only commands
        if action == 'esp' then
            if state == 'start' then
                startESP()
            else
                stopESP()
            end
            
        elseif action == 'noclip' then
            if state == 'start' then
                startNoClip()
            else
                stopNoClip()
            end
            
        elseif action == 'speed' then
            if state == 'start' then
                startSpeed(cmd.multiplier or 6)
            else
                stopSpeed()
            end
            
        elseif action == 'fly' then
            if state == 'start' then
                startFly()
            else
                stopFly()
            end
            
        elseif action == 'xray' then
            if state == 'start' then
                startXRay()
            else
                stopXRay()
            end
            
        elseif action == 'infiniteJump' then
            if state == 'start' then
                startInfiniteJump()
            else
                stopInfiniteJump()
            end
            
        elseif action == 'antiAfk' then
            if state == 'start' then
                startAntiAFK()
            else
                stopAntiAFK()
            end
            
        elseif action == 'autoFarm' then
            if state == 'start' then
                startAutoClick()
            else
                stopAutoClick()
            end
            
        elseif action == 'resetCharacter' then
            local localPlayer = Players.LocalPlayer
            local character = localPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass('Humanoid')
                if humanoid then
                    humanoid.Health = 0
                end
            end
            sendLog('🔄 Personagem resetado', 'success')
            
        elseif action == 'chat' then
            -- Send chat message using TextChatService
            local message = cmd.message or 'Mensagem do admin'
            local textChannel = TextChatService.TextChannels.RBXGeneral
            if textChannel then
                textChannel:SendAsync(message)
                sendLog('💬 Mensagem enviada: ' .. message, 'success')
            end
            
        elseif action == 'disconnect' then
            -- Disconnect from game
            if cmd.reason then
                sendLog('🚪 Desconectando: ' .. cmd.reason, 'warning')
            end
            wait(1)
            game:Shutdown()
            
        else
            sendLog('❌ Comando desconhecido: ' .. action, 'error')
        end
    end
end

-- ===== COMMAND LISTENER =====
task.spawn(function()
    while true do
        local res = httpGet('/commands')
        if res and res.Body and res.Body ~= 'null' then
            local decoded = HttpService:JSONDecode(res.Body)
            for id, cmd in pairs(decoded) do
                if not processed[id] and cmd.type then
                    task.spawn(function()
                        processCommand(id, cmd)
                    end)
                end
            end
        end
        task.wait(1)
    end
end)

-- ===== CHAT LOGGING =====
TextChatService.MessageReceived:Connect(function(msg)
    local textSource = msg.TextSource
    if textSource then
        local player = Players:GetPlayerByUserId(textSource.UserId)
        if player then
            sendLog('💬 ' .. player.Name .. ': ' .. msg.Text, 'chat')
        end
    end
end)

-- ===== CLEANUP =====
Players.LocalPlayer.CharacterRemoving:Connect(function()
    -- Stop all active functions
    for name, _ in pairs(activeFunctions) do
        if name == 'esp' then stopESP() end
        if name == 'noclip' then stopNoClip() end
        if name == 'speed' then stopSpeed() end
        if name == 'fly' then stopFly() end
        if name == 'xray' then stopXRay() end
        if name == 'infiniteJump' then stopInfiniteJump() end
        if name == 'antiAfk' then stopAntiAFK() end
        if name == 'autoFarm' then stopAutoClick() end
    end
end)

-- ===== INITIALIZE =====
sendLog('✅ Averion Client v4 (Self-Only) inicializado', 'success')

print([[
╔══════════════════════════════════════════╗
║     AVERION CLIENT v4 (SELF-ONLY)       ║
╠══════════════════════════════════════════╣
║ ✅ Sistema inicializado                  ║
║                                          ║
║ 🔑 Executor ID: ]] .. EXECUTOR_ID .. [[
║                                          ║
║ 🎮 FUNÇÕES DISPONÍVEIS:                 ║
║ 👁️  ESP - Ver outros jogadores          ║
║ 🚶 NoClip - Atravessar paredes          ║
║ ⚡ Speed - Aumentar velocidade           ║
║ 🦅 Fly - Voar livremente                ║
║ 🔍 X-Ray - Ver através das paredes      ║
║ 🦘 Infinite Jump - Pulo infinito        ║
║ ⏰ Anti-AFK - Evitar desconexão         ║
║ 🤖 Auto Farm (genérico)                 ║
║                                          ║
║ 💬 Chat via TextChatService             ║
║ 🔄 Reset Personagem                     ║
║ 🚪 Desconectar                          ║
╚══════════════════════════════════════════╝
]])
