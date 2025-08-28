--Stategraphs are used to present feedback to the player based on the state of the creature.  Here we setup two states,
--one to handle when the creature is idle and one to handle when the creature is running.
local states=
{
	--This handles the idle state.
    State{

        name = "idle",

        --Tags are how we can classify states.  The 'canrotate' tag tells the animation system that these animations can
		--be flipped based on which way the creature is facing which means we don't have to create multiple animations.
        tags = {"idle", "canrotate"},

        --Here is how we define what happens when we enter this state.
        onenter = function(inst, playanim)

        	--In this case, all we want to do is play a looping version of the idle animation.
            inst.AnimState:PlayAnimation("idle", true)
        end,

    },

	--This handles the running state.
    State{

        name = "run",

        --Our running animation is also safe to be rotated.
        tags = {"run", "canrotate", "moving" },

        onenter = function(inst, playanim)

        	--When entering this state, we now play a looping run animation.
            inst.AnimState:PlayAnimation("run", true)

    		--Tell the locomotor that it's ok to start running.
    		inst.components.locomotor:RunForward()            
        end,
    },    

    --This handles the yell state.
    State{

        name = "yell",

        --Our new state along with our run state are tagged as 'moving' so that we can check for either one when we
        --receive a 'locomote' event from our 'locomotor' component.
        tags = {"yell", "canrotate", "moving"},

        onenter = function(inst, playanim)

            --When we first enter this state, we want our creature to yell.  The name of the sound is a combination of the fmod project, 
            --the folder within the fmod project and the name of the sound event.
            inst.SoundEmitter:PlaySound("tut08/creature/yell")            

            --We also want it to play our new fancy yell animation.
            inst.AnimState:PlayAnimation("yell")
        end,

        --The events section allows us to handle events specific to the current state we are in.
        --In this case we are going to switch to the run state as soon as we receive the 'animover'
        --event which tells us that our yell animation is done.
        events=
        {
            EventHandler("animover", 
                function (inst, data)

                    --Time to start running.
                    inst.sg:GoToState("run")
                end
            ),
        }        
    },    
}

--Event handlers are how stategraphs get told what happening with the prefab.  The stategraph then decides how it wants
--to present that to the user which usually involves some combination of animation and audio.
local event_handlers=
{

	--The locomotor sends events to the state graph called 'locomote'.  Here we setup how we're going to handle the event.
    EventHandler("locomote", 
        function(inst) 

        	--First we check to see if the locomotor is trying to move our creature.
            if inst.components.locomotor:WantsToMoveForward() then

                --Next we check to see if we're not already in a moving state.
                if not inst.sg:HasStateTag("moving") then

                	--Instead of going straight to the run state, let's jump to the yell state first.
                    inst.sg:GoToState("yell")
                end

           --If we're not trying to move forward, then all we want to do is stand still.
            else

            	--So if we're not already standing still.
                if not inst.sg:HasStateTag("idle") then
                	
                	--Let's start standing still.
                    inst.sg:GoToState("idle")
                end
            end
        end),
}

--Register our new stategraph and set the default state to 'idle'.
return StateGraph("tut08", states, event_handlers, "idle", {})