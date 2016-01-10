local load_time_start = os.clock()

if minetest.setting_getbool("creative_mode") then

	local playerlist = {}

	minetest.register_tool("wz2100:nx_link", {
		description = "test",
		inventory_image = "wz2100_SpyTurret01.png",
		--wield_scale = {x=2,y=2,z=2},
		range = 14,
		tool_capabilities = {
			full_punch_interval = 1.0,
			max_drop_level=0,
			groupcaps={
				fleshy={times={[2]=0.80, [3]=0.40}, uses=20, maxlevel=1},
				snappy={times={[2]=0.80, [3]=0.40}, uses=20, maxlevel=1},
				choppy={times={[3]=0.90}, uses=20, maxlevel=0}
			}
		},
		on_use = function(_, user, pointed_thing)
			if not (user and pointed_thing) then
				return
			end
			local pname = user:get_player_name()
			local pos = minetest.get_pointed_thing_position(pointed_thing, under)
			if not (pos and pname) then
				return
			end
			local t1 = tonumber(os.clock())
			local t2 = playerlist[pname] or load_time_start
			if t1 < t2+2 then
				return
			end
			local node = minetest.get_node_or_nil(pos)
			if not node then
				return
			end
			local pp = user:getpos()
			minetest.sound_play("wz2100_nxstower", {pos = pp})
			playerlist[pname] = t1
			if node.name == "default:chest_locked" then
				local meta = minetest.get_meta(pos)
				if not meta then
					return
				end
				if meta:get_string("owner") == pname then
					minetest.chat_send_player(pname, "You already own this locked chest.")
				else
					meta:set_string("owner", pname or "")
					meta:set_string("infotext", "Locked Chest (owned by "..
						meta:get_string("owner")..")")
					minetest.chat_send_player(pname, "Now you are the owner of this locked chest.")
				end
				minetest.after(vector.distance(pos, pp)/10, function(pos)
					minetest.sound_play("wz2100_nxsexpld", {pos = pos})
				end, pos)
			end
		end,
	})
end

local v = 50
local a = 1
minetest.register_entity("wz2100:test",{
	hp_max = 1,
	visual="cube",
	visual_size={x=.33,y=.33},
	collisionbox = {0,0,0,0,0,0},
	physical=false,
	textures={"default_stone.png", "default_stone.png", "default_wood.png", "default_wood.png", "default_cobble.png"},
	on_step = function(self, dtime)
		local pos = self.object:getpos()
		local all_objects = minetest.get_objects_inside_radius(pos, 10)
		local dist = 10
		local i
		for n,obj in pairs(all_objects) do
			if obj:is_player()
			and obj:get_hp() > 0 then
				local dis = vector.distance(obj:getpos(), pos)
				if dis < dist
				and dis > 0 then
					dist = dis
					i = n
				end
			end
		end
		if not i then
			return
		end
		local used_obj = all_objects[i]

		local p2 = used_obj:getpos()
		p2.y = p2.y+1.625
		local dif = vector.subtract(p2, pos)
		local yaw = math.atan(dif.z/dif.x)+math.pi^2 --copied from the creatures mod
		if p2.x > pos.x then
			yaw = yaw+math.pi
		end
		yaw = yaw-2
		self.object:setyaw(yaw)
		local dir = vector.direction(pos, p2)
		local delay = vector.straightdelay(math.max(vector.distance(pos, p2), 0), v, a)
		minetest.after(delay, function(obj)
			obj:set_hp(obj:get_hp()-1)
		end, used_obj)
		minetest.add_particle(pos,
			vector.multiply(dir, v),
			vector.multiply(dir, a),
			delay,
			1, false, "default_stone.png^[transform"..math.random(0,7)
		)
		minetest.sound_play(minetest.sound_play("nuke_explode", {pos = pos}))
	end
	--[[on_activate = function(self, staticdata)
		if tmp.nodename ~= nil and tmp.texture ~= nil then
			self.nodename = tmp.nodename
			tmp.nodename = nil
			self.texture = tmp.texture
			tmp.texture = nil
		else
			if staticdata ~= nil and staticdata ~= "" then
				local data = staticdata:split(';')
				if data and data[1] and data[2] then
					self.nodename = data[1]
					self.texture = data[2]
				end
			end
		end
		if self.texture ~= nil then
			self.object:set_properties({textures={self.texture}})
		end
		if self.nodename == "itemframes:pedestal" then
			self.object:set_properties({automatic_rotate=1})
		end
	end,
	get_staticdata = function(self)
		if self.nodename ~= nil and self.texture ~= nil then
			return self.nodename .. ';' .. self.texture
		end
		return ""
	end,]]
})



local v = 1000
local a = 1
local r = 100

local function get_touched_obj(pos, r, dir, player)
	for _,obj in pairs(minetest.get_objects_inside_radius(pos, r)) do
		if not obj:is_player()
		or obj:get_player_name() ~= player:get_player_name() then
			local opos = obj:getpos()
			local dist = vector.distance(pos, opos)
			local sdir = vector.direction(pos, opos)
			local dirdif = vector.round(vector.multiply(vector.subtract(dir, sdir), 2/dist))
			if vector.equals(dirdif, vector.zero) then
				return obj
			end
		end
	end
end

local function shoot(player, range, particle_texture, sound)
	local t1 = os.clock()

	local playerpos=player:getpos()
	local dir=player:get_look_dir()

	local startpos = {x=playerpos.x, y=playerpos.y+1.625, z=playerpos.z}

	local obj = get_touched_obj(startpos, range, dir, player)
	if not obj then
		return
	end

	local bl, pos2 = minetest.line_of_sight(startpos, vector.add(vector.multiply(dir, range), startpos), 1)
	if not pos2 then
		return
	end
	local snd = minetest.sound_play(sound, {pos = playerpos, max_hear_distance = range})
	local delay = vector.straightdelay(math.max(vector.distance(startpos, pos2)-0.5, 0), v, a)
	if not bl then
		--
	end
	minetest.add_particle(startpos,
		vector.multiply(dir, v),
		vector.multiply(dir, a),
		delay,
		1, false, particle_texture.."^[transform"..math.random(0,7)
	)

	print("[] after "..tostring(os.clock()-t1).."s")
end

minetest.register_tool("wz2100:magun", {
	description = "Weapon",
	inventory_image = "default_stone.png",
	range = 0,
	stack_max = 1,
	on_use = function(_, user)
		shoot(user, r, "default_stone.png", "extrablocks_shot")
	end,
})

minetest.register_globalstep(function()
	for _,player in pairs(minetest.get_connected_players()) do
		if player:get_wielded_item():to_string() == "wz2100:magun"
		and player:get_player_control().LMB then
			shoot(player, r, "default_stone.png", "extrablocks_shot")
		end
	end
end)




minetest.log("info", string.format("[wz2100] loaded after ca. %.2fs", os.clock() - load_time_start))
