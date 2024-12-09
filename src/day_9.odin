package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "util"

Block :: struct { id, start, size: uint }
Disk_Map :: distinct [dynamic]Block

main :: proc() {
    data, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)

    Empty_Space :: struct {
        idx: int,
        start, size: uint,
        new_block: bool,
    }

    find_empty_space :: proc(disk_map: []Block, min_size: uint = 1) -> (space: Empty_Space, has_space: bool) {
        last_block := &disk_map[len(disk_map) - 1]

        for &block, idx in disk_map[1:] {
            prev_block := &disk_map[idx]
            space_offset := prev_block.start + prev_block.size
            space_size := block.start - space_offset

            if space_size >= min_size {
                has_space = true

                if prev_block.id == last_block.id {
                    // enlarge block
                    space = Empty_Space{
                        idx       = idx,
                        new_block = false,
                        size      = space_size,
                    }
                }
                else {
                    // insert new block
                    space = Empty_Space{
                        idx       = idx + 1,
                        new_block = true,
                        start     = space_offset,
                        size      = space_size,
                    }
                }

                return
            }
        }

        return
    }

    calc_checksum :: proc(disk_map: Disk_Map) -> (fs_checksum: uint) {
        for &block, idx in disk_map {
            for block_pos in block.start..<block.start + block.size {
                fs_checksum += block_pos * block.id
            }
        }
        return
    }

    { // part 1
        disk_map := make(Disk_Map, len(data))
        copy(disk_map[:], data[:])
        defer delete(disk_map)

        for space in find_empty_space(disk_map[:]) {
            last_block := &disk_map[len(disk_map) - 1]
            size := min(last_block.size, space.size)

            last_block.size -= size
            if last_block.size == 0 {
                pop(&disk_map)
            }

            if space.new_block {
                inject_at(&disk_map, space.idx, Block{
                    id    = last_block.id,
                    start = space.start,
                    size  = size,
                })
            }
            else {
                disk_map[space.idx].size += size
            }
        }

        fmt.println(calc_checksum(disk_map))
    }

    { // part 2
        disk_map := make(Disk_Map, len(data))
        copy(disk_map[:], data[:])
        defer delete(disk_map)

        #reverse for orig_block in data {
            idx, _ := util.linear_search_proc_data(disk_map[:], orig_block,
                proc(a: Block, b: Block) -> bool { return a.id == b.id })

            block := disk_map[idx]
            space, found := find_empty_space(disk_map[:idx+1], block.size)
            if !found { continue }

            block.start = space.start
            ordered_remove(&disk_map, idx)
            inject_at(&disk_map, space.idx, block)
        }

        fmt.println(calc_checksum(disk_map))
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
