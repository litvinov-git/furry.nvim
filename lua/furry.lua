local fz = require("mini.fuzzy")

local jumplist = {}                                          -- table of of matched coordinates to jump to
local current = 1                                            -- last index selected from the jumplist
local ns_id = vim.api.nvim_create_namespace("furry_matches") -- namespace for highlighting

local config = {
    highlight = true
}

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

local function fuzzy_visible(query)
    jumplist = {}
    current = 1

    local items = get_visible_lines()

    local texts = {}
    for i, item in ipairs(items) do
        texts[i] = item.text
    end

    local matches, indices = fz.filtersort(query, texts)
    if #matches == 0 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":echo 'No matches'<CR>", true, false, true), "n", true)
        return
    end

    for i = 1, #matches do
        table.insert(jumplist, {
            line = vim.fn.line('w0') + indices[i] - 2, -- use the line from indice
            col = fz.match(query, matches[i]).positions[1] - 1,
            col_last = fz.match(query, matches[i]).positions[# fz.match(query, matches[i]).positions] - 1,
        })
    end

    if config.highlight == true then
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
                    hl_group = "Search"           -- highlight group
                }
            )
        end
    end

    local winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(winid, { jumplist[1].line + 1, jumplist[1].col })
end

local function furry()
    vim.ui.input(
        { prompt = "Furry: " },
        function(input)
            if input == nil or input == "" then
                vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
                return
            end
            fuzzy_visible(input)
        end
    )
end

local function next()
    current = current + 1
    if current > #jumplist then
        current = 1
    end
    local winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end

local function prev()
    current = current - 1
    if current < 1 then
        current = #jumplist
    end
    local winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(winid, { jumplist[current].line + 1, jumplist[current].col })
end


vim.api.nvim_create_user_command("Furry", furry, {})
vim.api.nvim_create_user_command("FurryNext", next, {})
vim.api.nvim_create_user_command("FurryPrev", prev, {})

