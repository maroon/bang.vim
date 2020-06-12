if exists('g:bang_loaded')
  finish
endif
let g:bang_loaded = 1

command! -nargs=+ Bang lua require'bang'.start_job({<f-args>})
