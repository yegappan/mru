" What: Remember list of recently edited files, changes by Mosh
" From http://www.vim.org/scripts/script.php?script_id=521 2017

" File: mru.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 3.9.1m
" Last Modified: 2019-07-04
" Copyright: Copyright (C) 2003-2018 Yegappan Lakshmanan
" License:   Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            mru.vim is provided *as is* and comes with no warranty of any
"            kind, either expressed or implied. In no event will the copyright
"            holder be liable for any damages resulting from the use of this
"            software.
"
" ****************** Do not modify after this line ************************
if exists('loaded_mru')
    finish
endif
let loaded_mru=1

if v:version < 700
    finish
endif

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" MRU configuration variables {{{1
" Maximum number of entries allowed in the MRU list
if !exists('MRU_Max_Entries')
    let MRU_Max_Entries = 100
endif

" Files to exclude from the MRU list
if !exists('MRU_Exclude_Files')
    let MRU_Exclude_Files = ''
endif

" Files to include in the MRU list
if !exists('MRU_Include_Files')
    let MRU_Include_Files = ''
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
    if has('unix') || has('macunix')
        let MRU_File = $HOME . '/.vim_mru_files'
    else
        let MRU_File = $VIM . '/_vim_mru_files'
        if has('win32')
            " MS-Windows
            if $USERPROFILE != ''
                let MRU_File = $USERPROFILE . '\_vim_mru_files'
            endif
        endif
    endif
else
    let MRU_File=expand(MRU_File)
endif

" Option for enabling or disabling the MRU menu
if !exists('MRU_Add_Menu')
    let MRU_Add_Menu = 1
endif

" Maximum number of file names to show in the MRU menu. If too many files are
" listed in the menu, then Vim becomes slow when updating the menu. So set
" this to a low value.
if !exists('MRU_Max_Menu_Entries')
    let MRU_Max_Menu_Entries = 10
endif

" Maximum number of file names to show in a MRU sub-menu. If the MRU list
" contains more file names than this setting, then the MRU menu is split into
" one or more sub-menus.
if !exists('MRU_Max_Submenu_Entries')
    let MRU_Max_Submenu_Entries = 10
endif

" When only a single matching filename is found in the MRU list, the following
" option controls whether the file name is displayed in the MRU window or the
" file is directly opened. When this variable is set to 0 and a single
" matching file name is found, then the file is directly opened.
if !exists('MRU_Window_Open_Always')
    let MRU_Window_Open_Always = 0
endif

" When opening a file from the MRU list, the file is opened in the current
" tab. If the selected file has to be opened in a tab always, then set the
" following variable to 1. If the file is already opened in a tab, then the
" cursor will be moved to that tab.
if !exists('MRU_Open_File_Use_Tabs')
    let MRU_Open_File_Use_Tabs = 0
endif

" Format of the file names displayed in the MRU window.
" The default is to display the filename followed by the complete path to the
" file in parenthesis. This variable controls the expressions used to format
" and parse the path. This can be changed to display the filenames in a
" different format. The 'formatter' specifies how to split/format the filename
" and 'parser' specifies how to read the filename back; 'syntax' matches the
" part to be highlighted.
if !exists('MRU_Filename_Format')
    let MRU_Filename_Format = {
        \   'formatter':   'fnamemodify(split(v:val,"\\t")[0],":t")
                      \. "	("
                      \.    split(v:val, "\\zs\\t")[0]
                      \. ") "
                      \. join(split(v:val,"\\t")[1:],"	")',
        \   'parser':      '(\zs.\+\ze)',
        \   'syntax': '^\S\+'
        \}
endif

function! MoshIsPath(in)
  return filereadable(a:in) || isdirectory(a:in)
endfunction

function! MoshPathAbbrev(in)
  " Change /home/mosh/etc to ~/etc
  let l:in = a:in
  let dict = { '^'.expand("$HOME").'/' : '~/', }
  for i in items(dict)
    let l:in = substitute(l:in,i[0],i[1],'i')
  endfor
  return l:in
endfun

" Control to temporarily lock the MRU list. Used to prevent files from
" getting added to the MRU list when the ':vimgrep' command is executed.
let s:mru_list_locked = 0

" MRU_LoadList                          {{{1
" Loads the latest list of file names from the MRU file
function! s:MRU_LoadList()
    " If the MRU file is present, then load the list of filenames. Otherwise
    " start with an empty list.
    if filereadable(g:MRU_File)
        let s:MRU_files = readfile(g:MRU_File)
        if s:MRU_files[0] =~# '^\s*" Most recently edited files in Vim'
            " Generated by the previous version of the MRU plugin.
            " Discard the list.
            let s:MRU_files = []
        elseif s:MRU_files[0] =~# '^#'
            " Remove the comment line
            call remove(s:MRU_files, 0)
        else
            " Unsupported format
            let s:MRU_files = []
        endif
    else
        let s:MRU_files = []
    endif

    " Refresh the MRU menu with the latest list of filenames
    call s:MRU_Refresh_Menu()
endfunction

" MRU_SaveList                          {{{1
" Saves the MRU file names to the MRU file
function! s:MRU_SaveList()
    let l = []
    call add(l, '# Most recently edited files in Vim (version 3.0)')
    call extend(l, s:MRU_files)
    call writefile(l, g:MRU_File)
endfunction

command!    MRUSaveReadable
  \ :call filter(s:MRU_files, 'MoshIsPath(expand(split(v:val,"\\t")[0]))') |
  \ :call s:MRU_SaveList()

" MRU_AddFile                           {{{1
" Adds a file to the MRU file list
"   acmd_bufnr - Buffer number of the file to add
function! s:MRU_AddFile(acmd_bufnr)
    if s:mru_list_locked
        " MRU list is currently locked
        return
    endif

    " Get the full path to the filename
    let fname = fnamemodify(bufname(a:acmd_bufnr + 0), ':p')
    if fname == ''
        return
    endif

    " Skip temporary buffers with buftype set. The buftype is set for buffers
    " used by plugins.
    if &buftype != ''
        return
    endif

    if g:MRU_Include_Files != ''
        " If MRU_Include_Files is set, include only files matching the
        " specified pattern
        if fname !~# g:MRU_Include_Files
            return
        endif
    endif

    if g:MRU_Exclude_Files != ''
        " Do not add files matching the pattern specified in the
        " MRU_Exclude_Files to the MRU list
        if fname =~# g:MRU_Exclude_Files
            return
        endif
    endif

    " If the filename is not already present in the MRU list and is not
    " readable then ignore it
    let idx = index(s:MRU_files, fname)
    if idx == -1
        if !MoshIsPath(expand(fname))
            " File is not readable and is not in the MRU list
            return
        endif
    endif

    " Load the latest MRU file list
    call s:MRU_LoadList()

    let fname2 = MoshPathAbbrev(fname)
    let pwd2 = MoshPathAbbrev($PWD)
    let date = strftime("%Y-%b-%d-%H:%M")

    " Remove the new file name from the existing MRU list (if already present)
    " Should be case insensitive search index()
    call filter(s:MRU_files,   'v:val !~? fname')

    " Use no-magic \M, as ~ means $HOME in fname2.
    call filter(s:MRU_files,   'v:val !~? "\\M".fname2')

    " Save 'filename date pwd' 2019-07-03 Mosh
    " Add the new file list to the beginning of the updated old file list
    call insert(s:MRU_files, fname2."\t".date."\tPWD=".pwd2, 0)

    " Trim the list
    if len(s:MRU_files) > g:MRU_Max_Entries
        call remove(s:MRU_files, g:MRU_Max_Entries, -1)
    endif

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

" MRU_escape_filename                   {{{1
" Escape special characters in a filename. Special characters in file names
" that should be escaped (for security reasons)
let s:esc_filename_chars = ' *?[{`$%#"|!<>();&' . "'\t\n"
function! s:MRU_escape_filename(fname)
    if exists("*fnameescape")
        return fnameescape(a:fname)
    else
        return escape(a:fname, s:esc_filename_chars)
    endif
endfunction

" MRU_Edit_File                         {{{1
" Edit the specified file
"   filename - Name of the file to edit
"   sanitized - Specifies whether the filename is already escaped for special
"   characters or not.
function! s:MRU_Edit_File(filename, sanitized)
    if !a:sanitized
        let esc_fname = s:MRU_escape_filename(a:filename)
    else
        let esc_fname = a:filename
    endif

    " If the user wants to always open the file in a tab, then open the file
    " in a tab. If it is already opened in a tab, then the cursor will be
    " moved to that tab.
    if g:MRU_Open_File_Use_Tabs
        call s:MRU_Open_File_In_Tab(a:filename, esc_fname)
        return
    endif

    " If the file is already open in one of the windows, jump to it
    let winnum = bufwinnr('^' . a:filename . '$')
    if winnum != -1
        if winnum != winnr()
            exe winnum . 'wincmd w'
        endif
    else
        if !&hidden && (&modified || &buftype != '' || &previewwindow)
            " Current buffer has unsaved changes or is a special buffer or is
            " the preview window.  The 'hidden' option is also not set.
            " So open the file in a new window.
            exe 'split ' . esc_fname
        else
            " The current file can be replaced with the selected file.
            exe 'edit ' . esc_fname
        endif
    endif
endfunction

" MRU_Open_File_In_Tab
" Open a file in a tab. If the file is already opened in a tab, jump to the
" tab. Otherwise, create a new tab and open the file.
"   fname     : Name of the file to open
"   esc_fname : File name with special characters escaped
function! s:MRU_Open_File_In_Tab(fname, esc_fname)
    " If the selected file is already open in the current tab or in
    " another tab, jump to it. Otherwise open it in a new tab
    if bufwinnr('^' . a:fname . '$') == -1
        let tabnum = -1
        let i = 1
        let bnum = bufnr('^' . a:fname . '$')
        while i <= tabpagenr('$')
            if index(tabpagebuflist(i), bnum) != -1
                let tabnum = i
                break
            endif
            let i += 1
        endwhile

        if tabnum != -1
            " Goto the tab containing the file
            exe 'tabnext ' . i
        else
            " Open a new tab as the last tab page
            tablast
            exe 'tabnew ' . a:esc_fname
        endif
    endif

    " Jump to the window containing the file
    let winnum = bufwinnr('^' . a:fname . '$')
    if winnum != winnr()
        exe winnum . 'wincmd w'
    endif
endfunction

" MRU_Window_Edit_File                  {{{1
"   fname     : Name of the file to edit. May specify single or multiple
"               files.
"   edit_type : Specifies how to edit the file. Can be one of 'edit' or 'view'.
"               'view' - Open the file as a read-only file
"               'edit' - Edit the file as a regular file
"   multi     : Specifies  whether a single file or multiple files need to be
"               opened.
"   open_type : Specifies where to open the file.
"               useopen - If the file is already present in a window, then
"                         jump to that window.  Otherwise, open the file in
"                         the previous window.
"               newwin_horiz - Open the file in a new horizontal window.
"               newwin_vert - Open the file in a new vertical window.
"               newtab  - Open the file in a new tab. If the file is already
"                         opened in a tab, then jump to that tab.
"               preview - Open the file in the preview window
function! s:MRU_Window_Edit_File(fname, multi, edit_type, open_type)
    let esc_fname = s:MRU_escape_filename(a:fname)

    if a:open_type ==# 'newwin_horiz'
        " Edit the file in a new horizontally split window above the previous
        " window
        wincmd p
        exe 'belowright new ' . esc_fname
    elseif a:open_type ==# 'newwin_vert'
        " Edit the file in a new vertically split window above the previous
        " window
        wincmd p
        exe 'belowright vnew ' . esc_fname
    elseif a:open_type ==# 'newtab' || g:MRU_Open_File_Use_Tabs
        call s:MRU_Open_File_In_Tab(a:fname, esc_fname)
    elseif a:open_type ==# 'preview'
        " Edit the file in the preview window
        exe 'topleft pedit ' . esc_fname
    else
        " If the selected file is already open in one of the windows,
        " jump to it
        let winnum = bufwinnr('^' . a:fname . '$')
        if winnum != -1
            exe winnum . 'wincmd w'
        else
            if g:MRU_Auto_Close == 1 && g:MRU_Use_Current_Window == 0
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

            let split_window = 0

            if (!&hidden && (&modified || &previewwindow)) || a:multi
                " Current buffer has unsaved changes or is the preview window
                " or the user is opening multiple files
                " So open the file in a new window
                let split_window = 1
            endif

            if &buftype != ''
                " Current buffer is a special buffer (maybe used by a plugin)
                if g:MRU_Use_Current_Window == 0 ||
                            \ bufnr('%') != bufnr('__MRU_Files__')
                    let split_window = 1
                endif
            endif

            " Edit the file
            if split_window
                " Current buffer has unsaved changes or is a special buffer or
                " is the preview window.  So open the file in a new window
                if a:edit_type ==# 'edit'
                    exe 'split ' . esc_fname
                else
                    exe 'sview ' . esc_fname
                endif
            else
                if a:edit_type ==# 'edit'
                    exe 'edit ' . esc_fname
                else
                    exe 'view ' . esc_fname
                endif
            endif
        endif
    endif
endfunction

" MRU_Select_File_Cmd                   {{{1
" Open a file selected from the MRU window
"
"   'opt' has two values separated by comma. The first value specifies how to
"   edit the file  and can be either 'edit' or 'view'. The second value
"   specifies where to open the file. It can take one of the following values:
"     'useopen' to open file in the previous window
"     'newwin_horiz' to open the file in a new horizontal split window
"     'newwin_vert' to open the file in a new vertical split window.
"     'newtab' to open the file in a new tab.
" If multiple file names are selected using visual mode, then open multiple
" files (either in split windows or tabs)
function! s:MRU_Select_File_Cmd(opt) range
    let [edit_type, open_type] = split(a:opt, ',')

    let fnames = getline(a:firstline, a:lastline)

    if g:MRU_Auto_Close == 1 && g:MRU_Use_Current_Window == 0
        " Automatically close the window if the file window is
        " not used to display the MRU list.
        silent! close
    endif

    let multi = 0

    for f in fnames
        if f == ''
            continue
        endif

        " The text in the MRU window contains the filename in parenthesis
        let file = matchstr(f, g:MRU_Filename_Format.parser)

        call s:MRU_Window_Edit_File(file, multi, edit_type, open_type)

        if a:firstline != a:lastline
            " Opening multiple files
            let multi = 1
        endif
    endfor
endfunction

" MRU_Warn_Msg                          {{{1
" Display a warning message
function! s:MRU_Warn_Msg(msg)
    echohl WarningMsg
    echo a:msg
    echohl None
endfunction

" MRU_Open_Window                       {{{1
" Display the Most Recently Used file list in a temporary window.
" If the optional argument is supplied, then it specifies the pattern of files
" to selectively display in the MRU window.
function! s:MRU_Open_Window(...)

    " Load the latest MRU file list
    call s:MRU_LoadList()

    " Check for empty MRU list
    if empty(s:MRU_files)
        call s:MRU_Warn_Msg('MRU file list is empty')
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

    setlocal modifiable

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    " Set the 'filetype' to 'mru'. This allows the user to apply custom
    " syntax highlighting or other changes to the MRU bufer.
    setlocal filetype=mru
    " Use fixed height for the MRU window
    setlocal winfixheight
    setlocal ts=16

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim

    " Create mappings to select and edit a file from the MRU list
    " 2017-May-15 Mosh, was 'e' to edit, not <CR>
    nnoremap <buffer> <silent> <CR>
                \ :call <SID>MRU_Select_File_Cmd('edit,useopen')<CR>
    nnoremap <buffer> <silent> e
                \ :call <SID>MRU_Select_File_Cmd('edit,useopen')<CR>
    vnoremap <buffer> <silent> <CR>
                \ :call <SID>MRU_Select_File_Cmd('edit,useopen')<CR>
    nnoremap <buffer> <silent> o
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_horiz')<CR>
    vnoremap <buffer> <silent> o
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_horiz')<CR>
    nnoremap <buffer> <silent> <S-CR>
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_horiz')<CR>
    vnoremap <buffer> <silent> <S-CR>
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_horiz')<CR>
    nnoremap <buffer> <silent> O
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_vert')<CR>
    vnoremap <buffer> <silent> O
                \ :call <SID>MRU_Select_File_Cmd('edit,newwin_vert')<CR>
    nnoremap <buffer> <silent> t
                \ :call <SID>MRU_Select_File_Cmd('edit,newtab')<CR>
    vnoremap <buffer> <silent> t
                \ :call <SID>MRU_Select_File_Cmd('edit,newtab')<CR>
    nnoremap <buffer> <silent> v
                \ :call <SID>MRU_Select_File_Cmd('view,useopen')<CR>
    nnoremap <buffer> <silent> p
                \ :call <SID>MRU_Select_File_Cmd('view,preview')<CR>
    vnoremap <buffer> <silent> p
                \ :<C-u>if line("'<") == line("'>")<Bar>
                \     call <SID>MRU_Select_File_Cmd('open,preview')<Bar>
                \ else<Bar>
                \     echoerr "Only a single file can be previewed"<Bar>
                \ endif<CR>
    nnoremap <buffer> <silent> u :MRU<CR>
    nnoremap <buffer> <silent> <2-LeftMouse>
                \ :call <SID>MRU_Select_File_Cmd('edit,useopen')<CR>
    nnoremap <buffer> <silent> q :close<CR>

    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions

    " Display the MRU list
    if a:0 == 0
        " No search pattern specified. Display the complete list
        let m = copy(s:MRU_files)
    else
        " Display only the entries matching the specified pattern
        " First try using it as a literal pattern
        let m = filter(copy(s:MRU_files), 'stridx(v:val, a:1) != -1')
        if len(m) == 0
            " No match. Try using it as a regular expression
            let m = filter(copy(s:MRU_files), 'v:val =~# a:1')
        endif
    endif

    " Get the tail part of the file name (without the directory) and display
    " it along with the full path in parenthesis.
    let  output = map(m, g:MRU_Filename_Format.formatter)
    silent! 0put =output

    " Delete the empty line at the end of the buffer
    silent! $delete _

    " Move the cursor to the beginning of the file
    normal! gg

    " Add syntax highlighting for the file names
    if has_key(g:MRU_Filename_Format, 'syntax')
        exe "syntax match MRUFileName '" . g:MRU_Filename_Format.syntax . "'"
        highlight default link MRUFileName Identifier
    endif

    syntax match MRUDate '\d\d\d\d-\w\+-\d\d\S\+'
    highlight default link MRUDate LineNr

    syntax match MRUPwd 'PWD=\S\+'
    highlight default link MRUPwd Directory

    syntax match MRUFullPath '(.\+)'
    highlight default link MRUFullPath MoreMsg

    setlocal nomodifiable
endfunction

" MRU_Complete                          {{{1
" Command-line completion function used by :MRU command
function! s:MRU_Complete(ArgLead, CmdLine, CursorPos)
    if a:ArgLead == ''
        " Return the complete list of MRU files
        return s:MRU_files
    else
        " Return only the files matching the specified pattern
        return filter(copy(s:MRU_files), 'v:val =~? a:ArgLead')
    endif
endfunction

" MRU_Cmd                               {{{1
" Function to handle the MRU command
"   pat - File name pattern passed to the MRU command
function! s:MRU_Cmd(pat)
    if a:pat == ''
        " No arguments specified. Open the MRU window
        call s:MRU_Open_Window()
        return
    endif

    " Load the latest MRU file
    call s:MRU_LoadList()

    " Empty MRU list
    if empty(s:MRU_files)
        call s:MRU_Warn_Msg('MRU file list is empty')
        return
    endif

    " First use the specified string as a literal string and search for
    " filenames containing the string. If only one filename is found,
    " then edit it (unless the user wants to open the MRU window always)
    let m = filter(copy(s:MRU_files), 'stridx(v:val, a:pat) != -1')
    if len(m) > 0
        if len(m) == 1 && !g:MRU_Window_Open_Always
            " 2019-Aug-28 Mosh
            let m0=split(m[0],'\t')[0]
            call s:MRU_Edit_File(m0, 0)
            return
        endif

        " More than one file matches. Try find an accurate match
        let new_m = filter(m, 'v:val ==# a:pat')
        if len(new_m) == 1 && !g:MRU_Window_Open_Always
            " 2019-Aug-28 Mosh
            let new_m0=split(new_m[0],'\t')[0]
            call s:MRU_Edit_File(new_m0, 0)
            return
        endif

        " Couldn't find an exact match, open the MRU window with all the
        " files matching the pattern.
        call s:MRU_Open_Window(a:pat)
        return
    endif

    " Use the specified string as a regular expression pattern and search
    " for filenames matching the pattern
    let m = filter(copy(s:MRU_files), 'v:val =~? a:pat')

    if len(m) == 0
        " If an existing file (not present in the MRU list) is specified,
        " then open the file.
        if MoshIsPath(expand(a:pat))
            call s:MRU_Edit_File(a:pat, 0)
            return
        endif

        " No filenames matching the specified pattern are found
        call s:MRU_Warn_Msg("MRU file list doesn't contain " .
                    \ "files matching " . a:pat)
        return
    endif

    if len(m) == 1 && !g:MRU_Window_Open_Always
        " 2019-Aug-28 Mosh
        let m0=split(m[0],'\t')[0]
        call s:MRU_Edit_File(m0, 0)
        return
    endif

    call s:MRU_Open_Window(a:pat)
endfunction

" MRU_add_files_to_menu                 {{{1
" Adds a list of files to the "Recent Files" sub menu under the "File" menu.
"   prefix - Prefix to use for each of the menu entries
"   file_list - List of file names to add to the menu
function! s:MRU_add_files_to_menu(prefix, file_list)
    for fname in a:file_list
        " Escape special characters in the filename
        let esc_fname = escape(fnamemodify(fname, ':t'), ".\\" .
                                        \ s:esc_filename_chars)
        let esc_fname = substitute(esc_fname, '&', '&&', 'g')

        " Truncate the directory name if it is long
        let dir_name = fnamemodify(fname, ':h')
        let len = strchars(dir_name)
        " Shorten long file names by adding only few characters from
        " the beginning and end.
        if len > 30
            let dir_name = strcharpart(dir_name, 0, 10) .
                        \ '...' .
                        \ strcharpart(dir_name, len - 20)
        endif
        let esc_dir_name = escape(dir_name, ".\\" . s:esc_filename_chars)
        let esc_dir_name = substitute(esc_dir_name, '&', '&&', 'g')

        let menu_path = '&File.&Recent\ Files.' . a:prefix . esc_fname .
                    \ '\ (' . esc_dir_name . ')'
        let esc_mfname = s:MRU_escape_filename(fname)
        exe 'anoremenu <silent> ' . menu_path .
                    \ " :call <SID>MRU_Edit_File('" . esc_mfname . "', 1)<CR>"
        exe 'tmenu ' . menu_path . ' Edit file ' . esc_mfname
    endfor
endfunction

" MRU_Refresh_Menu                      {{{1
" Refresh the MRU menu
function! s:MRU_Refresh_Menu()
    if !has('menu') || !g:MRU_Add_Menu
        " No support for menus
        return
    endif

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim

    " Remove the MRU menu
    " To retain the teared-off MRU menu, we need to add a dummy entry
    silent! unmenu &File.&Recent\ Files
    " The menu priority of the File menu is 10. If the MRU plugin runs
    " first before menu.vim, the File menu order may not be correct.
    " So specify the priority of the File menu here.
    10noremenu &File.&Recent\ Files.Dummy <Nop>
    silent! unmenu! &File.&Recent\ Files

    anoremenu <silent> &File.&Recent\ Files.Refresh\ list
                \ :call <SID>MRU_LoadList()<CR>
    exe 'tmenu File.&Recent\ Files.Refresh\ list Reload the MRU file list from '
                \ . s:MRU_escape_filename(g:MRU_File)
    anoremenu File.&Recent\ Files.-SEP1-           :

    " Add the filenames in the MRU list to the menu
    let entry_cnt = len(s:MRU_files)
    if entry_cnt > g:MRU_Max_Menu_Entries
        " Show only MRU_Max_Menu_Entries file names in the menu
        let mru_list = s:MRU_files[0 : g:MRU_Max_Menu_Entries - 1]
        let entry_cnt = g:MRU_Max_Menu_Entries
    else
        let mru_list = s:MRU_files
    endif
    if entry_cnt > g:MRU_Max_Submenu_Entries
        " Split the MRU menu into sub-menus
        for start_idx in range(0, entry_cnt, g:MRU_Max_Submenu_Entries)
            let last_idx = start_idx + g:MRU_Max_Submenu_Entries - 1
            if last_idx >= entry_cnt
                let last_idx = entry_cnt - 1
            endif
            let prefix = 'Files\ (' . (start_idx + 1) . '\.\.\.' .
                        \ (last_idx + 1) . ').'
            call s:MRU_add_files_to_menu(prefix,
                        \ mru_list[start_idx : last_idx])
        endfor
    else
        call s:MRU_add_files_to_menu('', mru_list)
    endif

    " Remove the dummy menu entry
    unmenu &File.&Recent\ Files.Dummy

    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions
endfunction

" Load the MRU list on plugin startup
call s:MRU_LoadList()

" MRU autocommands {{{1
" Autocommands to detect the most recently used files
autocmd BufRead * call s:MRU_AddFile(expand('<abuf>'))
autocmd BufNewFile * call s:MRU_AddFile(expand('<abuf>'))
autocmd BufWritePost * call s:MRU_AddFile(expand('<abuf>'))

" The ':vimgrep' command adds all the files searched to the buffer list.
" This also modifies the MRU list, even though the user didn't edit the
" files. Use the following autocmds to prevent this.
autocmd QuickFixCmdPre *vimgrep* let s:mru_list_locked = 1
autocmd QuickFixCmdPost *vimgrep* let s:mru_list_locked = 0

" Command to open the MRU window
command! -nargs=? -complete=customlist,s:MRU_Complete MRU
            \ call s:MRU_Cmd(<q-args>)
command! -nargs=? -complete=customlist,s:MRU_Complete Mru
            \ call s:MRU_Cmd(<q-args>)

" }}}

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

" vim:set foldenable foldmethod=marker:
