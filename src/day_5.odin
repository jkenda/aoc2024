package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"


Parsing_Section :: enum {
    Page_Ordering_Rules,
    Pages_To_Produce,
}

Rule :: struct {
    before, after: int
}
Update :: distinct [dynamic]int
Input  :: struct {
    ordering_rules: [dynamic]Rule,
    pages_to_produce: [dynamic]Update,
}

delete_input :: proc(input: ^Input) {
    delete(input.ordering_rules)
    for &update in input.pages_to_produce {
        delete(update)
    }
    delete(input.pages_to_produce)
}

main :: proc() {
    input, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete_input(&input)

    { // part 1
        sum := 0

        for update, i in input.pages_to_produce {
            // which updates are in order
            if is_in_order(input.ordering_rules[:], update[:]) {
                middle_page := update[len(update) / 2]
                sum += middle_page
            }
        }

        fmt.println(sum)
    }
}

read_and_parse :: proc(path: string) -> (input: Input, err: os.Error) {
    data := os.read_entire_file_or_err(path) or_return
    defer delete(data)

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    // parse input
    now_parsing := Parsing_Section.Page_Ordering_Rules
    for line in strings.split_lines_iterator(&str) {
        if line == "" {
            now_parsing = .Pages_To_Produce
            continue
        }

        switch now_parsing {
        case .Page_Ordering_Rules:
            str_rule := strings.split(line, "|") or_return
            defer delete(str_rule)
            assert(len(str_rule) == 2)

            page_before, ok1 := strconv.parse_int(str_rule[0])
            page_after , ok2 := strconv.parse_int(str_rule[1])
            assert(ok1 && ok2)

            append(&input.ordering_rules, Rule{ page_before, page_after })

        case .Pages_To_Produce:
            str_update := strings.split(line, ",") or_return
            defer delete(str_update)

            append(&input.pages_to_produce, make(Update))
            reserve(&input.pages_to_produce, len(str_update))
            pages_back := &input.pages_to_produce[len(input.pages_to_produce) - 1]

            for str_page in str_update {
                page, ok := strconv.parse_int(str_page)
                assert(ok)
                append(pages_back, page)
            }
        }
    }

    return
}

is_in_order :: proc(ordering_rules: []Rule, update: []int) -> bool {
    for _, i in update {
        for _, j in update {
            if i == j { continue }

            i_before := min(i, j)
            i_after  := max(i, j)
            opposite_rule := Rule { update[i_after], update[i_before] }
            if slice.contains(ordering_rules, opposite_rule) { return false }
        }
    }

    return true
}
