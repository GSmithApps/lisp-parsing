function get_next_line!(vector_of_remaining_lines::Vector{String},)::Union{String, Nothing}

    # Base Case
    if isempty(vector_of_remaining_lines)
        return nothing
    end

    current_line = popfirst!(vector_of_remaining_lines)

    if strip(current_line) == "" || first(lstrip(current_line))  ∉ ['|']
        return get_next_line!(vector_of_remaining_lines)
    end

    return current_line

end

"""
Recursively processes lines of code from a vector based on trailing space difference.

The logic compares the trailing spaces of the current line to the previous line.
An increase in trailing spaces (assumed 2 spaces per level) is converted into
leading opening parentheses. The first '/' is replaced with a ')'.
"""
function process_lines_of_source_code(
    vector_of_remaining_lines::Vector{String},
    line_to_process::String,
    new_source_code::String,
)::String

    next_line = get_next_line!(vector_of_remaining_lines)

    if isnothing(next_line)
        return new_source_code
    end

    current_line_with_leading_pipe_removed = replace(line_to_process, "|" => " ", count=1)
    next_line_with_leading_pipe_removed = replace(next_line, "|" => " ", count=1)

    # current_line_leading_spaces counts the number of leading spaces up to the actual characters...
    # but remember that the front pipe is removed. So it's like the following:
    # Something like "| / hi" has two leading spaces
    current_line_leading_spaces = length(current_line_with_leading_pipe_removed) - length(lstrip(replace(current_line_with_leading_pipe_removed, "/ " => "  ")))
    next_line_leading_spaces = length(next_line_with_leading_pipe_removed) - length(lstrip(next_line_with_leading_pipe_removed))

    leading_space_decrease = current_line_leading_spaces - next_line_leading_spaces

    num_slashes_in_current_line = count("/ ", current_line_with_leading_pipe_removed)

    # Calculate the number of structure-opening parentheses, assuming 2 spaces per step.
    num_close_parenthesis = max(0, floor(Int, leading_space_decrease / 2)) + max(0, num_slashes_in_current_line - 1)

    # 3. Transform the line content.
    # Replace the first occurrence of "/" with ")" and "|"with " "
    transformed_line = replace(current_line_with_leading_pipe_removed, "/" => "(")

    # 4. Accumulate the new source code (newSourceCode).
    close_parens_string = repeat(" )", num_close_parenthesis)

    # Append the new structure to the accumulator, adding a newline for clarity.
    new_source_code_accumulator = new_source_code * transformed_line * close_parens_string * "\n"

    # previous line leading spaces needs to be calculated based on the "/"

    # 6. Recurse.
    return process_lines_of_source_code(
        vector_of_remaining_lines,
        next_line,
        new_source_code_accumulator,
    )
end

# Wrapper function for a clean initial call and demonstration.
function processLinesOfSourceCode(lines::Vector{String})
    stack_copy = copy(lines)

    first_line = get_next_line!(stack_copy)

    result = process_lines_of_source_code(stack_copy, first_line, "")
    return result
end

function processSourceCode(sourceCode::String)
    sourceCodeLines = split(sourceCode, "\n")

    return processLinesOfSourceCode(map(String, sourceCodeLines))

end

source = read("example.mlg", String)

output = processSourceCode(source)

open("transpiled.txt", "w") do io
    print(io, output) # Writes "First line.\n"
end

