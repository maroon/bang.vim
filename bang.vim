if !exists('s:buffer')
  let s:buffer = {}
endif

function! s:OnEvent(job_id, data, event)
  let s:current = get(s:buffer, a:job_id)
  if a:event == 'stdout' || a:event == 'stderr'
    call setbufline(s:current, line("w$"), a:data)
  elseif a:event == 'exit'
    call appendbufline(s:current, line('$'), '>> Press return to close the buffer <<')
    call remove(s:buffer, a:job_id)
  else
    return
  endif
  execute 'normal G'
endfunction

function! s:Cleanup(job_id)
  silent execute ":b#|bw! #"
  silent execute jobstop(a:job_id)
endfunction

function Bang(command)
  let s:callbacks = {
  \ 'on_stdout': function('s:OnEvent'),
  \ 'on_stderr': function('s:OnEvent'),
  \ 'on_exit': function('s:OnEvent')
  \ }
  let s:anjob = jobstart(a:command, s:callbacks)
  let s:local_buffer = bufnr("Bang-Job-" . s:anjob, 1)
  let s:buffer[s:anjob] = s:local_buffer
  call setbufvar(s:local_buffer, "&buftype", "nofile")
  silent execute s:local_buffer . "buffer"
  silent execute 'nnoremap <buffer><silent> <CR> :call <SID>Cleanup(' . s:anjob . ')<CR>'
endfunction

command! -nargs=* Bang call Bang('<args>')
