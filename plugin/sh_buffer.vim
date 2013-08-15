" Maintainer:  Mark J. Lorenz <markjlorenz@gmail.com>
" URL:         
" License:     MIT
" ThankYou:    This scrip is basically a hacked verions of
"              [vim-coffee-script](http://github.com/kchmck/vim-coffee-script) 
"              by Mick Koch <kchmck@gmail.com>.  I don't even
"              really know how it works.

" Reset the CoffeeCompile variables for the current buffer.
function! s:ShCompileResetVars()
  " Compiled output buffer
  let b:sh_compile_buf = -1
  let b:sh_compile_pos = []
endfunction

" Clean things up in the source buffer.
function! s:ShCompileClose()
  exec bufwinnr(b:sh_compile_src_buf) 'wincmd w'
  call s:ShCompileResetVars()
endfunction

" Don't overwrite the CoffeeCompile variables.
if !exists('b:sh_compile_buf')
  call s:ShCompileResetVars()
endif

" Check here too in case the compiler above isn't loaded.
if !exists('sh_compiler')
  let sh_compiler = $SHELL
endif

" Update the CoffeeCompile buffer given some input lines.
function! s:ShCompileUpdate(startline, endline)
  let input = join(getline(a:startline, a:endline), "\n")

  " Move to the CoffeeCompile buffer.
  exec bufwinnr(b:sh_compile_buf) 'wincmd w'

  " Coffee doesn't like empty input.
  if !len(input)
    return
  endif

  " Compile input.
  let output = system(g:sh_compiler . ' 2>&1', input)

  " Be sure we're in the CoffeeCompile buffer before overwriting.
  if exists('b:sh_compile_buf')
    echoerr 'Sh buffers are messed up'
    return
  endif

  " Replace buffer contents with new output and delete the last empty line.
  setlocal modifiable
    exec '% delete _'
    put! =output
    exec '$ delete _'
  setlocal nomodifiable

  setlocal filetype=

  call setpos('.', b:sh_compile_pos)
endfunction

" Peek at compiled CoffeeScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:ShCompile(startline, endline, args)
  if !executable(g:sh_compiler)
    echoerr "Can't find Sh `" . g:sh_compiler . "`"
    return
  endif

  " If in the ShCompile buffer, switch back to the source buffer and
  " continue.
  if !exists('b:sh_compile_buf')
    exec bufwinnr(b:sh_compile_src_buf) 'wincmd w'
  endif

  " Parse arguments.
  let watch = a:args =~ '\<watch\>'
  let unwatch = a:args =~ '\<unwatch\>'
  let size = str2nr(matchstr(a:args, '\<\d\+\>'))

  " Determine default split direction.
  if exists('g:sh_compile_vert')
    let vert = 1
  else
    let vert = a:args =~ '\<vert\%[ical]\>'
  endif

  let b:sh_compile_watch = 1

  " Build the ShCompile buffer if it doesn't exist.
  if bufwinnr(b:sh_compile_buf) == -1
    let src_buf = bufnr('%')
    let src_win = bufwinnr(src_buf)

    " Create the new window and resize it.
    if vert
      let width = size ? size : winwidth(src_win) / 2

      belowright vertical new
      exec 'vertical resize' width
    else
      " Try to guess the compiled output's height.
      let height = size ? size : min([winheight(src_win) / 2,
      \                               a:endline - a:startline + 2])

      belowright new
      exec 'resize' height
    endif

    " We're now in the scratch buffer, so set it up.
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    autocmd BufWipeout <buffer> call s:ShCompileClose()
    " Save the cursor when leaving the CoffeeCompile buffer.
    autocmd BufLeave <buffer> let b:sh_compile_pos = getpos('.')

    nnoremap <buffer> <silent> q :hide<CR>

    let b:sh_compile_src_buf = src_buf
    let buf = bufnr('%')

    " Go back to the source buffer and set it up.
    exec bufwinnr(b:sh_compile_src_buf) 'wincmd w'
    let b:sh_compile_buf = buf
  endif

  call s:ShCompileUpdate(a:startline, a:endline)
endfunction

" Peek at compiled CoffeeScript.
command! -range=%  -bar -nargs=* -complete=customlist,
\        ShBuffer call s:ShCompile(<line1>, <line2>, <q-args>)
