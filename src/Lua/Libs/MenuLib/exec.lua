--MenuLib v0.6 written by luigi budd

--TODO: check for versions and replace functions?
if rawget(_G,"MenuLib")
	print("\x82MenuLib already loaded, aborting...")
	return
end

rawset(_G, "MenuLib", {})

rawset(_G, "BASEVIDWIDTH", BASEVIDWIDTH or 320)
rawset(_G, "BASEVIDHEIGHT", BASEVIDHEIGHT or 200)

local function enumflags(prefix, work, flagstyle)
	for k,enum in ipairs(work)
		local val
        if flagstyle == "flags"
            val = 1<<(k-1)
        elseif flagstyle == "enum"
            val = k
        end
		
		assert(val ~= -1,"\x85Ran out of bits for "..prefix.."! (k="..k..")\x80")
		assert(val ~= nil,"\x85".."Didn\'t give flagstyle in enumflags\x80")
		
		rawset(_G,prefix..enum,val)
		print("Enummed "..prefix..""..enum.." ("..val..")")
	end
end

--Popup-Style flags
enumflags("PS_", {
	--this popup will automatically draw the title and separating line
	"DRAWTITLE",
	
	--this popup wont have an "X" button, youd better have it close itself!
	"NOXBUTTON",
	
	--this popup wont fade the other menus behind it
	"NOFADE",
	
	--this popup is purely visual, and will not be interactable
	"IRRELEVANT",
	
	--this popup will not slide in from the bottom
	"NOSLIDEIN",
	
	--HOLY SHIT
	--this popup cannot be closed with the escape key
	"NOESCAPE",
}, "flags")

--Menu-Style flags
enumflags("MS_", {
	--the menu will not draw the separating line
	"NOLINE",
	
	--this menu will not do the expanding animation
	"NOANIM",
}, "flags")

--Close-Reason enums
enumflags("CR_", {
    --we're going back in the menu layers
	"MENUEXITED",

    --we're closing a popup
	"POPUPCLOSED",

    --all menus/popups were forced to close
    "FORCEDCLOSEALL",
}, "flags")
--Init-Reason enums
enumflags("IR_", {
    --this menu was opened by the initMenu function
	"INITMENU",

    --this menu was opened by the initPopup function
	"INITPOPUP",
}, "enum")

MenuLib.VERSION = 006
MenuLib.SUBVERSION = 0
--dont forget the ending "/" (and "debug" from the file tree below!)
MenuLib.root = MENULIB_ROOT or ""

MenuLib.templates = {}

MenuLib.client = {
	
	--Self explanatory
	menuactive = false,
	menuTime = 0,
	
	mouse_x = (BASEVIDWIDTH*FU) / 2,
	mouse_y = (BASEVIDHEIGHT*FU) / 2,
	mouse_graphic = nil,
	
	--the button ID that we're hovering over
	hovering = -1,
	canPressSomething = false,
	
	--menu ID
	currentMenu = {
		id = -1,
		layers = {}
	},
	popups = {},
	menuLayer = 0,
	
	--use this when detecting mouse presses
	doMousePress = false,
	mouseTime = -1,
	mouseHeld = 0, -- 1 = JUST pressed down, 2 = held, -1 = let go, 0 = none
	
	--text input stuff (messy)
	textbuffer = nil,
	textbuffer_id = nil,
	textbuffer_funcs = {},
	text_shiftdown = false,
	text_ctrldown = false,
	text_capslock = false,
	textbuffer_sfx = nil,
	textbuffer_tooltip = nil,
	
	commandbuffer = nil,
}


local tree = {
	"main",
	
	"Functions/exec",
	"HUD/exec",
}

for k,file in ipairs(tree)
	dofile(MenuLib.root .. file)
end