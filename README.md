# DevilSpawn.jl

Provides a hacky workaround to force a task to @spawn on an available background thread (except if `nthreads() == 1`).

This package becomes oblivious once Julia allows to define where a task is allowed to spawn.

`@spawn_background expr` will spawn a Task on another thread, automatically retrying until it spawns somewhere that's not `taskid == 1`.

## Example

Running Julia with 8 threads: `export JULIA_NUM_THREADS=8`

```julia
julia> using DevilSpawn

julia> Threads.nthreads()
8

julia> for _ in 1:6
           @spawn_background begin @info "Blocking thread $(Threads.threadid())" ; while true end end
       end

[ Info: Blocking thread 7
[ Info: Blocking thread 4
[ Info: Blocking thread 8
[ Info: Blocking thread 2
[ Info: Blocking thread 6
[ Info: Blocking thread 3

# Threads 2, 3, 4, 6, 7, 8 are now blocked with a long-running task without yield points.
# The main thread 1 is never blocked.
# The next call is guaranteed to run on thread 5, since it is the only available one:

julia> @spawn_background (@info "Blocking thread $(Threads.threadid())" ; while true end)
[ Info: Blocking thread 5
Task (runnable) @0x000000010e2fb610

# Consecutive @spawn_background calls don't have any effect until another thread becomes available again,
# but *crucially*, the REPL remains responsive, while the task waits for a thread:

julia> @spawn_background (@info "Blocking thread $(Threads.threadid())" ; while true end)
Task (runnable) @0x000000010e2fb610

julia> println("🎉")
🎉
```
