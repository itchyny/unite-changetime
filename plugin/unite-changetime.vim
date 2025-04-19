" =============================================================================
" Filename: plugin/unite-changetime.vim
" Author: itchyny
" License: MIT License
" Last Change: 2025/04/19 11:05:15.
" =============================================================================

if exists('g:loaded_unite_changetime') || !has('patch-8.2.1794')
  finish
endif
let g:loaded_unite_changetime = 1

let s:save_cpo = &cpo
set cpo&vim

let s:unite_changetime = #{ description: 'change time', is_quit: 1 }

function! s:unite_changetime.func(candidate)
  let filepath = a:candidate.action__path
  let old_value = getftime(filepath)
  let input_value = trim(input(strftime('New time: %F %T -> ', old_value)))
  if input_value ==# ''
    return
  endif
  let date_time_str = substitute(input_value, '/', '-', 'g')
  let new_value =
        \ strptime('%F %T', date_time_str) ??
        \ strptime('%F %R', date_time_str) ??
        \ strptime('%F',    date_time_str) ??
        \ strptime('%F %T', strftime('%Y-', old_value) .. date_time_str) ??
        \ strptime('%F %R', strftime('%Y-', old_value) .. date_time_str) ??
        \ strptime('%F',    strftime('%Y-', old_value) .. date_time_str) ??
        \ strptime('%F %T', strftime('%F ', old_value) .. date_time_str) ??
        \ strptime('%F %R', strftime('%F ', old_value) .. date_time_str)
  if new_value == 0
    redraw
    call s:echo_error_msg('Invalid date time format: ' .. input_value)
    return
  endif
  let date_time_str = strftime('%FT%T', new_value)
  let [&shellredir, save_shellredir] = ['>%s 2>&1', &shellredir]
  let lines = systemlist(printf('touch -h -ad %s -md %s %s',
        \ date_time_str, date_time_str, shellescape(filepath)))
  let &shellredir = save_shellredir
  if v:shell_error
    redraw
    for line in lines
      call s:echo_error_msg(line)
    endfor
  endif
endfunction

function! s:echo_error_msg(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction

call unite#custom_action('file', 'change_time', s:unite_changetime)

let &cpo = s:save_cpo
unlet s:save_cpo
