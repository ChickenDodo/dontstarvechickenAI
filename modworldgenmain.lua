--[NEW] These lua files are required to setup a new room.
GLOBAL.require("map/tasks")
GLOBAL.require("constants")

--[NEW] Here we define a new room containing one 'tut08' creature.  Ignore the colour and value parameters.
AddRoom("tut08_room", 
	{
		colour={r=0.3,g=0.2,b=0.1,a=0.3},
		value = GLOBAL.GROUND.FOREST, 
		contents =  
		{
			countprefabs= 
			{
				--[NEW] Here we specify how many 'tut08' creatures we want as part of our room.
				tut08 = 1,
			}
		}
	})

--[NEW] We get a reference to the 'Forest Hunters' task which is one of the standard world generation tasks.
local task = GLOBAL.tasks.GetTaskByName("Forest hunters", GLOBAL.tasks.sampletasks)

--[NEW] We now add a new room choice to this task which is the room filled with our new creature.  By giving it a value 
--		of 50, we're telling the world generation to spawn up to 50 new rooms with our new creature meaning there should 
--		be up to 50 of our creature spawned randomly around the world.
task.room_choices["tut08_room"] = 50

