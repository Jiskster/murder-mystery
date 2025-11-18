--i swear we had this before...
local sglib = MM.require "Libs/sglib"

local function wrap(v,p,c)
	if not (p.mo and p.mo.valid) then return end
	if (p.spectator) then return end
	if (MM_N.gameover) then return end
	if not p.mm.attract.tics then return end
	
	do
		local att = p.mm.attract
		local dest = {
			x = att.x,
			y = att.y,
			z = att.z
		}
		
		-- i think its fine if we pass a table instead, sglib doesnt need
		-- anything outside of coords anyways
		local to_screen = sglib.ObjectTracking(v,p,c,dest)
		
		if not to_screen.onScreen then return end
		
		if att.name ~= nil
			v.drawString(to_screen.x,
				to_screen.y,
				att.name,
				V_SMALLSCALEPATCH|V_ALLOWLOWERCASE,
				"thin-fixed-center"
			)
			v.drawScaled(to_screen.x,
				to_screen.y,
				v.cachePatch("MM_TNYCROSS"),
				FU/2,
				V_SMALLSCALEPATCH|V_ALLOWLOWERCASE
			)
		end
	end
end

local function HUD_DrawGoHere(v,p,c)
	MMHUD.interpolate(v,true)
	wrap(v,p,c)
	MMHUD.interpolate(v,false)
end

return HUD_DrawGoHere