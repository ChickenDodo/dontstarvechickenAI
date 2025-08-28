Follow = Class(BehaviourNode, function(self, inst, min_dist, target_dist, max_dist, canrun, search_radius)
    BehaviourNode._ctor(self, "Follow")             
    self.inst         = inst                        

    self.min_dist     = type(min_dist) == "number" and min_dist or 2       --Minimum distance to keep from the target
    self.target_dist  = type(target_dist) == "number" and target_dist or 5 --Desired following distance
    self.max_dist     = type(max_dist) == "number" and max_dist or 10      --Maximum distance before trying to catch up

    self.canrun       = canrun ~= nil and canrun or true              
    self.search_radius = type(search_radius) == "number" and search_radius or 30 -- Radius to search for target

    self.action = "STAND"                           --Current action state (APPROACH, BACKOFF, or STAND)
end)

--Get the closest player as the follow target
function Follow:GetTarget()
    local player = GetClosestInstWithTag("player", self.inst, self.search_radius) --Find closest player within radius
    return player                                  --Return the target or nil if none found
end

-- Debug string to show target info
function Follow:DBString()
    local pos = Point(self.inst.Transform:GetWorldPosition())  --Get AI position
    local target_pos = Vector3(0,0,0)                          --Default target position
    if self.currenttarget then
        target_pos = Point(self.currenttarget.Transform:GetWorldPosition()) --Get target position
    end
    return string.format("%s %s, (%2.2f) ", tostring(self.currenttarget), self.action, math.sqrt(distsq(target_pos, pos)))
    --Shows target, action, and distance
end

--Main update loop for follow behavior
function Follow:Visit()
    self.currenttarget = self:GetTarget()          --Update current target

    --If target is invalid or dead, stop and fail
    if not self.currenttarget or not self.currenttarget:IsValid()
       or (self.currenttarget.components.health and self.currenttarget.components.health:IsDead()) then
        self.inst.components.locomotor:Stop()     --Stop movement
        self.status = FAILED
        return
    end

    --Get positions and squared distance
    local pos = Point(self.inst.Transform:GetWorldPosition())
    local target_pos = Point(self.currenttarget.Transform:GetWorldPosition())
    local dist_sq = distsq(pos, target_pos)

    --Decide whether to approach or back off
    if dist_sq < self.min_dist * self.min_dist then
        self.action = "BACKOFF"                     --Too close, move away
    elseif dist_sq > self.max_dist * self.max_dist then
        self.action = "APPROACH"                   --Too far, move closer
    else
        self.action = "APPROACH"                   --Within range, maintain approach
    end

    --Move according to action
    if self.action == "APPROACH" then
        local should_run = dist_sq > (self.max_dist * 0.75) * (self.max_dist * 0.75) --Run if far from max distance
        local is_running = self.inst.sg:HasStateTag("running")  --Check if already running
        if self.canrun and (should_run or is_running) then
            self.inst.components.locomotor:GoToPoint(target_pos, nil, true)  --Run to target
        else
            self.inst.components.locomotor:GoToPoint(target_pos)  --Walk to target
        end
    elseif self.action == "BACKOFF" then
        local angle = self.inst:GetAngleToPoint(target_pos)     --Get direction to target
        if self.canrun then
            self.inst.components.locomotor:RunInDirection(angle + 180) --Run away from target
        else
            self.inst.components.locomotor:WalkInDirection(angle + 180) --Walk away from target
        end
    end

    self.status = RUNNING                             
    self:Sleep(0.25)                                  
end
