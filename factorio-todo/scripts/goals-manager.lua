local mod_gui = require("__core__.lualib.mod-gui")

local GoalsManager = {}

-- Goal templates organized by category
GoalsManager.GOAL_TEMPLATES = {
    planetary = {
        "establish-vulcanus",
        "master-gleba",
        "survive-aquilo", 
        "exploit-fulgora"
    },
    quality = {
        "quality-infrastructure",
        "legendary-production"
    },
    logistics = {
        "interplanetary-logistics",
        "elevated-rails"
    },
    research = {
        "unlock-space-science",
        "achieve-fusion-power"
    }
}

-- Create the goals browser window
function GoalsManager.create_goals_browser(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.goals_browser then
        return frame_flow.goals_browser
    end
    
    local browser = frame_flow.add{
        type = "frame",
        name = "goals_browser",
        direction = "vertical",
        caption = {"gui-goals.goals-browser-title"}
    }
    
    -- Description
    browser.add{
        type = "label",
        caption = {"gui-goals.goals-browser-description"},
        style = "description_label"
    }
    
    -- Goal sections
    local sections_scroll = browser.add{
        type = "scroll-pane",
        name = "sections_scroll",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy = "auto"
    }
    sections_scroll.style.maximal_height = 400
    sections_scroll.style.minimal_width = 500
    
    local sections_list = sections_scroll.add{
        type = "flow",
        name = "sections_list",
        direction = "vertical"
    }
    
    -- Build goal sections
    for section_id, goal_list in pairs(GoalsManager.GOAL_TEMPLATES) do
        local section_frame = sections_list.add{
            type = "frame",
            name = "section_" .. section_id,
            style = "inside_shallow_frame"
        }
        
        -- Section header
        local section_header = section_frame.add{
            type = "flow",
            name = "header_" .. section_id,
            direction = "horizontal"
        }
        
        section_header.add{
            type = "button",
            name = "toggle_section_" .. section_id,
            caption = {"gui-goals.section-expand"},
            style = "mini_button"
        }
        
        section_header.add{
            type = "label",
            caption = {"goal-sections." .. section_id},
            style = "heading_2_label"
        }
        
        -- Goals list (initially collapsed)
        local goals_container = section_frame.add{
            type = "flow",
            name = "goals_" .. section_id,
            direction = "vertical",
            visible = false
        }
        
        for _, goal_id in ipairs(goal_list) do
            local goal_flow = goals_container.add{
                type = "flow",
                name = "goal_flow_" .. goal_id,
                direction = "horizontal"
            }
            
            -- Goal checkbox
            local is_active = false
            for _, active_goal in ipairs(storage.goal_settings.active_goals) do
                if active_goal == goal_id then
                    is_active = true
                    break
                end
            end
            
            goal_flow.add{
                type = "checkbox",
                name = "goal_checkbox_" .. goal_id,
                state = is_active
            }
            
            -- Goal info
            local goal_info = goal_flow.add{
                type = "flow",
                name = "goal_info_" .. goal_id,
                direction = "vertical"
            }
            
            goal_info.add{
                type = "label",
                caption = {"goal-templates." .. goal_id},
                style = "bold_label"
            }
            
            goal_info.add{
                type = "label",
                caption = {"goal-descriptions." .. goal_id},
                style = "description_label"
            }
        end
    end
    
    -- Controls
    local browser_controls = browser.add{
        type = "flow",
        name = "browser_controls",
        direction = "horizontal"
    }
    
    browser_controls.add{
        type = "button",
        name = "goals_browser_apply",
        caption = {"gui-goals.goals-browser-apply"},
        style = "confirm_button"
    }
    
    browser_controls.add{
        type = "button",
        name = "goals_browser_close",
        caption = {"gui-goals.goals-browser-close"}
    }
    
    return browser
end

-- Destroy the goals browser
function GoalsManager.destroy_goals_browser(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if frame_flow.goals_browser then
        frame_flow.goals_browser.destroy()
    end
end

-- Apply goal selections from the browser
function GoalsManager.apply_goal_selections(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not frame_flow.goals_browser then return end
    
    local new_active_goals = {}
    
    -- Check all goal checkboxes
    for section_id, goal_list in pairs(GoalsManager.GOAL_TEMPLATES) do
        for _, goal_id in ipairs(goal_list) do
            local checkbox_name = "goal_checkbox_" .. goal_id
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            local section_frame = sections_list["section_" .. section_id]
            local goals_container = section_frame["goals_" .. section_id]
            local goal_flow = goals_container["goal_flow_" .. goal_id]
            if goal_flow and goal_flow[checkbox_name] and goal_flow[checkbox_name].state then
                table.insert(new_active_goals, goal_id)
            end
        end
    end
    
    storage.goal_settings.active_goals = new_active_goals
    storage.goal_settings.goals_enabled = #new_active_goals > 0
    
    -- Create active goals if needed
    for _, goal_id in ipairs(new_active_goals) do
        local goal_exists = false
        for _, existing_goal in ipairs(storage.goals) do
            if existing_goal.template_id == goal_id then
                goal_exists = true
                break
            end
        end
        
        if not goal_exists then
            local new_goal = {
                id = storage.next_goal_id,
                template_id = goal_id,
                completed = false,
                created = game.tick
            }
            table.insert(storage.goals, new_goal)
            storage.next_goal_id = storage.next_goal_id + 1
        end
    end
    
    return new_active_goals
end

-- Toggle a goal section's visibility
function GoalsManager.toggle_section_visibility(player, section_id)
    local frame_flow = mod_gui.get_frame_flow(player)
    if not frame_flow.goals_browser then return end
    
    local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
    local section_frame = sections_list["section_" .. section_id]
    local goals_container = section_frame["goals_" .. section_id]
    local toggle_button = section_frame["header_" .. section_id]["toggle_section_" .. section_id]
    
    if goals_container.visible then
        goals_container.visible = false
        toggle_button.caption = {"gui-goals.section-collapse"}
    else
        goals_container.visible = true
        toggle_button.caption = {"gui-goals.section-expand"}
    end
end

return GoalsManager