if exists("g:loaded_deepl")
  finish
endif
let g:loaded_deepl = 1

command! -range JA2ENfloat lua require("deepl").translate(<line1>, <line2>, "JA", "EN", "f")
command! -range EN2JAfloat lua require("deepl").translate(<line1>, <line2>, "EN", "JA", "f")
command! -range JA2ENreplace lua require("deepl").translate(<line1>, <line2>, "JA", "EN", "r")
command! -range EN2JAreplace lua require("deepl").translate(<line1>, <line2>, "EN", "JA", "r")
command! DeeplClose lua require("deepl").close()
