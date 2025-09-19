LFS_CustomEntities = LFS_CustomEntities or {}

-- Receive server updates
net.Receive("LFS_CustomEntities_Update", function()
    LFS_CustomEntities = net.ReadTable()
end)

-- HUDPaint hook to draw custom entities
hook.Add("HUDPaint", "LFS_CustomEntities_HUD", function()
    if not IsValid(LocalPlayer():GetActiveWeapon()) then return end
    if LocalPlayer():GetActiveWeapon():GetClass() ~= "weapon_lfsmissilelauncher" then return end

    for _, ent in ipairs(LFS_CustomEntities) do
        if not IsValid(ent) then continue end

        -- Ensure the interface is mocked before drawing
        local methods = {
            GetHP = function() return 10 end,
            GetMaxHP = function() return 10 end,
            GetShield = function() return 0 end,
            GetMaxShield = function() return 0 end,
        }
        for name, func in pairs(methods) do
            if not ent[name] then
                ent[name] = func
            end
        end

        local pos = ent:LocalToWorld(ent:OBBCenter()):ToScreen()

        -- alpha render
        local Dist = (LocalPlayer():GetPos() - ent:LocalToWorld(ent:OBBCenter())):Length()
        local Alpha = math.max(255 - Dist * 0.015,0)

        local color = Color(0, 127, 255, Alpha)
        simfphys.LFS.HudPaintPlaneIdentifier(pos.x, pos.y, color, ent)
    end
end)

E2Helper.Descriptions["e:setLockState(n)"] = "Set an entities lock state via LFS (0/1 false/true)"
E2Helper.Descriptions["setLockState(e, n)"] = "Set an entities lock state via LFS (0/1 false/true)"
E2Helper.Descriptions["e:isBeingLocked"] = "Returns an array of players that are trying to acquire a full lock on an entity"
E2Helper.Descriptions["e:isLocked"] = "Returns an array of players that have a full lock on an entity"