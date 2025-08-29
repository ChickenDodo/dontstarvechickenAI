--Define a new behavior node class for visiting an item
Journey = Class(BehaviourNode, function(self, inst, journey_search_radius, journey_wait_time)
    BehaviourNode._ctor(self, "Journey")  
    self.inst = inst                                

    self.journey_search_radius = journey_search_radius --Set the maximum distance to search for the item
    self.journey_wait_time = journey_wait_time         --Set how long to wait at a item before moving on
    self.currenttarget = nil                           --Current item being targeted
    self.waiting = false                               --Whether the creature is currently waiting at a item
end)

--Collect all items within
function Journey:GetTargets()
    local targets = {}                                     --Empty table to store items
    local journey_search_radius = self.journey_search_radius --Shortcut to the search radius

--[[
-- Get random flower nearby
local flower = GetRandomInstWithTag("flower", player, 15)

]]
    --Find the first item entity within radius
    local item = FindEntity(self.inst, journey_search_radius, function(item)
        return item and item:IsValid() and item:HasTag("flower") 
    end)

    --Keep finding items until no more are found
    while item do
        table.insert(targets, item)               --Add this item to the targets list
        item._skip_next_search = true             --Temporarily mark it so it's not found again
        item = FindEntity(self.inst, journey_search_radius, function(item)
            return item and item:IsValid() and item:HasTag("flower") and not item._skip_next_search
        end)
    end

    --Remove temporary marks from all collected items
    for i, f in ipairs(targets) do
        f._skip_next_search = nil
    end

    return targets                                  --Return the list of items
end

--Pick a item to target that is not the current one
function Journey:GetTarget()
    local items = self:GetTargets()               --Get all nearby items
    if #items == 0 then                           --If no items found
        return nil                                  --Return nil (no target)
    end

    local new_target = items[math.random(#items)]  --Pick a random item
    --If picked the same as current target and more than 1 item exists
    if new_target == self.currenttarget and #items > 1 then
        local idx = math.random(#items-1)         --Pick a different index
        if items[idx] == self.currenttarget then
            idx = idx + 1                           --Avoid selecting the current target again
        end
        new_target = items[idx]                   --Set new target
    end
    return new_target                               
end

--Debug Stuff
function Journey:DBString()
    return string.format("Go to item %s", tostring(self.currenttarget)) --Show which item is targeted
end

--Update loop for the behavior
function Journey:Visit()
    if self.waiting then                            --If currently waiting 
        self.status = RUNNING                       --Keep status running
        self:Sleep(self.journey_wait_time)          --Wait for the defined wait_time
        self.waiting = false                        --Done waiting
        self.currenttarget = nil                    --Clear the target to pick a new one next
        return
    end

    --If no target or target is invalid, pick a new one
    if not self.currenttarget or not self.currenttarget:IsValid() then
        self.currenttarget = self:GetTarget()
        if not self.currenttarget then              --If no valid item found
            self.status = FAILED                    
            return
        end
    end

    --Get positions of self and target
    local pos = Point(self.inst.Transform:GetWorldPosition())
    local target_pos = Point(self.currenttarget.Transform:GetWorldPosition())
    local dist_sq = distsq(pos, target_pos)        --Compute squared distance

    --If close enough to the item
    if dist_sq < 1 then
        self.inst.components.locomotor:Stop()     --Stop moving
        self.waiting = true                       --Start waiting
        self.status = RUNNING
        return
    end

    --Move towards the item
    local should_run = dist_sq > (self.journey_search_radius * 0.5)^2 --Run if far away
    if should_run then
        self.inst.components.locomotor:GoToPoint(target_pos, nil, true) --Run to
    else
        self.inst.components.locomotor:GoToPoint(target_pos) --Walk to
    end

    self.status = RUNNING                           
    self:Sleep(0.25) --Wait a bit before next update
end
