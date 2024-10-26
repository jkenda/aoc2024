package main

import "core:fmt"
import "core:math/rand"
import "core:time"
import "core:crypto"
import "rand_gpu"

Lang :: enum {
    Odin,
    Clojure,
    C,
}

main :: proc() {
    fmt.println("Write today's puzzle in the language chosen by most of the RNGs.")
    fmt.println("If they all choose differently, take the one with the caret.")
    fmt.println()

    {
        // default RNG -- psudorandom generator
        // has to be given a seed with the current time
        rand.reset(cast(u64)time.now()._nsec)
        fmt.println(rand.choice_enum(Lang))
    }

    {
        // my RNG
        context.random_generator = rand_gpu.random_generator(.TINYMT64, 1, 1)
        fmt.println(rand.choice_enum(Lang))
    }

    {
        // crypto RNG -- gets entropy from the CPU
        assert(crypto.HAS_RAND_BYTES)
        context.random_generator = crypto.random_generator()
        fmt.println(rand.choice_enum(Lang), '<')
    }
}
