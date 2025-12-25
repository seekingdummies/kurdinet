-- plrmanager.lua (updated)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- player data tables
local playerData = {}
local deathCount = {}
local respawnCount = {}

-- callbacks
local onPlayerDeath = function(player, character) end
local onPlayerRespawn = function(player, character) end

-- helper functions
local function getPlayers()
    local plrs = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(plrs, p)
        end
    end
    return plrs
end

local function getCharacter(player)
    return player.Character
end

local function checkForModel(character)
    if not character then return nil, false end
    local model = character:FindFirstChild("Model")
    if model then
        local hitbox = model:FindFirstChild("hitbox")
        return model, hitbox ~= nil
    end
    return nil, false
end

local function monitorModel(player, character)
    if not character then return end
    local data = playerData[player.UserId]
    if not data then return end

    local model, hasHitbox = checkForModel(character)
    data.HasModel = model ~= nil
    data.HasHitbox = hasHitbox
    data.Model = model

    character.ChildAdded:Connect(function(child)
        if child.Name == "Model" then
            local _, hitbox = checkForModel(character)
            data.HasModel = true
            data.HasHitbox = hitbox
            data.Model = child
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child.Name == "Model" then
            data.HasModel = false
            data.HasHitbox = false
            data.Model = nil
        end
    end)
    if model then
        model.ChildAdded:Connect(function(child)
            if child.Name == "hitbox" then
                data.HasHitbox = true
            end
        end)
        model.ChildRemoved:Connect(function(child)
            if child.Name == "hitbox" then
                data.HasHitbox = false
            end
        end)
    end
end

local function onCharacterAdded(player, character)
    local data = playerData[player.UserId]
    if not data then return end

    data.Character = character
    data.IsAlive = true
    data.HasModel = false
    data.HasHitbox = false
    data.Model = nil

    respawnCount[player.UserId] = (respawnCount[player.UserId] or 0) + 1

    -- wait for humanoid
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    monitorModel(player, character)

    pcall(function() onPlayerRespawn(player, character) end)

    humanoid.Died:Connect(function()
        data.IsAlive = false
        data.HasModel = false
        data.HasHitbox = false
        data.Model = nil
        deathCount[player.UserId] = (deathCount[player.UserId] or 0) + 1
        data.LastDeathTime = tick()
        pcall(function() onPlayerDeath(player, character) end)
    end)
end

-- player events
Players.PlayerAdded:Connect(function(player)
    playerData[player.UserId] = {
        Player = player,
        Character = player.Character,
        IsAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 or false,
        LastDeathTime = 0,
        HasModel = false,
        HasHitbox = false,
        Model = nil
    }
    deathCount[player.UserId] = 0
    respawnCount[player.UserId] = 0

    if player.Character then
        onCharacterAdded(player, player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player.UserId] = nil
    deathCount[player.UserId] = nil
    respawnCount[player.UserId] = nil
end)

-- initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        playerData[player.UserId] = {
            Player = player,
            Character = player.Character,
            IsAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 or false,
            LastDeathTime = 0,
            HasModel = false,
            HasHitbox = false,
            Model = nil
        }
        deathCount[player.UserId] = 0
        respawnCount[player.UserId] = 0

        if player.Character then
            onCharacterAdded(player, player.Character)
        end
        player.CharacterAdded:Connect(function(character)
            onCharacterAdded(player, character)
        end)
    end
end

-- utility functions
local function getAllPlayerCharacters()
    local chars = {}
    for _, data in pairs(playerData) do
        if data.Character and data.IsAlive then
            table.insert(chars, data.Character)
        end
    end
    return chars
end

local function getPlayersWithModel()
    local plrs = {}
    for _, data in pairs(playerData) do
        if data.HasModel and data.IsAlive then
            table.insert(plrs, data.Player)
        end
    end
    return plrs
end

local function getPlayersWithHitbox()
    local plrs = {}
    for _, data in pairs(playerData) do
        if data.HasHitbox and data.IsAlive then
            table.insert(plrs, data.Player)
        end
    end
    return plrs
end

local function hasModel(player)
    local data = playerData[player.UserId]
    return data and data.HasModel or false
end

local function hasHitbox(player)
    local data = playerData[player.UserId]
    return data and data.HasHitbox or false
end

local function getModel(player)
    local data = playerData[player.UserId]
    return data and data.Model or nil
end

local function getPlayerByName(name)
    for _, data in pairs(playerData) do
        if data.Player.Name == name then
            return data.Player, data.Character
        end
    end
    return nil
end

local function getDeathCount(player)
    return deathCount[player.UserId] or 0
end

local function getRespawnCount(player)
    return respawnCount[player.UserId] or 0
end

local function isPlayerAlive(player)
    local data = playerData[player.UserId]
    return data and data.IsAlive or false
end

-- callbacks
local function setDeathCallback(callback)
    onPlayerDeath = callback
end
local function setRespawnCallback(callback)
    onPlayerRespawn = callback
end

print("[plrmanager] patched and ready")

-- export
return {
    getPlayers = getPlayers,
    getCharacter = getCharacter,
    getAllPlayerCharacters = getAllPlayerCharacters,
    getPlayerByName = getPlayerByName,
    getDeathCount = getDeathCount,
    getRespawnCount = getRespawnCount,
    isPlayerAlive = isPlayerAlive,
    setDeathCallback = setDeathCallback,
    setRespawnCallback = setRespawnCallback,
    playerData = playerData,
    deathCount = deathCount,
    respawnCount = respawnCount,

    -- patched helpers
    hasModel = hasModel,
    hasHitbox = hasHitbox,
    getModel = getModel
}
