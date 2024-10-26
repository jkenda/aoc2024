package rand_gpu

when ODIN_OS == .Windows do foreign import rand_gpu "rand_gpu.lib"
when ODIN_OS == .Linux   do foreign import rand_gpu "librand_gpu.so"


Rng :: struct {}

Algorithm :: enum {
    KISS09,
    LCG12864,
    LFIB,
    MRG63K3A,
    MSWS,
    MT19937,
    MWC64X,
    PCG6432,
    PHILOX2X32_10,
    RAN2,
    TINYMT64,
    TYCHE,
    TYCHE_I,
    WELL512,
    XORSHIFT6432STAR,
}


@(link_prefix="rand_gpu_")
foreign rand_gpu {

    /**
     * @brief Initializes a new random number generator with default parameters.
     */
    @(private)
    @(link_name="rand_gpu_new_rng_default")
    _new_rng_default :: proc() -> ^Rng ---

    /**
     * @brief Initializes a new random number generator.
     * 
     * @param algorithm algorithm for the RNG
     * @param n_buffers Number of buffers for storing random numbers
     * @param buffer_multi Buffer size multiplier
     */
    new_rng :: proc(algorithm: Algorithm, n_buffers: uint, buffer_multi: uint) -> ^Rng ---

    /**
     * @brief Initializes a new random number generator.
     * 
     * @param seed Custom seed
     * @param algorithm Algorithm for the RNG
     * @param n_buffers Number of buffers for storing random numbers
     * @param buffer_multi Buffer size multiplier
     */
    new_rng_with_seed :: proc(algorithm: Algorithm, n_buffers: uint, buffer_multi: uint, seed: u64) -> ^Rng  ---

    /**
     * @brief Deletes the RNG.
     * @param Rng RNG to be deleted
     */
    delete_rng :: proc(rng: ^Rng) ---

    /**
     * @brief Delete all RNGs.
     */
    delete_all :: proc() ---

    /**
     * @brief Resets the RNG.
     * @param rng RNG to be reset
     */
    reset :: proc(rng: ^Rng, seed: u64) ---


    /**
     * @brief Returns next 64-bit random number.
     * @param rng RNG to retrieve the random number from
     */
    rng_64b :: proc(rng: ^Rng) -> u64 ---

    /**
     * @brief Returns next 32-bit random number.
     * @param rng RNG to retrieve the random number from
     */
    rng_32b :: proc(rng: ^Rng) -> u32 ---

    /**
     * @brief Returns next 16-bit random number.
     * @param rng RNG to retrieve the random number from
     */
    rng_16b :: proc(rng: ^Rng) -> u16 ---

    /**
     * @brief Returns next 8-bit random number.
     * @param rng RNG to retrieve the random number from
     */
    rng_8b :: proc(rng: ^Rng) -> u8 ---

    /**
     * @brief Returns next bool.
     * @param rng RNG to retrieve the random number from
     */
    rng_bool :: proc(rng: ^Rng) -> bool ---

    /**
     * @brief Returns next random float.
     * @param rng RNG to retrieve the random number from
     */
    @(link_name="rand_gpu_rng_float")
    rng_f32 :: proc(rng: ^Rng) -> f32 ---

    /**
     * @brief Returns next random double.
     * @param rng RNG to retrieve the random number from
     */
    @(link_name="rand_gpu_rng_double")
    rng_f64 :: proc(rng: ^Rng) -> f64 ---

    ///**
    // * @brief Returns next random long double.
    // * @param rng RNG to retrieve the random number from
    // */
    //@(link_name="rand_gpu_rng_long_double")
    //rng_f128 :: proc(rng: ^Rng) -> f128 ---

    /**
     * @brief Returns next random number.
     * @param rng RNG to retrieve the random number from
     * @param dst where to put the random bytes
     * @param nbytes how many bytes to copy
     */
    @(private)
    @(link_name="rand_gpu_rng_put_random")
    _rng_put_random :: proc(rng: ^Rng, dst: rawptr, nbytes: uint) ---

    /**
     * @brief Discards u bytes from RNG's buffer.
     */
    rng_discard :: proc(rng: ^Rng, z: uint) ---


    /**
     * @brief Returns buffer size of RNG (equal for all RNGs).
     * @param rng RNG whose buffer size to retrieve
     */
    rng_buffer_size :: proc(rng: ^Rng) -> uint ---

    /**
     * @brief Returns number of times the buffer was switched.
     * @param rng RNG whose buffer switches to retrieve
     */
    rng_buffer_switches :: proc(rng: ^Rng) -> uint ---

    /**
     * @brief Returns number of times we had to wait for GPU to fill the buffer.
     * @param rng RNG whose buffer misses to retrieve
     * (Minimize the number of misses by tweaking n_buffers and buffer_multi for better performance.)
     */
    rng_buffer_misses :: proc(rng: ^Rng) -> uint ---

    /**
     * @brief Returns RNG initialization time in ms.
     * @param rng RNG whose init time to retrieve
     */
    rng_init_time :: proc(rng: ^Rng) -> f32 ---

    /**
     * @brief Returns average calculation time for GPU in ms
     * @param rng RNG whose GPU calculation time to retrieve
     */
    rng_avg_gpu_calculation_time :: proc(rng: ^Rng) -> f32 ---

    /**
     * @brief Returns average transfer time for GPU in ms (including time spent waiting for calculations).
     * @param rng RNG whose GPU transfer time to retrieve
     */
    rng_avg_gpu_transfer_time :: proc(rng: ^Rng) -> f32 ---


    /**
     * @brief Returns number of bytes occupied by all RNG instances.
     */
    memory_usage :: proc() -> uint ---

    /**
     * @brief Returns number of times the buffer was switched in all RNG instances.
     */
    buffer_switches :: proc() -> uint ---

    /**
     * @brief Returns number of times we had to wait for GPU to fill the buffer in all RNG instances.
     */
    buffer_misses :: proc() -> uint ---

    /**
     * @brief Return average init time of all RNG instances.
     */
    avg_init_time :: proc() -> f32 ---

    /**
     * @brief Return average GPU calculation time of all RNG instances.
     */
    avg_gpu_calculation_time :: proc() -> f32 ---

    /**
     * @brief Return average GPU transfer time of all RNG instances (including time spent waiting for calculations).
     */
    avg_gpu_transfer_time :: proc() -> f32 ---

    /**
     * @brief Returns the compilation time for the algorithm in ms.
     * @param enum of the algorithm
     */
    compilation_time :: proc(algorithm: Algorithm) -> f32 ---

    /**
     * @brief Returns the name of the algorithm corresponding to the enum.
     * @param enum of the algorithm
     * @param long_name false - return only name, true - return full name and description
     */
    algorithm_name :: proc(algorithm : Algorithm, description: bool) -> cstring ---

}


import "base:runtime"
import "core:math/rand"
import "core:mem"
import "core:crypto"

/**
 * @brief Initializes a new random number generator with default parameters.
 */
new_rng_default :: proc() -> ^Rng {
    context.random_generator = crypto.random_generator()
    return new_rng_with_seed(.TYCHE, 2, 16, rand.uint64())
}

/**
 * @brief Returns next random number.
 * @param rng RNG to retrieve the random number from
 * @param dst where to put the random bytes
 * @param nbytes how many bytes to copy
 */
rng_put_random :: proc(rng: ^Rng, data: []u8) {
    _rng_put_random(rng, raw_data(data), len(data))
}

// random_generator returns a `runtime.Random_Generator` that generates random numbers on the GPU
random_generator_default :: proc() -> runtime.Random_Generator {
    context.random_generator = crypto.random_generator()
    return {
        procedure = proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
            switch mode {
            case .Read:
                rng := cast(^Rng)data
                rng_put_random(cast(^Rng)data, p)
            case .Reset:
                rng := cast(^Rng)data
                seed: u64
                mem.copy_non_overlapping(&seed, raw_data(p), min(size_of(seed), len(p)))
                reset(rng, seed)
            case .Query_Info:
                if len(p) != size_of(runtime.Random_Generator_Query_Info) {
                    return
                }
                info := (^runtime.Random_Generator_Query_Info)(raw_data(p))
                info^ += { .Uniform, .Resettable }
            }
        },
        data = new_rng_default(),
    }
}

// random_generator returns a `runtime.Random_Generator` that generates random numbers on the GPU
random_generator :: proc(algorithm: Algorithm, n_buffers: uint, buffer_multi: uint) -> runtime.Random_Generator {
    context.random_generator = crypto.random_generator()
    return {
        procedure = proc(data: rawptr, mode: runtime.Random_Generator_Mode, p: []byte) {
            switch mode {
            case .Read:
                rng := cast(^Rng)data
                rng_put_random(cast(^Rng)data, p)
            case .Reset:
                rng := cast(^Rng)data
                seed: u64
                mem.copy_non_overlapping(&seed, raw_data(p), min(size_of(seed), len(p)))
                reset(rng, seed)
            case .Query_Info:
                if len(p) != size_of(runtime.Random_Generator_Query_Info) {
                    return
                }
                info := (^runtime.Random_Generator_Query_Info)(raw_data(p))
                info^ += { .Uniform, .Resettable }
            }
        },
        data = new_rng_with_seed(algorithm, n_buffers, buffer_multi, rand.uint64()),
    }
}
