ROOT = {}
ROOT.console = function()
    DISPLAY(Console)
end
ROOT.quit = function()
    wants_to_exit = true
end


cheats = {}
cheats.all_badges = false
cheats.instawarp = true
cheats.hide_pokemon_logo = true
cheats.walk_thru_walls = false
cheats.invisible2trainers = true
cheats.skip_oak_speech = true
cheats.fastwalk = true
cheats.repel = false
cheats.skip_intro = true
cheats.bike = false
cheats.always_win = false
cheats.skip_follow_oak = false

config = {}
if PLATFORM == '3ds' then
    config['audio (broken)'] = false
end
config.render_map = true
config.render_mgba = true
config.render_mgba_top = false
config.use_custom_tiles = false
config.show_hidden_sprites = false
config.show_item_hex = false

ROOT.config = config
ROOT.cheats = cheats
