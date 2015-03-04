" =============================================================================
" Filename: plugin/unite-changetime.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/02/24 02:02:55.
" =============================================================================

if exists('g:loaded_unite_changetime') || v:version < 703
  finish
endif
let g:loaded_unite_changetime = 1

let s:save_cpo = &cpo
set cpo&vim

let s:unite_changetime = {
      \ 'description': 'change time',
      \ 'is_quit': 1
      \ }

function! s:unite_changetime.func(candidate)
  let filepath = a:candidate.action__path
  let vimfiler_current_dir = get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir ==# ''
    let vimfiler_current_dir = getcwd()
  endif
  let current_dir = getcwd()
  if system('stat -l . > /dev/null 2>&1; echo $?') =~# '^0'
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
    if newtime ==# ''
      let newtime = atime
    endif
    let matcher = '\a\{3,}[ .,]\+\d\+[ .,]\+\d\+\|\%(\d\+[ .,]\+\)\?\a\{3,}[ .,]\+\d\+'
    if newtime =~# matcher
      let ymd = split(matchstr(newtime, matcher), '[ ,]\+')
      let m = tolower(ymd[0] =~# '\a\{3,}' ? ymd[0] : ymd[1])
      let day = 0 + (len(ymd) == 3 ? (ymd[0] =~# '\d\+' ? ymd[0] : ymd[1]) : 1)
      let months = [ 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' ]
      let months_long = [ 'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december' ]
      let month = 1 + max([index(months, m), index(months_long, m)])
      let year = 0 + (len(ymd) == 3 ? ymd[2] : ymd[1])
      if day > 1000 && year < 32
        let [day, year] = [year, day]
      endif
      if year < 1000 || day > 31 || month < 1 || month > 12
        let newtime = atime
      endif
      let newtime = join([ year, month, day ], ' ')
    endif
    if newtime =~# '^\s*\d\d\d\d\s*$'
      let newtime .= ' 1'
    endif
    if newtime =~# '^\s*\d\d\?\s\+\d\d\d\d\s*$'
      let newtime = matchstr(newtime, '\d\d\d\d') . ' ' . matchstr(newtime, '^\s*\d*')
    endif
    if newtime =~# '^\s*\d\d\d\d\s\+\d\d\?\s*$'
      let newtime .= ' 1'
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

call unite#custom_action('file', 'change_time', s:unite_changetime)

let g:unite_changetime = s:unite_changetime

let &cpo = s:save_cpo
unlet s:save_cpo
