let s:buffer = {}

function! s:OnEvent(job_id, data, event)
  let s:current = get(s:buffer, a:job_id)
  if empty(s:current) || !bufexists(s:current)
    return
  endif
  if a:event == 'stdout' || a:event == 'stderr'
    call setbufline(s:current, line("w$"), a:data)
  elseif a:event == 'exit'
    call appendbufline(s:current, line('$'), '>> Press return to close the buffer <<')
  else
    return
  endif
  silent execute s:current . "buffer +"
endfunction

function! s:Cleanup(job_id)
  call remove(s:buffer, a:job_id)
  if get(jobwait([a:job_id], 0), 0) == -1
    call jobstop(a:job_id)
  endif
endfunction

function Bang(command)
  let s:callbacks = {
  \ 'on_stdout': function('s:OnEvent'),
  \ 'on_stderr': function('s:OnEvent'),
  \ 'on_exit': function('s:OnEvent')
  \ }
  let s:job_id = jobstart(a:command, s:callbacks)
  let s:local_buffer = bufnr("Bang-Job-" . s:job_id, 1)
  let s:buffer[s:job_id] = s:local_buffer
  silent execute s:local_buffer . "buffer"
  silent execute 'setlocal buftype=nofile bufhidden=wipe'
  silent execute 'nnoremap <buffer><silent> <CR> :b#<CR>'
  silent execute 'au BufUnload <buffer> call <SID>Cleanup('.s:job_id.')'
endfunction
