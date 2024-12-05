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

Update :: distinct [dynamic]int
Rule   :: struct { before, after: int }
Rules  :: map[Rule]struct{}
Input  :: struct {
    ordering_rules: Rules,
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

        for &update, i in input.pages_to_produce {
            // which updates are in order
            if _, ok := out_of_order(input.ordering_rules, update[:]); !ok {
                middle_page := update[len(update) / 2]
                sum += middle_page
            }
        }

        fmt.println(sum)
    }

    { // part 2
        sum := 0

        for &update, i in input.pages_to_produce {
            // fix the order of updates
            is_out_of_order := false

            for idxs in out_of_order(input.ordering_rules, update[:]) {
                is_out_of_order = true
                slice.swap(update[:], idxs[0], idxs[1])
            }

            if (is_out_of_order) {
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

            input.ordering_rules[Rule{ page_before, page_after }] = {}

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

out_of_order :: proc(ordering_rules: Rules, update: []int) -> ([2]int, bool) {
    for _, i in update {
        #reverse for _, j in update {
            opposite_rule := Rule {
                before = update[max(i, j)],
                after  = update[min(i, j)],
            }
            if _, ok := ordering_rules[opposite_rule]; ok {
                return { i, j }, true
            }
        }
    }

    return { 0, 0 }, false
}
