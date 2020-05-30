if !exists('s:buffer')
  let s:buffer = {}
endif

function! s:OnEvent(job_id, data, event)
  if a:event == 'stdout' || a:event == 'stderr'
    call setbufline(s:buffer[a:job_id], line("w$"), a:data)
  elseif a:event == 'exit'
    call appendbufline(s:buffer[a:job_id], line('$'), '>> Press return to close the buffer <<')
  else
    return
  endif
  execute 'normal G'
endfunction

function! s:Cleanup(job_id)
  execute ":b#|bw! #"
  execute jobstop(a:job_id)
  call remove(s:buffer, a:job_id)
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
  execute s:local_buffer . "buffer"
  execute 'nnoremap <buffer><silent> <CR> :call <SID>Cleanup(' . s:anjob . ')<CR>'
endfunction

command! -nargs=* Bang call Bang('<args>')
