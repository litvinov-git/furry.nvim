-- Import mini.fuzzy
local fz = require("mini.fuzzy")

-- Highlighting namespaces
local ns_id = vim.api.nvim_create_namespace("furry_matches") -- for highlighting matches
local ns_id_cur = vim.api.nvim_create_namespace("furry_current") -- for HL current

-- Autocmd group
local cmd_group = vim.api.nvim_create_augroup("furry_on_change", { clear = true }) -- on editing the buffer
local cmd_group_buf = vim.api.nvim_create_augroup("furry_on_buf", { clear = true }) -- on changing the buffer
local cmd_group_dynamic = vim.api.nvim_create_augroup("furry_dynamic", { clear = true }) -- for dynamic input update

local jumplist = {} -- table of matches and their positions
local current = 1 -- last match jumped to
local last_prompt = "  " -- last input of search

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
    sort_by = "lines",
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


-- Get visible lines as range =======================================
local function visible()
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('w$')

    local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)

    return { lines, top }
end
-- Get all buffer lines as range
local function global()
    local top = 1
    local bot = vim.fn.line('$')

    local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)

    return { lines, top }
end
-- Get visible lines including current and below
local function down()
    local top = vim.fn.line('.')
    local bot = vim.fn.line('w$')

    local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)

    return { lines, top }
end
-- Get visible lines including current and above
local function up()
    local top = vim.fn.line('w0')
    local bot = vim.fn.line('.')

    local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)

    return { lines, top }
end


-- Perform search, load and highlight results ======================
local function get_matches(query, range)
    jumplist = {}
    current = 1

    local matches, indices = fz.filtersort(query, range[1])

    -- Collect coordinates of matches
    for i = 1, #matches do
        if opts.max_score <= 0 or fz.match(query, matches[i]).score <= opts.max_score then
            table.insert(jumplist, {
                line = range[2] + indices[i] - 2,
                col = fz.match(query, matches[i]).positions[1] - 1,
                col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
            })
        end
    end

    -- Perform progressive search
    if #jumplist == 0 and opts.progressive == true then
        for i = 1, #matches do
            table.insert(jumplist, {
                line = range[2] + indices[i] - 2,
                col = fz.match(query, matches[i]).positions[1] - 1,
                col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
            })
        end
    end

    -- Stop if no matches
    if #jumplist == 0 then
        return
    end

    -- Record the best match before sorting in line order
    local best_match = jumplist[1]

    -- Sort in line order
    if opts.sort_by == "lines" then
        table.sort(jumplist, function(a, b)
            return (a.line < b.line) or (a.line == b.line and a.col < b.col)
        end)
    end

    -- Write the index of the best match to current
    current = index_of(jumplist, best_match)

    -- Highlight matches
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

    -- Highlight current
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

    -- Write data to vim.b
    vim.b.jumplist = jumplist
    vim.b.current = current
    vim.b.last_prompt = last_prompt
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

-- Special actions table =========================================
local cmds = {}
function cmds.dump()
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    vim.api.nvim_buf_clear_namespace(0, ns_id_cur, 0, -1)
    vim.api.nvim_clear_autocmds({ group = cmd_group, buffer = 0 })
    pcall(vim.keymap.del, "n", "n", { buffer = 0 })
    pcall(vim.keymap.del, "n", "N", { buffer = 0 })
    jumplist, vim.b.jumplist = {}, {}
    current, vim.b.current = 1, 1
end

function cmds.repeat_last()
    if last_prompt == " " or last_prompt == "" then
        return
    end
    get_matches(last_prompt, visible())
end

-- Autocmd to either dump or rematch when returning to the buffer ===================
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
function M.furry(range)
    -- Save last prompt and cursor position
    local winid = vim.api.nvim_get_current_win()
    local save_cursor = vim.api.nvim_win_get_cursor(winid)
    -- Update on input change
    vim.api.nvim_create_autocmd("CmdlineChanged", {
        group = cmd_group_dynamic,
        callback = function()
            local prompt = vim.fn.getcmdline()

            -- Dump if empty or a space
            if prompt == "" or prompt == " " then
                cmds.dump()
                vim.cmd("redraw")
                return
            end

            -- Match, redraw
            get_matches(prompt, range)
            if #jumplist == 0 then
                return
            end
            vim.api.nvim_win_set_cursor(winid,
                { jumplist[current].line + 1, jumplist[current].col })
            vim.cmd("redraw")
        end
    })
    -- Open input, then act on it
    vim.ui.input(
        { prompt = "Furry: " },
        function(input)
            -- Stop the input listener
            vim.api.nvim_clear_autocmds({ group = cmd_group_dynamic })

            -- Restore last prompt and cursor position
            vim.api.nvim_win_set_cursor(winid, save_cursor)

            -- Special actions if input is empty or a space
            if input == nil or input == "" then
                cmds[opts.on_empty]()
                return
            elseif input == " " then
                cmds[opts.on_space]()
                return
            else
                get_matches(input, range)
            end

            -- Check if anything was matched
            if #jumplist == 0 then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'Furry: no matches'<CR>", true, false, true),
                    "n",
                    true)
                pcall(vim.keymap.del, "n", "n", { buffer = 0 })
                pcall(vim.keymap.del, "n", "N", { buffer = 0 })
                return
            end

            -- Jump, reset the on_change action
            vim.api.nvim_win_set_cursor(winid,
                { jumplist[current].line + 1, jumplist[current].col })
            vim.api.nvim_clear_autocmds({ group = cmd_group, buffer = 0 })
            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                group = cmd_group,
                buffer = 0,
                once = false,
                callback = function()
                    cmds[opts.on_change]()
                end,
            })
            vim.keymap.set("n", "n", function() M.next() end, { buffer = 0 })
            vim.keymap.set("n", "N", function() M.prev() end, { buffer = 0 })

            -- Save the prompt
            last_prompt = input
        end
    )
end

-- Create user commands ========================================================================
vim.api.nvim_create_user_command("Furry", function()
    M.furry(visible())
end, {})
vim.api.nvim_create_user_command("FurryDown", function()
    M.furry(down())
end, {})
vim.api.nvim_create_user_command("FurryUp", function()
    M.furry(up())
end, {})
vim.api.nvim_create_user_command("FurryGlobal", function()
    M.furry(global())
end, {})
vim.api.nvim_create_user_command("FurryNext", M.next, {})
vim.api.nvim_create_user_command("FurryPrev", M.prev, {})

return M
