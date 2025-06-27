local ProgressTracker = require("scripts/progress-tracker")

local TodoManager = {}

-- Add a new todo
function TodoManager.add_todo(player, text, refresh_callback)
    if text == "" then return end
    
    -- Parse resource tracking from text
    local progress_info = ProgressTracker.parse_resource_goal(text)
    
    local new_todo = {
        id = storage.next_todo_id,
        text = text,
        completed = false,
        owner = player.name,
        created = game.tick,
        order = #storage.todos + 1,
        progress = progress_info
    }
    
    table.insert(storage.todos, new_todo)
    storage.next_todo_id = storage.next_todo_id + 1
    
    if refresh_callback then
        refresh_callback()
    end
end

-- Toggle todo completion
function TodoManager.toggle_todo(todo_id, refresh_callback)
    for _, todo in pairs(storage.todos) do
        if todo.id == todo_id then
            todo.completed = not todo.completed
            break
        end
    end
    if refresh_callback then
        refresh_callback()
    end
end

-- Delete a todo
function TodoManager.delete_todo(todo_id, player, refresh_callback)
    for i, todo in pairs(storage.todos) do
        if todo.id == todo_id then
            if todo.owner == player.name then
                table.remove(storage.todos, i)
                if refresh_callback then
                    refresh_callback()
                end
            end
            break
        end
    end
end

-- Clear completed todos
function TodoManager.clear_completed_todos(refresh_callback)
    local new_todos = {}
    for _, todo in pairs(storage.todos) do
        if not todo.completed then
            table.insert(new_todos, todo)
        end
    end
    storage.todos = new_todos
    -- Reorder remaining todos
    for i, todo in ipairs(storage.todos) do
        todo.order = i
    end
    if refresh_callback then
        refresh_callback()
    end
end

-- Move todo up in order
function TodoManager.move_todo_up(todo_id, refresh_callback)
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        if todo.id == todo_id and i > 1 then
            -- Swap order values
            local temp_order = storage.todos[i-1].order
            storage.todos[i-1].order = todo.order
            todo.order = temp_order
            
            if refresh_callback then
                refresh_callback()
            end
            break
        end
    end
end

-- Move todo down in order
function TodoManager.move_todo_down(todo_id, refresh_callback)
    table.sort(storage.todos, function(a, b) return a.order < b.order end)
    
    for i, todo in ipairs(storage.todos) do
        if todo.id == todo_id and i < #storage.todos then
            -- Swap order values
            local temp_order = storage.todos[i+1].order
            storage.todos[i+1].order = todo.order
            todo.order = temp_order
            
            if refresh_callback then
                refresh_callback()
            end
            break
        end
    end
end

return TodoManager