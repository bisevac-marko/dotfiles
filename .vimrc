" TODO: running app
" TODO: make vim auto add user defined struct as syntax highliting information

colorscheme gruvbox
set guioptions-=T
set guioptions-=m
set guioptions-=L
set guioptions-=r

set t_Co=256
syntax on

behave mswin
set t_vb=on
set showmatch
set noerrorbells
set belloff=all
set tabstop=4 softtabstop=4
set shiftwidth=4
set backspace=2
set expandtab
set smartindent
set autoindent
set nu
set nowrap
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set cursorline
set guifont=Liberation_Mono:h10.9

set makeprg=build.bat

set wildmenu
set wildmode=longest:full,full
" switch to coresponding cpp/h file
"map <m-c> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
" source config file
map <m-S-r> :source ~/.vimrc<CR>
" find file
map <m-f> :e 
" find buffer
map <m-b> :buffer 
" switch to other window
" complete word
inoremap <Tab> <C-n>
" scrolling window
map <m-j> <C-d>
" switch to other window
map <m-k> <C-u>

nnoremap <m-m> :silent make<CR>
nnoremap <m-e> :cnext<CR>
nnoremap <m-q> :cprevious<CR>

nnoremap <m-p> :call GoToFunction()<CR>
nnoremap <m-w> :call SwitchWindow()<CR>
nnoremap <m-r> :call SearchAndReplace()<CR>
nnoremap <m-g> :call GrepCppProject()<CR>
nnoremap <m-c> :call ToggleComment()<cr>
vnoremap <m-c> :call ToggleComment()<cr>
nnoremap <m-s> :call SaveFile()<cr>

inoremap ( ()<Esc>i
inoremap [ []<Esc>i
inoremap { {<CR>}<Esc>O
autocmd Syntax html,vim inoremap < <lt>><Esc>i| inoremap > <c-r>=ClosePair('>')<CR>
inoremap ) <c-r>=ClosePair(')')<CR>
inoremap ] <c-r>=ClosePair(']')<CR>
inoremap } <c-r>=CloseBracket()<CR>
inoremap " <c-r>=QuoteDelim('"')<CR>
inoremap ' <c-r>=QuoteDelim("'")<CR>


let s:is_cursor_left = 0

function! SwitchWindow()
    let list_of_open_window = range(1,winnr('$'))
    if s:is_cursor_left == 1
        let s:is_cursor_left = 0
        execute "normal \<c-w>l"
    else
        let s:is_cursor_left = 1
        execute "normal \<c-w>h"
    endif
endfunction


function! ToggleCompileWindow()
endfunction

function! CompileProject(directory)

    let file_list = split(globpath(a:directory, '*'), '\n')

    for file_path in file_list
        let file_path_split = split(file_path, '\')
        let file_name_index = len(file_path_split) - 1
        " echom file_path_split[file_name_index] 
        if file_path_split[file_name_index] == "build.bat"
            let path_to_file = file_path[:-10]
            exe 'cd ' . path_to_file
            let window_count = 0
            windo let window_count = window_count + 1

            if window_count == 1
                execute "normal \<c-w>v"
                call SwitchWindow()
                exe 'terminal ++curwin ' . file_path_split[file_name_index]
                call SwitchWindow()
            else
                exe 'terminal ++curwin ' . file_path_split[file_name_index]
                call SwitchWindow()
            endif
        elseif isdirectory(file_path)
            call CompileProject(file_path)
        endif
    endfor

endfunction

" function search regex:\v^(<\w+>\s*)\(
function! AllFileFunctionsNames(input, cmd, curs)
    let out = []
    let file = readfile(expand("%:p")) " read current file
    for line in file
        let match = matchstr(line, '\v^(<\w+>\s*)\(')
        if (!empty(match))
            if (stridx(match, a:input) != -1)
                call add(out, match)
                echo match
            endif
        endif
    endfor
    return out
endfunction

function! GetFunctionLineNumber(function_name)
    let file = readfile(expand("%:p")) " read current file
    let line_num = 1
    for line in file
        let match = matchstr(line, a:function_name)
        if (!empty(match))
            return line_num
        endif
        let line_num += 1
    endfor
    return -1
endfunction

function! SearchAndReplace()
    call inputsave()
    let replace = input("Replace: ")
    let replace_with = input("With: ")
    call inputrestore()

    execute ":%s/" . replace . "/" . replace_with . "/" . "gcI"

endfunction

function! GrepCppProject()

    call inputsave()
    let search_for = input("Search for: ")
    call inputrestore()

    execute ":vimgrep " . search_for . " " . "*.cpp *.h"

endfunction

function! GoToFunction()
    call inputsave()
    let input_string = input("Go To Function: ", "", "customlist,AllFileFunctionsNames")
    call inputrestore()

    let function_line_number = GetFunctionLineNumber(input_string)

    if (function_line_number != -1)
        exe function_line_number
    endif

endfunction

function! CompilePopup(directory)
    let file_list = split(globpath(a:directory, '*'), '\n')

    for file_path in file_list
        let file_path_split = split(file_path, '\')
        let file_name_index = len(file_path_split) - 1


        if file_path_split[file_name_index] == "build.bat"
            let path_to_file = file_path[:-10]
            exe 'cd ' . path_to_file

            let popup_list = popup_list()
            if (len(popup_list) > 0)
                call popup_close(popup_list[0])
            endif

            let popup_args = {'posinvert':'FALSE', 'minwidth':204, 'minheight':30, 'col':1, 'line':25, 'border':[1]}
            let buf = term_start("build.bat", #{hidden: 1})
            let winid = popup_create(buf, popup_args)
            hi! win_color gui=NONE guibg=Grey15 guifg=NavajoWhite1
            call win_execute(winid, 'setlocal wincolor=win_color')



        elseif isdirectory(file_path)
            call CompilePopup(file_path)
        endif
    endfor
endfunction

function! TogglePopup()
    let winid = popup_list()

    if (len(winid) > 0)

        let popup_fields = popup_getpos(winid[0])

        if (!popup_fields["visible"])
            call popup_show(winid[0])
        else
            call popup_hide(winid[0])
            execute "normal \<m-w>"
        endif
    endif

endfunction

let s:comment_map = { 
    \   "c": '\/\/',
    \   "cpp": '\/\/',
    \   "go": '\/\/',
    \   "java": '\/\/',
    \   "javascript": '\/\/',
    \   "lua": '--',
    \   "scala": '\/\/',
    \   "php": '\/\/',
    \   "python": '#',
    \   "ruby": '#',
    \   "rust": '\/\/',
    \   "sh": '#',
    \   "desktop": '#',
    \   "fstab": '#',
    \   "conf": '#',
    \   "profile": '#',
    \   "bashrc": '#',
    \   "bash_profile": '#',
    \   "mail": '>',
    \   "eml": '>',
    \   "bat": 'REM',
    \   "ahk": ';',
    \   "vim": '"',
    \   "tex": '%',
    \ }

function! ToggleComment()
    if has_key(s:comment_map, &filetype)
        let comment_leader = s:comment_map[&filetype]
        if getline('.') =~ "^\\s*" . comment_leader . " " 
            " Uncomment the line
            execute "silent s/^\\(\\s*\\)" . comment_leader . " /\\1/"
        else 
            if getline('.') =~ "^\\s*" . comment_leader
                " Uncomment the line
                execute "silent s/^\\(\\s*\\)" . comment_leader . "/\\1/"
            else
                " Comment the line
                execute "silent s/^\\(\\s*\\)/\\1" . comment_leader . " /"
            end
        end
    else
        echo "No comment leader found for filetype"
    end
endfunction



function ClosePair(char)
 if getline('.')[col('.') - 1] == a:char
 return "\<Right>"
 else
 return a:char
 endif
endf

function CloseBracket()
 if match(getline(line('.') + 1), '\s*}') < 0
 return "\<CR>}"
 else
 return "\<Esc>j0f}a"
 endif
endf

function QuoteDelim(char)
 let line = getline('.')
 let col = col('.')
 if line[col - 2] == "\\"
 "Inserting a quoted quotation mark into the string
 return a:char
 elseif line[col - 1] == a:char
 "Escaping out of the string
 return "\<Right>"
 else
 "Starting a string
 return a:char.a:char."\<Esc>i"
 endif
endf


function UpdateSyntaxFile()

    let curr_file = readfile(expand('%:p'))
    let syntax_file_path = "C:\\Users\\Marko\\vimfiles\\syntax\\c.vim"
    let syntax_file = readfile(syntax_file_path, 'b')

    for line in curr_file
        " let match = matchstr(line, '\struct\s\w\+[\n\r]')
        let match = matchstr(line, 'struct\s\+\w\+')
        if (!empty(match))
            let syntax_line = syntax_file[len(syntax_file) - 1]
            let keyword = split(match)[1]
            let syntax_match = matchstr(syntax_line, keyword)

            if (empty(syntax_match))
                let str_to_write = "syn keyword marko_keyword " . keyword
                call writefile([str_to_write], syntax_file_path, "a")
            endif
        endif
    endfor

endfunction

function SaveFile()
    let curr_file_name = expand('%:t')

    let match = matchstr(curr_file_name, '\(\w\+\.cpp\|\w\+\.c\|\w\+\.h\)')
    if (!empty(match))
        call UpdateSyntaxFile()
    endif

    execute "silent sav %"
endfunction

