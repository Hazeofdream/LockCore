/******************************************************************************\
Lock Core by Haze_of_dream
\******************************************************************************/

E2Lib.RegisterExtension("LockCore", true, "Allows E2 chips to create, remove and check lock states from LunasFlightSchool")

LFS_CustomEntities = LFS_CustomEntities or {}

util.AddNetworkString("LFS_CustomEntities_Update")

local function Broadcast()
    net.Start("LFS_CustomEntities_Update")
    net.WriteTable(LFS_CustomEntities)
    net.Broadcast()
end

local function ForceUnlocks()
    -- Forcefully cut lock for any launcher currently locked on this entity
    for _, ply in pairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.ClosestEnt == ent and wep:GetClass() == "weapon_lfsmissilelauncher" then
           wep:StopSounds()
           if wep:GetIsLocked() then
                wep:SetLockOn(NULL)
           end
        end
    end
end

-- Send all entities to client's launchers to be mocked
hook.Add("Think", "LFS_CustomStorage_Inject", function()
    for _, ply in ipairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_lfsmissilelauncher" then
            if not istable(wep.FoundVehicles) then continue end
            for _, ent in ipairs(LFS_CustomEntities) do
                if IsValid(ent) and not table.HasValue(wep.FoundVehicles, ent) then
                    table.insert(wep.FoundVehicles, ent)
                end
            end
        end
    end
end)

hook.Add("Think", "LFS_CustomEntities_BlockMissileLock", function()
    for _, ply in ipairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_lfsmissilelauncher" then continue end
        if not istable(wep.FoundVehicles) then continue end

        local target = wep:GetClosestEnt()
        if IsValid(target) and not table.HasValue(LFS_CustomEntities, target) then
            -- Immediately remove disallowed target
            wep:StopSounds()

            -- Force timers forward to avoid reacquire
            wep.nextFind = CurTime() + 1
            wep.guided_nextThink = CurTime() + 1
            wep.FindTime = CurTime() + 1
        end
    end
end)

-- Clean up removed entities
hook.Add("EntityRemoved", "LFS_CustomStorage_Cleanup", function(ent)
    for i, e in pairs(LFS_CustomEntities) do
        if e == ent then
            table.remove(LFS_CustomEntities, i)
            break
        end
    end

    Broadcast()
end)

__e2setcost(40)
e2function entity entity:setLockState(number state)
    if not IsValid(this) then return self:throw("Invalid entity!", nil) end
    if not E2Lib.isOwner(self, this) then return self:throw("You do not own the target prop!", nil) end

    local key = table.KeyFromValue(LFS_CustomEntities, this)

    if state == 1 then
        if table.HasValue(LFS_CustomEntities, this) then
            return false
        end

        table.insert(LFS_CustomEntities, this)
    end

    if state == 0 then
        local key = table.KeyFromValue(LFS_CustomEntities, this)
        if key then
            table.remove(LFS_CustomEntities, key)
        end
    end

    Broadcast()
end

__e2setcost(40)
e2function entity setLockState(entity ent, number state)
    if not IsValid(ent) then return self:throw("Invalid entity!", nil) end
    if not E2Lib.isOwner(self, ent) then return self:throw("You do not own the target prop!", nil) end

    local LFS_CustomEntities = LFS_CustomEntities or {}

    if state then
        if table.HasValue(LFS_CustomEntities, ent) then
            return false
        end

        table.insert(LFS_CustomEntities, ent)
    elseif state == 0 then
        local key = table.KeyFromValue(LFS_CustomEntities, this)
        if key then
            table.remove(LFS_CustomEntities, key)
        end
    end

    Broadcast()
end

__e2setcost(20)
e2function array entity:isBeingLocked()
    if not IsValid(this) then return self:throw("Invalid entity!", nil) end

    local targetingPlayers = {}
    for _, ply in pairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_lfsmissilelauncher" then
            if wep:GetClosestEnt() == this and wep.TrackSND ~= nil then
                table.insert(targetingPlayers, ply)
            end
        end
    end

    return targetingPlayers
end

__e2setcost(20)
e2function array entity:isLocked()
    if not IsValid(this) then return self:throw("Invalid entity!", nil) end

    local targetingPlayers = {}
    for index, ply in pairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_lfsmissilelauncher" then
            if wep:GetClosestEnt() == this and wep:GetIsLocked() then
                table.insert(targetingPlayers, ply)
            end
        end
    end

    return targetingPlayers
end
