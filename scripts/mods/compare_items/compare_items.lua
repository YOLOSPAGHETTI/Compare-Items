local mod = get_mod("compare_items")

local pl = require'pl.import_into'()

local sup_table = {}
local sup_property_offset_table1 = {}
local sup_property_offset_table2 = {}
local sup_property_offset_adjust_table1 = {}
local sup_property_offset_adjust_table2 = {}
local sup_power_offset_table = {}
local inf_table = {}
local inf_property_offset_table1 = {}
local inf_property_offset_table2 = {}
local inf_property_offset_adjust_table1 = {}
local inf_property_offset_adjust_table2 = {}
local inf_power_offset_table = {}
local dup_table = {}
local sim_table = {}
local sim_property_offset_table1 = {}
local sim_property_offset_table2 = {}
local sim_property_offset_adjust_table1 = {}
local sim_property_offset_adjust_table2 = {}
local sim_power_offset_table = {}

local item_text_style = {
	font_size = 18,
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

local function compare_traits(item1, item2)
	if mod:get(mod.SETTING_NAMES.LINK_ON_TRAIT) then
		local traits1 = item1.traits
		local traits2 = item2.traits
		
		local item1_trait = get_item_trait(traits1)
		local item2_trait = get_item_trait(traits2)
		
		return item1_trait == item2_trait
	else
		return true
	end
end

local function compare_power(item1, item2)
	if mod:get(mod.SETTING_NAMES.LINK_ON_POWER) then
		return item1.power_level == item2.power_level
	else
		return true
	end
end

local function group_items(items)
	local groupings = {}
	
	for _, item1 in pairs(items) do
		
		if not two_dim_table_contains(groupings, item1) then
			local data1 = item1.data
			local backend_id1 = item1.backend_id
			local group = {}
			
			for _, item2 in pairs(items) do
				local data2 = item2.data
				local backend_id2 = item2.backend_id
			
				if backend_id1 ~= backend_id2 and data1.item_type == data2.item_type and compare_power(item1, item2) and compare_traits(item1, item2) then
				
					local properties1 = item1.properties
					local properties2 = item2.properties
					
					local property_data1 = {}
	
					if properties1 then
						for property_key, property_value in pairs(properties1) do
							table.insert(property_data1, WeaponProperties.properties[property_key])
						end
					end
					
					local property_data2 = {}
					
					if properties2 then
						for property_key, property_value in pairs(properties2) do
							table.insert(property_data2, WeaponProperties.properties[property_key])
						end
					end
				
					local item1_buff_name1 = ""
					local item1_buff_name2 = ""
					local item2_buff_name1 = ""
					local item2_buff_name2 = ""
				
					if property_data1[1] then
						item1_buff_name1 = property_data1[1].buff_name
					end
					if property_data1[2] then
						item1_buff_name2 = property_data1[2].buff_name
					end
					if property_data2[1] then
						item2_buff_name1 = property_data2[1].buff_name
					end
					if property_data2[2] then
						item2_buff_name2 = property_data2[2].buff_name
					end
				
					if item1_buff_name1 == item2_buff_name1 and item1_buff_name2 == item2_buff_name2 then
						if not table_contains(group, item1) then
							table.insert(group, item1)
						end
						table.insert(group, item2)
					end
				end
			end
			
			if #group ~= 0 then
				table.insert(groupings, group)
			end
		end
	end
	return groupings
end

local function get_property_diff(property_data, lerp_value1, lerp_value2)
	if lerp_value1 == nil or lerp_value2 == nil then
		return 0
	end
	local display_value = nil
	local description_values = property_data.description_values
	
	if property_data.buff_name == "properties_movespeed" then
		return 0
	elseif description_values then
		local min_value, max_value = nil
		local data = description_values[1]
		local value_type = data.value_type
		local value = data.value

		if type(value) == "table" then
			if #value > 2 then
				local index1 = (lerp_value1 == 1 and #value) or 1 + math.floor(lerp_value1 / (1 / #value))
				local index2 = (lerp_value2 == 1 and #value) or 1 + math.floor(lerp_value2 / (1 / #value))
				display_value = value[index1] - value[index2]
			else
				min_value = value[1]
				max_value = value[2]
				display_value = math.abs(math.lerp(min_value, max_value, lerp_value1)) - math.abs(math.lerp(min_value, max_value, lerp_value2))
			end
		else
			display_value = value
		end

		if value_type == "percent" then
			display_value = 100 * display_value
		elseif value_type == "baked_percent" then
			display_value = 100 * (display_value - 1)
		end
	end
	return display_value
end

local function parse_offset_whole(value)
	local value_str = tostring(value)
	
	if value ~= 0 then
		if value > 0 then
			value_str = "+"..value_str
		end
		return value_str
	end

	return ""
end

local function parse_offset_dec(value)
	local new_value = math.floor(value*10+0.5)
	local new_value_str = tostring(new_value)
	
	if new_value ~= 0 then
		if string.len(new_value_str) == 1 then
			new_value_str = "+0."..new_value_str
		elseif string.sub(new_value_str,1,1) ~= "-" then
			new_value_str = "+"..string.sub(new_value_str,1,-2).."."..string.sub(new_value_str,-1,-1)
		elseif string.len(new_value_str) == 2 then
			new_value_str = "-0."..string.sub(new_value_str,2,-1)
		else
			new_value_str = string.sub(new_value_str,1,-2).."."..string.sub(new_value_str,-1,-1)
		end
		return new_value_str
	end

	return ""
end

local function adjust_first_offset_position(property_data, buff_value)
	local adjust = 0
	
	if property_data then
		local buff_name = property_data.buff_name
		
		if buff_name == "properties_block_cost" then
			adjust = -1
		elseif buff_name == "properties_protection_chaos" or buff_name == "properties_protection_skaven" then
			if buff_value == 1 then
				adjust = 1
			else
				adjust = -1
			end
		elseif buff_name == "properties_protection_aoe" then
			adjust = 1
		end
	end
	
	return adjust
end

local function adjust_second_offset_position(adjust1, property_data)
	local adjust2 = 0
	
	if property_data then
		local buff_name = property_data.buff_name
		
		if buff_name == "properties_block_cost" or buff_name == "properties_protection_chaos" or buff_name == "properties_protection_skaven" or buff_name == "properties_protection_aoe" then
			adjust2 = 1
		end
		
		if adjust1 > 0 then
			adjust2 = adjust2 + adjust1
		end
	end
	
	return adjust2
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
					
				local inf_style_key = "text_inf_" .. tostring(i) .. "_" .. tostring(k)
				local sup_style_key = "text_sup_" .. tostring(i) .. "_" .. tostring(k)
				local dup_style_key = "text_dup_" .. tostring(i) .. "_" .. tostring(k)
				local sim_style_key = "text_sim_" .. tostring(i) .. "_" .. tostring(k)

				widget.style[inf_style_key] = table.clone(item_text_style)
				widget.style[sup_style_key] = table.clone(item_text_style)
				widget.style[dup_style_key] = table.clone(item_text_style)
				widget.style[sim_style_key] = table.clone(item_text_style)

				widget.style[inf_style_key].offset = table.clone(widget.style["item_icon_" .. tostring(i) .. "_" .. tostring(k)].offset)
				widget.style[inf_style_key].offset[1] = widget.style[inf_style_key].offset[1] + 8
				widget.style[inf_style_key].offset[2] = widget.style[inf_style_key].offset[2] + 41
				widget.style[inf_style_key].offset[3] = 10
				widget.style[inf_style_key].text_color = Colors.get_color_table_with_alpha("red", 255)
				
				widget.style[sup_style_key].offset = table.clone(widget.style["item_icon_" .. tostring(i) .. "_" .. tostring(k)].offset)
				widget.style[sup_style_key].offset[1] = widget.style[sup_style_key].offset[1] + 8
				widget.style[sup_style_key].offset[2] = widget.style[sup_style_key].offset[2] + 41
				widget.style[sup_style_key].offset[3] = 10
				widget.style[sup_style_key].text_color = Colors.get_color_table_with_alpha("green", 255)
				
				widget.style[dup_style_key].offset = table.clone(widget.style["item_icon_" .. tostring(i) .. "_" .. tostring(k)].offset)
				widget.style[dup_style_key].offset[1] = widget.style[dup_style_key].offset[1] + 8
				widget.style[dup_style_key].offset[2] = widget.style[dup_style_key].offset[2] + 41
				widget.style[dup_style_key].offset[3] = 10
				widget.style[dup_style_key].text_color = Colors.get_color_table_with_alpha("white", 255)
				
				widget.style[sim_style_key].offset = table.clone(widget.style["item_icon_" .. tostring(i) .. "_" .. tostring(k)].offset)
				widget.style[sim_style_key].offset[1] = widget.style[sim_style_key].offset[1] + 8
				widget.style[sim_style_key].offset[2] = widget.style[sim_style_key].offset[2] + 41
				widget.style[sim_style_key].offset[3] = 10
				widget.style[sim_style_key].text_color = Colors.get_color_table_with_alpha("yellow", 255)
					
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
					
				passes[#passes + 1] = {
					text_id = "text_inf",
					content_id = item_key,
					pass_type = "text",
					style_id = inf_style_key,
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
					style_id = sup_style_key,
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
					style_id = sup_style_key,
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
					style_id = dup_style_key,
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
					style_id = sim_style_key,
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
local FONT_SIZE_MULTIPLIER = 1.4

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

		font_size = ui_style.font_size or font_size
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

	return full_font_height, num_texts
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

UITooltipPasses.power_offset = {
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
					font_size = 30,
					horizontal_alignment = "left",
					font_type = "hell_shark",
					text_color = Colors.get_color_table_with_alpha("orange", 255),
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
		
		if is_inferior(backend_id) or is_superior(backend_id) or is_similar(backend_id) then
			if is_inferior(backend_id) then
				local outer_index = get_outer_table_index(inf_table, backend_id)
				local inner = inf_table[outer_index]
				local offset_inner = inf_power_offset_table[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				content.text = parse_offset_whole(offset)
			elseif is_superior(backend_id) then
				local outer_index = get_outer_table_index(sup_table, backend_id)
				local inner = sup_table[outer_index]
				local offset_inner = sup_power_offset_table[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				content.text = parse_offset_whole(offset)
			elseif is_similar(backend_id) then
				local outer_index = get_outer_table_index(sim_table, backend_id)
				local inner = sim_table[outer_index]
				local offset_inner = sim_power_offset_table[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				if offset > 0 then
					style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				else
					style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				end
				content.text = parse_offset_whole(offset)
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
			local text_height = 0
			text_size[2] = text_height
			
			if draw then
				position[1] = position_x + frame_margin + 75
				position[2] = position[2] - get_text_height(ui_renderer, text_size, text_style, content, content.text, ui_style_global)
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

UITooltipPasses.property1_offset = {
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
					horizontal_alignment = "right",
					font_type = "hell_shark",
					text_color = Colors.get_color_table_with_alpha("orange", 255),
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
		
		local adjust = 0
		
		if is_inferior(backend_id) or is_superior(backend_id) or is_similar(backend_id) then
			if is_inferior(backend_id) then
				local outer_index = get_outer_table_index(inf_table, backend_id)
				local inner = inf_table[outer_index]
				local offset_inner = inf_property_offset_table1[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				local adjust_inner = inf_property_offset_adjust_table1[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
			elseif is_superior(backend_id) then
				local outer_index = get_outer_table_index(sup_table, backend_id)
				local inner = sup_table[outer_index]
				local offset_inner = sup_property_offset_table1[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				local adjust_inner = sup_property_offset_adjust_table1[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
			elseif is_similar(backend_id) then
				local outer_index = get_outer_table_index(sim_table, backend_id)
				local inner = sim_table[outer_index]
				local offset_inner = sim_property_offset_table1[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				if offset > 0 then
					style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				else
					style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				end
				local adjust_inner = sim_property_offset_adjust_table1[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
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
			local text_height = 0
			text_size[2] = text_height
			
			if draw then
				position[1] = position_x + frame_margin
				local base_height = get_text_height(ui_renderer, text_size, text_style, content, content.text, ui_style_global)
				position[2] = position[2] + base_height + base_height*adjust
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

UITooltipPasses.property2_offset = {
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
					horizontal_alignment = "right",
					font_type = "hell_shark",
					text_color = Colors.get_color_table_with_alpha("orange", 255),
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
		
		local adjust = 0
		
		if is_inferior(backend_id) or is_superior(backend_id) or is_similar(backend_id) then
			if is_inferior(backend_id) then
				local outer_index = get_outer_table_index(inf_table, backend_id)
				local inner = inf_table[outer_index]
				local offset_inner = inf_property_offset_table2[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				local adjust_inner = inf_property_offset_adjust_table2[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
			elseif is_superior(backend_id) then
				local outer_index = get_outer_table_index(sup_table, backend_id)
				local inner = sup_table[outer_index]
				local offset_inner = sup_property_offset_table2[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				local adjust_inner = sup_property_offset_adjust_table2[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
			elseif is_similar(backend_id) then
				local outer_index = get_outer_table_index(sim_table, backend_id)
				local inner = sim_table[outer_index]
				local offset_inner = sim_property_offset_table2[outer_index]
				local offset = offset_inner[get_table_index(inner, backend_id)]
				if offset > 0 then
					style.text.text_color = Colors.get_color_table_with_alpha("green", 255)
				else
					style.text.text_color = Colors.get_color_table_with_alpha("red", 255)
				end
				local adjust_inner = sim_property_offset_adjust_table2[outer_index]
				adjust = adjust_inner[get_table_index(inner, backend_id)]
				content.text = parse_offset_dec(offset)
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
			local text_height = 0
			text_size[2] = text_height
			
			if draw then
				position[1] = position_x + frame_margin
				local base_height = get_text_height(ui_renderer, text_size, text_style, content, content.text, ui_style_global)
				position[2] = position[2] + base_height*2 + base_height*adjust
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

mod:hook(ItemGridUI, "set_item_page", function (func, self, ...)
	sup_table = {}
	sup_property_offset_table1 = {}
	sup_property_offset_table2 = {}
	sup_property_offset_adjust_table1 = {}
	sup_property_offset_adjust_table2 = {}
	sup_power_offset_table = {}
	inf_table = {}
	inf_property_offset_table1 = {}
	inf_property_offset_table2 = {}
	inf_property_offset_adjust_table1 = {}
	inf_property_offset_adjust_table2 = {}
	inf_power_offset_table = {}
	dup_table = {}
	sim_table = {}
	sim_property_offset_table1 = {}
	sim_property_offset_table2 = {}
	sim_property_offset_adjust_table1 = {}
	sim_property_offset_adjust_table2 = {}
	sim_power_offset_table = {}

	local items = self._items
	
	local groupings = group_items(items)
	
	for _, group in pairs(groupings) do	
		local superior = {}
		local superior_property_offset1 = {}
		local superior_property_offset2 = {}
		local superior_property_offset_adjust1 = {}
		local superior_property_offset_adjust2 = {}
		local superior_power_offset = {}
		local inferior = {}
		local inferior_property_offset1 = {}
		local inferior_property_offset2 = {}
		local inferior_property_offset_adjust1 = {}
		local inferior_property_offset_adjust2 = {}
		local inferior_power_offset = {} 
		local duplicate = {}
		local similar = {}
		local similar_property_offset1 = {}
		local similar_property_offset2 = {}
		local similar_property_offset_adjust1 = {}
		local similar_property_offset_adjust2 = {}
		local similar_power_offset = {}
		
		local max_property1 = -1
		local max_property2 = -1
		local max_power = -1
		local next_property1 = -1
		local next_property2 = -1
		local next_power = -1
		
		for _, item in pairs(group) do
			local properties = item.properties
		
			local property_values = {}
	
			if properties then
				for property_key, property_value in pairs(properties) do
					table.insert(property_values, property_value)
				end
			end
		
			local power = item.power_level
			
			if property_values[1] > max_property1 then
				if max_property1 > next_property1 then
					next_property1 = max_property1
				end
				max_property1 = property_values[1]
			elseif property_values[1] > next_property1 and property_values[1] < max_property1 then
				next_property1 = property_values[1]
			end
			if property_values[2] then
				if property_values[2] > max_property2 then
					if max_property2 > next_property2 then
						next_property2 = max_property2
					end
					max_property2 = property_values[2]
				elseif property_values[2] > next_property2 and property_values[2] < max_property2 then
					next_property2 = property_values[2]
				end
			end
			if power > max_power then
				if max_power > next_power then
					next_power = max_power
				end
				max_power = power
			elseif power > next_power and power < max_power then
				next_power = power
			end
		end
		if next_property1 == -1 then
			next_property1 = max_property1
		end
		if next_property2 == -1 then
			next_property2 = max_property2
		end
		if next_power == -1 then
			next_power = max_power
		end
		
		for _, item in pairs(group) do
			local properties = item.properties
			
			local property_data = {}
			local property_values = {}
	
			if properties then
				for property_key, property_value in pairs(properties) do
					table.insert(property_data, WeaponProperties.properties[property_key])
					table.insert(property_values, property_value)
				end
			end
			
			local power = item.power_level
			
			if get_property_diff(property_data[1], property_values[1], max_property1) == 0 and get_property_diff(property_data[2], property_values[2], max_property2) == 0 and power == max_power then		
				local property_offset1 = get_property_diff(property_data[1], property_values[1], next_property1)
				local property_offset2 = get_property_diff(property_data[2], property_values[2], next_property2)
				local property_offset_adjust1 = adjust_first_offset_position(property_data[1], property_values[1])
				local property_offset_adjust2 = adjust_second_offset_position(property_offset_adjust1, property_data[2])
				local power_offset = power - next_power
				
				table.insert(superior, item.backend_id)
				table.insert(superior_property_offset1, property_offset1)
				table.insert(superior_property_offset2, property_offset2)
				table.insert(superior_property_offset_adjust1, property_offset_adjust1)
				table.insert(superior_property_offset_adjust2, property_offset_adjust2)
				table.insert(superior_power_offset, power_offset)
			end
		end
		
		if #superior ~= 0 then
			for _, item in pairs(group) do
				local backend_id = item.backend_id
				if not table_contains(superior, backend_id) then
					local properties = item.properties
		
					local property_data = {}
					local property_values = {}
		
					if properties then
						for property_key, property_value in pairs(properties) do
							table.insert(property_data, WeaponProperties.properties[property_key])
							table.insert(property_values, property_value)
						end
					end
					
					local power = item.power_level
				
					local property_offset1 = get_property_diff(property_data[1], property_values[1], max_property1)
					local property_offset2 = get_property_diff(property_data[2], property_values[2], max_property2)
					local property_offset_adjust1 = adjust_first_offset_position(property_data[1], property_values[1])
					local property_offset_adjust2 = adjust_second_offset_position(property_offset_adjust1, property_data[2])
					local power_offset = power - max_power
					
					table.insert(inferior, backend_id)
					table.insert(inferior_property_offset1, property_offset1)
					table.insert(inferior_property_offset2, property_offset2)
					table.insert(inferior_property_offset_adjust1, property_offset_adjust1)
					table.insert(inferior_property_offset_adjust2, property_offset_adjust2)
					table.insert(inferior_power_offset, power_offset)
				end
			end
			
			if #superior > 1 then
				duplicate = superior
			end
			if #inferior == 0 then
				superior = {}
				superior_property_offset1 = {}
				superior_property_offset2 = {}
				superior_power_offset = {}
			end
			
		else
			for _, item1 in pairs(group) do
				for _, item2 in pairs(group) do
					local backend_id1 = item1.backend_id
					local backend_id2 = item2.backend_id
				
					if backend_id1 ~= backend_id2 then
						local properties1 = item1.properties
						local properties2 = item2.properties
				
						local property_data1 = {}
						local property_values1 = {}
		
						if properties1 then
							for property_key, property_value in pairs(properties1) do
								table.insert(property_data1, WeaponProperties.properties[property_key])
								table.insert(property_values1, property_value)
							end
						end
						
						local property_data2 = {}
						local property_values2 = {}
		
						if properties2 then
							for property_key, property_value in pairs(properties2) do
								table.insert(property_data2, WeaponProperties.properties[property_key])
								table.insert(property_values2, property_value)
							end
						end
				
						local power1 = item1.power_level
						local power2 = item2.power_level
					
						if get_property_diff(property_data1[1], property_values1[1], property_values2[1]) == 0 and get_property_diff(property_data1[2], property_values1[2], property_values2[2]) == 0 and power1 == power2 then
							if not table_contains(duplicate, backend_id1) then
								table.insert(duplicate, backend_id1)
							end
							if not table_contains(duplicate, backend_id2) then
								table.insert(duplicate, backend_id2)
							end
						else
							if not table_contains(similar, backend_id1) then
								table.insert(similar, backend_id1)
								
								local property_offset1 = 0
								local property_offset2 = 0
								local power_offset = 0
								if get_property_diff(property_data1[1], property_values1[1], max_property1) == 0 then
									property_offset1 = get_property_diff(property_data1[1], property_values1[1], next_property1)
								else
									property_offset1 = get_property_diff(property_data1[1], property_values1[1], max_property1)
								end
								if get_property_diff(property_data1[2], property_values1[2], max_property2) == 0 then
									property_offset2 = get_property_diff(property_data1[2], property_values1[2], next_property2)
								else
									property_offset2 = get_property_diff(property_data1[2], property_values1[2], max_property2)
								end
								if power1 == max_power then
									power_offset = power1 - next_power
								else
									power_offset = power1 - max_power
								end
								
								local property_offset_adjust1 = adjust_first_offset_position(property_data1[1], property_values1[1])
								local property_offset_adjust2 = adjust_second_offset_position(property_offset_adjust1, property_data1[2])

								table.insert(similar_property_offset1, property_offset1)
								table.insert(similar_property_offset2, property_offset2)
								table.insert(similar_property_offset_adjust1, property_offset_adjust1)
								table.insert(similar_property_offset_adjust2, property_offset_adjust2)
								table.insert(similar_power_offset, power_offset)
							end
							if not table_contains(similar, backend_id2) then								
								table.insert(similar, backend_id2)
								
								local property_offset1 = 0
								local property_offset2 = 0
								local power_offset = 0
								
								if get_property_diff(property_data2[1], property_values2[1], max_property1) == 0 then
									property_offset1 = get_property_diff(property_data2[1], property_values2[1], next_property1)
								else
									property_offset1 = get_property_diff(property_data2[1], property_values2[1], max_property1)
								end
								if get_property_diff(property_data2[2], property_values2[2], max_property2) == 0 then
									property_offset2 = get_property_diff(property_data2[2], property_values2[2], next_property2)
								else
									property_offset2 = get_property_diff(property_data2[2], property_values2[2], max_property2)
								end
								if power2 == max_power then
									power_offset = power2 - next_power
								else
									power_offset = power2 - max_power
								end
								
								local property_offset_adjust1 = adjust_first_offset_position(property_data2[1], property_values2[1])
								local property_offset_adjust2 = adjust_second_offset_position(property_offset_adjust1, property_data2[2])

								table.insert(similar_property_offset1, property_offset1)
								table.insert(similar_property_offset2, property_offset2)
								table.insert(similar_property_offset_adjust1, property_offset_adjust1)
								table.insert(similar_property_offset_adjust2, property_offset_adjust2)
								table.insert(similar_power_offset, power_offset)
							end
						end
					end	
				end
			end
		end
		
		table.insert(sup_table, superior)
		table.insert(sup_property_offset_table1, superior_property_offset1)
		table.insert(sup_property_offset_table2, superior_property_offset2)
		table.insert(sup_property_offset_adjust_table1, superior_property_offset_adjust1)
		table.insert(sup_property_offset_adjust_table2, superior_property_offset_adjust2)
		table.insert(sup_power_offset_table, superior_power_offset)
		
		table.insert(inf_table, inferior)
		table.insert(inf_property_offset_table1, inferior_property_offset1)
		table.insert(inf_property_offset_table2, inferior_property_offset2)
		table.insert(inf_property_offset_adjust_table1, inferior_property_offset_adjust1)
		table.insert(inf_property_offset_adjust_table2, inferior_property_offset_adjust2)
		table.insert(inf_power_offset_table, inferior_power_offset)
		
		table.insert(dup_table, duplicate)
		
		table.insert(sim_table, similar)
		table.insert(sim_property_offset_table1, similar_property_offset1)
		table.insert(sim_property_offset_table2, similar_property_offset2)
		table.insert(sim_property_offset_adjust_table1, similar_property_offset_adjust1)
		table.insert(sim_property_offset_adjust_table2, similar_property_offset_adjust2)
		table.insert(sim_power_offset_table, similar_power_offset)
	end
		
	func(self, ...)
end)


mod:hook(UIPasses.item_tooltip, "init", function(func, pass_definition, ui_content, ui_style, style_global)
	local pass_data = func(pass_definition, ui_content, ui_style, style_global)
	table.insert(pass_data.passes, 4, {
			data = UITooltipPasses.title.setup_data(),
			draw = UITooltipPasses.title.draw
		})
	table.insert(pass_data.passes, 12, {
			data = UITooltipPasses.power_offset.setup_data(),
			draw = UITooltipPasses.power_offset.draw
		})
	table.insert(pass_data.passes, 13, {
			data = UITooltipPasses.property1_offset.setup_data(),
			draw = UITooltipPasses.property1_offset.draw
		})
	table.insert(pass_data.passes, 13, {
			data = UITooltipPasses.property2_offset.setup_data(),
			draw = UITooltipPasses.property2_offset.draw
		})
	table.insert(pass_data.passes, #pass_data.passes + 1, {
			data = UITooltipPasses.advanced_input_helper.setup_data(),
			draw = UITooltipPasses.advanced_input_helper.draw
		})
	return pass_data
end)
