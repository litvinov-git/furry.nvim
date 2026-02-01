# FURRY.NVIM
A simple alternative to flash.nvim/leap.nvim with fuzzy matching, built on mini.fuzzy.
Yes, other name suggestions are welcome in form of GitHub issues.
## What is it for?
Sometimes literal matching is not convenient at all, as well as scanning your screen for labels. I use furry.nvim for instant jump anywhere on the visible lines.
## Usage
- `:Furry` - type the string you want to match for, press `<CR>`, simple as. It is best to avoid spaces
- `:FurryNext` / `:FurryPrev` - cycle to the next/previous match, ordered by fuzzy matching scores
Using `:Furry` with no input removes all highlighting from previous Furry searches
## Installation
With lazy.nvim:
```lua
{ "litvinov-git/furry.nvim" },
```
To enable the aforementioned commands, put somewhere in your config (init.lua for example):
```lua
require("furry")
```
To bind the keys:
```lua
vim.keymap.set("n", "sf", ":Furry<CR>")
vim.keymap.set("n", "sa", ":FurryPrev<CR>")
vim.keymap.set("n", "sd", ":FurryNext<CR>")
```
## Configuration
Expect it very soon in a few commits. The following options are going to be available:
- Turn off highlighting
- Limit the number of matches
- Change cycling order to lines down/up instead of score
