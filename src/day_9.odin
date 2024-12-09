package main

import "core:os"
import "core:fmt"
import "core:strings"

Block :: struct { id, start, size: uint }
Disk_Map :: distinct [dynamic]Block

main :: proc() {
    disk_map, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(disk_map)

    Empty_Space :: struct {
        idx: int,
        start, size: uint,
        new_block: bool,
    }

    find_empty_space :: proc(disk_map: Disk_Map) -> (space: Empty_Space, has_space: bool) {
        last_block := &disk_map[len(disk_map) - 1]

        for &block, idx in disk_map[1:] {
            prev_block := &disk_map[idx]
            space_offset := prev_block.start + prev_block.size
            space_size := block.start - space_offset

            if space_size > 0 {
                has_space = true

                if prev_block.id == last_block.id {
                    // enlarge block
                    space = Empty_Space{
                        idx       = idx,
                        new_block = false,
                        size      = min(space_size, last_block.size),
                    }
                }
                else {
                    // insert new block
                    space = Empty_Space{
                        idx       = idx + 1,
                        new_block = true,
                        start     = space_offset,
                        size      = min(space_size, last_block.size),
                    }
                }

                return
            }
        }

        has_space = false
        return
    }

    { // part 1
        for space in find_empty_space(disk_map) {
            last_block := &disk_map[len(disk_map) - 1]
            last_block.size -= space.size
            if last_block.size == 0 {
                pop(&disk_map)
            }

            if space.new_block {
                inject_at(&disk_map, space.idx, Block{
                    id    = last_block.id,
                    start = space.start,
                    size  = space.size,
                })
            }
            else {
                disk_map[space.idx].size += space.size
            }
        }

        fs_checksum : uint = 0
        for &block, idx in disk_map {
            for block_pos in block.start..<block.start + block.size {
                fs_checksum += block_pos * block.id
            }
        }

        fmt.println(fs_checksum)
    }
}

read_and_parse :: proc(path: string) -> (disk_map: Disk_Map, err: os.Error) {
    Block_Type :: enum {
        Free_Space,
        Data,
    }

    data := os.read_entire_file_or_err(path) or_return
    defer delete(data)

    block_type := Block_Type.Data
    start : uint = 0
    id : uint = 0

    for c, idx in data {
        block_size := uint(c) - uint('0')

        switch block_type {
        case .Free_Space:
        case .Data:
            append(&disk_map, Block {
                id     = id,
                start = start,
                size   = uint(block_size),
            })
            id += 1
        }

        block_type = .Free_Space if block_type == .Data else .Data
        start += uint(block_size)
    }

    return
}

print_fs :: proc(disk_map: Disk_Map) {
    prev_block_end : uint = 0

    for block in disk_map {
        for _ in prev_block_end..<block.start {
            fmt.print('.')
        }

        for _ in 0..<block.size {
            fmt.print(block.id)
        }

        prev_block_end = block.start + block.size
    }
    fmt.println()
}
