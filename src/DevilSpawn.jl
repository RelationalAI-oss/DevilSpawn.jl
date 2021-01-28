module DevilSpawn

import Base.Threads

"""
    @spawn_background expr

Like `@spawn`, but ensures that the spawned task isn't scheduled on the main thread, except
if `nthreads() == 1`, in which case this is equivalent to `@async`.

If all background threads are currently blocked, we retry until one becomes available using
a small exponential backoff. A `yield()` call or automatically placed yield point will free
up the thread and allow another task to be scheduled.

If all background threads are currently busy, this Task will block, retrying until one 
becomes available using a small exponential backoff. A `yield()` call in one of the other 
threads or an automatically placed yield point will eventually free up a thread, and allow 
this task to be scheduled.
"""
macro spawn_background(exprs...)
    esc(quote
        $Threads.@spawn $spawn_background(()->$(exprs...))
    end)
end

function spawn_background(f, attempt_num=0)
    if Threads.threadid() == 1 && Threads.nthreads() > 1
        # Out of concern that we might build up a bunch of tasks, all clamoring to schedule
        # on main while we wait for an availabl thread, we use a very small exponential
        # backoff between scheduling attempts. We keep this very fast, so that it shouldn't
        # contribute noticable latency, but will help to prevent many enqueued tasks from
        # burning CPU while they wait.
        sleep(1E-9 * (1 << min(32, attempt_num)))
        # Maintain demand on the new Task, so that errors will propagate.
        return fetch(Threads.@spawn spawn_background(f, attempt_num+1))
    else
        f()
    end
end

export @spawn_background

end # module
