# 🐯 FURRY.NVIM
A simple yet powerful and configurable alternative to flash.nvim/leap.nvim with fuzzy matching and no mental friction of looking up the labels. Drop-in fuzzy replacement for built-in /-search. Built on mini.fuzzy.
Can also be used well with file trees and other kinds of file managers as long as they are technically separate buffers.
Yes, other name suggestions are welcome in form of GitHub issues.
## We just got a big update!
The fresh release 2.0.0 brought requested features such as:
- Dynamic update with input
- Regular search mapping

Any of the inconveniences you might have had are likely fixed. If not, please open an issue.

Now furry.nvim is a full-featured fuzzy replacement for /-search (with `:FurryGlobal`) and for flash.nvim (with `:Furry` which scans visible lines), if you prefer the fuzzy workflow instead of labels.

(Why not have both labels and fuzzy? Read to the bottom)
## Usage
- `:Furry` - type the string you want to match for, press `<CR>`, simple as. It is best to avoid spaces. Matches on visible lines
- `n`/`N` or `:FurryNext` / `:FurryPrev` - cycle to the next/previous match, exactly like in the regular /-grep search
- `:FurryGlobal` - matches on all lines of the buffers
- `:FurryDown` - matches on visible lines below the current lines
- `:FurryUp` - matches on visible lines above the current one

Search results update dynamically with input, like in regular /-search

Using `:Furry` with no input or a single space as the input calls distinct configurable actions.

`n`/`N` keys are only used by furry.nvim if the search is active, hence there are no conflicts with regular grep cycling.
## Installation and configuration
With lazy.nvim:
```lua
    {
        "litvinov-git/furry.nvim",
        dependencies = { "nvim-mini/mini.fuzzy" },
        config = function()
            require("furry").setup({
            -- Defaults:
                -- highlight_matches = true,
                -- highlight_current = true,
                -- max_score = 1800,
                -- progressive = true,
                -- sort_by = "lines",
			    -- on_empty = "dump",
			    -- on_space = "repeat_last",
			    -- on_change = "dump",
			    -- on_buf_enter = "repeat_last",
            })
        end

    },
```
If you want to change an option, uncomment it and change the value accordingly:
- `highlight_matches` - whether to highlight all matches with the group "Search"
- `highlight_current` - whether to highlight the last match you jumped to with the group "IncSearch"
- `max_score` - above which score to cut the matches (the lower, the stricter the matching)
- `progressive` - whether to search with no score limit if nothing was found before
- `sort_by` - in what order to cycle trough matches, `"lines"` for regular up/down, `"score"` to sort by quality of the match
- `on_empty` - what action take when the input is empty
- `on_space` - what action take when input is a single space
- `on_change` - what action take when the current buffer is edited
- `on_buf_enter` - what action take when entering another buffer
    - note that all search data is saved per buffer, so "repeat_last" will keep separate "instances"
    of the plugin in each buffer, and switching will not interupt or change anything
- List of available actions:
    - `dump` - clear the jumplist (list of matches) and highlighting
    - `repeat_last` - search and highlight again with the last used prompt
        - `repeat_last` is the behavior of the standart / search, which rescans on every buffer change

For example, to bind the keys:
```lua
vim.keymap.set("n", "sf", ":Furry<CR>")
vim.keymap.set("n", "sa", ":FurryPrev<CR>")
vim.keymap.set("n", "sd", ":FurryNext<CR>")
```
Note that you don\`t have to manually map `:FurryNext` and `:FurryPrev`, as the regular search mappings work by default.
## Want to get fast like a cheetah? 🐯
Abuse fuzzy matching. A good example:
1. You want to jump to `"Flash Treesitter"` in:
    ```lua
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        keys = {
            { "<leader>fl", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            --             { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
            --             { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
            --             { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            --             { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
        },
    },
    ```
2. Call Furry with your keymap, awfully pronounce your desired keyword, omitting all the vowels and keeping only a the first couple of consonants in the words, possibly using common abbreviations: `"flts"`
3. Type it, hit `<CR>`
4. Boom, you are there! In a single cheetah stride


With flash.nvim, this would take less keystrokes (3 versus 5), but possibly more mental gymnastics:
1. Call flash
2. Type fl
3. Scan your screen for the label
4. Reach for the label on your keyboard and hit it.

Having to read the label might interupt your flow, and make you forget what you wanted to do with the keyword.  
### Why not both labels and fuzzy?
flash.nvim does in fact have a fuzzy mode. However, the labels must not conflict with any possible next char, and hence using it you will likely have barely any matches labeled.
With fuzzy matching simply too many characters can trigger a new match for labels to be usable. Next/prev match cycling is not a model flash really utilizes, so it is not easy at all to match some of the things you might want to.
### Special thanks
- flash.nvim by folke - for showing what the true speed might be like, and for many lua API tips and tricks I looked up in its source
- mini.fuzzy from nvim.mini - for powering the matching itself
- Neovim docs - for being a life changing piece of literature
