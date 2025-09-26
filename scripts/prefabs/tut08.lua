--Here we list any assets required by our prefab.
local assets=
{
    --this is the name of the Spriter file.
    Asset("ANIM", "anim/tut08.zip"),
    
    --This is the FMOD file which contains all of the sound events.
    Asset("SOUNDPACKAGE", "sound/tut08.fev"),

    --This is the FMOD file which contains all the actual sound data.
    Asset("SOUND", "sound/tut08.fsb"),    
}

    -- ALLOW ATTACKING
    local function canbeattacked(inst, attacked)
        return not inst.sg:HasStateTag("flying")
    end

--This function creates a new entity based on a prefab.
local function init_prefab()

    --First we create an entity.
    local inst = CreateEntity()

    --Then we add a transform component se we can place this entity in the world.
    local trans = inst.entity:AddTransform()

    --Then we add an animation component which allows us to animate our entity.
    local anim = inst.entity:AddAnimState()
    
    --The bank name is the name of the Spriter file.
    anim:SetBank("tut08")

    --The build name is the name of the animation folder in spriter.
    anim:SetBuild("tut08")

    inst:AddComponent("inspectable") -- Adding the Inspectable component

    --We need to add a 'locomotor' component otherwise our creature can't walk around the world.
    inst:AddComponent("locomotor")
    --Here we can tune how fast our creature runs forward.
    inst.components.locomotor.runspeed = 7

    --ATTACKABLE
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "crow_body"
    inst.components.combat.canbeattackedfn = canbeattacked
	inst.components.combat.canattack = true
	inst.components.combat.defaultdamage = 10
    --HEALTH
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)
    inst.components.health.murdersound = "dontstarve/wilson/hit_animal"
    --LOOT DROPS
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:AddRandomLoot("feather_", 1)
    inst.components.lootdropper:AddRandomLoot("smallmeat", 1)
    inst.components.lootdropper.numrandomloot = 1
    inst.components.lootdropper.chanceloot = 1

    --We need to add a 'physics' component for our character to walk through the world.  Lucky for us, this
    --this is made easy for us by the 'MakeCharacterPhysics' function.  This function sets up physics,
    --collision tags, collision masks, friction etc.  All we need to give it is a mass and a radius which 
    --in this case we've set to 10 and 0.5.
    MakeCharacterPhysics(inst, 10, .5)

    --Here we attach our stategraph to our prefab.
    inst:SetStateGraph("SGtut08")

    --We need a reference to the brain we want to attach to our creature.
    local brain = require "brains/tut08_brain"

    --And then we attach the brain to our creature.
    inst:SetBrain(brain)

    --Our creature needs a sound component to be able to play back sound.
    inst.entity:AddSoundEmitter()

    --return our new entity so that it can be added to the world.
    return inst
end

--Here we register our new prefab so that it can be used in game.
return Prefab( "monsters/tut08", init_prefab, assets, nil)
