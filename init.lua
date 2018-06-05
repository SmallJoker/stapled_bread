local function try_staple(itemstack, placer, pointed)
	if pointed.type ~= "node" then
		return
	end
	if pointed.above.y - pointed.under.y ~= 0 then
		return
	end

	-- Node under must be a tree
	local node_under = minetest.get_node(pointed.under)
	local def_under = minetest.registered_nodes[node_under.name] or {}
	if not def_under.groups or not def_under.groups.tree then
		return
	end
	if def_under.paramtype2 == "facedir"
			or def_under.paramtype2 == "colorfacedir" then
		-- Only vertical facedirs are allowed
		local dir = minetest.wallmounted_to_dir(node_under.param2)
		if dir.x ~= 0 or dir.z ~= 0 then
			return
		end
	end

	-- Node above must be airlike, but not ignore
	local node_above = minetest.get_node(pointed.above)
	local def_above = minetest.registered_nodes[node_above.name] or {}
	if node_above.name == "ignore" or not def_above.buildable_to then
		return
	end

	-- Staple to the tree
	local dir = vector.direction(pointed.above, pointed.under)
	local pos = minetest.pointed_thing_to_face_pos(placer, pointed)
	local obj = minetest.add_entity(
		vector.add(pos, vector.multiply(dir, -0.01)),
		"stapled_bread:bread_slice"
	)
	if obj then
		local entity = obj:get_luaentity()
		if not creative or not creative.is_enabled_for(
				placer:get_player_name()) then
			itemstack:take_item(1)
		end
		entity.object:set_yaw(math.atan2(-dir.x, dir.z))
		entity.object:set_properties({
			textures = { itemstack:get_name() }
		})
	end
	return itemstack
end

local function staple_place_wrapper(itemstack, placer, pointed_thing)
	return try_staple(itemstack, placer, pointed_thing) or itemstack
end

local extent = 0.12
local box = {-extent, -extent, -extent, extent, extent, extent}
minetest.register_entity("stapled_bread:bread_slice", {
	visual = "wielditem",
	textures = { "unknown_node.png" },
	visual_size = {x = 0.2, y = 0.2},
	physical = false,
	collisionbox = box,
	selectionbox = box,
	get_staticdata = function(self)
		return self.object:get_properties().textures[1]
	end,
	on_activate = function(self, staticdata, dtime_s)
		if staticdata and staticdata ~= "" then
			self.object:set_properties({
				textures = { staticdata }
			})
		end
	end
})

-- REGISTER BREAD STUFF

minetest.override_item("farming:bread", {
	on_place = staple_place_wrapper
})

minetest.register_craftitem("stapled_bread:bread_slice", {
	description = "Bread Slice",
	inventory_image = "stapled_bread_slice.png",
	on_use = minetest.item_eat(1),
	on_place = staple_place_wrapper
})

minetest.register_craft({
	type = "shapeless",
	output = "stapled_bread:bread_slice 5",
	recipe = {
		"farming:bread"
	}
})
