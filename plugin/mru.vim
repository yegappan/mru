" File: mru.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 1.6
" Last Modified: July 19, 2003
"
" Overview
" --------
" The Most Recently Used (MRU) plugin provides an easy access to a list of
" recently opened/used files in Vim. This plugin automatically stores the file
" names as you open/use them in Vim.
"
" This plugin will work on all the platforms where Vim is supported. This
" plugin will work in both console and GUI Vim. This plugin will work only if
" the 'compatible' option is not set. As this plugin relies on the 'viminfo'
" feature, make sure Vim is built with this feature (+viminfo) enabled (use
" the ":version" command)
"
" The MRU filenames are stored in a global variable which retains the stored
" value across Vim sessions using the 'viminfo' feature. For this to work, the
" 'viminfo' option should have the '!' flag set. This plugin will
" automatically add this flag to the 'viminfo' option.
"
" When you are using multiple instances of Vim at the same time, as you quit
" every instance of Vim, the MRU list from that instance will override the
" list from other instances of Vim. This is similar to how Vim handles the
" buffer list across Vim sessions.
"
" Installation
" ------------
" 1. Copy the mru.vim script to the $HOME/.vim/plugin directory.  Refer to
"    ':help add-plugin', ':help add-global-plugin' and ':help runtimepath' for
"    more details about Vim plugins.
" 2. Restart Vim.
" 3. You can use the ":MRU" command to list and edit the recently used files.
"
" Usage
" -----
" You can use the ":MRU" command to list all the most recently used file
" names. The file names will be listed in a temporary Vim window. If the MRU
" list window is already opened, then the MRU list displayed in the window
" will be refreshed.
"
" You can use the normal Vim commands to move around the window. You cannot
" make changes in the window.
"
" You can select a file name to edit by pressing the <Enter> key or by double
" clicking the left mouse button on a file name.  The selected file will be
" opened. 
"
" You can press the 'o' key to open the file name under the cursor in the
" MRU window in a new window.
"
" You can press the 'u' key in the MRU window to update the file list. This is
" useful if you keep the MRU window open.
"
" You can close the MRU window by pressing the 'q' key or using one of the Vim
" window commands.
"
" Configuration
" -------------
" By changing the following variables you can configure the behavior of this
" plugin. Set the following variables in your .vimrc file using the 'let'
" command.
"
" By default, the plugin will remember the names of the last 10 used files.
" As you edit more files, old file names will be removed from the MRU list.
" You can set the 'MRU_Max_Entries' variable to remember more file names. For
" example, to remember 50 most recently used file names, you can use
"
"       let MRU_Max_Entries = 50
"
" By default, all the edited file names will be added to the MRU list. If you
" want to exclude file names matching a list of patterns, you can set the
" MRU_Exclude_Files variable to a list of Vim regular expressions. By default,
" this variable is set to an empty string. For example, to not include files
" in the temporary (/tmp, /var/tmp and d:\temp) directories, you can set the
" MRU_Exclude_Files variable to
"
"       let MRU_Exclude_Files = '^/tmp/.*\|^/var/tmp/.*'  " For Unix
"       let MRU_Exclude_Files = '^c:\\temp\\.*'           " For MS-Windows
" 
" The specified pattern should be a Vim regular expression pattern.
"
" The default height of the MRU window is 8. You can set the MRU_Window_Height
" variable to change the window height.
"
"       let MRU_Window_Height = 15
"
" By default, when the :MRU command is invoked, the MRU list will be displayed
" in a new window. Instead, if you want the MRU plugin to reuse the current
" window, then you can set the 'MRU_Use_Current_Window' variable to one.
"
"       let MRU_Use_Current_Window = 1
"
" The MRU plugin will reuse the current window. When a file name is selected,
" the file is also opened in the current window.
"
" When you select a file from the MRU window, the MRU window will be
" automatically closed and the selected file will be opened in the previous
" window. You can set the 'MRU_Auto_Close' variable to zero to keep the MRU
" window open.
"
"       let MRU_Auto_Close = 0
"
" ****************** Do not modify after this line ************************
if exists('loaded_mru') || &cp || !has('viminfo')
    finish
endif
let loaded_mru=1

" Maximum number of entries allowed in the MRU list
if !exists('MRU_Max_Entries')
    let MRU_Max_Entries = 10
endif

" Files to exclude from the MRU list
if !exists('MRU_Exclude_Files')
    let MRU_Exclude_Files = ''
endif

" Height of the MRU window
" Default height is 8
if !exists('MRU_Window_Height')
    let MRU_Window_Height = 8
endif

if !exists('MRU_Use_Current_Window')
    let MRU_Use_Current_Window = 0
endif

if !exists('MRU_Auto_Close')
    let MRU_Auto_Close = 1
endif

" The MRU plugin relies on the 'viminfo' feature to store and restore the MRU
" list.
" If the 'viminfo' option is not set then set it to the Vim default value
if &viminfo == ''
    set viminfo&vim
endif

" Add (prepend) the ! flag to remember global variables names across Vim
" sessions
set viminfo^=!

if !exists('MRU_LIST')
    let MRU_LIST = ''
endif

" MRU_AddFile
" Add a file to the MRU file list
function! s:MRU_AddFile()
    " Get the full path to the filename
    let fname = fnamemodify(expand('<afile>'), ':p')
    if fname == ''
        return
    endif

    " Skip temporary buffer with buftype set
    if &buftype != ''
        return
    endif

    if g:MRU_Exclude_Files != ''
        " Do not add files matching the pattern specified in the
        " MRU_Exclude_Files to the MRU list
        if fname =~? g:MRU_Exclude_Files
            return
        endif
    endif

    let already_present = 0

    " If the filename is already present in the MRU list, then move
    " it to the beginning of the list
    let idx = stridx(g:MRU_LIST, fname . "\n")
    if idx != -1
        let already_present = 1

        " Remove the entry from the list by extracting the text before it
        " and then the text after it and then concatenate them
        let text_before = strpart(g:MRU_LIST, 0, idx)
        let rem_text = strpart(g:MRU_LIST, idx)
        let next_idx = stridx(rem_text, "\n")
        let text_after = strpart(rem_text, next_idx + 1)
        let g:MRU_LIST = text_before . text_after
    endif

    " If the file is not present in the system and was not already present in
    " the MRU list, then skip it
    if !already_present && !filereadable(fname)
        return
    endif

    " Allow (retain) only MRU_Max_Entries in the MRU list. Remove/discard
    " the remaining entries. As we are adding a one entry to the list,
    " the list should have only MRU_Max_Entries - 1 in it.
    let cnt = g:MRU_Max_Entries - 1
    let mru_list = g:MRU_LIST
    let g:MRU_LIST = ''
    while cnt > 0 && mru_list != ''
        " Extract one filename from the list
        let one_line = strpart(mru_list, 0, stridx(mru_list, "\n"))

        " Remove the extracted line from the list
        let mru_list = strpart(mru_list, stridx(mru_list, "\n") + 1)

        " Add it to the global MRU list
        let g:MRU_LIST = g:MRU_LIST . one_line . "\n"

        " One more entry used up
        let cnt = cnt - 1
    endwhile

    " Add the new filename to the beginning of the MRU list
    let g:MRU_LIST = fname . "\n" . g:MRU_LIST

    " If the MRU window is open, update the displayed MRU list
    let bname = '__MRU_Files__'
    let winnum = bufwinnr(bname)
    if winnum != -1
        let cur_winnr = winnr()
        call s:MRU_Display()
        if winnr() != cur_winnr
            exe cur_winnr . 'wincmd w'
        endif
    endif
endfunction

" MRU_EditFile
" Open a file selected from the MRU window
function! s:MRU_EditFile(new_window)
    let fname = getline('.')

    if fname == ''
        return
    endif

    if a:new_window
        exe 'leftabove new ' . fname
    else
        " If the selected file is already open in one of the windows,
        " jump to it
        let winnum = bufwinnr(fname)
        if winnum != -1
            if g:MRU_Auto_Close == 1 && g:MRU_Use_Current_Window == 0
                " Automatically close the window if the file window is
                " not used to display the MRU list.
                silent! close
            endif
            " As the window numbers will change after closing a window,
            " get the window number again and jump to it, if the cursor
            " is not already in that window
            let winnum = bufwinnr(fname)
            if winnum != winnr()
                exe winnum . 'wincmd w'
            endif
        else
            if g:MRU_Auto_Close == 1 && g:MRU_Use_Current_Window == 0
                " Automatically close the window if the file window is
                " not used to display the MRU list.
                silent! close

                " Jump to the window from which the MRU window was opened
                if exists('s:MRU_last_buffer')
                    exe 'let last_winnr = bufwinnr(' . s:MRU_last_buffer ')'
                    if last_winnr != -1 && last_winnr != winnr()
                        exe last_winnr . 'wincmd w'
                    endif
                endif
            else
                if g:MRU_Use_Current_Window == 0
                    " Goto the previous window
                    " If MRU_Use_Current_Window is set to one, then the
                    " current window is used to open the file
                    wincmd p
                endif
            endif

            " Edit the file
            let bno = bufnr(fname)
            if bno != -1
                exe 'buffer ' . bno
            else
                exe 'edit ' . fname
            endif
        endif
    endif
endfunction

" MRU_Display
" Display the Most Recently Used file list in a temporary window.
function! s:MRU_Display()
    " Empty MRU list
    if g:MRU_LIST == ''
        echohl WarningMsg | echo 'MRU List is empty' | echohl None
        return
    endif

    " Save the current buffer number. This is used later to open a file when a
    " entry is selected from the MRU window. The window number is not saved,
    " as the window number will change when new windows are opened.
    let s:MRU_last_buffer = bufnr('%')

    let bname = '__MRU_Files__'

    " If the window is already open, jump to it
    let winnum = bufwinnr(bname)
    if winnum != -1
        if winnr() != winnum
            " If not already in the window, jump to it
            exe winnum . 'wincmd w'
        endif

        setlocal modifiable

        " Delete the contents of the buffer to the black-hole register
        silent! %delete _
    else
        if g:MRU_Use_Current_Window
            " Reuse the current window
            "
            " If the __MRU_Files__ buffer exists, then reuse it. Otherwise open
            " a new buffer
            let bufnum = bufnr(bname)
            if bufnum == -1
                let wcmd = bname
            else
                let wcmd = '+buffer' . bufnum
            endif

            exe 'silent! edit ' . wcmd
        else
            " Open a new window at the bottom

            " If the __MRU_Files__ buffer exists, then reuse it. Otherwise open
            " a new buffer
            let bufnum = bufnr(bname)
            if bufnum == -1
                let wcmd = bname
            else
                let wcmd = '+buffer' . bufnum
            endif

            exe 'silent! botright ' . g:MRU_Window_Height . 'split ' . wcmd
        endif
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted

    " Create a mapping to jump to the file
    nnoremap <buffer> <silent> <CR> :call <SID>MRU_EditFile(0)<CR>
    nnoremap <buffer> <silent> o :call <SID>MRU_EditFile(1)<CR>
    nnoremap <buffer> <silent> u :MRU<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>MRU_EditFile(0)<CR>
    nnoremap <buffer> <silent> q :close<CR>

    " Display the MRU list
    silent! 0put =g:MRU_LIST

    setlocal nomodifiable
endfunction

" Autocommands to detect the most recently used files
autocmd BufRead * call s:MRU_AddFile()
autocmd BufNewFile * call s:MRU_AddFile()
autocmd BufWritePost * call s:MRU_AddFile()

" Command to open the MRU window
command! -nargs=0 MRU call s:MRU_Display()

