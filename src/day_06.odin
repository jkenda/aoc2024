package main

import "core:os"
import "core:fmt"
import "core:strings"

Direction :: enum { Up, Down, Left, Right }
Position  :: distinct [2]int
Map       :: distinct [][]u8

// current state of the program
Guard :: struct {
    position: Position,
    direction: Direction,
}
State :: struct {
    mapped_area: Map,
    guard: Guard,
}

Direction_Set :: bit_set[Direction]
Position_Map  :: distinct map[Position]Direction_Set
Guard_Set     :: distinct map[Guard]struct{}


main :: proc() {
    is_inside :: proc(mapped_area: Map, position: Position) -> bool {
        if position.x < 0 || position.y < 0 { return false }
        return position.y < len(mapped_area) && position.x < len(mapped_area[0])
    }

    guard_move :: proc(state: ^State, visited: ^Position_Map = nil, makes_loop: ^bool = nil) -> bool {
        mapped_area := &state.mapped_area
        guard := &state.guard

        // finish if a previously visited state is encountered
        // (meaning we would loop forever)
        // or the guard leaves the mapped area
        if visited != nil && makes_loop != nil {
            if dir_set, ok := visited[guard.position]; ok {
                if guard.direction in dir_set {
                    makes_loop^ = true
                    return false
                }
            }
        }
        if !is_inside(mapped_area^, guard.position) { return false }

        // move the guard
        offset: Position
        switch guard.direction {
        case .Up:
            offset = { 0, -1 }
        case .Down:
            offset = { 0,  1 }
        case .Left:
            offset = { -1, 0 }
        case .Right:
            offset = {  1, 0 }
        }

        next := guard.position + offset
        if !is_inside(mapped_area^, next) || mapped_area[next.y][next.x] == '.' {
            // the next position is empty -- the guard goes straight
            if visited != nil {
                visited[guard.position] |= { guard.direction }
            }
            guard.position = next
        }
        else {
            // the next position is ubstructed -- the guard turns right
            switch guard.direction {
            case .Up:
                guard.direction = .Right
            case .Down:
                guard.direction = .Left
            case .Left:
                guard.direction = .Up
            case .Right:
                guard.direction = .Down
            }
        }

        return is_inside(mapped_area^, guard.position)
    }


    // make the initial state
    data, state, err := make_initial_state(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)
    guard_initial := state.guard

    { // part 1
        visited: Position_Map
        defer clear(&visited)

        for guard_move(&state, &visited) {}

        // print num. of visited positions
        fmt.println(len(visited))
    }

    { // part 2
        additional_obstructions: Position_Map

        // move the guard once so it's not in the initial position
        state.guard = guard_initial
        guard_move(&state)

        visited: Position_Map
        already_obstructed: Position_Map
        defer clear(&already_obstructed)
        defer clear(&visited)

        for is_inside(state.mapped_area, state.guard.position) {
            // put an obstruction in the guard's way
            obstruc_pos := state.guard.position
            defer guard_move(&state, &already_obstructed)
            if _, ok := already_obstructed[obstruc_pos]; ok { continue }

            // save the guard state and start from the initial one
            guard := state.guard
            state.guard = guard_initial
            state.mapped_area[obstruc_pos.y][obstruc_pos.x] = 'O'

            // clear the visited positions
            clear(&visited)

            // see if we make a loop
            makes_loop := false
            for guard_move(&state, &visited, &makes_loop) {}
            if makes_loop {
                additional_obstructions[obstruc_pos] = {}
            }

            // restore previous state
            state.mapped_area[obstruc_pos.y][obstruc_pos.x] = '.'
            state.guard = guard
        }

        // print the final state and num. of visited positions
        fmt.println(len(additional_obstructions))
    }
}

make_initial_state :: proc(path: string) -> (data: []u8, state: State, err: os.Error) {
    dir_of_rune :: proc(c: u8) -> Direction {
        switch c {
        case '^': return .Up
        case 'v': return .Down
        case '<': return .Left
        case '>': return .Right
        case: assert(false, "invalid char!")
        }
        return nil
    }

    // read data and trim whitespace
    data = os.read_entire_file_or_err(path) or_return
    str := string(data)
    str = strings.trim(str, " \n\r\t")

    // initialize the mapped area
    state.mapped_area = transmute(Map)strings.split_lines(str)

    // find the position of the guard
    guard_search: for &line, y in state.mapped_area {
        for c, x in line {
            switch c {
            case '.', '#':
                continue

            case '^', 'v', '<', '>':
                line[x] = '.'
                state.guard = Guard {
                    position  = Position{ x, y },
                    direction = dir_of_rune(c)
                }
                break guard_search
            case:
                assert(false, "invalid character!")
            }
        }
    }

    return
}
