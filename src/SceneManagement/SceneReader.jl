module SceneReaderModule
    using JSON3
    using ...AnimatorModule
    using ...AnimationModule
    using ...ColliderModule
    using ...CircleColliderModule
    using ...EntityModule
    using ...Math
    using ...RigidbodyModule
    using ...SoundSourceModule
    using ...SpriteModule
    using ...UI.TextBoxModule
    using ...UI.ScreenButtonModule
    using ...TransformModule


    function scriptObj(name::String, parameters::Array)
        () -> (name; parameters)
    end

    export deserializeScene
    function deserializeScene(filePath, isEditor)
        try
            entitiesJson = read(filePath, String)

            json = JSON3.read(entitiesJson)
            entities =[]
            uiElements = []
            res = []
    
            for entity in json.Entities
                components = []
                scripts = []
    
                for component in entity.components
                    push!(components, deserializeComponent(component, isEditor))
                end
                
                for script in entity.scripts
                    scriptParameters = []
                    for scriptParameter in script.parameters
                        push!(scriptParameters, scriptParameter)
                    end
                    scriptObject = scriptObj(script.name, scriptParameters)
                    push!(scripts, scriptObject)
                end
                
                newEntity = Entity(entity.name)
                newEntity.id = entity.id
                newEntity.isActive = entity.isActive
                newEntity.scripts = scripts

                for component in components
                    if typeof(component) == Animator
                        add_animator(newEntity, component::Animator)
                        continue
                    elseif typeof(component) == Collider
                        add_collider(newEntity, component::Collider)
                        continue
                    elseif typeof(component) == CircleCollider
                        add_circle_collider(newEntity, component::CircleCollider)
                        continue
                    elseif typeof(component) == Rigidbody
                        add_rigidbody(newEntity, component::Rigidbody)
                        continue
                    elseif typeof(component) == SoundSource
                        add_sound_source(newEntity, component::SoundSource)
                        continue
                    elseif typeof(component) == Sprite
                        add_sprite(newEntity, component::Sprite)
                        continue
                    end
                end
                
                push!(entities, newEntity)
            end
            uiElements = deserializeUIElements(json.UIElements)
    
            push!(res, entities)
            push!(res, uiElements)
            return res
        catch e 
            println(e)
			Base.show_backtrace(stdout, catch_backtrace())
			rethrow(e)
        end
    end

    function deserializeUIElements(jsonUIElements)
        res = []

        for uiElement in jsonUIElements
            try
                newUIElement = nothing
                if uiElement.type == "TextBox"
                    newUIElement = TextBox(uiElement.name, uiElement.fontPath, uiElement.fontSize, Vector2(uiElement.position.x, uiElement.position.y), uiElement.text, uiElement.isCenteredX, uiElement.isCenteredY)        
                else
                    newUIElement = ScreenButton(uiElement.name, uiElement.buttonUpSpritePath, uiElement.buttonDownSpritePath, Vector2(uiElement.size.x, uiElement.size.y), Vector2(uiElement.position.x, uiElement.position.y), uiElement.fontPath, uiElement.text, Vector2(uiElement.textOffset.x, uiElement.textOffset.y))
                end
                
                push!(res, newUIElement)
            catch e 
                println(e)
				Base.show_backtrace(stdout, catch_backtrace())
				rethrow(e)
            end
        end

        return res
    end

    export deserializeComponent
    function deserializeComponent(component, isEditor)
        try
            if component.type == "Transform"
                newComponent = Transform(Vector2f(component.position.x, component.position.y), Vector2f(component.scale.x, component.scale.y))
            elseif component.type == "Animator"
                newAnimations = Animation[]
                for animation in component.animations
                newAnimationFrames = Vector{Vector4}()
                for animationFrame in animation.frames
                    push!(newAnimationFrames, Vector4(animationFrame.x, animationFrame.y, animationFrame.z, animationFrame.t))
                end
                push!(newAnimations, Animation(newAnimationFrames, convert(Int32, animation.animatedFPS)))
                end
                newComponent = Animator(newAnimations)
            elseif component.type == "Collider"
                isTrigger::Bool = !haskey(component, "isTrigger") ? false : component.isTrigger
                enabled::Bool = !haskey(component, "enabled") ? true : component.enabled
                isPlatformerCollider::Bool = !haskey(component, "isPlatformerCollider") ? false : component.isPlatformerCollider
                offset::Vector2f = !haskey(component, "offset") ? Vector2f(0,0) : Vector2f(component.offset.x, component.offset.y)
                newComponent = Collider(enabled::Bool, isPlatformerCollider, isTrigger, offset,  Vector2f(component.size.x, component.size.y), component.tag::String)
            elseif component.type == "CircleCollider"
                newComponent = CircleCollider(convert(Float64, component.diameter), component.enabled, component.isTrigger, Vector2f(component.offset.x, component.offset.y), component.tag)
            elseif component.type == "Rigidbody"
                newComponent = Rigidbody(; mass = convert(Float64, component.mass), useGravity = !haskey(component, "useGravity") ? true : component.useGravity)
            elseif component.type == "SoundSource"
                newComponent = SoundSource(Int32(component.channel), component.isMusic, component.path, Int32(component.volume))
            elseif component.type == "Sprite"
                color = !haskey(component, "color") || isempty(component.color) ? Vector3(255,255,255) : Vector3(component.color.x, component.color.y, component.color.z)
                crop = !haskey(component, "crop") || isempty(component.crop) ? Vector4(0,0,0,0) : Vector4(component.crop.x, component.crop.y, component.crop.z, component.crop.t)
                isWorldEntity = !haskey(component, "isWorldEntity") ? true : component.isWorldEntity
                layer = !haskey(component, "layer") ? 0 : component.layer
                offset = !haskey(component, "offset") ? Vector2f() : Vector2f(component.offset.x, component.offset.y)
                position = !haskey(component, "position") ? Vector2f() : Vector2f(component.position.x, component.position.y)
                rotation = !haskey(component, "rotation") ? 0.0 : convert(Float64, component.rotation)
                pixelsPerUnit = !haskey(component, "pixelsPerUnit") ? -1 : component.pixelsPerUnit
                center = !haskey(component, "center") ? Vector2(0,0) : Vector2(component.center.x, component.center.y)
                newComponent = Sprite(color::Vector3, crop::Union{Ptr{Nothing}, Math.Vector4}, component.isFlipped::Bool, component.imagePath::String, isWorldEntity::Bool, Int32(layer), offset::Vector2f, position::Vector2f, rotation::Float64, Int32(pixelsPerUnit), center::Vector2)
            end
            
            return newComponent
        catch e
            println(e)
			Base.show_backtrace(stdout, catch_backtrace())
			rethrow(e)
        end
    end
end
