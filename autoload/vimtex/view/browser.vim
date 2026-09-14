function! vimtex#view#browser#new() abort
  return s:viewer.init()
endfunction

let s:viewer = vimtex#view#_template#new({'name': 'Browser'})

function! s:viewer._check() abort
  return executable('python3')
endfunction

function! s:viewer._start(file) dict abort
  call luaeval('require("core.tex_preview").view(_A)', a:file)
endfunction

function! s:viewer.compiler_callback(file) dict abort
  if g:vimtex_view_automatic
    call luaeval('require("core.tex_preview").refresh(_A)', a:file)
  endif
endfunction
