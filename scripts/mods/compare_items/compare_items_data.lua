local mod = get_mod("compare_items")

mod.SETTING_NAMES = {
	LINK_ON_TRAIT = "link_on_trait_text",
	LINK_ON_POWER = "link_on_power_text",
}

return {
	name = mod:localize("mod_name"),                -- Readable mod name
	description = mod:localize("mod_description"),  -- Mod description
	is_togglable = true,                            -- If the mod can be enabled/disabled
	options = {
		widgets = {
			{
				setting_id = mod.SETTING_NAMES.LINK_ON_TRAIT,
				type = "checkbox",
				tooltip = "link_on_trait_tip",
				default_value = true
			},
			{
				setting_id = mod.SETTING_NAMES.LINK_ON_POWER,
				type = "checkbox",
				tooltip = "link_on_power_tip",
				default_value = true
			}
		}
	}
}