" =============================================================================
" Filename: plugin/unite-changetime.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/30 20:34:50.
" =============================================================================

if exists('g:loaded_unite_changetime')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

let s:unite_changetime = {
      \ 'description': 'change time',
      \ 'is_quit': 1
      \ }

function! s:unite_changetime.func(candidate)
  let filepath = a:candidate.action__path
  let vimfiler_current_dir = get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir == ''
    let vimfiler_current_dir = getcwd()
  endif
  let current_dir = getcwd()
  if system('stat -l . > /dev/null 2>&1; echo $?') =~ '^0'
    let atime = system('stat -lt "%Y/%m/%d %H:%M" "'.filepath
          \."\" | awk {'print $6\" \"$7'} | tr -d '\\n'")
  else
    let atime = system('stat --printf "%y" "'.filepath."\" | sed -e 's/\\..*//'")
  endif
  let atime = substitute(atime, '-', '/', 'g')
  try
    silent! lcd `=vimfiler_current_dir`
    let newtime = input(printf('New time: %s -> ', atime))
    " redraw
    if newtime == ''
      let newtime = atime
    endif
    let newtime = substitute(newtime, '\d\@<!\(\d\)$', '0\1', '')
    let newtime = substitute(newtime, '\d\@<!\(\d\)\d\@!', '0\1', 'g')
    let newtime = substitute(newtime, '[ -]', '', 'g')
    if newtime =~? '^\d\+/\d\+/\d\+$' || len(newtime) <= 8
      let newtime .= '0000'
    endif
    let newtime = substitute(newtime, '\(\d\+:\d\+\):\(\d\+\)$', '\1.\2', '')
    let newtime = substitute(newtime, '[/:]', '', 'g')
    silent! call system('touch -at '.newtime.' -mt '.newtime.' "'.filepath.'" &')
  finally
    silent! lcd `=current_dir`
  endtry
endfunction

if exists('*unite#custom_action')
  call unite#custom_action('file', 'unite_changetime', s:unite_changetime)
endif

let g:unite_changetime = s:unite_changetime

let g:loaded_unite_changetime = 1

let &cpo = s:save_cpo
unlet s:save_cpo