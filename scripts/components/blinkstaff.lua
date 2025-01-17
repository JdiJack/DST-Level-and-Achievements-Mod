local BlinkStaff = Class(function(self, inst)
    self.inst = inst
    self.onblinkfn = nil
    self.blinktask = nil
    self.frontfx = nil
    self.backfx = nil
end)

function BlinkStaff:SetFX(front, back)
    self.frontfx = front
    self.backfx = back
end

function BlinkStaff:SpawnEffect(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if self.backfx ~= nil then
        SpawnPrefab(self.backfx).Transform:SetPosition(x, y - .1, z)
    end
    if self.frontfx ~= nil then
        SpawnPrefab(self.frontfx).Transform:SetPosition(x, y, z)
    end
end

local function OnBlinked(caster, self, dpt)
    if caster.sg == nil then
        caster:Show()
        if caster.components.health ~= nil then
            caster.components.health:SetInvincible(false)
        end
        if caster.DynamicShadow ~= nil then
            caster.DynamicShadow:Enable(true)
        end
    elseif caster.sg.statemem.onstopblinking ~= nil then
        caster.sg.statemem.onstopblinking()
    end
    local pt = dpt:GetPosition()
    if pt ~= nil and TheWorld.Map:IsPassableAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt) then
        caster.Physics:Teleport(pt:Get())
    end
    self:SpawnEffect(caster)
    caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")
    if caster.components.allachivevent.teleport ~= true then
        caster.components.allachivevent.teleportamount = caster.components.allachivevent.teleportamount + 1
        if caster.components.allachivevent.teleportamount >= allachiv_eventdata["teleport"] then
            caster.components.allachivevent.teleport = true
            caster.components.allachivevent:seffc(caster, "teleport")
        end
    end
end

function BlinkStaff:Blink(pt, caster)
    if (caster.sg ~= nil and caster.sg.currentstate.name ~= "quicktele") or
        not TheWorld.Map:IsPassableAtPoint(pt:Get()) or
        TheWorld.Map:IsGroundTargetBlocked(pt) then
        return false
    elseif self.blinktask ~= nil then
        self.blinktask:Cancel()
    end

    self:SpawnEffect(caster)
    caster.SoundEmitter:PlaySound("dontstarve/common/staff_blink")

    if caster.sg == nil then
    caster:Hide()
    if caster.DynamicShadow ~= nil then
        caster.DynamicShadow:Enable(false)
    end
    if caster.components.health ~= nil then
        caster.components.health:SetInvincible(true)
    end
    elseif caster.sg.statemem.onstartblinking ~= nil then
        caster.sg.statemem.onstartblinking()
    end

    self.blinktask = caster:DoTaskInTime(.25, OnBlinked, self, DynamicPosition(pt))

    if self.onblinkfn ~= nil then
        self.onblinkfn(self.inst, pt, caster)
    end

    return true
end

return BlinkStaff
