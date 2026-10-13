local files={
    "core/core.lua", "core/theme.lua", "core/theme_ui.lua", "core/theme_welcome.lua",
    "core/first.lua", "modules/gui/base.lua", "modules/gui/elem.lua", "modules/gui/themes.lua", "modules/gui/tools.lua",
}
for _,path in ipairs(files) do
    local f,err=loadfile(path)
    if not f then error(path..": "..err) end
end
print("PASS Milestone 2 syntax: "..#files.." Lua files")
