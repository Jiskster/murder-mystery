--i swear we had this before...
local sglib = MM.require "Libs/sglib"
local function clamp(minimum,value,maximum)
	if maximum < minimum
		local temp = minimum
		minimum = maximum
		maximum = temp
	end
	return max(minimum,min(maximum,value))
end

local function wrap(v,p,c)
	if not (p.mo and p.mo.valid) then return end
	if (p.spectator) then return end
	if (MM_N.gameover) then return end
	
	-- i hate splitscreen
	local sci_w = (v.width() / v.dupx())
	local sci_h = (v.height() / v.dupy())
	local sc_w = sci_w*FU
	local sc_h = sci_h*FU
	local sch_w = (sci_w - BASEVIDWIDTH)*FU/2
	local sch_h = (sci_h - BASEVIDHEIGHT)*FU/2
	
	for k, att in ipairs(p.mm.attract)
		local dest = {
			x = att.x,
			y = att.y,
			z = att.z
		}
		
		-- i think its fine if we pass a table instead, sglib doesnt need
		-- anything outside of coords anyways
		local to_screen = sglib.ObjectTracking(v,p,c,dest)
		local x = to_screen.x
		local y = to_screen.y
		local snap = 0
		local patch = att.patch
		
		local base = to_screen.base
		
		local offscreen = false
		if to_screen.x + sch_w <= 0 or to_screen.x + sch_w >= sc_w
			offscreen = true
		end
		/*
		if to_screen.y + sch_h <= 0 or to_screen.y + sch_h >= (sc_h * 6/5)
			offscreen = true
		end
		*/
		local angdiff = base.viewangle - R_PointToAngle2(base.viewx,base.viewy, dest.x,dest.y)
		if abs(angdiff) > FixedAngle(base.fov)
			offscreen = true
		end
		
		if offscreen
			local border = 30
			local center = {
				x = 160*FU,
				y = 100*FU,
			}
			local scr = {
				x = (160 - border)*FU + sch_w,
				y = (100 - border)*FU + sch_h,
			}
			x = center.x + FixedMul(scr.x, sin(to_screen.angle))
			y = center.y - FixedMul(scr.y, cos(to_screen.angle))

			-- whatever
			if (patch == "MM_BEARTRAP_OUT")
				MMHUD.interpolate(v,k)
				v.drawScaled(x, y,
					FU/2,
					v.getSpritePatch(SPR_BGLS, W, 0, 
						InvAngle(angdiff) + ANGLE_90
					),
					snap
				)

				patch = "MM_BEARTRAP_OUT2"
			end
		end

		MMHUD.interpolate(v,k)
		if (att.str ~= nil)
			v.drawString(x, y,
				att.str,
				V_SMALLSCALEPATCH|V_ALLOWLOWERCASE|snap,
				"thin-fixed-center"
			)
		end
		if (patch ~= nil)
			v.drawScaled(x, y,
				FU/2,
				v.cachePatch(patch),
				snap
			)
		end
		MMHUD.interpolate(v,false)
	end
end

local function HUD_DrawGoHere(v,p,c)
	wrap(v,p,c)
end

return HUD_DrawGoHere