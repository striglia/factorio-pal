# Factorio AI Agent Development Assistant

This repository develops AI-powered Factorio mods focused on parallel agent tools and intelligent automation systems.

## Project Structure

- `/factorio-todo/` - Todo management mod with AI-driven goal progression
- `/scripts/` - Development utilities and automation scripts
- Individual mod directories contain standard Factorio mod structure:
  - `info.json` - Mod metadata and dependencies
  - `control.lua` - Main mod logic and event handlers
  - `data.lua` - Game data modifications and prototypes
  - `locale/` - Localization files
  - `graphics/` - Custom sprites and icons

## Development Workflow

### Key Commands
- `./sync-mod.sh` or `/factorio-copy` - Sync mod to Factorio mods directory
- Test in-game immediately after sync
- Check Factorio log for Lua errors: `~/Library/Application Support/Factorio/factorio-current.log`

### Factorio Mod Development Context

**Core Factorio Concepts:**
- **Entities** - Game objects (assemblers, belts, inserters, etc.)
- **Items** - Things that can be crafted/moved
- **Recipes** - Crafting formulas
- **Technologies** - Research tree progression
- **Events** - Game state changes to hook into
- **Surfaces** - Game worlds/dimensions
- **Forces** - Player teams/AI factions

**Common Event Patterns:**
```lua
script.on_event(defines.events.on_tick, function(event)
    -- Called every game tick (60/second)
end)

script.on_event(defines.events.on_built_entity, function(event)
    -- When player/robot builds something
end)
```

**Data Storage:**
- `global` table persists between saves
- Use `storage` for mod-specific data in Factorio 2.0+
- Always handle save/load scenarios

## AI Agent Development Guidelines

### Focus Areas
1. **Parallel Processing** - Multiple AI agents working simultaneously
2. **Factory Optimization** - Analyzing and improving production chains
3. **Resource Management** - Intelligent allocation and logistics
4. **Goal-Oriented Planning** - Dynamic objective generation and execution
5. **Player Assistance** - Augmenting human decision-making

### AI Integration Patterns
- **State Analysis** - Read game state, analyze patterns
- **Decision Trees** - AI-driven branching logic for complex scenarios
- **Learning Systems** - Adapt behavior based on player patterns
- **Prediction Models** - Anticipate player needs and bottlenecks

### Development Principles
- **Factorio-First** - Always prioritize game integration over AI complexity
- **Performance-Conscious** - Factorio runs at 60 UPS, minimize computational overhead
- **Player-Centric** - AI should enhance, not replace player agency
- **Modular Design** - Build reusable AI components across different mods

## Testing & Debugging

### In-Game Testing
1. Launch Factorio
2. Enable mod in Mod Settings
3. Start new game or load existing save
4. Monitor log output: `/log` command in-game console
5. Use `/c` commands for debugging Lua state

### Common Debug Patterns
```lua
game.print("Debug: " .. serpent.line(data))
log("Error in function: " .. err)
```

### Performance Monitoring
- Use `/c game.speed = 0.5` to slow game for debugging
- Monitor UPS in debug info (F4 menu)
- Profile heavy operations with `game.create_profiler()`

## Factorio API Reference

### Essential APIs
- `game.players` - Access player objects
- `game.surfaces[1]` - Main game surface
- `game.forces.player` - Player force/team
- `game.tick` - Current game tick counter
- `remote.call()` - Inter-mod communication

### Entity Manipulation
```lua
-- Find entities
local entities = surface.find_entities_filtered{
    area = {{-10, -10}, {10, 10}},
    type = "inserter"
}

-- Create entities
surface.create_entity{
    name = "fast-inserter",
    position = {x, y},
    force = force
}
```

## Resource Management

### Factorio Mod Portal Integration
- Update `info.json` version before releases
- Use semantic versioning (1.0.0)
- Include dependencies and Factorio version compatibility

### Version Control
- Exclude user-specific Factorio files
- Include only source code and assets
- Tag releases matching mod portal versions

## AI Development Resources

### Factorio-Specific AI Challenges
- **Combinatorial Optimization** - Factory layout and logistics
- **Real-time Strategy** - Dynamic resource allocation
- **Pattern Recognition** - Identifying bottlenecks and inefficiencies
- **Multi-agent Coordination** - Managing multiple AI systems

### Integration Points
- **External APIs** - Connect to external AI services via HTTP
- **File I/O** - Export game state for offline analysis
- **Mod Settings** - AI configuration and tuning parameters

## Getting Started with New Mods

1. Create mod directory with descriptive name
2. Copy `info.json` template and update metadata
3. Start with minimal `control.lua` for event handling
4. Add `data.lua` if creating new game content
5. Test frequently with `/factorio-copy` sync
6. Focus on single AI capability per mod
7. Build modular components for reuse

## Recommended Reading

### Essential Documentation
- **[Official Factorio Modding Documentation](https://lua-api.factorio.com/)** - Complete API reference and tutorials
- **[Factorio Wiki: Modding](https://wiki.factorio.com/Modding)** - Community guides and examples
- **[Factorio Prototype Documentation](https://lua-api.factorio.com/latest/prototypes.html)** - Defining custom entities, items, recipes

### Key Concepts to Master
1. **[Events System](https://lua-api.factorio.com/latest/events.html)** - Understanding game event lifecycle
2. **[Data Stage vs Control Stage](https://lua-api.factorio.com/latest/data-lifecycle.html)** - When code runs during mod loading
3. **[Global Table Management](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html#save-load-cycle)** - Persistent data handling across saves
4. **[Surface and Entity APIs](https://lua-api.factorio.com/latest/classes/LuaSurface.html)** - Core game world manipulation
5. **[Settings Framework](https://lua-api.factorio.com/latest/settings-stage.html)** - Player-configurable mod options

### Advanced Topics
- **[Custom GUIs](https://lua-api.factorio.com/latest/classes/LuaGui.html)** - Building mod interfaces
- **[Mod Compatibility](https://lua-api.factorio.com/latest/auxiliary/mod-dependencies.html)** - Working with other mods
- **[Performance Guidelines](https://lua-api.factorio.com/latest/auxiliary/performance-tips.html)** - Optimizing for 60 UPS
- **[Locale System](https://wiki.factorio.com/Tutorial:Localisation)** - Multi-language support
- **[Graphics and Sprites](https://wiki.factorio.com/Tutorial:Creating_graphics)** - Custom visual assets

### Community Resources
- **[Factorio Discord #mod-making](https://discord.gg/factorio)** - Active modding community
- **[r/factorio Modding Posts](https://reddit.com/r/factorio)** - Community examples and help
- **[GitHub: Factorio Mods](https://github.com/topics/factorio-mod)** - Open source mod examples
- **[Factorio Mod Portal](https://mods.factorio.com/)** - Browse existing mods for inspiration

### Code Examples and Templates
- **[Base Game Source](https://wiki.factorio.com/Data.raw)** - Reference implementations
- **[Mod Template Repository](https://github.com/Bilka2/Factorio-mod-template)** - Starter templates
- **[Advanced Mod Examples](https://mods.factorio.com/mod/stdlib)** - Complex mod architectures

### Debugging and Development Tools
- **[Factorio Mod Development Pack](https://mods.factorio.com/mod/debugadapter)** - VS Code integration
- **[What is it really used for?](https://mods.factorio.com/mod/what-is-it-really-used-for)** - Production analysis
- **[Enhanced Console](https://mods.factorio.com/mod/enhanced-console)** - Better debugging interface

Remember: Factorio mods run in a sandboxed Lua environment with specific APIs. Always consult the official Factorio modding documentation for API details and limitations.