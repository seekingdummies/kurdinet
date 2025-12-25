local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Table to store player data
local playerData = {}
local deathCount = {}
local respawnCount = {}

-- Callbacks for custom events
local onPlayerDeath = function(player, character) end
local onPlayerRespawn = function(player, character) end

-- Function to get all current players
local function getPlayers()
    local plrs = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(plrs, p)
        end
    end
    return plrs
end

-- Function to get a player's character
local function getCharacter(player)
    if player == LocalPlayer then return nil end
    return player.Character
end

-- Function to handle character spawning
local function onCharacterAdded(player, character)
    if player == LocalPlayer then return end
    
    print(player.Name .. " spawned")
    playerData[player.UserId].Character = character
    playerData[player.UserId].IsAlive = true
    
    respawnCount[player.UserId] = (respawnCount[player.UserId] or 0) + 1
    
    -- Wait for character to load fully
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end
    
    -- Call custom respawn callback
    pcall(function()
        onPlayerRespawn(player, character)
    end)
    
    -- Handle character death
    humanoid.Died:Connect(function()
        if player == LocalPlayer then return end
        
        print(player.Name .. " died")
        deathCount[player.UserId] = (deathCount[player.UserId] or 0) + 1
        playerData[player.UserId].IsAlive = false
        playerData[player.UserId].LastDeathTime = tick()
        
        -- Call custom death callback
        pcall(function()
            onPlayerDeath(player, character)
        end)
    end)
end

-- PlayerAdded event
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    
    print(player.Name .. " joined")
    
    -- Initialize player data
    playerData[player.UserId] = {
        Player = player,
        Character = nil,
        IsAlive = false,
        LastDeathTime = 0
    }
    deathCount[player.UserId] = 0
    respawnCount[player.UserId] = 0
    
    -- Handle current character if it exists
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
    
    -- Handle future character spawns
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
end)

-- PlayerRemoving event
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then return end
    
    print(player.Name .. " left")
    
    -- Clean up player data
    playerData[player.UserId] = nil
    deathCount[player.UserId] = nil
    respawnCount[player.UserId] = nil
end)

-- Initialize for players already in game (excluding LocalPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        playerData[player.UserId] = {
            Player = player,
            Character = player.Character,
            IsAlive = player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 or false,
            LastDeathTime = 0
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

-- Utility functions
local function getAllPlayerCharacters()
    local chars = {}
    for userId, data in pairs(playerData) do
        if data.Character and data.IsAlive then
            table.insert(chars, data.Character)
        end
    end
    return chars
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

-- Set custom event callbacks
local function setDeathCallback(callback)
    onPlayerDeath = callback
end

local function setRespawnCallback(callback)
    onPlayerRespawn = callback
end

print('[plrmanager] initialized')

-- Return API
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
    respawnCount = respawnCount
}
