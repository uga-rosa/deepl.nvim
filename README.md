**Use translate.nvim**

[translate.nvim](https://github.com/uga-rosa/translate.nvim)

# deepl.nvim

Hit deepl api from neovim and display in floating window

# Require

- neovim 0.5.0+
- [deepl API account](https://www.deepl.com/en/pro-api/)

# Setup

```lua
require("deepl").setup({
  authkey = "", -- your deepl api's auth_key
  plan = "free" -- your plan ("free" or "pro")
})
```

# How to use

Translate.

```lua
require("deepl").translate(<line1>, <line2>, from, to, mode)
```

- \<line1>: start line
- \<line2>: last line
- from: from language (e.g. "EN", "JA")
- to: to language (same above)
- mode: "f" (floating window) or "r" (replace)

Close a floating window.

```lua
lua require("deepl").close()
```

# Example setting

Register in command.

```vim
command! -range DeeplJa2EnFloat lua require("deepl").translate(<line1>, <line2>, "JA", "EN", "f")
command! DeeplClose lua require("deepl").close()
```
