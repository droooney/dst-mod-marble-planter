AddComponentPostInit("playercontroller", function (self, inst)
    if inst ~= GLOBAL.ThePlayer then
        return
    end

    inst:AddComponent("MarblePlanter")

    local oldOnRightClick = self.OnRightClick

    self.OnRightClick = function (_, down, ...)
        oldOnRightClick(self, down, ...)

        if down or not GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_LSHIFT) then
            return
        end

        local activeItem = self.inst.replica.inventory:GetActiveItem()

        if not activeItem or activeItem.prefab ~= "marblebean" then
            return
        end

        inst.components.MarblePlanter:StartThread()
    end
end)
