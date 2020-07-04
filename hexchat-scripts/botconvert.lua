-- SPDX-License-Identifier: GPL-3.0-or-later -*- Lua -*-

local name = "botconvert.lua"
local ver = "0.1"
local desc = "Convert bot messages"

-- Register
hexchat.register(name, ver, desc)

local bots = {}

local saved_bots = hexchat.pluginprefs["botconvert_bots"]
for bot in string.gmatch(saved_bots, '[^,]+') do
    table.insert(bots, bot)
end

-- Converting function
local re = "^%[(..-)%] (.*)"
local matched = false
local function botconvert_cb(event, word)
    if matched then
        -- This event is from script, Don't do anything.
        matched = false
        return hexchat.EAT_NONE
    end
    local nick = word[1]
    local message = word[2]
    for _, bot in pairs(bots) do
        if hexchat.nickcmp(hexchat.strip(nick), bot) == 0 then
            local match_nick, match_message = message:match(re)

            if match_nick or match_message then
                matched = true
                hexchat.emit_print(event, match_nick, match_message)
                return hexchat.EAT_ALL
            end
        end
    end

    return hexchat.EAT_NONE
end

-- Command function
local help = "Usage: /botconvert [list | add <nick> | remove <nick>]"
local function cmd_botconvert_cb(word, eol)
    local command = word[2]
    if command == "list" then
        print("Defined bots:")
        for _, bot in pairs(bots) do
            print("-", bot)
        end
    elseif command == "add" then
        local add = word[3]
        if add then
            table.insert(bots, add)
            hexchat.pluginprefs["botconvert_bots"] = table.concat(bots, ",")
            print("Added bot:", add)
        else
            print("Argument error: <nick> was not found.")
            print(help)
        end
    elseif command == "remove" then
        local remove = word[3]
        if remove then
            for i, v in ipairs(bots) do
                if v == remove then
                    table.remove(bots, i)
                end
            end
            hexchat.pluginprefs["botconvert_bots"] = table.concat(bots, ",")
            print("Removed bot:", remove)
        else
            print("Argument error: <nick> was not found.")
            print(help)
        end
    else
        print(help)
    end
    return hexchat.EAT_HEXCHAT
end

-- Setup print hook
hexchat.hook_print("Channel Message", function(word) return botconvert_cb("Channel Message", word) end)
hexchat.hook_print("Channel Msg Hilight", function(word) return botconvert_cb("Channel Msg Hilight", word) end)
hexchat.hook_print("Channel Action", function(word) return botconvert_cb("Channel Action", word) end)
hexchat.hook_print("Channel Action Hilight", function(word) return botconvert_cb("Channel Action Hilight", word) end)

-- Command hook
hexchat.hook_command("BOTCONVERT", cmd_botconvert_cb, help)

-- Unload hook
hexchat.hook_unload(function() hexchat.pluginprefs["botconvert_bots"] = table.concat(bots, ",") end)

-- vim:ts=4:sw=4:et:ft=lua
