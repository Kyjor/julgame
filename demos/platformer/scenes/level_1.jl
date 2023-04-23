using .julgame
using .julgame.Math

include("../../../src/Camera.jl")
include("../../../src/Main.jl")
include("../src/sceneReader.jl")
include("../../../src/Component/Transform.jl")

function level_1(isUsingEditor = false)
    #file loading
    ASSETS = joinpath(@__DIR__, "..", "assets")
    main = MAIN

    main.scene.entities = deserializeEntities(joinpath(@__DIR__, "ExampleScene.json"))
    main.scene.camera = Camera(Vector2f(975, 750), Vector2f(),Vector2f(0.64, 0.64), Transform())

    println(main.scene.entities)
    main.assets = ASSETS
    main.loadScene(main.scene)
    main.init(isUsingEditor)
    return main
end