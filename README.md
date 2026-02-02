# FURRY.NVIM
A simple alternative to flash.nvim/leap.nvim with fuzzy matching, built on mini.fuzzy.
Yes, other name suggestions are welcome in form of GitHub issues.
## What is it for?
Sometimes literal matching is not convenient at all, as well as scanning your screen for labels. I use furry.nvim for instant jump anywhere on the visible lines.
## Usage
- `:Furry` - type the string you want to match for, press `<CR>`, simple as. It is best to avoid spaces
- `:FurryNext` / `:FurryPrev` - cycle to the next/previous match
Using `:Furry` with no input removes all highlighting from previous Furry searches
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
            })
        end

    },
```
If you want to change the option, uncomment it and change the value accordingly:
- `highlight_matches` - whether to highlight all matches with the group "Search"
- `highlight_current` - whether to highlight the last match you jumped to with the group "IncSearch"
- `max_score` - above which score to cut the matches (the higher, the stricter the matching)

To bind the keys:
```lua
vim.keymap.set("n", "sf", ":Furry<CR>")
vim.keymap.set("n", "sa", ":FurryPrev<CR>")
vim.keymap.set("n", "sd", ":FurryNext<CR>")
```
## Want to get fast like a cheetah?
Abuse fuzzy matching. A good example:
1. You want to jump to `"Flash Treesitter"` in:
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
2. Call Furry with your keymap, awfully pronounce your desired keyword, omitting all the vowels and keeping only a the first couple of consonants in the words, possibly using common abbreviations: `"flts"`
3. Type it, hit `<CR>`
4. Boom, you are there! In a single cheetah stride


With flash.nvim, this would take less keystrokes (3 versus 5), but possibly more mental gymnastics:
1. Call flash
2. Type fl
3. Scan your screen for the label
4. Reach for the label on your keyboard and hit it.

Having to read the label might interupt your flow, and make you forget what you wanted to do with the keyword.  
