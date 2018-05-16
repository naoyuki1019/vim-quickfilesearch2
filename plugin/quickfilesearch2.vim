"/**
" * @file quickfilesearch2.vim
" * @author naoyuki onishi <naoyuki1019 at gmail.com>
" * @version 1.0
" */

if exists("g:loaded_quickfilesearch2")
  finish
endif
let g:loaded_quickfilesearch2 = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:qsf_lsfile')
  let g:qsf_lsfile = '.lsfile'
endif

if !exists('g:qsf_maxline')
  let g:qsf_maxline = 200
endif

let s:dir = ''

command! -nargs=* QSF call quickfilesearch2#QFSFileSearch(<f-args>)


function! s:search_lsfile(dir)

  let l:lsfile_path = fnamemodify(a:dir.'/'.g:qsf_lsfile, ':p')
  echo l:lsfile_path
  if filereadable(l:lsfile_path)
    return l:lsfile_path
  endif

  let l:dir = fnamemodify(a:dir.'/../', ':p:h')

  if s:dir == l:dir
    echo "windows root " . s:dir
    return ''
  endif

  if '/' == l:dir
    echo "root directory / "
    return ''
  endif

  let s:dir = l:dir

  return s:search_lsfile(l:dir)

endfunction


function! quickfilesearch2#QFSFileSearch(...)

  if 1 > a:0
    return
  endif

  " get listfile path
  let l:lsfile_path = s:search_lsfile(expand('%:h'))

  if '' == l:lsfile_path
    echo 'Not Found:['.g:qsf_lsfile.']'
    return
  endif

  echo l:lsfile_path
  let l:lsfile_tmp = l:lsfile_path.'.tmp'
  echo l:lsfile_tmp

  "引数を空白で連結
  let l:searchword = ''
  for l:s in a:000
    let l:searchword .= l:s . ' '
  endfor
  let l:searchword = l:searchword[0:strlen(l:searchword) - 2]
  echo l:searchword

  "tmp作成
  if 0 != s:make_tmp(l:lsfile_path, l:lsfile_tmp, l:searchword)
    return
  endif

  "tmp表示
  call s:cgetfile(l:lsfile_tmp)

  "tmp削除
  silent execute '!rm ' . shellescape(l:lsfile_tmp)

endfunction

function! s:make_tmp(lsfile_path, lsfile_tmp, searchword)

  let l:grep_cmd = '!grep -G -i -s'
  let l:searchword = substitute(a:searchword, '\([^\.]\)\*', '\1.\*', 'g')
  let l:searchword = substitute(l:searchword, ' ', '.*', 'g')
  let l:escaped_lsfile_path = shellescape(a:lsfile_path)
  let l:escaped_lsfile_tmp = shellescape(a:lsfile_tmp)
  let l:conf = confirm(l:searchword)
  silent execute l:grep_cmd.' '.l:searchword.'  '.l:escaped_lsfile_path.' > '.l:escaped_lsfile_tmp

  if !filereadable(fnamemodify(a:lsfile_tmp, ':p'))
    let l:conf = confirm("An error occurred")
    return 1
  endif
  return 0
endfunction

function! s:cgetfile(lsfile_tmp)

  "行数が多いとquickfixに読み込むのに時間がかかるため行数チェック
  execute 'edit ' . a:lsfile_tmp
  let l:line = line('$')
  execute 'bd! ' . bufnr('%')
  "閾値より大きい場合はメッセージ表示で終わり
  if l:line > g:qsf_maxline
    let l:conf = confirm("Search result exceeded ".g:qsf_maxline."!")
    return
  endif

  "使用する前に閉じておく
  cclose

  "閾値より少ない場合はエラーファイルへ
  let l:bak_errorformat = &errorformat
  let &errorformat='%f'
  execute 'cgetfile ' . a:lsfile_tmp
  copen
  let &errorformat=l:bak_errorformat

endfunction
