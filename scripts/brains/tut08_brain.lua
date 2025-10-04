require "behaviours/patrol"
require "behaviours/followplayer"
require "behaviours/journey"
require "behaviours/chaseandattack"

--[[RunAway
--This is the distance at which our creature will start fleeing.
local AVOID_PLAYER_DIST = 8 --Ingame units
--This is the distance at which our creature will stop fleeing.
local AVOID_PLAYER_STOP = 18
]]

--Patrol
--This is the range at which the patrol points can spawn within
local PATROL_POINT_RADIUS_SPAWN = 10
--This is the number of patrol points that generate
local NUMBER_OF_PATROL_POINTS = 4
--This is the wait time before moving onto the next patrol point
local PATROL_WAIT_TIME = 5 --Seconds
--This is the radius at which the creature checks for the tallbird egg
local GROUND_SCAN_RADIUS = 15 --this should be bigger than PATROL_POINT_RADIUS_SPAWN

--Follow Player
local FOLLOW_PLAYER_MINIMUM_DISTANCE = 2
local FOLLOW_PLAYER_TARGET_DIST = 5
local FOLLOW_PLAYER_MAX_DIST = 20

--Flower Journey
local JOURNEY_SEARCH_RADIUS = 20
local JOURNEY_WAIT_TIME = 2



--function to return if a tallbirdegg is nearby
local function IsTallbirdEggNear(inst, radius)
    local egg = FindEntity(inst, radius, function(item)
        if not item or type(item) ~= "table" then return false end
        if item.prefab ~= "tallbirdegg" then return false end --We can change the item.prefab to any other item we want
        return true
    end)
    return egg ~= nil
end

--https://vietnd69.github.io/dst-api-webdocs/docs/game-scripts/core-systems/fundamentals/utilities/simutil#find-closest-entity
--[[ Doing it this way might not apply well as we might want to only trigger it with a tallbird egg, not other types of eggs
local entity, distsq = FindClosestEntity(player, 20, false, {"tree"}, {"burnt"})
if entity then
    print("Found tree at distance:", math.sqrt(distsq)) 
end
]]

-- Function to check if an item is seeds
local function is_seeds(item)
    return item.prefab == "seeds"
end

-- Retarget function for following players with seeds
local function FollowPlayerWithSeedsRetargetFn(inst)
    -- Look for entities within a certain distance
    return FindEntity(inst, 20, --MAGIC NUMBER
        function(guy)
            -- Check that the entity is alive
            if guy.components.health and not guy.components.health:IsDead() then
                -- Only target players
                if guy:HasTag("player") and guy.components.inventory then
                    -- Optional: limit to a max distance squared
                    if guy:GetDistanceSqToInst(inst) < (20 * 20) then --MAGIC NUMBER
                        -- Check if player has seeds
                        if guy.components.inventory:FindItem(is_seeds) then
                            return guy
                        end
                    end
                end
            end
            return nil
        end
    )
end

local function NearestEvergreenPos(inst)
    local evergreen = GetClosestInstWithTag("evergreen", inst, SEE_TREE_DIST)
    if evergreen and 
       evergreen:IsValid() then
        return Vector3(evergreen.Transform:GetWorldPosition() )
    end
end

--Here we create a new brain 
local tut08_brain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--This function sets up our brain's 'behavior tree'.  A behavior tree is just a prioritized list of behaviors.  
--In this case, our creature's first priority is always to runaway and it's second priority is to stand around 
--looking pretty.  You can find more behaviours in the game's data/scripts/behaviours folder.
function tut08_brain:OnStart()

	--Some behavior trees have multiple priority nodes.  Ours has a single node with two behaviours.    
    local root = PriorityNode(
    {
    	--Here we tell our creature to 'RunAway' from anything in the game tagged as 'scarytoprey' and then we 
        --specify the distances we want to start and stop running at.
        --RunAway(self.inst, "scarytoprey", AVOID_PLAYER_DIST, AVOID_PLAYER_STOP),
		
		--Chase and Attack
        ChaseAndAttack(self.inst, 10, 20), -- MAX_CHASE_TIME = 10s, MAX_CHASE_DIST = 20 units
		
        --Patrol if tallbirdegg is nearby
        WhileNode(function() 
            return IsTallbirdEggNear(self.inst, GROUND_SCAN_RADIUS)
        end, "PatrolIfEggNear",
            Patrol(self.inst, PATROL_POINT_RADIUS_SPAWN, NUMBER_OF_PATROL_POINTS, PATROL_WAIT_TIME)
        ),

        --Follow player only if they have seeds
        WhileNode(function()
            self.target = FollowPlayerWithSeedsRetargetFn(self.inst)
            return self.target ~= nil
        end, "FollowPlayerWithSeeds",
            Follow(self.inst, FOLLOW_PLAYER_MINIMUM_DISTANCE, FOLLOW_PLAYER_TARGET_DIST, FOLLOW_PLAYER_MAX_DIST)
        ),
        
        -- Go to the nearest flower
        Journey(self.inst, JOURNEY_SEARCH_RADIUS, JOURNEY_WAIT_TIME),

        --Here we tell our creature that if it's not running away, it should simply stand still.
        StandStill(self.inst, function() return true end),

    --This tells the creature to check every 0.25 seconds if it should be changing which behaviour it's doing.
    }, .25)
    
    --Now we attach the behaviour tree to our brain.
    self.bt = BT(self.inst, root)
    
end

--Register our new brain so that it can later be attached to any creature we create.
return tut08_brain
