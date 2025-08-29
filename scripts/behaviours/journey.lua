--Define a new behavior node class for visiting flowers
GoToFlowerJourney = Class(BehaviourNode, function(self, inst, journey_search_radius, journey_wait_time)
    BehaviourNode._ctor(self, "GoToFlowerJourney")  
    self.inst = inst                                

    self.journey_search_radius = journey_search_radius --Set the maximum distance to search for flowers
    self.journey_wait_time = journey_wait_time                       --Set how long to wait at a flower before moving on
    self.currenttarget = nil                         --Current flower being targeted
    self.waiting = false                             --Whether the creature is currently waiting at a flower
end)

--Collect all flowers within
function GoToFlowerJourney:GetTargets()
    local targets = {}                                     --Empty table to store flowers
    local journey_search_radius = self.journey_search_radius --Shortcut to the search radius

    --Find the first flower entity within radius
    local flower = FindEntity(self.inst, journey_search_radius, function(item)
        return item and item:IsValid() and item:HasTag("flower") 
    end)

    --Keep finding flowers until no more are found
    while flower do
        table.insert(targets, flower)               --Add this flower to the targets list
        flower._skip_next_search = true             --Temporarily mark it so it's not found again
        flower = FindEntity(self.inst, journey_search_radius, function(item)
            return item and item:IsValid() and item:HasTag("flower") and not item._skip_next_search
        end)
    end

    --Remove temporary marks from all collected flowers
    for i, f in ipairs(targets) do
        f._skip_next_search = nil
    end

    return targets                                  --Return the list of flowers
end

--Pick a flower to target that is not the current one
function GoToFlowerJourney:GetTarget()
    local flowers = self:GetTargets()               --Get all nearby flowers
    if #flowers == 0 then                           --If no flowers found
        return nil                                  --Return nil (no target)
    end

    local new_target = flowers[math.random(#flowers)]  --Pick a random flower
    --If picked the same as current target and more than 1 flower exists
    if new_target == self.currenttarget and #flowers > 1 then
        local idx = math.random(#flowers-1)         --Pick a different index
        if flowers[idx] == self.currenttarget then
            idx = idx + 1                           --Avoid selecting the current target again
        end
        new_target = flowers[idx]                   --Set new target
    end
    return new_target                               
end

--Debug Stuff
function GoToFlowerJourney:DBString()
    return string.format("Go to flower %s", tostring(self.currenttarget)) --Show which flower is targeted
end

--Update loop for the behavior
function GoToFlowerJourney:Visit()
    if self.waiting then                            --If currently waiting at a flower
        self.status = RUNNING                       --Keep status running
        self:Sleep(self.journey_wait_time)                  --Wait for the defined wait_time
        self.waiting = false                        --Done waiting
        self.currenttarget = nil                    --Clear the target to pick a new one next
        return
    end

    --If no target or target is invalid, pick a new one
    if not self.currenttarget or not self.currenttarget:IsValid() then
        self.currenttarget = self:GetTarget()
        if not self.currenttarget then              --If no valid flower found
            self.status = FAILED                    
            return
        end
    end

    --Get positions of self and target
    local pos = Point(self.inst.Transform:GetWorldPosition())
    local target_pos = Point(self.currenttarget.Transform:GetWorldPosition())
    local dist_sq = distsq(pos, target_pos)        --Compute squared distance

    --If close enough to the flower
    if dist_sq < 1 then
        self.inst.components.locomotor:Stop()     --Stop moving
        self.waiting = true                       --Start waiting
        self.status = RUNNING
        return
    end

    --Move towards the flower
    local should_run = dist_sq > (self.journey_search_radius * 0.5)^2 --Run if far away
    if should_run then
        self.inst.components.locomotor:GoToPoint(target_pos, nil, true) --Run to flower
    else
        self.inst.components.locomotor:GoToPoint(target_pos) --Walk to flower
    end

    self.status = RUNNING                           
    self:Sleep(0.25)                                --Wait a bit before next update
end
