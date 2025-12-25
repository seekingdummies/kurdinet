local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Load player manager
local plrManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/seekingdummies/kurdinet/refs/heads/main/src/modules/plrmanager.lua"))()

-- Raycast parameters setup
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- Get origin from Model's ponto Attachment
local function getOrigin(model)
    local ponto = model:FindFirstChild("ponto")
    if not ponto then return nil end
    
    local attachment = ponto:FindFirstChildOfClass("Attachment")
    if not attachment then return nil end
    
    return attachment.WorldPosition
end

-- Get player's hitbox from their Model
local function getHitbox(player)
    if not plrManager.hasHitbox(player) then return nil end
    
    local model = plrManager.getModel(player)
    if not model then return nil end
    
    return model:FindFirstChild("hitbox")
end

-- Calculate direction between two points
local function getDirection(from, to)
    return (to - from).Unit
end

-- Perform raycast between origin and target
local function castRay(origin, direction, distance, ignoreList)
    rayParams.FilterDescendantsInstances = ignoreList or {}
    
    local ray = workspace:Raycast(origin, direction * distance, rayParams)
    return ray
end

-- Check if player has line of sight to target
local function hasLineOfSight(originPos, targetPos, ignoreList)
    local direction = getDirection(originPos, targetPos)
    local distance = (targetPos - originPos).Magnitude
    
    local ray = castRay(originPos, direction, distance, ignoreList)
    
    -- If no hit or hit is the target, we have LOS
    return ray == nil or ray.Distance >= distance - 0.1
end

-- Cast to specific player
local function castToPlayer(shooterModel, targetPlayer)
    if not plrManager.isPlayerAlive(targetPlayer) then 
        return nil 
    end
    
    if not plrManager.hasHitbox(targetPlayer) then 
        return nil 
    end
    
    local origin = getOrigin(shooterModel)
    if not origin then return nil end
    
    local hitbox = getHitbox(targetPlayer)
    if not hitbox then return nil end
    
    local targetPos = hitbox.Position
    local distance = (targetPos - origin).Magnitude
    local direction = getDirection(origin, targetPos)
    
    -- Ignore shooter's model and character
    local ignoreList = {shooterModel}
    
    local ray = castRay(origin, direction, distance, ignoreList)
    
    local clearShot = hasLineOfSight(origin, targetPos, ignoreList)
    
    return {
        Hit = ray ~= nil and ray.Instance == hitbox,
        Player = targetPlayer,
        Hitbox = hitbox,
        Distance = distance,
        ClearShot = clearShot,
        Position = targetPos,
        RayResult = ray
    }
end

-- Find nearest player with Model and hitbox
local function castToNearestPlayer(shooterModel)
    local origin = getOrigin(shooterModel)
    if not origin then return nil end
    
    local playersWithHitbox = plrManager.getPlayersWithHitbox()
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, player in ipairs(playersWithHitbox) do
        local hitbox = getHitbox(player)
        if hitbox then
            local dist = (hitbox.Position - origin).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = player
            end
        end
    end
    
    if nearest then
        return castToPlayer(shooterModel, nearest)
    end
    
    return nil
end

-- Get all valid targets (alive players with Model+hitbox)
local function getAllValidTargets()
    return plrManager.getPlayersWithHitbox()
end

-- Cast to all valid targets and return array of results
local function castToAllTargets(shooterModel)
    local targets = getAllValidTargets()
    local results = {}
    
    for _, player in ipairs(targets) do
        local result = castToPlayer(shooterModel, player)
        if result then
            table.insert(results, result)
        end
    end
    
    -- Sort by distance
    table.sort(results, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return results
end

-- Get closest target within FOV (field of view in degrees)
local function getClosestInFOV(shooterModel, lookDirection, fov)
    local origin = getOrigin(shooterModel)
    if not origin then return nil end
    
    local targets = castToAllTargets(shooterModel)
    local fovRad = math.rad(fov)
    
    for _, result in ipairs(targets) do
        local dirToTarget = getDirection(origin, result.Position)
        local angle = math.acos(lookDirection:Dot(dirToTarget))
        
        if angle <= fovRad / 2 then
            return result
        end
    end
    
    return nil
end

print('[raycast] initialized')

return {
    castToPlayer = castToPlayer,
    castToNearestPlayer = castToNearestPlayer,
    castToAllTargets = castToAllTargets,
    getAllValidTargets = getAllValidTargets,
    getClosestInFOV = getClosestInFOV,
    hasLineOfSight = hasLineOfSight,
    getHitbox = getHitbox,
    getOrigin = getOrigin,
    plrManager = plrManager
}
