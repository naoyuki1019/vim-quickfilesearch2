scriptencoding utf-8
"/**
" * @file quickfilesearch2.vim
" * @author naoyuki onishi <naoyuki1019 at gmail.com>
" * @version 1.0
" */

if exists('g:loaded_quickfilesearch2')
  finish
endif
let g:loaded_quickfilesearch2 = 1

let s:save_cpo = &cpo
set cpo&vim

if has("win32") || has("win95") || has("win64") || has("win16")
  let s:is_win = 1
  let s:ds = '\'
else
  let s:is_win = 0
  let s:ds = '/'
endif

if !exists('g:qsf_lsfile')
  let g:qsf_lsfile = '.lsfile'
endif

if !exists('g:qsf_maxline')
  let g:qsf_maxline = 200
endif

"Move the cursor to quickfix window after search
if !exists('g:qsf_focus_quickfix')
  let g:qsf_focus_quickfix = 1
endif

"mkfile ***.sh ***.bat
if !exists('g:qsf_mkfile')
  if 1 == s:is_win
    let g:qsf_mkfile = '.lsfile.bat'
  else
    let g:qsf_mkfile = '.lsfile.sh'
  endif
endif

let s:bufnr = ''
let s:searchword = ''
let s:find_mkfile = 0

command! -nargs=* FS call quickfilesearch2#QFSFileSearch(<f-args>)
command! QFSFileSearch2 call quickfilesearch2#QFSFileSearchInput()
command! QFSMakeList call quickfilesearch2#QFSMakeList()


function! s:rm_tail_ds(dir)
  let l:dir = a:dir
  let l:len = strlen(a:dir)
  let l:tail = l:dir[l:len-1]
  if '/' == l:tail || '\' == l:tail
    let l:dir = l:dir[0:l:len-2]
  endif
  return l:dir
endfunction

function! s:search_lsfile(dir)
  let l:dir = a:dir

  if 1 == s:is_win
    if 3 == strlen(l:dir)
      let l:dir = s:rm_tail_ds(l:dir)
    endif
  else
  endif

  let l:lsfile_path = fnamemodify(l:dir.s:ds.g:qsf_lsfile, ':p')
  if filereadable(l:lsfile_path)
    return l:dir.s:ds.g:qsf_lsfile
  endif

  let l:mkfile_path = fnamemodify(l:dir.s:ds.g:qsf_mkfile, ':p')
  if filereadable(l:mkfile_path)
    let s:find_mkfile = 1
    let l:res = s:exec_make(l:dir.s:ds)
    if 0 == l:res
      return l:dir.s:ds.g:qsf_lsfile
    endif
  endif

  if 1 == s:is_win
    if 2 == strlen(l:dir)
      return ''
    endif
  else
    if '/' == l:dir
      return ''
    endif
  endif

  let l:dir = fnamemodify(l:dir.s:ds.'..'.s:ds, ':p:h')
  return s:search_lsfile(l:dir)

endfunction


function! s:search_mkfile(dir)
  let l:dir = a:dir

  if 1 == s:is_win
    if 3 == strlen(l:dir)
      let l:dir = s:rm_tail_ds(l:dir)
    endif
  else
  endif

  let l:mkfile_path = fnamemodify(l:dir.s:ds.g:qsf_mkfile, ':p')
  if filereadable(l:mkfile_path)
    let s:find_mkfile = 1
    let l:res = s:exec_make(l:dir.s:ds)
    if 0 == l:res
      return l:dir.s:ds.g:qsf_mkfile
    endif
  endif

  if 1 == s:is_win
    if 2 == strlen(l:dir)
      return ''
    endif
  else
    if '/' == l:dir
      return ''
    endif
  endif

  let l:dir = fnamemodify(l:dir.s:ds.'..'.s:ds, ':p:h')
  return s:search_mkfile(l:dir)

endfunction

function! s:get_bufnr()

  let l:bufdir = ''

  let l:bufnr = bufnr('%')
  if getbufvar(l:bufnr, '&buftype') ==# ''
    let l:bufdir = fnamemodify(bufname(l:bufnr), ':p:h')
    if '' != l:bufdir
      return l:bufnr
    endif
  endif

  let l:bufnr = bufnr('#')
  if getbufvar(l:bufnr, '&buftype') ==# ''
    let l:bufdir = fnamemodify(bufname(l:bufnr), ':p:h')
    if '' != l:bufdir
      return l:bufnr
    endif
  endif

  let l:bufnr = s:bufnr
  if getbufvar(l:bufnr, '&buftype') ==# ''
    let l:bufdir = fnamemodify(bufname(l:bufnr), ':p:h')
    if '' != l:bufdir
      return l:bufnr
    endif
  endif

  return ''

endfunction

function! quickfilesearch2#QFSFileSearchInput()
  let l:filename = input('Enter filename:')
  if '' == l:filename
    return
  endif
  call quickfilesearch2#QFSFileSearch(l:filename)
endfunction


function! quickfilesearch2#QFSFileSearch(...)

  if 1 > a:0
    return
  endif
  let l:searchword = join(a:000, ' ')

  " get listfile path
  let l:bufnr = s:get_bufnr()
  if '' == l:bufnr
    return
  endif

  let s:find_mkfile = 0
  let l:lsfile_path = s:search_lsfile(fnamemodify(bufname(l:bufnr), ':p:h'))
  if '' == l:lsfile_path
    let s:find_mkfile = 0
    let l:lsfile_path = s:search_lsfile(fnamemodify(bufname(s:bufnr), ':p:h'))
    if '' == l:lsfile_path
      if 0 == s:find_mkfile
        call confirm('note: not found ['.g:qsf_lsfile.'] & ['.g:qsf_mkfile.']')
      else
        call confirm('note: search end')
      endif
      return
    endif
  endif

  let s:bufnr = l:bufnr
  let l:lsfile_tmp = fnamemodify(l:lsfile_path.'.tmp', ':p')
  " echo l:lsfile_tmp

  "tmp作成
  call s:make_tmp(l:lsfile_path, l:lsfile_tmp, l:searchword)

  if !filereadable(l:lsfile_tmp)
    let l:conf = confirm('error: cannot open ['.l:lsfile_tmp.']')
    return
  endif

  "tmp表示
  call s:cgetfile(l:lsfile_tmp)

  "tmp削除
  call delete(l:lsfile_tmp)

  "Move the cursor to quickfix window after search
  if 0 == g:qsf_focus_quickfix
    wincmd w
  endif

endfunction

function! s:make_tmp(lsfile_path, lsfile_tmp, searchword)

  if 1 == s:is_win
    let l:grep_cmd = '!findstr'
  else
    let l:grep_cmd = '!\grep -G -i -s -e'
  endif
  let l:searchword = substitute(a:searchword, '\v([^\.])\*', '\1.\*', 'g')
  let l:searchword = substitute(l:searchword, '\v([^\\])\.([^\*])', '\\.', 'g')
  let l:searchword = substitute(l:searchword, '\v\s{1,}', '.*', 'g')
  let l:searchword = shellescape(l:searchword)
  let l:escaped_lsfile_path = shellescape(a:lsfile_path)
  let l:escaped_lsfile_tmp = shellescape(a:lsfile_tmp)
  let l:execute = l:grep_cmd.' '.l:searchword.' '.l:escaped_lsfile_path.' > '.l:escaped_lsfile_tmp
  " let l:conf = confirm('debug: '.l:execute)
  silent execute '!\touch '.l:escaped_lsfile_tmp
  silent execute l:execute
  let s:searchword = l:searchword
endfunction

function! s:cgetfile(lsfile_tmp)

  "行数が多いとquickfixに読み込むのに時間がかかるため行数チェック
  execute 'tabe ' . a:lsfile_tmp
  let l:line = line('$')
  let l:fsize = getfsize(expand('%'))
  execute 'bd! ' . bufnr('%')

  "Not Found
  if 0 == l:fsize
    let l:conf = confirm('note: not found ['.s:searchword.']')
    return
  endif

  "閾値より大きい場合はメッセージ表示で終わり
  if l:line > g:qsf_maxline
    let l:conf = confirm('caution: search result('.l:line.' lines) exceeded '.g:qsf_maxline.' lines!')
    return
  endif

  "閾値より少ない場合はエラーファイルへ
  let l:bak_errorformat = &errorformat
  let &errorformat='%f'
  execute 'cgetfile ' . a:lsfile_tmp
  let &errorformat=l:bak_errorformat

  copen

endfunction

function! quickfilesearch2#QFSMakeList()

  " get listfile path
  let l:bufnr = s:get_bufnr()
  if '' == l:bufnr
    return
  endif

  let s:find_mkfile = 0
  let l:mkfile_path = s:search_mkfile(fnamemodify(bufname(l:bufnr), ':p:h'))
  if '' == l:mkfile_path
    let s:find_mkfile = 0
    let l:mkfile_path = s:search_mkfile(fnamemodify(bufname(s:bufnr), ':p:h'))
    if '' == l:mkfile_path
      if 0 == s:find_mkfile
        call confirm('note: not found ['.g:qsf_mkfile.']')
      else
        call confirm('note: search end')
      endif
      return
    endif
  endif

endfunction

function! s:exec_make(dir)

  let l:lsfile_path = fnamemodify(a:dir.g:qsf_lsfile, ':p')
  let l:mkfile_path = fnamemodify(a:dir.g:qsf_mkfile, ':p')

  if 1 == s:is_win
    let l:drive = a:dir[:stridx(a:dir, ':')]
    let l:execute = '!'.l:drive.' & cd '.shellescape(a:dir).' & '.shellescape(l:mkfile_path)
  else
    let l:execute = '!cd '.shellescape(a:dir).'; /bin/bash '.shellescape(l:mkfile_path)
  endif

  let l:conf = confirm('execute? ['.l:execute.']', "Yyes\nNno")
  if 1 != l:conf
    return 2
  endif

  call delete(l:lsfile_path)
  silent execute l:execute

  if !filereadable(l:lsfile_path)
    let l:conf = confirm('error: could not create ['.l:lsfile_path.']')
    return 1
  endif

  let l:conf = confirm('info: created ['.l:lsfile_path.']')
  return 0

endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

