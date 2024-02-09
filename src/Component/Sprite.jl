module SpriteModule
    using ..Component.JulGame
    import ..Component.JulGame: deprecated_get_property
    import ..Component

    export Sprite
    struct Sprite
        color::Math.Vector3
        crop::Union{Ptr{Nothing}, Math.Vector4}
        isFlipped::Bool
        imagePath::String
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        position::Math.Vector2f
        rotation::Float64
        pixelsPerUnit::Int32
        center::Math.Vector2
    end

    export InternalSprite
    mutable struct InternalSprite
        center::Math.Vector2
        color::Math.Vector3
        crop::Union{Ptr{Nothing}, Math.Vector4}
        isFlipped::Bool
        isFloatPrecision::Bool
        image::Union{Ptr{Nothing}, Ptr{SDL2.LibSDL2.SDL_Surface}}
        imagePath::String
        isWorldEntity::Bool
        layer::Int32
        offset::Math.Vector2f
        parent::Any # Entity
        position::Math.Vector2f
        rotation::Float64
        pixelsPerUnit::Int32
        size::Math.Vector2
        texture::Union{Ptr{Nothing}, Ptr{SDL2.LibSDL2.SDL_Texture}}
        
        function InternalSprite(parent::Any, imagePath::String, crop::Union{Ptr{Nothing}, Math.Vector4}=C_NULL, isFlipped::Bool=false, color::Math.Vector3 = Math.Vector3(255,255,255), isCreatedInEditor::Bool=false; pixelsPerUnit::Int32=Int32(-1), isWorldEntity::Bool=true, position::Math.Vector2f = Math.Vector2f(), rotation::Float64 = 0.0, layer::Int32 = Int32(0), center::Math.Vector2 = Math.Vector2(0,0))
            this = new()

            this.offset = Math.Vector2f()
            this.isFlipped = isFlipped
            this.imagePath = imagePath
            this.center = center
            this.color = color
            this.crop = crop
            this.image = C_NULL
            this.isWorldEntity = isWorldEntity
            this.layer = layer
            this.parent = parent
            this.pixelsPerUnit = pixelsPerUnit
            this.position = position
            this.rotation = rotation
            this.texture = C_NULL
            this.isFloatPrecision = false

            if isCreatedInEditor
                return this
            end
        
            fullPath = joinpath(BasePath, "assets", "images", imagePath)
            
            this.image = SDL2.IMG_Load(fullPath)
            if this.image == C_NULL
                error = unsafe_string(SDL2.SDL_GetError())
                
                println(fullPath)
                println(string("Couldn't open image! SDL Error: ", error))
                Base.show_backtrace(stdout, catch_backtrace())
                return
            end
            surface = unsafe_wrap(Array, this.image, 10; own = false)
            this.size = Math.Vector2(surface[1].w, surface[1].h)
        
            return this
        end
    end

    function Base.getproperty(this::InternalSprite, s::Symbol)
        method_props = (
            initialize = Component.initialize,
            flip = Component.flip,
            loadImage = Component.load_image,
            destroy = Component.destroy,
            setColor = Component.set_color
        )
        deprecated_get_property(method_props, this, s)
    end
    
    function Component.draw(this::InternalSprite)
        if this.image == C_NULL || JulGame.Renderer == C_NULL
            return
        end
        if this.texture == C_NULL
            this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer, this.image)
            this.setColor()
        end

        parentTransform = this.parent.transform

        cameraDiff = this.isWorldEntity ? 
        Math.Vector2(MAIN.scene.camera.position.x * SCALE_UNITS, MAIN.scene.camera.position.y * SCALE_UNITS) : 
        Math.Vector2(0,0)
        position = this.isWorldEntity ?
        parentTransform.getPosition() :
        this.position

        srcRect = (this.crop == Math.Vector4(0,0,0,0) || this.crop == C_NULL) ? C_NULL : Ref(SDL2.SDL_Rect(this.crop.x, this.crop.y, this.crop.z, this.crop.t))
        dstRect = Ref(SDL2.SDL_FRect(
            (position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - (parentTransform.getScale().x * SCALE_UNITS - SCALE_UNITS) / 2, # TODO: Center the sprite within the entity
            (position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - (parentTransform.getScale().y * SCALE_UNITS - SCALE_UNITS) / 2,
            (this.crop == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS,
            (this.crop == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS
        ))

        if this.pixelsPerUnit > 0 || JulGame.PIXELS_PER_UNIT > 0
            ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
            dstRect = Ref(SDL2.SDL_FRect(
                (position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - ((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS / ppu - SCALE_UNITS) / 2,
                (position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - ((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS / ppu - SCALE_UNITS) / 2,
                (srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS/ppu,
                (srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS/ppu
            ))     
        end

        srcRect = !this.isFloatPrecision ? (this.crop == Math.Vector4(0,0,0,0) || this.crop == C_NULL) ? C_NULL : Ref(SDL2.SDL_Rect(this.crop.x,this.crop.y,this.crop.z,this.crop.t)) : srcRect
        dstRect = !this.isFloatPrecision ? Ref(SDL2.SDL_Rect(
            convert(Int32, round((position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - (parentTransform.getScale().x * SCALE_UNITS - SCALE_UNITS) / 2)), # TODO: Center the sprite within the entity
            convert(Int32, round((position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - (parentTransform.getScale().y * SCALE_UNITS - SCALE_UNITS) / 2)),
            convert(Int32, round(this.crop == C_NULL ? this.size.x : this.crop.z)),
            convert(Int32, round(this.crop == C_NULL ? this.size.y : this.crop.t))
        )) : dstRect
        
        if this.pixelsPerUnit > 0 || JulGame.PIXELS_PER_UNIT > 0 && !this.isFloatPrecision
            ppu = this.pixelsPerUnit > 0 ? this.pixelsPerUnit : JulGame.PIXELS_PER_UNIT
            dstRect = Ref(SDL2.SDL_Rect(
                convert(Int32, round((position.x + this.offset.x) * SCALE_UNITS - cameraDiff.x - ((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS / ppu - SCALE_UNITS) / 2)),
                convert(Int32, round((position.y + this.offset.y) * SCALE_UNITS - cameraDiff.y - ((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS / ppu - SCALE_UNITS) / 2)),
                convert(Int32, round((srcRect == C_NULL ? this.size.x : this.crop.z) * SCALE_UNITS/ppu)),
                convert(Int32, round((srcRect == C_NULL ? this.size.y : this.crop.t) * SCALE_UNITS/ppu))
            ))     
        end

        if  this.isFloatPrecision && SDL2.SDL_RenderCopyExF(
            JulGame.Renderer, 
            this.texture, 
            srcRect, 
            dstRect,
            this.rotation,
            C_NULL, # Ref(SDL2.SDL_Point(0,0)) CENTER
            this.isFlipped ? SDL2.SDL_FLIP_HORIZONTAL : SDL2.SDL_FLIP_NONE) != 0

            error = unsafe_string(SDL2.SDL_GetError())
        end

        if  !this.isFloatPrecision && SDL2.SDL_RenderCopyEx(
            JulGame.Renderer, 
            this.texture, 
            srcRect, 
            dstRect,
            this.rotation, # ROTATION
            C_NULL, # Ref(SDL2.SDL_Point(0,0)) CENTER
            this.isFlipped ? SDL2.SDL_FLIP_HORIZONTAL : SDL2.SDL_FLIP_NONE) != 0

            error = unsafe_string(SDL2.SDL_GetError())
        end
    end

    function Component.initialize(this::InternalSprite)
        if this.image == C_NULL
            return
        end

        this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer, this.image)
    end

    function Component.flip(this::InternalSprite)
        this.isFlipped = !this.isFlipped
    end

    function Component.set_parent(this::InternalSprite, parent::Any)
        this.parent = parent
    end

    function Component.load_image(this::InternalSprite, imagePath::String)
        SDL2.SDL_ClearError()
        this.image = SDL2.IMG_Load(joinpath(BasePath, "assets", "images", imagePath))
        error = unsafe_string(SDL2.SDL_GetError())
        if !isempty(error)
            println(string("Couldn't open image! SDL Error: ", error))
            SDL2.SDL_ClearError()
            this.image = C_NULL
            return
        end

        surface = unsafe_wrap(Array, this.image, 10; own = false)
        this.size = Math.Vector2(surface[1].w, surface[1].h)
        
        this.imagePath = imagePath
        this.texture = SDL2.SDL_CreateTextureFromSurface(JulGame.Renderer, this.image)
        this.setColor()
    end

    function Component.destroy(this::InternalSprite)
        if this.image == C_NULL
            return
        end

        SDL2.SDL_DestroyTexture(this.texture)
        SDL2.SDL_FreeSurface(this.image)
        this.image = C_NULL
        this.texture = C_NULL
    end

    function Component.set_color(this::InternalSprite)
        SDL2.SDL_SetTextureColorMod(this.texture, UInt8(this.color.x%256), UInt8(this.color.y%256), (this.color.z%256));
    end
end
