module DevilSpawn

import Base.Threads

"""
    @spawn_background expr

Like `@spawn`, but ensures that the spawned task isn't scheduled on the main thread, except
if `nthreads() == 1`.

If all background threads are currently blocked, we retry until one becomes available using
a small exponential backoff. A `yield()` call or automatically placed yield point will free
up the thread and allow another task to be scheduled.
"""
macro spawn_background(exprs...)
    esc(quote
        $Threads.@spawn $spawn_background(()->$(exprs...))
    end)
end

function spawn_background(f, attempt_num=0)
    if Threads.threadid() == 1 && Threads.nthreads() > 1
        sleep(1E-9 * (1 << min(32, attempt_num)))
        # Maintain demand on the new Task, so that errors will propagate.
        return fetch(Threads.@spawn spawn_background(f, attempt_num+1))
    else
        f()
    end
end

export @spawn_background

end # module
