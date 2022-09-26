-- Register the mod, which grants the ability to add code that correspond to in-game events (i.e. "callbacks").
local mod = RegisterMod("Count Red Key Rooms", 1)

--[[ Steps: 
    Starting in the player's room, check around it for rooms that exist
    Open every red room connected to the given room
    Now find the rooms that exist again
    The difference between these two lists are the new red rooms
    Record its stats, then call this method in them
    Once all of the methods have been called, return
--]]

local recordData = {["numRooms"] = 0}
local roomsCalled = {}
level = Game():GetLevel()

function RecordStats(RoomIndex)
    local roomData = level:GetRoomByIdx(RoomIndex).Data
    recordData["numRooms"] = recordData["numRooms"] + 1
    recordData[roomData.Type] = recordData[roomData.Type] or 0
    recordData[roomData.Type] = recordData[roomData.Type] + 1
end

function OpenAllRedKeyRooms(RoomIndex)
    for i = 0, 7 do
        level:MakeRedRoomDoor(RoomIndex, i)
    end
end

function GetBorderingRooms(RoomIndex)
    local existingRooms = {}
    
    -- Check in this order: Left, Up, Right, Down
    if RoomIndex % 13 ~= 0 then
        existingRooms[1] = RoomIndex - 1
    end
    if RoomIndex > 12 then
        existingRooms[2] = RoomIndex - 13
    end
    if RoomIndex % 13 ~= 12 then
        existingRooms[3] = RoomIndex + 1
    end
    if RoomIndex < 156 then
        existingRooms[4] = RoomIndex + 13
    end
    
    -- At this point, existingRooms has the room indices of all POSSIBLE bordering rooms
    -- Next, we check if these actually exist
    
    for i = 1, 4 do
        existingRooms[i] = CheckExists(existingRooms[i]) and existingRooms[i]
    end
    
    -- Now, existingRooms has only rooms that exist and border the room in it. yay!
    
    return existingRooms
end

function CheckExists(RoomIndex)
    local roomDescriptor = level:GetRoomByIdx(RoomIndex)
    local roomData = roomDescriptor.Data
    return roomData
end

function MapRoom(RoomIndex)
    local RoomIndex = RoomIndex or level:GetCurrentRoomIndex()
    
    if roomsCalled[RoomIndex] or (level:GetRoomByIdx(RoomIndex).Data.Shape ~= 1) then
        return
    else
        roomsCalled[RoomIndex] = true
    end
    
    print(RoomIndex .. "")
    
    -- Get starting existing rooms
    local startingExistingRooms = GetBorderingRooms(RoomIndex)
    
    -- Open all red rooms
    OpenAllRedKeyRooms(RoomIndex)
    
    -- Get existing rooms including new red ones
    local redExistingRooms = GetBorderingRooms(RoomIndex)
    
    -- Check differences between the two
    local redRooms = {}
    for i = 1, 4 do
        -- If a room is nil in starting and nonnil in red, add it to this
        redRooms[i] = startingExistingRooms[i] or redExistingRooms[i]
        if redRooms[i] then RecordStats(redRooms[i]) end
    end
    
    -- Now call this method on all surrounding rooms
    for i = 1, 4 do
        if redExistingRooms[i] then MapRoom(redExistingRooms[i]) end
    end
end

function DisplayStats()
    print("Number of rooms checked: " .. recordData["numRooms"])
    recordString = ""
    for i = 0, 29 do
        if recordData[i] then
            recordString = (recordString .. i .. ": " .. recordData[i] .. "; ")
        end
    end
    
    print(recordString)
end

function StartRepeatedMapping(timesToRun)
    -- Restarts the game, then maps, then does it again
    -- Come up with a way to stop it
    local timesRun = 0
    local timesToRun = timesToRun or 10
    
    for i = 1, timesToRun do
        Isaac.ExecuteCommand("restart")
        MapRoom()
    end
end