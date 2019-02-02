local mod = get_mod("compare_items")

-- Everything here is optional. You can remove unused parts.
return {
	name = "Compare Items",                               -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = true,                            -- If the mod can be enabled/disabled
	is_mutator = false,                             -- If the mod is mutator
	mutator_settings = {},                          -- Extra settings, if it's mutator
	options_widgets = {                             -- Widget settings for the mod options menu
		{
			["setting_name"] = "link_on_trait",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("link_on_trait_text"),
			["tooltip"] = mod:localize("link_on_trait_tip"),
			["default_value"] = true
		},
		{
			["setting_name"] = "link_on_power",
			["widget_type"] = "checkbox",
			["text"] = mod:localize("link_on_power_text"),
			["tooltip"] = mod:localize("link_on_power_tip"),
			["default_value"] = true
		}
	}
}