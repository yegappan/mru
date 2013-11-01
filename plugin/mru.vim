" File: mru.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 2.2
" Last Modified: May 30, 2006
"
" Overview
" --------
" The Most Recently Used (MRU) plugin provides an easy access to a list of
" recently opened/edited files in Vim. This plugin automatically stores the
" file names as you open/edit them in Vim.
"
" This plugin will work on all the platforms where Vim is supported. This
" plugin will work in both console and GUI Vim.
"
" The recently used filenames are stored in a file specified by the Vim
" MRU_File variable.
"
" Installation
" ------------
" 1. Copy the mru.vim script to the $HOME/.vim/plugin or the
"    $HOME/vimfiles/plugin or the $VIM/vimfiles directory.  Refer to the
"    ':help add-plugin', ':help add-global-plugin' and ':help runtimepath'
"    topics for more details about Vim plugins.
" 2. Set the MRU_File Vim variable in the .vimrc file to the location of a
"    file to store the most recently edited file names.
" 3. Restart Vim.
" 4. You can use the ":MRU" command to list and edit the recently used files.
"    In GUI Vim, you can use the 'File->Recent Files' menu to access the
"    recently used files.
"
" Usage
" -----
" You can use the ":MRU" command to list all the most recently edited file
" names. The file names will be listed in a temporary Vim window. If the MRU
" window is already opened, then the MRU list displayed in the window will be
" refreshed.
"
" If you are using GUI Vim, then the names of the recently edited files are
" added to the "File->Recent Files" menu. You can select the name of a file
" from this sub-menu to edit the file.
"
" You can use the normal Vim commands to move around the MRU window. You
" cannot make changes in the MRU window.
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
" You can use the ":MRUedit" command to edit files from the MRU list. This
" command supports completion of file names from the MRU list. You can specify
" the file either by the name or by the location in the MRU list.
"
" Whenever the MRU list changes, the MRU file is updated with the latest MRU
" list. When you have multiple instances of Vim running at the same time, the
" latest MRU list will show up in all the instances of Vim.
"
" Configuration
" -------------
" By changing the following variables you can configure the behavior of this
" plugin. Set the following variables in your .vimrc file using the 'let'
" command.
"
" The list of recently edit file names is stored in the file specified by the
" MRU_File variable.  The default setting for this variable is
" $HOME/.vim_mru_files for Unix systems and $VIM/_vim_mru_files for non-Unix
" systems. You can change this variable to point to a file by adding the
" following line to the .vimrc file:
"
"       let MRU_File = 'd:\myhome\_vim_mru_files'
"
" By default, the plugin will remember the names of the last 10 used files.
" As you edit more files, old file names will be removed from the MRU list.
" You can set the 'MRU_Max_Entries' variable to remember more file names. For
" example, to remember 20 most recently used file names, you can use
"
"       let MRU_Max_Entries = 20
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
if exists('loaded_mru')
    finish
endif
let loaded_mru=1

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

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

if !exists('MRU_File')
    if has('unix')
        let MRU_File = $HOME . "/.vim_mru_files"
    else
        let MRU_File = $VIM . "/_vim_mru_files"
    endif
endif

" MRU_LoadList
" Load the latest MRU file list from the MRU file
function! s:MRU_LoadList()
    " Read the list from the MRU file.
    if filereadable(g:MRU_File)
        exe "source " . escape(g:MRU_File, ' ')
    endif

    if exists('g:MRU_files')
        " Replace file separator (|) with newline
        let s:MRU_files = substitute(g:MRU_files, "|", "\n", "g")
        unlet! g:MRU_files
    else
        let s:MRU_files = ''
    endif

    " Refresh the MRU menu
    call s:MRU_Refresh_Menu()
endfunction

" MRU_SaveList
" Save the MRU list to the file
function! s:MRU_SaveList()
    " Replace all newlines with file separator (|)
    let mru_list = substitute(s:MRU_files, "\n", "|", "g")

    " set the verbose option to zero (default). Otherwise this will
    " mess up the text emitted below.
    let old_verbose = &verbose
    set verbose&vim

    " Clear the messages displayed on the status line
    echo

    " Save the MRU list
    exe "redir! > " . g:MRU_File
    silent! echon '" Most recently edited files in Vim (auto-generated)' . "\n"
    silent! echon "let MRU_files='" . mru_list . "'\n"
    redir END

    " Restore the verbose setting
    let &verbose = old_verbose
endfunction

" MRU_RemoveLines()
" Remove the lines matching 'one_line' from 'str'
function! s:MRU_RemoveLines(str, one_line)
    let idx = stridx(a:str, a:one_line . "\n")
    if idx == -1
        " one_line is not present in str
        return a:str
    endif

    let x = a:str

    while idx != -1
        " Remove the entry from the list by extracting the text before it
        " and then the text after it and then concatenate them
        let text_before = strpart(x, 0, idx)
        let rem_text = strpart(x, idx)
        let next_idx = stridx(rem_text, "\n")
        let text_after = strpart(rem_text, next_idx + 1)

        let x = text_before . text_after
        let idx = stridx(x, a:one_line . "\n")
    endwhile

    return x
endfunction

" MRU_TrimLines()
" Returns the first "lcnt" lines from "lines"
function! s:MRU_TrimLines(lines, lcnt)
    " Retain only  lcnt lines in lines. Remove the remaining lines
    let llist = a:lines
    let cnt = a:lcnt
    let new_llist = ''
    while cnt > 0 && llist != ''
        " Extract one filename from the list
        let one_line = strpart(llist, 0, stridx(llist, "\n"))

        " Remove the extracted line from the list
        let llist = strpart(llist, stridx(llist, "\n") + 1)

        if one_line != ''
            " Retain the line (if non-empty)
            let new_llist = new_llist . one_line . "\n"
        endif

        " One more entry used up
        let cnt = cnt - 1
    endwhile

    return new_llist
endfunction

" MRU_AddFile
" Add a file to the MRU file list
function! s:MRU_AddFile(filename)
    if a:filename == ''
        return
    endif

    " Get the full path to the filename
    let fname = fnamemodify(a:filename, ':p')

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

    " If the filename is already present in the MRU list, then move
    " it to the beginning of the list
    let idx = stridx(s:MRU_files, fname . "\n")
    if idx == -1 && !filereadable(fname)
        " File is not readable and is not in the MRU list
        return
    endif

    " Load the latest MRU file list
    call s:MRU_LoadList()

    " Remove the new file name from the existing MRU list (if already present)
    let old_flist = s:MRU_RemoveLines(s:MRU_files, fname)

    " Add the new file list to the beginning of the updated old file list
    let s:MRU_files = fname . "\n" . old_flist

    " Return the trimmed list
    let s:MRU_files = s:MRU_TrimLines(s:MRU_files, g:MRU_Max_Entries)

    " Save the updated MRU list
    call s:MRU_SaveList()

    " Refresh the MRU menu
    call s:MRU_Refresh_Menu()

    " If the MRU window is open, update the displayed MRU list
    let bname = '__MRU_Files__'
    let winnum = bufwinnr(bname)
    if winnum != -1
        let cur_winnr = winnr()
        call s:MRU_Open_Window()
        if winnr() != cur_winnr
            exe cur_winnr . 'wincmd w'
        endif
    endif
endfunction

" MRU_Edit_File
" Edit the specified file
function! s:MRU_Edit_File(filename)
    let fname = escape(a:filename, ' ')
    " If the file is already open in one of the windows, jump to it
    let winnum = bufwinnr(fname)
    if winnum != -1
        if winnum != winnr()
            exe winnum . 'wincmd w'
        endif
    else
        if &modified
            " Current buffer has unsaved changes, so open the file in a
            " new window
            exe 'split ' . fname
        else
            exe 'edit ' . fname
        endif
    endif
endfunction

" MRU_Window_Edit_File
" Open a file selected from the MRU window
function! s:MRU_Window_Edit_File(new_window)
    let fname = getline('.')

    if fname == ''
        return
    endif

    let fname = escape(fname, ' ')

    if a:new_window
        " Edit the file in a new window
        exe 'leftabove new ' . fname

        if g:MRU_Auto_Close == 1 && g:MRU_Use_Current_Window == 0
            " Go back to the MRU window and close it
            let cur_winnr = winnr()

            wincmd p
            silent! close

            if winnr() != cur_winnr
                exe cur_winnr . 'wincmd w'
            endif
        endif
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
                    let last_winnr = bufwinnr(s:MRU_last_buffer)
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
            if &modified
                exe 'split ' . fname
            else
                exe 'edit ' . fname
            endif
        endif
    endif
endfunction

" MRU_Open_Window
" Display the Most Recently Used file list in a temporary window.
function! s:MRU_Open_Window()

    " Load the latest MRU file list
    call s:MRU_LoadList()

    " Empty MRU list
    if s:MRU_files == ''
        echohl WarningMsg | echo 'MRU file list is empty' | echohl None
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
                let cmd = 'edit ' . bname
            else
                let cmd = 'buffer ' . bufnum
            endif

            exe cmd

            if bufnr('%') != bufnr(bname)
                " Failed to edit the MRU buffer
                return
            endif
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
    " Use fixed height for the MRU window
    if v:version >= 602
        setlocal winfixheight
    endif

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim

    " Create a mapping to jump to the file
    nnoremap <buffer> <silent> <CR> :call <SID>MRU_Window_Edit_File(0)<CR>
    nnoremap <buffer> <silent> o :call <SID>MRU_Window_Edit_File(1)<CR>
    nnoremap <buffer> <silent> u :MRU<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>
                \ :call <SID>MRU_Window_Edit_File(0)<CR>
    nnoremap <buffer> <silent> q :close<CR>

    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions

    " Display the MRU list
    silent! 0put =s:MRU_files

    " Move the cursor to the beginning of the file
    exe 1

    setlocal nomodifiable
endfunction

" MRU_Edit_Complete
" Command-line completion function used by :MRUedit command
function! s:MRU_Edit_Complete(ArgLead, CmdLine, CursorPos)
    " Return the list of MRU files
    return s:MRU_files
endfunction

" MRU_Edit_File_Cmd
" Function to handle the MRUedit command
function! s:MRU_Edit_File_Cmd(fspec)
    if a:fspec == ''
        return
    endif

    " Load the latest MRU file
    call s:MRU_LoadList()

    " User can specify either a number of a partial file name to
    " edit a file from the MRU list
    if a:fspec =~ '\d\+'
        " A number is specified
        let fnum = a:fspec
        if fnum > g:MRU_Max_Entries
            echohl WarningMsg
            echo 'Maximum number of entries in MRU list = ' .
                        \ g:MRU_Max_Entries 
            echohl None
            return
        endif

        let mru_list = s:MRU_files

        let i = 1
        while mru_list != '' && i < fnum
            let one_fname = strpart(mru_list, 0, stridx(mru_list, "\n"))
            if one_fname == ''
                break
            endif

            let mru_list = strpart(mru_list, stridx(mru_list, "\n") + 1)
            let i = i + 1
        endwhile

        if i == fnum
            let fname = strpart(mru_list, 0, stridx(mru_list, "\n"))
            if fname != ''
                call s:MRU_Edit_File(fname)
            endif
        endif
    else
        " Locate the file name matching the supplied partial name
        let mru_list = s:MRU_files
        let fname = ''
        let fname_cnt = 0

        while mru_list != ''
            let one_fname = strpart(mru_list, 0, stridx(mru_list, "\n"))
            if one_fname == ''
                break
            endif

            if one_fname =~? a:fspec
                let fname = one_fname
                let fname_cnt = fname_cnt + 1
            endif

            let mru_list = strpart(mru_list, stridx(mru_list, "\n") + 1)
        endwhile

        if fname_cnt == 0
            echohl WarningMsg
            echo 'No matching file for ' . a:fspec
            echohl None
            return
        endif

        if fname_cnt > 1
            echohl WarningMsg
            echo 'More than one match for ' . a:fspec
            echohl None
            return
        endif

        call s:MRU_Edit_File(fname)
    endif
endfunction

" MRU_Refresh_Menu()
" Refresh the MRU menu
function! s:MRU_Refresh_Menu()
    if !has('gui_running') || &guioptions !~ 'm'
        " Not running in GUI mode
        return
    endif

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim

    " Remove the MRU menu
    " To retain the teared-off MRU menu, we need to add a dummy entry
    silent! unmenu &File.Recent\ Files
    noremenu &File.Recent\ Files.Dummy <Nop>
    silent! unmenu! &File.Recent\ Files

    anoremenu <silent> &File.Recent\ Files.Refresh\ list
                \ :call <SID>MRU_LoadList()<CR>
    anoremenu File.Recent\ Files.-SEP1-           :

    " Add the filenames in the MRU list to the menu
    let flist = s:MRU_files
    while flist != ''
        " Extract one filename from the list
        let fname = strpart(flist, 0, stridx(flist, "\n"))
        if fname == ''
            break
        endif

        " Escape special characters in the filename
        let esc_fname = escape(fnamemodify(fname, ':t'), ". \\|\t")

        " Remove the extracted line from the list
        let flist = strpart(flist, stridx(flist, "\n") + 1)

        " Truncate the directory name if it is long
        let dir_name = fnamemodify(fname, ':h')
        let len = strlen(dir_name)
        " Shorten long file names by adding only few characters from
        " the beginning and end.
        if len > 30
            let dir_name = strpart(dir_name, 0, 10) .
                        \ '...' . 
                        \ strpart(dir_name, len - 20)
        endif
        let esc_dir_name = escape(dir_name, ". \\|\t")

        exe 'anoremenu <silent> &File.Recent\ Files.' . esc_fname .
                    \ '\ (' . esc_dir_name . ')' .
                    \ " :call <SID>MRU_Edit_File('" . fname . "')<CR>"
    endwhile

    " Remove the dummy menu entry
    unmenu &File.Recent\ Files.Dummy

    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions
endfunction

" Load the MRU list on plugin startup
call s:MRU_LoadList()

" Autocommands to detect the most recently used files
autocmd BufRead * call s:MRU_AddFile(expand('<afile>'))
autocmd BufNewFile * call s:MRU_AddFile(expand('<afile>'))
autocmd BufWritePost * call s:MRU_AddFile(expand('<afile>'))

" Command to open the MRU window
command! -nargs=0 MRU call s:MRU_Open_Window()
command! -nargs=1 -complete=custom,s:MRU_Edit_Complete MRUedit
            \ call s:MRU_Edit_File_Cmd(<q-args>)

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
