-- Tests for GoalsManager module
local GoalsManager = require("scripts/goals-manager")
local mod_gui = require("__core__.lualib.mod-gui")

describe("GoalsManager", function()
    local test_player
    
    before_each(function()
        test_player = game.get_player(1) or game.create_player{name = "test_player"}
        
        -- Initialize storage
        if not storage.goal_settings then
            storage.goal_settings = {
                goals_enabled = false,
                active_goals = {}
            }
        end
        
        if not storage.goals then
            storage.goals = {}
            storage.next_goal_id = 1
        end
        
        -- Clean up any existing GUI elements
        GoalsManager.destroy_goals_browser(test_player)
    end)
    
    after_each(function()
        -- Clean up GUI elements after each test
        GoalsManager.destroy_goals_browser(test_player)
    end)
    
    describe("GOAL_TEMPLATES", function()
        it("should have required goal template categories", function()
            assert.is_not_nil(GoalsManager.GOAL_TEMPLATES.planetary)
            assert.is_not_nil(GoalsManager.GOAL_TEMPLATES.quality)
            assert.is_not_nil(GoalsManager.GOAL_TEMPLATES.logistics)
            assert.is_not_nil(GoalsManager.GOAL_TEMPLATES.research)
        end)
        
        it("should have goals in each category", function()
            for section_id, goal_list in pairs(GoalsManager.GOAL_TEMPLATES) do
                assert.is_table(goal_list)
                assert.is_true(#goal_list > 0, "Section " .. section_id .. " should have goals")
            end
        end)
        
        it("should have expected planetary goals", function()
            local planetary_goals = GoalsManager.GOAL_TEMPLATES.planetary
            
            local expected_goals = {
                "establish-vulcanus",
                "master-gleba",
                "survive-aquilo",
                "exploit-fulgora"
            }
            
            for _, expected_goal in ipairs(expected_goals) do
                local found = false
                for _, actual_goal in ipairs(planetary_goals) do
                    if actual_goal == expected_goal then
                        found = true
                        break
                    end
                end
                assert.is_true(found, "Expected goal " .. expected_goal .. " not found")
            end
        end)
    end)
    
    describe("goals browser management", function()
        it("should create goals browser with proper structure", function()
            local browser = GoalsManager.create_goals_browser(test_player)
            
            assert.is_not_nil(browser)
            assert.equals(browser.name, "goals_browser")
            assert.equals(browser.type, "frame")
            
            -- Check for essential components
            assert.is_not_nil(browser.sections_scroll)
            assert.is_not_nil(browser.sections_scroll.sections_list)
            assert.is_not_nil(browser.browser_controls)
            assert.is_not_nil(browser.browser_controls.goals_browser_apply)
            assert.is_not_nil(browser.browser_controls.goals_browser_close)
        end)
        
        it("should not create duplicate browsers", function()
            local browser1 = GoalsManager.create_goals_browser(test_player)
            local browser2 = GoalsManager.create_goals_browser(test_player)
            
            assert.equals(browser1, browser2) -- Should return same browser
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            assert.is_not_nil(frame_flow.goals_browser)
        end)
        
        it("should create goal sections for all categories", function()
            GoalsManager.create_goals_browser(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            
            for section_id, _ in pairs(GoalsManager.GOAL_TEMPLATES) do
                assert.is_not_nil(sections_list["section_" .. section_id])
            end
        end)
        
        it("should create goal checkboxes for all goals", function()
            GoalsManager.create_goals_browser(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            
            for section_id, goal_list in pairs(GoalsManager.GOAL_TEMPLATES) do
                local section_frame = sections_list["section_" .. section_id]
                local goals_container = section_frame["goals_" .. section_id]
                
                for _, goal_id in ipairs(goal_list) do
                    local goal_flow = goals_container["goal_flow_" .. goal_id]
                    assert.is_not_nil(goal_flow)
                    assert.is_not_nil(goal_flow["goal_checkbox_" .. goal_id])
                end
            end
        end)
        
        it("should destroy goals browser", function()
            GoalsManager.create_goals_browser(test_player)
            local frame_flow = mod_gui.get_frame_flow(test_player)
            assert.is_not_nil(frame_flow.goals_browser)
            
            GoalsManager.destroy_goals_browser(test_player)
            assert.is_nil(frame_flow.goals_browser)
        end)
        
        it("should handle destroying non-existent browser gracefully", function()
            local frame_flow = mod_gui.get_frame_flow(test_player)
            assert.is_nil(frame_flow.goals_browser)
            
            -- Should not error
            local success = pcall(function()
                GoalsManager.destroy_goals_browser(test_player)
            end)
            assert.is_true(success)
        end)
    end)
    
    describe("goal section visibility", function()
        it("should start with sections collapsed", function()
            GoalsManager.create_goals_browser(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            
            for section_id, _ in pairs(GoalsManager.GOAL_TEMPLATES) do
                local section_frame = sections_list["section_" .. section_id]
                local goals_container = section_frame["goals_" .. section_id]
                assert.is_false(goals_container.visible)
            end
        end)
        
        it("should toggle section visibility", function()
            GoalsManager.create_goals_browser(test_player)
            
            local section_id = "planetary"
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            local section_frame = sections_list["section_" .. section_id]
            local goals_container = section_frame["goals_" .. section_id]
            
            -- Initially collapsed
            assert.is_false(goals_container.visible)
            
            -- Toggle to expand
            GoalsManager.toggle_section_visibility(test_player, section_id)
            assert.is_true(goals_container.visible)
            
            -- Toggle to collapse
            GoalsManager.toggle_section_visibility(test_player, section_id)
            assert.is_false(goals_container.visible)
        end)
        
        it("should update toggle button caption", function()
            GoalsManager.create_goals_browser(test_player)
            
            local section_id = "planetary"
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            local section_frame = sections_list["section_" .. section_id]
            local toggle_button = section_frame["header_" .. section_id]["toggle_section_" .. section_id]
            
            -- Should start with expand caption
            assert.equals(toggle_button.caption, {"gui-goals.section-expand"})
            
            -- After toggling, should show collapse caption
            GoalsManager.toggle_section_visibility(test_player, section_id)
            assert.equals(toggle_button.caption, {"gui-goals.section-collapse"})
        end)
        
        it("should handle toggling non-existent section gracefully", function()
            GoalsManager.create_goals_browser(test_player)
            
            -- Should not error when toggling non-existent section
            local success = pcall(function()
                GoalsManager.toggle_section_visibility(test_player, "non_existent_section")
            end)
            assert.is_true(success)
        end)
    end)
    
    describe("goal selection and application", function()
        it("should apply goal selections correctly", function()
            storage.goal_settings.active_goals = {}
            storage.goals = {}
            
            GoalsManager.create_goals_browser(test_player)
            
            -- Manually set some checkboxes to true for testing
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            
            -- Select first planetary goal
            local planetary_section = sections_list["section_planetary"]
            local planetary_goals = planetary_section["goals_planetary"]
            local first_goal_id = GoalsManager.GOAL_TEMPLATES.planetary[1]
            local first_goal_flow = planetary_goals["goal_flow_" .. first_goal_id]
            local first_checkbox = first_goal_flow["goal_checkbox_" .. first_goal_id]
            first_checkbox.state = true
            
            -- Apply selections
            local active_goals = GoalsManager.apply_goal_selections(test_player)
            
            assert.equals(#active_goals, 1)
            assert.equals(active_goals[1], first_goal_id)
            assert.equals(#storage.goal_settings.active_goals, 1)
            assert.is_true(storage.goal_settings.goals_enabled)
        end)
        
        it("should create goal entries for selected goals", function()
            storage.goal_settings.active_goals = {}
            storage.goals = {}
            storage.next_goal_id = 1
            
            GoalsManager.create_goals_browser(test_player)
            
            -- Select multiple goals
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            
            local selected_goals = {}
            
            -- Select first planetary goal
            local planetary_section = sections_list["section_planetary"]
            local planetary_goals = planetary_section["goals_planetary"]
            local first_goal_id = GoalsManager.GOAL_TEMPLATES.planetary[1]
            local first_goal_flow = planetary_goals["goal_flow_" .. first_goal_id]
            first_goal_flow["goal_checkbox_" .. first_goal_id].state = true
            table.insert(selected_goals, first_goal_id)
            
            -- Select first quality goal
            local quality_section = sections_list["section_quality"]
            local quality_goals = quality_section["goals_quality"]
            local quality_goal_id = GoalsManager.GOAL_TEMPLATES.quality[1]
            local quality_goal_flow = quality_goals["goal_flow_" .. quality_goal_id]
            quality_goal_flow["goal_checkbox_" .. quality_goal_id].state = true
            table.insert(selected_goals, quality_goal_id)
            
            GoalsManager.apply_goal_selections(test_player)
            
            -- Should have created goal entries
            assert.equals(#storage.goals, 2)
            
            -- Verify goal entries have correct properties
            for _, goal in ipairs(storage.goals) do
                assert.is_not_nil(goal.id)
                assert.is_not_nil(goal.template_id)
                assert.is_boolean(goal.completed)
                assert.is_not_nil(goal.created)
                
                -- Should be one of the selected goals
                local found = false
                for _, selected_goal in ipairs(selected_goals) do
                    if goal.template_id == selected_goal then
                        found = true
                        break
                    end
                end
                assert.is_true(found)
            end
        end)
        
        it("should not create duplicate goal entries", function()
            storage.goal_settings.active_goals = {}
            storage.goals = {}
            storage.next_goal_id = 1
            
            -- Pre-create a goal entry
            local goal_id = GoalsManager.GOAL_TEMPLATES.planetary[1]
            table.insert(storage.goals, {
                id = 1,
                template_id = goal_id,
                completed = false,
                created = 100
            })
            storage.next_goal_id = 2
            
            GoalsManager.create_goals_browser(test_player)
            
            -- Select the same goal
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            local planetary_section = sections_list["section_planetary"]
            local planetary_goals = planetary_section["goals_planetary"]
            local goal_flow = planetary_goals["goal_flow_" .. goal_id]
            goal_flow["goal_checkbox_" .. goal_id].state = true
            
            GoalsManager.apply_goal_selections(test_player)
            
            -- Should still have only one goal entry
            assert.equals(#storage.goals, 1)
            assert.equals(storage.goals[1].template_id, goal_id)
        end)
        
        it("should handle empty goal selection", function()
            storage.goal_settings.active_goals = {"some-goal"}
            storage.goal_settings.goals_enabled = true
            
            GoalsManager.create_goals_browser(test_player)
            
            -- Don't select any goals (all checkboxes remain false)
            GoalsManager.apply_goal_selections(test_player)
            
            assert.equals(#storage.goal_settings.active_goals, 0)
            assert.is_false(storage.goal_settings.goals_enabled)
        end)
        
        it("should handle applying selections when browser doesn't exist", function()
            -- Should not error when browser doesn't exist
            local success = pcall(function()
                GoalsManager.apply_goal_selections(test_player)
            end)
            assert.is_true(success)
        end)
    end)
    
    describe("goal state reflection", function()
        it("should reflect existing active goals in checkboxes", function()
            -- Set up some active goals
            local active_goal = GoalsManager.GOAL_TEMPLATES.planetary[1]
            storage.goal_settings.active_goals = {active_goal}
            storage.goal_settings.goals_enabled = true
            
            GoalsManager.create_goals_browser(test_player)
            
            local frame_flow = mod_gui.get_frame_flow(test_player)
            local sections_list = frame_flow.goals_browser.sections_scroll.sections_list
            local planetary_section = sections_list["section_planetary"]
            local planetary_goals = planetary_section["goals_planetary"]
            local goal_flow = planetary_goals["goal_flow_" .. active_goal]
            local checkbox = goal_flow["goal_checkbox_" .. active_goal]
            
            assert.is_true(checkbox.state)
            
            -- Other goals should remain unchecked
            for _, other_goal in ipairs(GoalsManager.GOAL_TEMPLATES.planetary) do
                if other_goal ~= active_goal then
                    local other_goal_flow = planetary_goals["goal_flow_" .. other_goal]
                    local other_checkbox = other_goal_flow["goal_checkbox_" .. other_goal]
                    assert.is_false(other_checkbox.state)
                end
            end
        end)
    end)
end)