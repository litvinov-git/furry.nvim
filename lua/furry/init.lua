-- Import mini.fuzzy
local fz = require("mini.fuzzy")

-- Highlighting namespaces
local ns_id = vim.api.nvim_create_namespace("furry_matches")     -- namespace for highlighting matches
local ns_id_cur = vim.api.nvim_create_namespace("furry_current") -- namespace for highlighting current

-- Autocmd group
local cmd_group = vim.api.nvim_create_augroup("furry_on_change", { clear = true })
local cmd_group_buf = vim.api.nvim_create_augroup("furry_on_buf", { clear = true })

local jumplist = {}
local current = 1
local last_prompt = "  "

-- Read variables of the buffer on enter, write if none
vim.api.nvim_create_autocmd("BufEnter", {
    group = cmd_group_buf,
    callback = function()
        if vim.b.jumplist == nil then
            vim.b.jumplist = {}
            vim.b.current = 1
            vim.b.last_prompt = " "
        end
        jumplist = vim.b.jumplist
        current = vim.b.current
        last_prompt = vim.b.last_prompt
    end,
})

-- Self table to expose API
local M = {}

-- Default configuration
local opts = {
    highlight_matches = true,
    highlight_current = true,
    max_score = 1800,
    progressive = true,
    on_empty = "dump",
    on_space = "repeat_last",
    on_change = "dump",
    on_buf_enter = "repeat_last"
}

-- Load user configuration
function M.setup(user_opts)
    opts = vim.tbl_deep_extend("force", opts, user_opts or {})
end

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
    last_prompt = query

    local items = get_visible_lines()

    local texts = {}
    for i, item in ipairs(items) do
        texts[i] = item.text
    end

    local matches, indices = fz.filtersort(query, texts)

    for i = 1, #matches do
        if opts.max_score <= 0 or fz.match(query, matches[i]).score <= opts.max_score then
            table.insert(jumplist, {
                line = vim.fn.line('w0') + indices[i] - 2,
                col = fz.match(query, matches[i]).positions[1] - 1,
                col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
            })
        end
    end

    if #jumplist == 0 and opts.progressive == true then
        for i = 1, #matches do
            table.insert(jumplist, {
                line = vim.fn.line('w0') + indices[i] - 2,
                col = fz.match(query, matches[i]).positions[1] - 1,
                col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
            })
        end
    end

    if #jumplist == 0 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'Furry: no matches'<CR>", true, false, true), "n",
            true)
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
    vim.b.jumplist = jumplist
    vim.b.current = current
    vim.b.last_prompt = last_prompt
end

-- Special actions table
local cmds = {}
function cmds.dump()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
    vim.api.nvim_clear_autocmds({ group = cmd_group, buffer = 0 })
    jumplist, vim.b.jumplist = {}, {}
    current, vim.b.current = 1, 1
end

function cmds.repeat_last()
    if last_prompt == " " or last_prompt == "" then
        return
    end
    fuzzy_visible(last_prompt)
end

vim.api.nvim_create_autocmd("BufEnter", {
    group = cmd_group_buf,
    callback = function()
        if #jumplist == 0 then
            return
        end
        cmds[opts.on_buf_enter]()
    end,
})

-- Read user input, clear highlighting if no input, perform furry search
function M.furry()
    vim.ui.input(
        { prompt = "Furry: " },
        function(input)
            if input == nil or input == "" then
                cmds[opts.on_empty]()
            elseif input == " " then
                cmds[opts.on_space]()
            else
                fuzzy_visible(input)
            end
            if #jumplist == 0 then
                return
            end
            local winid = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_cursor(winid,
                { jumplist[current].line + 1, jumplist[current].col })
            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                group = cmd_group,
                buffer = 0,
                once = false,
                callback = function()
                    cmds[opts.on_change]()
                end,
            })
        end
    )
end

-- Cycle to the next match, highlight as current
function M.next()
    if current == nil or #jumplist == 0 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'Furry: no matches'<CR>", true, false, true), "n",
            true)
        return
    end

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
    vim.b.current = current
    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

-- Cycle to the previous match, highlight as current
function M.prev()
    if current == nil or #jumplist == 0 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'Furry: no matches'<CR>", true, false, true), "n",
            true)
        return
    end

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
    vim.b.current = current
    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

-- Create user commands
vim.api.nvim_create_user_command("Furry", M.furry, {})
vim.api.nvim_create_user_command("FurryNext", M.next, {})
vim.api.nvim_create_user_command("FurryPrev", M.prev, {})

return M
