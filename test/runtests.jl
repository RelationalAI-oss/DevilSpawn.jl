using DevilSpawn
using Test

@testset "DevilSpawn.jl" begin
    spawned = [fetch(@spawn_background Threads.threadid()) for _ in 1:100]
    if Threads.nthreads() > 1
        @test !in(1, spawned)
    else
        @test all(==(1), spawned)
    end
end
