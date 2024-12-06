package main

import "core:os"
import "core:fmt"
import "core:strings"

Direction     :: enum { Up, Down, Left, Right }
Position      :: distinct [2]int
Direction_Set :: distinct map[Direction]struct{}
Position_Map  :: distinct map[Position]Direction_Set

// current state of the program
Map :: distinct [][]u8
Guard :: struct {
    position: Position,
    direction: Direction,
}
State :: struct {
    mapped_area: Map,
    guard: Guard,
}


visited: Position_Map

main :: proc() {
    is_inside :: proc(mapped_area: Map, position: Position) -> bool {
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

    guard_move :: proc(state: ^State) -> bool {
        mapped_area := &state.mapped_area
        guard := &state.guard

        // finish if a previously visited state is encountered
        // (meaning we would loop forever)
        // or the guard leaves the mapped area
        if visited_loc, ok := visited[guard.position]; ok {
            if _, ok := visited_loc[guard.direction]; ok {
                return false
            }
        }
        if !is_inside(mapped_area^, guard.position) { return false }

        // move the guard
        next := guard.position + offset(guard.direction)
        if !is_inside(mapped_area^, next) || mapped_area[next.y][next.x] == '.' {
            // the next position is empty -- the guard goes straight
            visited[guard.position] = {}
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

    { // part 1
        for guard_move(&state) {}

        // print the final state and num. of visited positions
        //print_state(state)
        fmt.println(len(visited))
        clear(&visited)
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
print_state :: proc(state: State) {
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
