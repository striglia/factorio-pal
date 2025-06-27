local mod_gui = require("__core__.lualib.mod-gui")

local GuiManager = {}

-- Create the toggle button for each player
function GuiManager.create_todo_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if not button_flow.todo_button then
        button_flow.add{
            type = "sprite-button",
            name = "todo_button",
            sprite = "utility/logistic_network_panel_black",
            tooltip = {"gui.todo-button-tooltip"}
        }
    end
end

-- Remove the toggle button
function GuiManager.destroy_todo_button(player)
    local button_flow = mod_gui.get_button_flow(player)
    if button_flow.todo_button then
        button_flow.todo_button.destroy()
    end
end

-- Create the main todo window
function GuiManager.create_todo_window(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.todo_window then
        return frame_flow.todo_window
    end
    
    local window = frame_flow.add{
        type = "frame",
        name = "todo_window",
        direction = "vertical",
        caption = {"gui.todo-window-title"}
    }
    
    -- Add input section
    local input_flow = window.add{
        type = "flow",
        name = "input_flow",
        direction = "horizontal"
    }
    
    input_flow.add{
        type = "textfield",
        name = "todo_input",
        text = "",
        tooltip = {"gui.todo-add-placeholder"}
    }
    
    input_flow.add{
        type = "button",
        name = "add_todo_button",
        caption = {"gui.todo-add-button"}
    }
    
    -- Add todo list container
    local list_scroll = window.add{
        type = "scroll-pane",
        name = "todo_scroll",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto"
    }
    list_scroll.style.maximal_height = 400
    list_scroll.style.minimal_width = 400
    
    local todo_list = list_scroll.add{
        type = "flow",
        name = "todo_list",
        direction = "vertical"
    }
    
    -- Add controls section
    local controls_flow = window.add{
        type = "flow",
        name = "controls_flow",
        direction = "horizontal"
    }
    
    controls_flow.add{
        type = "button",
        name = "clear_completed_button",
        caption = {"gui.todo-clear-completed"}
    }
    
    -- Add enable goals button if goals not enabled
    if not storage.goal_settings.goals_enabled then
        controls_flow.add{
            type = "button",
            name = "enable_goals_button",
            caption = {"gui-goals.enable-goals"},
            style = "green_button"
        }
    end
    
    return window
end

-- Destroy the todo window
function GuiManager.destroy_todo_window(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.todo_window then
        frame_flow.todo_window.destroy()
    end
end

-- Refresh the todo list display for all players
function GuiManager.refresh_todo_list_for_all_players()
    for _, player in pairs(game.connected_players) do
        local frame_flow = mod_gui.get_frame_flow(player)
        if frame_flow.todo_window then
            GuiManager.refresh_todo_list(player)
        end
    end
end

-- Refresh the todo list for a specific player
function GuiManager.refresh_todo_list(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not frame_flow.todo_window then return end
    
    local todo_list = frame_flow.todo_window.todo_scroll.todo_list
    todo_list.clear()
    
    if #storage.todos == 0 then
        todo_list.add{
            type = "label",
            caption = {"gui.todo-empty-message"},
            style = "description_label"
        }
        return
    end
    
    -- Sort todos by order field
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        local todo_flow = todo_list.add{
            type = "flow",
            name = "todo_" .. todo.id,
            direction = "horizontal"
        }
        
        -- Checkbox
        todo_flow.add{
            type = "checkbox",
            name = "todo_checkbox_" .. todo.id,
            state = todo.completed,
            tooltip = "Toggle completion"
        }
        
        -- Todo text with owner info and progress
        local text_style = todo.completed and "disabled_label" or "label"
        local display_text = "[" .. todo.owner .. "] " .. todo.text
        
        -- Add progress info to display text if trackable
        if todo.progress and todo.progress.trackable then
            display_text = display_text .. " (" .. todo.progress.current_count .. "/" .. todo.progress.target_count .. ")"
        end
        
        -- Create vertical flow for text and progress bar
        local text_progress_flow = todo_flow.add{
            type = "flow",
            name = "text_progress_flow_" .. todo.id,
            direction = "vertical"
        }
        
        text_progress_flow.add{
            type = "label",
            caption = display_text,
            style = text_style
        }
        
        -- Add progress bar for trackable todos
        if todo.progress and todo.progress.trackable then
            local progress_value = 0
            if todo.progress.target_count > 0 then
                progress_value = math.min(todo.progress.current_count / todo.progress.target_count, 1.0)
            end
            
            local progress_bar = text_progress_flow.add{
                type = "progressbar",
                name = "progress_bar_" .. todo.id,
                value = progress_value
            }
            progress_bar.style.width = 200
            progress_bar.style.height = 12
        end
        
        -- Reorder buttons
        local reorder_flow = todo_flow.add{
            type = "flow",
            name = "reorder_flow_" .. todo.id,
            direction = "vertical"
        }
        
        local move_up = reorder_flow.add{
            type = "sprite-button",
            name = "move_up_" .. todo.id,
            sprite = "utility/arrow_button_up",
            tooltip = {"gui.todo-move-up"}
        }
        move_up.style.width = 20
        move_up.style.height = 20
        
        local move_down = reorder_flow.add{
            type = "sprite-button",
            name = "move_down_" .. todo.id,
            sprite = "utility/arrow_button_down",
            tooltip = {"gui.todo-move-down"}
        }
        move_down.style.width = 20
        move_down.style.height = 20
        
        -- Disable buttons for first/last items
        if i == 1 then
            move_up.enabled = false
        end
        if i == #storage.todos then
            move_down.enabled = false
        end
        
        -- Delete button (only show for owner)
        if todo.owner == player.name then
            local delete_button = todo_flow.add{
                type = "sprite-button",
                name = "delete_todo_" .. todo.id,
                sprite = "utility/trash",
                tooltip = "Delete todo"
            }
            delete_button.style.width = 24
            delete_button.style.height = 24
        end
    end
end

return GuiManager