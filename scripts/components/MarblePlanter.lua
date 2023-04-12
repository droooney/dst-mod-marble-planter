local INCREMENTS = {
    { 2, -2},
    { 0, -2},
    {-2, -2},
    {-2,  0},
    {-2,  2},
    { 0,  2},
    { 2,  2},
    { 2,  0},
}

local MarblePlanter = Class(function (self, inst)
    self.inst = inst
    self.thread = nil
end)

function MarblePlanter:ClearThread()
    if not self.thread then
        return
    end

    KillThreadsWithID(self.thread.id)

    self.thread:SetList(nil)
    self.thread = nil
end

function MarblePlanter:GetNewBean()
    local activeItem = self.inst.replica.inventory:GetActiveItem()

    if activeItem and activeItem.prefab == "marblebean" then
        return activeItem
    end

    local inventory = self.inst.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack = body_item and body_item.replica.container

    for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
        for slot, item in pairs(inv:GetItems()) do
            if item and item.prefab == "marblebean" then
                inv:TakeActiveItemFromAllOfSlot(slot)

                return item
            end
        end
    end
end

function MarblePlanter:StartThread()
    self:ClearThread()

    self.thread = StartThread(function()
        self.inst:ClearBufferedAction()

        local tileCenter = Point(TheWorld.Map:GetTileCenterPoint(TheSim:ProjectScreenPos(TheSim:GetPosition())))
        local currentIncrementIndex = 0

        while true do
            local bean = self:GetNewBean()

            if not bean then
                break
            end

            local inventoryItem = bean.replica.inventoryitem

            currentIncrementIndex = currentIncrementIndex + 1

            if currentIncrementIndex > #INCREMENTS then
                break
            end

            local currentIncrement = INCREMENTS[currentIncrementIndex]
            local currentPoint = tileCenter + Point(currentIncrement[1], 0, currentIncrement[2])

            if inventoryItem and inventoryItem:CanDeploy(currentPoint, nil, self.inst) then
                local playerController = self.inst.components.playercontroller
                local action = BufferedAction(self.inst, nil, ACTIONS.DEPLOY, bean, currentPoint)

                if playerController.ismastersim then
                    self.inst.components.combat:SetTarget(nil)
                    playerController:DoAction(action)
                else
                    if playerController.locomotor then
                        action.preview_cb = function()
                            SendRPCToServer(RPC.RightClick, action.action.code, currentPoint.x, currentPoint.z, nil, nil, true)
                        end

                        playerController:DoAction(action)
                    else
                        SendRPCToServer(RPC.RightClick, action.action.code, currentPoint.x, currentPoint.z, nil, nil, true)
                    end
                end

                Sleep(FRAMES * 6)

                repeat
                    Sleep(FRAMES * 3)
                until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
                    and self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
            end
        end

        self:ClearThread()
    end, "MarblePlanterThread")
end

return MarblePlanter
