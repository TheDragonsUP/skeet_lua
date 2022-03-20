local roll_checkbox = ui.new_checkbox("AA", "Other", "Roll invert key")
local MM_enable = ui.new_checkbox("AA", "Anti-aimbot angles", "\aB6B665FFForce roll")
local roll_hotkey = ui.new_hotkey("AA", "Other", "Roll invert key", true)
local disablers = ui.new_multiselect("AA", "Other", "Roll disablers", "Quick peek assist", "Duck peek assist", "Edge yaw", "Velocity", "Jump at edge")
local disablers_hk = ui.new_hotkey("AA", "Other", "\n", true)
local velocity_slider = ui.new_slider("AA","Other", "Velocity limit", 2, 135)

local aa_ref = ui.reference("AA", "Anti-aimbot angles", "Enabled")
local roll_ref = ui.reference("AA", "Anti-aimbot angles", "Roll")
local qps_ref = ui.reference("RAGE", "OTHER", "Quick Peek assist")
local fd_ref = ui.reference("RAGE", "Other", "Duck peek assist")
local edge_ref = ui.reference("AA", "Anti-aimbot angles", "Edge yaw")
local fl_limit_ref = ui.reference("AA", "Fake lag", "Limit")
local edge_jump_ref = ui.reference("MISC", "Movement", "Jump at edge")

local csgo_weapons = require "gamesense/csgo_weapons"

local ffi = require("ffi")
local gamerules_ptr = client.find_signature("client.dll", "\x83\x3D\xCC\xCC\xCC\xCC\xCC\x74\x2A\xA1")
local gamerules = ffi.cast("intptr_t**", ffi.cast("intptr_t", gamerules_ptr) + 2)[0]

local return_fl = return_fl
local is_valve_ds_spoofed = 0

local function contains(tbl, val) 
    for i=1, #tbl do
        if tbl[i] == val then return true end 
    end 
    return false 
end

client.set_event_callback("setup_command", function(cmd)
    local weapon = csgo_weapons[entity.get_prop(entity.get_player_weapon(entity.get_local_player()), "m_iItemDefinitionIndex")]

    local xv, yv, zv = entity.get_prop(entity.get_local_player(), "m_vecVelocity")
	local velocity = math.sqrt(xv^2 + yv^2)
    local on_ground = bit.band(entity.get_prop(entity.get_local_player(), 'm_fFlags'), bit.lshift(1, 0))

    local disabler_tbl = {
        {
            Name = "Quick peek assist",
            Variable = (ui.get(qps_ref + 1))
        },
        {
            Name = "Duck peek assist",
            Variable = (({ui.get(fd_ref)})[1])
        },
        {
            Name = "Edge yaw",
            Variable = (ui.get(edge_ref))
        },
        {
            Name = "Velocity",
            Variable = (on_ground == 1 and velocity >= ui.get(velocity_slider))
        },
        {
            Name = "Jump at edge",
            Variable = (({ui.get(edge_jump_ref + 1)})[1])
        }
    }

    cmd.roll = ui.get(roll_ref)
    
    if is_valve_ds_spoofed == 1 then
        if cmd.chokedcommands > 6 then
            cmd.chokedcommands = 0
        end
        if ui.get(fl_limit_ref) > 6 then
            return_fl = ui.get(fl_limit_ref)
            ui.set(fl_limit_ref, 6)
        end
        if ui.get(roll_ref) > 44 then
            ui.set(roll_ref, 44)
        end
        if ui.get(roll_ref) < -44 then
            ui.set(roll_ref, -44)
        end
    else
        if ui.get(fl_limit_ref) == 6 and return_fl ~= nil then
            ui.set(fl_limit_ref, return_fl)
            return_fl = nil
        end
        if ui.get(roll_ref) == 44 then
            ui.set(roll_ref, 50)
        end
        if ui.get(roll_ref) == -44 then
            ui.set(roll_ref, -50)
        end
    end

    if weapon == nil then goto skip end

    if entity.get_prop(entity.get_local_player(), "m_MoveType") == 9 or weapon.type == "grenade" and velocity >= 1.01001 and on_ground == 1 or ui.get(roll_ref) == 0 or not ui.get(aa_ref) then
        cmd.roll = 0
    end

    if ui.get(roll_checkbox) then
        ui.set(roll_ref, ui.get(roll_hotkey) and (50 - (is_valve_ds_spoofed * 6)) or (-50 + (is_valve_ds_spoofed * 6)))
    end
    
    for _, v in ipairs(disabler_tbl) do
        if contains(ui.get(disablers), v.Name) and ui.get(disablers_hk) then
            if v.Variable then
                cmd.roll = 0
            end
        end
    end

    if contains(ui.get(disablers), "Velocity") then
        ui.set_visible(velocity_slider, true)
    else
        ui.set_visible(velocity_slider, false)
    end

    ::skip::

    local is_valve_ds = ffi.cast('bool*', gamerules[0] + 124)
    if is_valve_ds ~= nil then
        if cmd.roll ~= 0 and ui.get(MM_enable) then
            if is_valve_ds[0] == true then
                is_valve_ds[0] = 0
                is_valve_ds_spoofed = 1
            end
        else
            if is_valve_ds[0] == false and is_valve_ds_spoofed == 1 then
                --is_valve_ds[0] = 1
                --is_valve_ds_spoofed = 0
                cmd.roll = 0
            end
        end
    end
end)

client.set_event_callback("paint_ui", function()
    if globals.mapname() == nil and entity.get_local_player() == nil then
        is_valve_ds_spoofed = 0
        if return_fl ~= nil then
            ui.set(fl_limit_ref, return_fl)
            return_fl = nil
        end
    end
end)

client.set_event_callback("shutdown", function()
    if return_fl ~= nil then
        ui.set(fl_limit_ref, return_fl)
        return_fl = nil
    end
    if globals.mapname() == nil then 
        is_valve_ds_spoofed = 0
        return
    end
    local is_valve_ds = ffi.cast('bool*', gamerules[0] + 124)
    if is_valve_ds ~= nil then
        if is_valve_ds[0] == false and is_valve_ds_spoofed == 1 then
            is_valve_ds[0] = 1
            is_valve_ds_spoofed = 0
        end
    end
end)

client.set_event_callback("pre_config_load", function()
    return_fl = nil
end)
