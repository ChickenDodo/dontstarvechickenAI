Patrol = Class(BehaviourNode, function(self, inst, radius, num_points, patrol_wait_time)
    BehaviourNode._ctor(self, "Patrol")
    self.inst = inst
    self.waittime = 0              

    --Patrol settings
    self.radius = radius           --The range at which the patrol points can spawn within
    self.num_points = num_points   --How many patrol points to generate
    self.patrol_wait_time = patrol_wait_time

    --Waypoints
    self.waypoints = {}            --Empty list for patrol points, we'll generate these later
    self.current_wp = 1            --We are currently at waypoint 1

    --generate patrol points once spawned
    self:GenerateWaypoints()
end)

function Patrol:GenerateWaypoints()
    local x, y, z = self.inst.Transform:GetWorldPosition()   --We'll never use y as we never go up or down in the worldspace

    for i = 1, self.num_points do                            --Run loop for each num_points we want
        local angle = math.random() * 2 * PI                 --Pick a random angle from spawn point * 2 for a full circle
        local dist = math.random() * self.radius             --Pick a random distance between 0 and the chosen radius
        --Converts the creature's spawn position, angle + distance into world coordinates
        local wp_x = x + math.cos(angle) * dist              --We get the cosine to get the horizontal (x axis) offset, moves left/right
        local wp_z = z + math.sin(angle) * dist              --We get the sin to get the vertical (z axis) offset, moves forward/back
                                                             --We DONT get the tan, or the slope (y axis) offset, moves up/down, as we never use it, it will no longer be a circle and we want the creature to be on the ground
        --Calculations end up being a point somewhere in the circle around the creature

        table.insert(self.waypoints, Vector3(wp_x, 0, wp_z)) --Save coords by using a table to store our list of patrol points
    end
end

--Function to decide whether to move or not
function Patrol:Visit()
    if self.status == READY then
        self:PickNextMove()
        self.status = RUNNING
    else
        if GetTime() > self.waittime then
            self:PickNextMove()
        else
            self:Sleep(self.waittime - GetTime())
        end 
    end
end

function Patrol:PickNextMove()
    if #self.waypoints > 0 then                              --If there are any patrol points left
        local target = self.waypoints[self.current_wp]       --Target variable = our generated ones
        if target ~= nil then                                --If we have no target...
            self.inst.components.locomotor:GoToPoint(target) --Use the locomotor component to tell it to go there
        end
        --Cycle through patrol points
        --Self.current_wp = self.current_wp % #self.waypoints + 1
        --Is more compact but it looks confusing. Uses the modulo operator, wrapping to 0 after reaching the number of patrol points. Adding 1 shifts it back to 1 #self.waypoints.
        self.current_wp = self.current_wp + 1                --Add to current patrol point variable by 1
        if self.current_wp > #self.waypoints then            --If our current patrol point is greater than the list
            self.current_wp = 1                              --Set back to 1, repeating the cycle
        end
    end
        self.waittime = GetTime() + self.patrol_wait_time         --Sees how long it should wait b4 moving. GetTime() is a function which grabs the current game's time
end

--[[ THIS FREEZES ENTIRE GAME DUE TO BEING SINGLE-THREADED!!!
function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end
]]
