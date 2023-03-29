include("SceneInstance.jl")
include("Math/Vector2f.jl")
using SimpleDirectMediaLayer.LibSDL2

mutable struct Collider
    collisionEvents
    currentCollisions
    enabled
    offset::Vector2f
    parent
    size::Vector2f
    tag::String
    
    function Collider(size::Vector2f, offset::Vector2f, tag::String)
        this = new()

        this.collisionEvents = []
        this.currentCollisions = []
        this.enabled = true
        this.offset = offset
        this.size = size
        this.tag = tag

        return this
    end
end

function Base.getproperty(this::Collider, s::Symbol)
    if s == :getSize
        function()
            return this.size
        end
    elseif s == :setSize
        function(size::Vector2f)
            this.size = size
        end
    elseif s == :getOffset
        function()
            return this.offset
        end
    elseif s == :setOffset
        function(offset::Vector2f)
            this.offset = offset
        end
    elseif s == :getTag
        function()
            return this.tag
        end
    elseif s == :setTag
        function(tag::String)
            this.tag = tag
        end
    elseif s == :getParent
        function()
            return this.parent
        end
    elseif s == :setParent
        function(parent)
            this.parent = parent
        end
    elseif s == :checkCollisions
        function()
            colliders = SceneInstance.colliders
            #Only check the player against other colliders
            counter = 0
            for i in 1:length(colliders)
                #TODO: Skip any out of a certain range of this. This will prevent a bunch of unnecessary collision checks
                if !colliders[i].getParent().isActive || !colliders[i].enabled
                    if this.parent.getRigidbody().grounded && i == length(colliders)
                        this.parent.getRigidbody().grounded = false
                    end
                    continue
                end
                if this != colliders[i]
                    collision = checkCollision(this, colliders[i])
                    transform = this.getParent().getTransform()
                    if collision[1] == Top::CollisionDirection
                        push!(this.currentCollisions, colliders[i])
                        for eventToCall in this.collisionEvents
                            eventToCall()
                        end
                        #Begin to overlap, correct position
                        transform.setPosition(Vector2f(transform.getPosition().x, transform.getPosition().y + collision[2]))
                    elseif collision[1] == Left::CollisionDirection
                        push!(this.currentCollisions, colliders[i])
                        for eventToCall in this.collisionEvents
                            eventToCall()
                        end
                        #Begin to overlap, correct position
                        transform.setPosition(Vector2f(transform.getPosition().x + collision[2], transform.getPosition().y))
                    elseif collision[1] == Right::CollisionDirection
                        push!(this.currentCollisions, colliders[i])
                        for eventToCall in this.collisionEvents
                            eventToCall()
                        end
                        #Begin to overlap, correct position
                        transform.setPosition(Vector2f(transform.getPosition().x - collision[2], transform.getPosition().y))
                    elseif collision[1] == Bottom::CollisionDirection
                        push!(this.currentCollisions, colliders[i])
                        for eventToCall in this.collisionEvents
                            eventToCall()
                        end
                        #Begin to overlap, correct position
                        transform.setPosition(Vector2f(transform.getPosition().x, transform.getPosition().y - collision[2]))
                        this.parent.getRigidbody().grounded = true
                        break
                    elseif collision[1] == Below::ColliderLocation
                        push!(this.currentCollisions, colliders[i])
                        for eventToCall in this.collisionEvents
                            eventToCall()
                        end
                    elseif this.parent.getRigidbody().grounded && i == length(colliders) # If we're on the last collider to check and we haven't collided with anything yet
                        this.parent.getRigidbody().grounded = false
                    end
                end
            end
            this.currentCollisions = []
        end
    elseif s == :update
        function()
            
        end
    elseif s == :addCollisionEvent
        function(event)
            push!(this.collisionEvents, event)
        end
    else
        try
            getfield(this, s)
        catch e
            println(e)
        end
    end
end