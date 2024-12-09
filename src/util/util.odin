package util

/*
Searches the given slice for the first element satisfying predicate `f` in O(n) time.

Inputs:
- array: The slice to search in.
- d: The data to compare the elements against.
- f: The search condition.

Returns:
- index: The index `i`, such that `array[i]` is the first `x` in `array` for which `f(x, d) == true`, or -1 if such `x` does not exist.
*/
@(require_results)
linear_search_proc_data :: proc(array: $A/[]$T, d: T, f: proc(T, T) -> bool) -> (index: int, found: bool) {
	for x, i in array {
		if f(x, d) {
			return i, true
		}
	}
	return -1, false
}
