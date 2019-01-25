local mod = get_mod("compare_items")

local pl = require'pl.import_into'()

local sup_table = {}
local inf_table = {}
local inf_offset_table1 = {}
local inf_offset_table2 = {}
local dup_table = {}
local sim_table = {}
local sim_offset_table1 = {}
local sim_offset_table2 = {}

local item_text_style = {
	font_size = 15,
	word_wrap = false,
	pixel_perfect = true,
	horizontal_alignment = "left",
	vertical_alignment = "center",
	dynamic_font = true,
	font_type = "hell_shark",
	text_color = Colors.get_color_table_with_alpha("white", 255),
	size = {
		30,
		38
	},
	offset = {
		220+5,
		35+42,
		6
	}
}

local reload = false

local function table_contains(list, query)
	for _, item in pairs(list) do
		if item == query then
			return true
		end
	end
	return false
end

local function two_dim_table_contains(list, query)
	for _, list2 in pairs(list) do
		for _, item in pairs(list2) do
			if item == query then
				return true
			end
		end
	end
	return false
end

local function get_table_index(list, query)
	for i = 1,#list,1 do
		if list[i] == query then
			return i
		end
	end
	return 0
end

local function get_outer_table_index(list, query)
	for i = 1,#list,1 do
		for _, item in pairs(list[i]) do
			if item == query then
				return i
			end
		end
	end
	return 0
end

local function get_rarity_value(rarity)
	if rarity == "default" then
		return 0
	elseif rarity == "common" then
		return 1
	elseif rarity == "rare" then
		return 2
	elseif rarity == "exotic" then
		return 3
	elseif rarity == "unique" then
		return 4
	end
end

local function get_item_property(properties, position)
	local item_buff_name = ""
	local index = 1
	
	if properties then
		for property_key, property_value in pairs(properties) do
			if index == position then
				local property_data = WeaponProperties.properties[property_key]
				item_buff_name = property_data.buff_name
			end
			index = index + 1
		end
	end
	
	return item_buff_name
end

local function get_item_property_value(properties, position)
	local item_buff_value = 0
	local index = 1
	
	if properties then
		for property_key, property_value in pairs(properties) do
			if index == position then
				local property_data = WeaponProperties.properties[property_key]
				local buff_name = property_data.buff_name
				if buff_name == "properties_movespeed" then
					item_buff_value = 1
				else
					item_buff_value = property_value
				end
			end
			index = index + 1
		end
	end
	
	return item_buff_value
end

local function get_item_trait(traits)
	local item_buff_name = ""
	
	if traits then
		for _, trait_key in pairs(traits) do
			local trait_data = WeaponTraits.traits[trait_key]
			item_buff_name = trait_data.buff_name
		end
	end
	
	return item_buff_name
end

local function group_by_properties_and_trait(items)
	local groupings = {}
	local index = 1
	
	for _, item1 in pairs(items) do
		
		if not two_dim_table_contains(groupings, item1) then
			local data1 = item1.data
			local backend_id1 = item1.backend_id
			local group = {}
			
			for _, item2 in pairs(items) do
		
				local data2 = item2.data
				local backend_id2 = item2.backend_id
			
				local traits1 = item1.traits
				local traits2 = item2.traits
			
				local item1_trait = get_item_trait(traits1)
				local item2_trait = get_item_trait(traits2)
			
				if backend_id1 ~= backend_id2 and data1.item_type == data2.item_type and item1.power_level == item2.power_level and item1_trait == item2_trait then
				
					local properties1 = item1.properties
					local properties2 = item2.properties
				
					local item1_buff_name1 = get_item_property(properties1, 1)
					local item1_buff_name2 = get_item_property(properties1, 2)
					local item2_buff_name1 = get_item_property(properties2, 1)
					local item2_buff_name2 = get_item_property(properties2, 2)
				
					if item1_buff_name1 == item2_buff_name1 and item1_buff_name2 == item2_buff_name2 then
						if not table_contains(group, item1) then
							group[#group+1] = item1
						end
						group[#group+1] = item2
					end
				end
			end
			
			if #group ~= 0 then
				groupings[#groupings+1] = group
			end
		end
	end
	return groupings
end

local is_superior = function(backend_id)
	return two_dim_table_contains(sup_table, backend_id)
end

local is_inferior = function(backend_id)
	return two_dim_table_contains(inf_table, backend_id)
end

local is_duplicate = function(backend_id)
	return two_dim_table_contains(dup_table, backend_id)
end

local is_similar = function(backend_id)
	return two_dim_table_contains(sim_table, backend_id)
end

mod.remove_passes = function(self, widget)
	local passes = widget.element.passes
	
	widget.element.dirty = true
	local inf_pass_index = nil
	for i, pass in ipairs(passes) do
		if pass.text_id == "text_inf" then
			inf_pass_index = i
			break
		end
	end
	local sup_dup_pass_index = nil
	for i, pass in ipairs(passes) do
		if pass.text_id == "text_sup_dup" then
			sup_dup_pass_index = i
			break
		end
	end
	local sup_pass_index = nil
	for i, pass in ipairs(passes) do
		if pass.text_id == "text_sup" then
			sup_pass_index = i
			break
		end
	end
	local dup_pass_index = nil
	for i, pass in ipairs(passes) do
		if pass.text_id == "text_dup" then
			dup_pass_index = i
			break
		end
	end
	local sim_pass_index = nil
	for i, pass in ipairs(passes) do
		if pass.text_id == "text_sim" then
			sim_pass_index = i
			break
		end
	end
	if inf_pass_index then
		table.remove(passes, inf_pass_index)
	end
	if sup_dup_pass_index then
		table.remove(passes, sup_dup_pass_index)
	end
	if sup_pass_index then
		table.remove(passes, sup_pass_index)
	end
	if dup_pass_index then
		table.remove(passes, dup_pass_index)
	end
	if sim_pass_index then
		table.remove(passes, sim_pass_index)
	end
	local new_passes
	mod:pcall(function()
		new_passes = pl.seq(passes):filter(
			function(pass)
				return not pass.text_id or pass.text_id ~= 'text_inf' or pass.text_id ~= 'text_sup_dup' or pass.text_id ~= 'text_sup' or pass.text_id ~= 'text_dup' or pass.text_id ~= 'text_sim'
			end):copy()
	end)

	if new_passes then
		widget.element.passes = new_passes
	end
	
	widget.element.dirty = true
end

mod.create_passes = function(self, widget)
	local passes = widget.element.passes
	local content = widget.content
	
	local rows = content.rows
	local columns = content.columns
	
	for i = 1, rows, 1 do
		for k = 1, columns, 1 do
			local item_key = "item_" .. tostring(i) .. "_" .. tostring(k)
			if widget.content[item_key] then
				local backend_id = widget.content[item_key].backend_id
					
				local style_key = "text_" .. tostring(i) .. "_" .. tostring(k)

				widget.style[style_key] = table.clone(item_text_style)

				widget.style[style_key].offset = table.clone(widget.style["item_icon_" .. tostring(i) .. "_" .. tostring(k)].offset)
				widget.style[style_key].offset[1] = widget.style[style_key].offset[1] + 8
				widget.style[style_key].offset[2] = widget.style[style_key].offset[2] + 41
				widget.style[style_key].offset[3] = 10
					
				if is_inferior(backend_id) then
					widget.content[item_key].text_inf = "-"..get_outer_table_index(inf_table, backend_id)
				else
					widget.content[item_key].text_inf = "-"
				end
				if is_superior(backend_id) and is_duplicate(backend_id) then
					widget.content[item_key].text_sup_dup = "+"..get_outer_table_index(sup_table, backend_id).."="..get_outer_table_index(dup_table, backend_id)
				else
					widget.content[item_key].text_sup_dup = "+="
				end
				if is_superior(backend_id) then
					widget.content[item_key].text_sup = "+"..get_outer_table_index(sup_table, backend_id)
				else
					widget.content[item_key].text_sup = "+"
				end
				if is_duplicate(backend_id) then
					widget.content[item_key].text_dup = "="..get_outer_table_index(dup_table, backend_id)
				else
					widget.content[item_key].text_dup = "="
				end
				if is_similar(backend_id) then
					widget.content[item_key].text_sim = "~"..get_outer_table_index(sim_table, backend_id)
				else
					widget.content[item_key].text_sim = "~"
				end
					
				--mod:echo(tostring(i)..","..tostring(k))
				--mod:echo(tostring(is_inferior(backend_id))..","..tostring(is_superior(backend_id))..","..tostring(is_duplicate(backend_id))..","..tostring(is_similar(backend_id)))
					
				passes[#passes + 1] = {
					text_id = "text_inf",
					content_id = item_key,
					pass_type = "text",
					style_id = style_key,
					content_check_function = function(content)
						return is_inferior(content.backend_id)
					end,
				}
				widget.element.pass_data[#passes] = {
					text_id = "text_inf",
					content_id = item_key,
				}
				passes[#passes + 1] = {
					text_id = "text_sup_dup",
					content_id = item_key,
					pass_type = "text",
					style_id = style_key,
					content_check_function = function(content)
						return is_superior(content.backend_id) and is_duplicate(content.backend_id)
					end,
				}
				widget.element.pass_data[#passes] = {
					text_id = "text_sup_dup",
					content_id = item_key,
				}
				passes[#passes + 1] = {
					text_id = "text_sup",
					content_id = item_key,
					pass_type = "text",
					style_id = style_key,
					content_check_function = function(content)
						return is_superior(content.backend_id) and not is_duplicate(content.backend_id)
					end,
				}
				widget.element.pass_data[#passes] = {
					text_id = "text_sup",
					content_id = item_key,
				}
				passes[#passes + 1] = {
					text_id = "text_dup",
					content_id = item_key,
					pass_type = "text",
					style_id = style_key,
					content_check_function = function(content)
						return is_duplicate(content.backend_id) and not is_superior(content.backend_id)
					end,
				}
				widget.element.pass_data[#passes] = {
					text_id = "text_dup",
					content_id = item_key,
				}
				passes[#passes + 1] = {
					text_id = "text_sim",
					content_id = item_key,
					pass_type = "text",
					style_id = style_key,
					content_check_function = function(content)
						return is_similar(content.backend_id)
					end,
				}
				widget.element.pass_data[#passes] = {
					text_id = "text_sim",
					content_id = item_key,
				}
			end
		end
	end
end


mod:hook(HeroWindowLoadoutInventory, "on_exit", function (func, self, ...)
	reload = true
	local widget = self._item_grid._widget
	mod:remove_passes(widget)
	return func(self, ...)
end)

mod:hook(HeroWindowLoadoutInventory, "update", function (func, self, ...)
	local widget = self._item_grid._widget
	if not widget.content.item_1_2 then
		mod:remove_passes(widget)
		return func(self, ...)
	end
	if not widget.style.text_inf or reload then
		widget.style.text_inf = table.clone(item_text_style)
	end
	if not widget.style.text_sup_dup or reload then
		widget.style.text_sup_dup = table.clone(item_text_style)
	end
	if not widget.style.text_sup or reload then
		widget.style.text_sup = table.clone(item_text_style)
	end
	if not widget.style.text_dup or reload then
		widget.style.text_dup = table.clone(item_text_style)
	end
	if not widget.style.text_sim or reload then
		widget.style.text_sim = table.clone(item_text_style)
	end
	
	widget.content.text_inf = "-"
	widget.content.text_sup_dup = "+="
	widget.content.text_sup = "+"
	widget.content.text_dup = "="
	widget.content.text_sim = "~"
	
	if not self._created or reload then
		mod:create_passes(widget)
		self._created = true
	end
	widget.element.dirty = true

	if reload then
		reload = false
	end

	return func(self, ...)
end)

mod:hook(ItemGridUI, "_populate_inventory_page", function (func, self, ...)
	local widget = self._widget
	mod:remove_passes(widget)
	func(self, ...)
	mod:create_passes(widget)
end)

local DEFAULT_START_LAYER = 994
local function get_text_height(ui_renderer, size, ui_style, ui_content, text, ui_style_global)
	local widget_scale = nil

	if ui_style_global then
		widget_scale = ui_style_global.scale
	end

	local font_material, font_size, font_name = nil

	if ui_style.font_type then
		local font, size_of_font = UIFontByResolution(ui_style, widget_scale)
		font_name = font[3]
		font_size = font[2]
		font_material = font[1]
		font_size = size_of_font
	else
		local font = ui_style.font
		font_name = font[3]
		font_size = font[2]
		font_material = font[1]

		if not ui_style.font_size then
		end
	end

	if ui_style.localize then
		text = Localize(text)
	end

	local font_height, font_min, font_max = UIGetFontHeight(ui_renderer.gui, font_name, font_size)
	local texts = UIRenderer.word_wrap(ui_renderer, text, font_material, font_size, size[1])
	local text_start_index = ui_content.text_start_index or 1
	local max_texts = ui_content.max_texts or #texts
	local num_texts = math.min(#texts - text_start_index - 1, max_texts)
	local inv_scale = RESOLUTION_LOOKUP.inv_scale
	local full_font_height = (font_max + math.abs(font_min))*inv_scale*num_texts

	return full_font_height
end

local function is_chest(item_data)
	local item_type = item_data.item_type
	return item_type == "loot_chest"
end

UITooltipPasses.title = {
	setup_data = function ()
		local data = {
			text_pass_data = {
				text_id = "text"
			},
			text_size = {},
			content = {
				prefix_text = "placeholder"
			},
			style = {
				text = {
					vertical_alignment = "center",
					name = "description",
					localize = false,
					word_wrap = true,
					font_size = 18,
					horizontal_alignment = "center",
					font_type = "hell_shark",
					text_color = Colors.get_color_table_with_alpha("orange", 255)
				}
			}
		}

		return data
	end,
	draw = function (draw, ui_renderer, pass_data, ui_scenegraph, pass_definition, ui_style, ui_content, position, size, input_service, dt, ui_style_global, item, data, draw_downwards)
		local alpha_multiplier = pass_data.alpha_multiplier
		local alpha = 255 * alpha_multiplier
		local start_layer = pass_data.start_layer or DEFAULT_START_LAYER
		local frame_margin = data.frame_margin or 0
		local style = data.style
		local content = data.content

		local backend_id = item.backend_id

		if is_chest(item.data) then
			return 0
		end
		
		if is_inferior(backend_id) or is_superior(backend_id) or is_duplicate(backend_id) or is_similar(backend_id) then
			if is_inferior(backend_id) then
				content.text = "Inferior ("..get_outer_table_index(inf_table, backend_id)..")"
			elseif is_superior(backend_id) then
				if is_duplicate(backend_id) then
					content.text = "Superior ("..get_outer_table_index(sup_table, backend_id)..") / Duplicate ("..get_outer_table_index(dup_table, backend_id)..")"
				else
					content.text = "Superior ("..get_outer_table_index(sup_table, backend_id)..")"
				end
			elseif is_duplicate(backend_id) then
				content.text = "Duplicate ("..get_outer_table_index(dup_table, backend_id)..")"
			elseif is_similar(backend_id) then
				content.text = "Similar ("..get_outer_table_index(sim_table, backend_id)..")"
			end
			
			local position_x = position[1]
			local position_y = position[2]
			local position_z = position[3]
			position[3] = start_layer + 5
			local text_style = style.text
			local text_pass_data = data.text_pass_data
			local text_size = data.text_size
			text_size[1] = size[1] - frame_margin * 2
			text_size[2] = 0
			local text_height = -1*get_text_height(ui_renderer, text_size, text_style, content, content.text, ui_style_global)
			text_size[2] = text_height

			if draw then
				position[1] = position_x + frame_margin
				position[2] = position[2] - text_height
				text_style.text_color[1] = alpha

				UIPasses.text.draw(ui_renderer, text_pass_data, ui_scenegraph, pass_definition, text_style, content, position, text_size, input_service, dt, ui_style_global)
			end

			position[1] = position_x
			position[2] = position_y
			position[3] = position_z

			return text_height
		else
			return 0
		end
	end
}

UITooltipPasses.advanced_input_helper = {
	setup_data = function ()
		local frame_name = "item_tooltip_frame_01"
		local frame_settings = UIFrameSettings[frame_name]
		local data = {
			frame_name = "item_tooltip_frame_01",
			background_color = {
				240,
				3,
				3,
				3
			},
			text_pass_data = {
				text_id = "text"
			},
			text_size = {},
			frame_pass_data = {},
			frame_pass_definition = {
				texture_id = "frame",
				style_id = "frame"
			},
			frame_size = {
				0,
				0
			},
			content = {
				text = "placeholder",
				frame = frame_settings.texture
			},
			style = {
				frame = {
					texture_size = frame_settings.texture_size,
					texture_sizes = frame_settings.texture_sizes,
					color = {
						255,
						255,
						255,
						255
					},
					offset = {
						0,
						0,
						1
					}
				},
				text = {
					vertical_alignment = "center",
					font_size = 16,
					horizontal_alignment = "center",
					word_wrap = true,
					font_type = "hell_shark",
					text_color = Colors.get_color_table_with_alpha("font_title", 255)
				},
				background = {
					color = {
						255,
						10,
						10,
						10
					},
					offset = {
						0,
						0,
						-1
					}
				}
			}
		}

		return data
	end,
	draw = function (draw, ui_renderer, pass_data, ui_scenegraph, pass_definition, ui_style, ui_content, position, size, input_service, dt, ui_style_global, item, data, draw_downwards)
		local alpha_multiplier = pass_data.alpha_multiplier
		local alpha = 255 * alpha_multiplier
		local start_layer = pass_data.start_layer or DEFAULT_START_LAYER
		local frame_margin = data.frame_margin or 0
		local style = data.style
		local content = data.content

		if is_chest(item.data) then
			return 0
		end

		local position_x = position[1]
		local position_y = position[2]
		local position_z = position[3]
		local total_height = 0
		position[3] = start_layer - 6

		if (#pass_data.items == 2 or #pass_data.items == 3) and item ~= pass_data.items[1] then
			return 0
		end

		local backend_id = item.backend_id

		if is_inferior(backend_id) then
			content.text = "Inferior to other item(s)" -- with the same properties/trait
		elseif is_superior(backend_id) then
			if is_duplicate(backend_id) then
				content.text = "Superior to and a duplicate of other item(s)" -- with the same properties/trait
			else
				content.text = "Superior to other item(s)" -- with the same properties/trait
			end
		elseif is_duplicate(backend_id) then
			content.text = "A duplicate of other item(s)" -- with the same properties/trait
		elseif is_similar(backend_id) then
			content.text = "Similar to other item(s)" --  with the same properties/trait
		else
			return 0
		end

		if true then
			local text_style = style.text
			local text_pass_data = data.text_pass_data
			local text = content.text
			local text_size = data.text_size
			text_size[1] = size[1] - frame_margin*2
			text_size[2] = 0
			local text_height = -1 * get_text_height(ui_renderer, text_size, text_style, content, text, ui_style_global)
			total_height = total_height + text_height
			text_size[2] = text_height
			local frame_size = data.frame_size
			local frame_pass_data = data.frame_pass_data
			local frame_pass_definition = data.frame_pass_definition
			local frame_content = data.content
			local frame_style = data.style.frame
			frame_size[1] = text_size[1]
			frame_size[2] = text_size[2] + frame_margin/2
			total_height = total_height + frame_size[2]
			position[2] = position[2] - frame_size[2] - frame_margin/2
			position[1] = position[1] + frame_margin
			local old_y_position = position[2]

			if draw then
				local frame_color = frame_style.color
				frame_color[1] = alpha

				UIPasses.texture_frame.draw(ui_renderer, frame_pass_data, ui_scenegraph, frame_pass_definition, frame_style, frame_content, position, frame_size, input_service, dt, ui_style_global)

				local background_style = data.style.background
				local background_color = background_style.color
				background_color[1] = alpha
				position[3] = position[3] - 1

				UIRenderer.draw_rect(ui_renderer, position, frame_size, background_color)

				position[3] = position[3] + 1
			end

			position[2] = old_y_position + frame_margin/4
			text_size[1] = frame_size[1]

			if draw then
				local text_color = text_style.text_color
				text_color[1] = alpha

				UIPasses.text.draw(ui_renderer, text_pass_data, ui_scenegraph, pass_definition, text_style, content, position, text_size, input_service, dt, ui_style_global)
			end

			position[1] = position_x
			position[2] = position_y
			position[3] = position_z

			return 0
		end
	end
}


--[[
	Hooks
--]]

-- If you simply want to call a function after SomeObject.some_function has been executed
-- Arguments for SomeObject.some_function will be passed to my_function as well
--mod:hook_safe(ItemGridUI, "set_item_page", my_function)

-- If you want to do something more involved
mod:hook(ItemGridUI, "set_item_page", function (func, self, ...)
	sup_table = {}
	inf_table = {}
	inf_offset_table1 = {}
	inf_offset_table2 = {}
	dup_table = {}
	sim_table = {}
	sim_offset_table1 = {}
	sim_offset_table2 = {}

	local items = self._items
	
	local groupings = group_by_properties_and_trait(items)
	
	for _, group in pairs(groupings) do	
		local superior = {}
		local inferior = {}
		local inferior_offset1 = {}
		local inferior_offset2 = {}
		local duplicate = {}
		local similar = {}
		local similar_offset1 = {}
		local similar_offset2 = {}
		
		local max_property1 = 0
		local max_property2 = 0
		
		for _, item in pairs(group) do
			local properties = item.properties
		
			local item_buff_value1 = get_item_property_value(properties, 1)
			local item_buff_value2 = get_item_property_value(properties, 2)
			
			if item_buff_value1 > max_property1 then
				max_property1 = item_buff_value1
			end
			if item_buff_value2 > max_property2 then
				max_property2 = item_buff_value2
			end
		end
		
		for _, item in pairs(group) do
			local properties = item.properties
		
			local item_buff_value1 = get_item_property_value(properties, 1)
			local item_buff_value2 = get_item_property_value(properties, 2)
			
			if item_buff_value1 == max_property1 and item_buff_value2 == max_property2 then
				superior[#superior+1] = item.backend_id
			end
		end
		
		if #superior ~= 0 then
			for _, item in pairs(group) do
				local backend_id = item.backend_id
				if table_contains(superior, backend_id) == false then
					local properties = item.properties
		
					local item_buff_value1 = get_item_property_value(properties, 1)
					local item_buff_value2 = get_item_property_value(properties, 2)
				
					inferior[#inferior+1] = backend_id
					inferior_offset1[#inferior_offset1+1] = item_buff_value1 - max_property1
					inferior_offset2[#inferior_offset2+1] = item_buff_value2 - max_property2
				end
			end
			
			if #superior > 1 then
				duplicate = superior
			end
			if #inferior == 0 then
				superior = {}
			end
			
		else
			for _, item1 in pairs(group) do
				for _, item2 in pairs(group) do
					local backend_id1 = item1.backend_id
					local backend_id2 = item2.backend_id
				
					if backend_id1 ~= backend_id2 then
						local properties1 = item1.properties
						local properties2 = item2.properties
				
						local item1_buff_value1 = get_item_property_value(properties1, 1)
						local item1_buff_value2 = get_item_property_value(properties1, 2)
						local item2_buff_value1 = get_item_property_value(properties2, 1)
						local item2_buff_value2 = get_item_property_value(properties2, 2)
					
						if item1_buff_value1 == item2_buff_value1 and item1_buff_value2 == item2_buff_value2 then
							if not table_contains(duplicate, backend_id1) then
								duplicate[#duplicate+1] = backend_id1
							end
							if not table_contains(duplicate, backend_id2) then
								duplicate[#duplicate+1] = backend_id2
							end
						else
							if not table_contains(similar, backend_id1) then
								similar[#similar+1] = backend_id1
								similar_offset1[#similar_offset1+1] = item1_buff_value1 - item2_buff_value1
								similar_offset2[#similar_offset2+1] = item1_buff_value2 - item2_buff_value2
							end
							if not table_contains(similar, backend_id2) then
								similar[#similar+1] = backend_id2
								similar_offset1[#similar_offset1+1] = item2_buff_value1 - item1_buff_value1
								similar_offset2[#similar_offset2+1] = item2_buff_value2 - item1_buff_value2
							end
						end
					end	
				end
			end
		end
		
		sup_table[#sup_table+1] = superior
		inf_table[#inf_table+1] = inferior
		inf_offset_table1[#inf_offset_table1+1] = inferior_offset1
		inf_offset_table2[#inf_offset_table2+1] = inferior_offset2
		dup_table[#dup_table+1] = duplicate
		sim_table[#sim_table+1] = similar
		sim_offset_table1[#sim_offset_table1+1] = similar_offset1
		sim_offset_table2[#sim_offset_table2+1] = similar_offset2
	end
		
		

		-- mod:echo(item1.key)
	func(self, ...)
end)


mod:hook(UIPasses.item_tooltip, "init", function(func, pass_definition, ui_content, ui_style, style_global)
	local pass_data = func(pass_definition, ui_content, ui_style, style_global)
	table.insert(pass_data.passes, 4, {
			data = UITooltipPasses.title.setup_data(),
			draw = UITooltipPasses.title.draw
		})
	table.insert(pass_data.passes, #pass_data.passes + 1, {
			data = UITooltipPasses.advanced_input_helper.setup_data(),
			draw = UITooltipPasses.advanced_input_helper.draw
		})
	return pass_data
end)


--[[
	Callbacks
--]]

-- All callbacks are called even when the mod is disabled
-- Use mod:is_enabled() to check that the mod is enabled

-- Called on every update to mods
-- dt - time in milliseconds since last update
mod.update = function(dt)
	
end

-- Called when all mods are being unloaded
-- exit_game - if true, game will close after unloading
mod.on_unload = function(exit_game)
	
end

-- Called when game state changes (e.g. StateLoading -> StateIngame)
-- status - "enter" or "exit"
-- state  - "StateLoading", "StateIngame" etc.
mod.on_game_state_changed = function(status, state)
	
end

-- Called when a setting is changed in mod settings
-- Use mod:get(setting_name) to get the changed value
mod.on_setting_changed = function(setting_name)
	
end

-- Called when the checkbox for this mod is unchecked
-- is_first_call - true if called right after mod initialization
mod.on_disabled = function(is_first_call)

end

-- Called when the checkbox for this is checked
-- is_first_call - true if called right after mod initialization
mod.on_enabled = function(is_first_call)

end


--[[
	Initialization
--]]

-- Initialize and make permanent changes here
