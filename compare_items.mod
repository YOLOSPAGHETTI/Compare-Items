return {
	run = function()
		fassert(rawget(_G, "new_mod"), "compare_items must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("compare_items", {
			mod_script       = "scripts/mods/compare_items/compare_items",
			mod_data         = "scripts/mods/compare_items/compare_items_data",
			mod_localization = "scripts/mods/compare_items/compare_items_localization"
		})
	end,
	packages = {
		"resource_packages/compare_items/compare_items"
	}
}
