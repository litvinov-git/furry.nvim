local M = {}
local opts = {
    highlight_matches = true,
    highlight_current = true,
    max_score = 1800,
}
function M.setup(user_opts)
    opts = vim.tbl_deep_extend("force", opts, user_opts or {})
end

-- Import mini.fuzzy
local fz = require("mini.fuzzy")

-- Variables to keep last search data
local jumplist = {}                                              -- table of of matched coordinates to jump to
local current = 1                                                -- last index selected from the jumplist

-- Highlighting namespaces
local ns_id = vim.api.nvim_create_namespace("furry_matches")     -- namespace for highlighting matches
local ns_id_cur = vim.api.nvim_create_namespace("furry_current") -- namespace for highlighting current


-- Helper function that returns index of an element in a table
local function index_of(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return 1
end

-- Helper function that returns the table of tables of a a line in visible lines and its number in the buffer
local function get_visible_lines()
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('w$')

    local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)

    local items = {}
    for i, text in ipairs(lines) do
        table.insert(items, {
            lnum = top + i - 1,
            text = text,
        })
    end

    return items
end

-- Perform search, jump to the best match, load and highlight results
local function fuzzy_visible(query)
    jumplist = {}
    current = 1

    local items = get_visible_lines()

    local texts = {}
    for i, item in ipairs(items) do
        texts[i] = item.text
    end

    local matches, indices = fz.filtersort(query, texts)

    for i = 1, #matches do
        if fz.match(query, matches[i]).score <= opts.max_score then
            table.insert(jumplist, {
                line = vim.fn.line('w0') + indices[i] - 2,
                col = fz.match(query, matches[i]).positions[1] - 1,
                col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
            })
        end
    end

    if #jumplist == 0 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'No matches'<CR>", true, false, true), "n", true)
        return
    end

    local best_match = jumplist[1]

    table.sort(jumplist, function(a, b)
        return (a.line < b.line) or (a.line == b.line and a.col < b.col)
    end)

    current = index_of(jumplist, best_match)

    if opts.highlight_matches == true then
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        for _, match in ipairs(jumplist) do
            -- ns_id: namespace id created via nvim_create_namespace
            vim.api.nvim_buf_set_extmark(
                0,                                -- buffer (0 = current)
                ns_id,                            -- namespace
                match.line,                       -- 0-based line
                match.col,                        -- 0-based start column
                {
                    end_col = match.col_last + 1, --match.col_last, -- exclusive end column
                    hl_group = "Search",          -- highlight group
                    priority = 300
                }
            )
        end
    end
    if opts.highlight_current == true then
        vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
        vim.api.nvim_buf_set_extmark(
            0,                                            -- buffer (0 = current)
            ns_id_cur,                                    -- namespace
            jumplist[current].line,                       -- 0-based line
            jumplist[current].col,                        -- 0-based start column
            {
                end_col = jumplist[current].col_last + 1, --match.col_last, -- exclusive end column
                hl_group = "IncSearch",                   -- highlight group
                priority = 500
            }
        )
    end

    local winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

-- Read user input, clear highlighting if no input, perform furry search
function M.furry()
    vim.ui.input(
        { prompt = "Furry: " },
        function(input)
            if input == nil or input == "" then
                vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
                vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
                return
            end
            fuzzy_visible(input)
        end
    )
end

-- Cycle to the next match, highlight as current
function M.next()
    current = current + 1

    if current > #jumplist then
        current = 1
    end

    local winid = vim.api.nvim_get_current_win()

    if opts.highlight_current == true then
        vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
        vim.api.nvim_buf_set_extmark(
            0,                                            -- buffer (0 = current)
            ns_id_cur,                                    -- namespace
            jumplist[current].line,                       -- 0-based line
            jumplist[current].col,                        -- 0-based start column
            {
                end_col = jumplist[current].col_last + 1, --match.col_last, -- exclusive end column
                hl_group = "IncSearch",                   -- highlight group
                priority = 500
            }
        )
    end

    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

-- Cycle to the previous match, highlight as current
function M.prev()
    current = current - 1

    if current < 1 then
        current = #jumplist
    end

    local winid = vim.api.nvim_get_current_win()

    if opts.highlight_current == true then
        vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
        vim.api.nvim_buf_set_extmark(
            0,                                            -- buffer (0 = current)
            ns_id_cur,                                    -- namespace
            jumplist[current].line,                       -- 0-based line
            jumplist[current].col,                        -- 0-based start column
            {
                end_col = jumplist[current].col_last + 1, --match.col_last, -- exclusive end column
                hl_group = "IncSearch",                   -- highlight group
                priority = 500
            }
        )
    end

    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

-- Create user commands
vim.api.nvim_create_user_command("Furry", M.furry, {})
vim.api.nvim_create_user_command("FurryNext", M.next, {})
vim.api.nvim_create_user_command("FurryPrev", M.prev, {})



return M
