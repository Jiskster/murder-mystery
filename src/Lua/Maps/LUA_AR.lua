local function valid(a)
	return (a and a.valid)
end

--Level script
--Code by LeonardoTheMutant for Space Mesa
--Edited for Space Colony ARK (GLide KS)

local doors={
    { --1st door
        0, --timer
        4 --close tag
    },
    { --2nd door
        0,
        6
    },
    { --4th door
        0,
        8
    },
	{ --5th door
        0,
        10
    },
	{ --6th door
        0,
        12
    },
	{ --7th door
        0,
        14
    },
	{ --8th door
        0,
        16
    }
}
local doordelay=2*TICRATE

local rayTimer
local rayControlLine

addHook("LinedefExecute", do --open door 1 trigger
	P_LinedefExecute(3)
	doors[1][1] = doordelay
end,"ARD1OPN")

addHook("LinedefExecute", do --open door 2 trigger
	P_LinedefExecute(5)
	doors[2][1] = doordelay
end,"ARD2OPN")

addHook("LinedefExecute", do --open door 3 trigger
	P_LinedefExecute(7)
	doors[3][1] = doordelay
end,"ARD3OPN")

addHook("LinedefExecute", do --open door 4 trigger
	P_LinedefExecute(9)
	doors[4][1] = doordelay
end,"ARD4OPN")

addHook("LinedefExecute", do --open door 5 trigger
	P_LinedefExecute(11)
	doors[5][1] = doordelay
end,"ARD5OPN")

addHook("LinedefExecute", do --open door 6 trigger
	P_LinedefExecute(13)
	doors[6][1] = doordelay
end,"ARD6OPN")

addHook("LinedefExecute", do --open door 7 trigger
	P_LinedefExecute(15)
	doors[7][1] = doordelay
end,"ARD7OPN")

addHook("ThinkFrame", do
    if (gamemap != 127) return end

	--doors close timer
    for doornum, _ in pairs(doors)
        if (not doors[doornum][1]) then P_LinedefExecute(doors[doornum][2]) --close one of the doors
        else doors[doornum][1] = $ - 1 end --decrement the timer
    end
end)