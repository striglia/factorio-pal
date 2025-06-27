local item_mappings = require("data/item-mappings")

local ProgressTracker = {}

-- Parse resource goal from todo text
function ProgressTracker.parse_resource_goal(text)
    local lower_text = string.lower(text)
    
    -- Pattern matching for resource goals
    local patterns = {
        "collect (%d+) (.+)",
        "produce (%d+) (.+)", 
        "gather (%d+) (.+)",
        "get (%d+) (.+)",
        "make (%d+) (.+)",
        "craft (%d+) (.+)"
    }
    
    for _, pattern in ipairs(patterns) do
        local count_str, item_text = string.match(lower_text, pattern)
        if count_str and item_text then
            local target_count = tonumber(count_str)
            if target_count and target_count > 0 then
                -- Clean up item text (remove trailing 's', periods, etc.)
                item_text = string.gsub(item_text, "%.$", "") -- remove trailing period
                item_text = string.gsub(item_text, "s$", "") -- remove trailing s for plurals
                item_text = string.gsub(item_text, "es$", "e") -- fix -es plurals
                
                -- Look up internal item name
                local item_name = item_mappings[item_text] or item_text
                
                return {
                    trackable = true,
                    item_name = item_name,
                    target_count = target_count,
                    current_count = 0
                }
            end
        end
    end
    
    return nil -- Not a trackable resource goal
end

-- Update progress for all trackable todos
function ProgressTracker.update_progress_tracking(refresh_callback)
    local needs_refresh = false
    
    for _, todo in pairs(storage.todos) do
        if todo.progress and todo.progress.trackable and not todo.completed then
            local old_current = todo.progress.current_count
            local new_current = 0
            
            -- Check all connected players' inventories
            for _, player in pairs(game.connected_players) do
                local player_count = player.get_item_count(todo.progress.item_name)
                new_current = math.max(new_current, player_count)
            end
            
            todo.progress.current_count = new_current
            
            -- Auto-complete if target reached
            if new_current >= todo.progress.target_count and not todo.completed then
                todo.completed = true
                needs_refresh = true
                
                -- Notify players of completion
                for _, player in pairs(game.connected_players) do
                    player.print("Todo completed: " .. todo.text)
                end
            elseif old_current ~= new_current then
                needs_refresh = true
            end
        end
    end
    
    if needs_refresh and refresh_callback then
        refresh_callback()
    end
end

return ProgressTracker