include("../../../src/Macros.jl")
include("../../../src/SceneInstance.jl")
include("../../../src/Math/Lerp.jl")
include("../../../src/Math/Vector2f.jl")

mutable struct GameManager
    currentAct
    dialogue
    fadeOut
    goldPot
    moneyBlocks
    parent
    platforms
    playerMovement
    potGoingDown
    potTimeToMove
    secretDialogue
    textBox
    timerPot

    function GameManager()
        this = new()
        
        this.currentAct = 0
        this.fadeOut = true
        this.potGoingDown = true
        this.potTimeToMove = 1.0
        this.timerPot = 0.0

        return this
    end
end

function Base.getproperty(this::GameManager, s::Symbol)
    if s == :initialize
        function()
        end
    elseif s == :update
        function(deltaTime)
            if this.currentAct == 0
                if this.fadeOut 
                    println(this.textBox.alpha)
                    this.textBox.alpha -= 1
                    this.textBox.updateText(this.textBox.text)
                    if this.textBox.alpha <= 25
                        this.fadeOut = false
                    end
                else
                    this.textBox.alpha += 1
                    this.textBox.updateText(this.textBox.text)
                    if this.textBox.alpha >= 250
                        this.fadeOut = true
                    end
                end
                if Button_Jump::Button in InputInstance.buttons
                    this.resetPlayer()
                    # play falling sound
                end
            end
            potTransform = this.goldPot.getTransform()
            if this.currentAct == 1 && this.goldPot.isActive && this.potGoingDown
                this.timerPot = this.timerPot + deltaTime
                potTransform.position = Vector2f(potTransform.position.x, Lerp(6,7, this.timerPot/this.potTimeToMove))
                if this.timerPot >= this.potTimeToMove 
                    this.goldPot.isActive = false
                    #call player move
                    this.playerMovement.canMove = true
                    this.potGoingDown = false
                    this.timerPot = 0.0
                end
            elseif this.currentAct == 1 && this.goldPot.isActive && !this.potGoingDown
                this.timerPot = this.timerPot + deltaTime
                potTransform.position = Vector2f(potTransform.position.x, Lerp(7,6, this.timerPot/this.potTimeToMove))
                if this.timerPot >= this.potTimeToMove 
                    #call player move
                    this.playerMovement.canMove = true
                    this.timerPot = 0.0
                    this.currentAct = 2
                    this.dialogue.isPaused = false
                end
            elseif this.currentAct == 2 && this.goldPot.isActive && !this.potGoingDown
                this.timerPot = this.timerPot + deltaTime
                potTransform.position = Vector2f(Lerp(potTransform.position.x,0, this.timerPot/this.potTimeToMove), Lerp(6,5, this.timerPot/this.potTimeToMove))
                if this.timerPot >= this.potTimeToMove 
                    #call player move
                    this.playerMovement.canMove = true
                    this.timerPot = 0.0
                    this.currentAct = 2
                    this.dialogue.isPaused = false
                    this.potGoingDown = true
                end
            end

        end
    elseif s == :resetPlayer
        function()
            this.currentAct = 1
            this.textBox.alpha = 255
            this.textBox.updateText(" ")
            this.playerMovement.parent.getTransform().position = Vector2f(0,-1)
            this.playerMovement.form = 0
            this.playerMovement.isFalling = true
            SceneInstance.sounds[9].toggleSound()
            this.playerMovement.parent.getComponent(Animator).currentAnimation = this.playerMovement.parent.getComponent(Animator).animations[(this.playerMovement.form * 4) + 4]
        end
    elseif s == :setParent
        function(parent)
            this.parent = parent
        end
    else
        try
            getfield(this, s)
        catch e
            println(e)
        end
    end
end