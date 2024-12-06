package main

import "core:os"
import "core:fmt"
import "core:strings"

Direction :: enum { Up, Down, Left, Right }
Position  :: distinct [2]int

// current state of the program
Map   :: distinct [][]u8
Guard :: struct {
    position: Position,
    direction: Direction,
}
State :: struct {
    mapped_area: Map,
    guard: Guard,
}

Direction_Set :: distinct map[Direction]struct{}
Position_Set  :: distinct map[Position]struct{}
Guard_Set     :: distinct map[Guard]struct{}


main :: proc() {
    is_inside :: proc(mapped_area: Map, position: Position) -> bool {
        if position.x < 0 || position.y < 0 { return false }
        return position.y < len(mapped_area) && position.x < len(mapped_area[0])
    }

    offset :: proc(dir: Direction) -> Position {
        switch dir {
        case .Up:    return { 0, -1 }
        case .Down:  return { 0,  1 }
        case .Left:  return { -1, 0 }
        case .Right: return {  1, 0 }
        }
        return { 0, 0 }
    }

    dir_right :: proc(dir: Direction) -> Direction {
        switch dir {
        case .Up:    return .Right
        case .Down:  return .Left
        case .Left:  return .Up
        case .Right: return .Down
        }
        return nil
    }

    guard_move :: proc(
        state: ^State,
        pos_set: ^Position_Set = nil,
        guard_set: ^Guard_Set = nil,
        makes_loop: ^bool = nil,
    ) -> bool {
        mapped_area := &state.mapped_area
        guard := &state.guard

        // finish if a previously visited state is encountered
        // (meaning we would loop forever)
        // or the guard leaves the mapped area
        if guard_set != nil && makes_loop != nil {
            if _, ok := guard_set[guard^]; ok {
                makes_loop^ = true
                return false
            }
        }
        if !is_inside(mapped_area^, guard.position) { return false }

        // move the guard
        next := guard.position + offset(guard.direction)
        if !is_inside(mapped_area^, next) || mapped_area[next.y][next.x] == '.' {
            // the next position is empty -- the guard goes straight
            if guard_set != nil {
                guard_set[guard^] = {}
            }
            if pos_set != nil {
                pos_set[guard.position] = {}
            }

            guard.position = next
        }
        else {
            // the next position is ubstructed -- the guard turns right
            guard.direction = dir_right(guard.direction)
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
        visited: Position_Set
        defer clear(&visited)

        for guard_move(&state, &visited) {}

        // print num. of visited positions
        fmt.println(len(visited))
    }

    { // part 2
        additional_obstructions: Position_Set

        // move the guard once so it's not in the initial position
        state.guard = guard_initial
        guard_move(&state)

        visited: Guard_Set
        for is_inside(state.mapped_area, state.guard.position) {
            // clear the visited poositions
            clear(&visited)

            // save the guard state
            guard := state.guard

            // put an obstruction in the guard's way
            obstruc_pos := guard.position
            state.mapped_area[obstruc_pos.y][obstruc_pos.x] = 'O'

            // start from the initial guard state
            state.guard = guard_initial

            makes_loop := false
            for guard_move(&state, nil, &visited, &makes_loop) {}
            if makes_loop {
                additional_obstructions[obstruc_pos] = {}
            }

            // restore previous state
            state.mapped_area[obstruc_pos.y][obstruc_pos.x] = '.'
            state.guard = guard
            guard_move(&state)
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

// debug print
print_state :: proc(state: State, visited: Position_Set) {
    rune_of_dir :: proc(dir: Direction) -> rune {
        switch dir {
        case .Up:    return '^'
        case .Down:  return 'v'
        case .Left:  return '<'
        case .Right: return '>'
        }
        return '\x00'
    }

    for line, y in state.mapped_area {
        for c, x in line {
            pos := Position{ x, y }
            is_guard_position := (state.guard.position == pos)
            _, is_visited := visited[pos]

            character := rune(c)
            if is_guard_position {
                character = rune_of_dir(state.guard.direction)
            }
            else if is_visited {
                character = 'X'
            }

            fmt.print(character)
        }
        fmt.println()
    }
    fmt.println()
}
