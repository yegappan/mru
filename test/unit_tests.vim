" MRU plugin unit-tests

" MRU plugin settings
let MRU_File='vim_mru_file'
let MRU_Auto_Close=1
let MRU_Max_Entries=10
let MRU_buffer_name = '__MRU_Files__'

" Function to log test results
function! LogResult(test, result)
    redir >> results.txt
        silent echon "\r" . a:test . ': ' . a:result . "\n"
    redir END
endfunction

" Set the following variable to 1, to profile the MRU plugin
let s:do_profile=0

" Profile the MRU plugin
if s:do_profile
    profile start mru_profile.txt
    profile! file */mru.vim
endif

runtime plugin/mru.vim

" Create the files used by the tests
call writefile(['MRU test file1'], 'file1.txt')
call writefile(['MRU test file2'], 'file2.txt')
call writefile(['MRU test file3'], 'file3.txt')

call writefile(['#include <stdio.h', 'int main(){}'], 'abc.c')
call writefile(['#include <stdlib.h', 'int main(){}'], 'def.c')

" Remove the results from the previous test runs
call delete('results.txt')
call delete(MRU_File)

" ==========================================================================
" Test1
" When the MRU list is empty, invoking the MRU command should return an error
" ==========================================================================
let test_name = 'test1'

redir => msg
MRU
redir END
if msg =~# "MRU file list is empty"
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test2
" Open the MRU window and check the order of files listed in the window
" Open the MRU window when the window is already opened.
" ==========================================================================
let test_name = 'test2'

edit file1.txt
edit file2.txt
edit file3.txt
edit file2.txt
edit file1.txt

MRU
MRU

let l = getline(1, "$")
if l[0] =~# "file1.txt" && l[1] =~# "file2.txt" && l[2] =~# "file3.txt"
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test3
" Select a file from the MRU window and check whether it is opened
" ==========================================================================
let test_name = 'test3'

" Go to the last but one line
$

" Select the last file in the MRU window
exe "normal \<Enter>"

if fnamemodify(bufname('%'), ':p:t') !=# 'file3.txt'
    call LogResult(test_name, "FAIL (1)")
else
    " Make sure the MRU window is closed
    if bufwinnr(g:MRU_buffer_name) == -1
        call LogResult(test_name, 'pass')
    else
        call LogResult(test_name, "FAIL (2)")
    endif
endif

" ==========================================================================
" Test4
" MRU opens a selected file in the previous/last window
" ==========================================================================
let test_name = 'test4'

" Edit a file and then open a new window, open the MRU window and select the
" file
split file1.txt
only
below new

MRU
call search('file2.txt')
exe "normal \<Enter>"

if winnr() == 2
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test5
" MRU opens a selected file in the same window if the file is already opened
" ==========================================================================
let test_name = 'test5'

edit file1.txt
only
below split file2.txt
below split file3.txt

MRU
call search('file1.txt')
exe "normal \<Enter>"

if winnr() != 1 || fnamemodify(bufname('%'), ':p:t') !=# 'file1.txt'
    call LogResult(test_name, "FAIL (1)")
else
    MRU
    call search('file2.txt')
    exe "normal \<Enter>"
    if winnr() != 2 || fnamemodify(bufname('%'), ':p:t') !=# 'file2.txt'
        call LogResult(test_name, "FAIL (2)")
    else
        MRU
        call search('file3.txt')
        exe "normal \<Enter>"
        if winnr() != 3 || fnamemodify(bufname('%'), ':p:t') !=# 'file3.txt'
            call LogResult(test_name, "FAIL (3)")
        else
            call LogResult(test_name, 'pass')
        endif
    endif
endif

" ==========================================================================
" Test6
" MRU opens a file selected with 'o' command in a new window
" ==========================================================================
let test_name = 'test6'
enew | only

edit file1.txt
below new

MRU
normal o

if winnr() == 3 && fnamemodify(bufname('%'), ':p:t') ==# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test7
" MRU opens the selected file in a new window if the previous buffer is
" modified. 
" ==========================================================================
let test_name = 'test7'
enew | only

insert
MRU plugin test
.
MRU
call search('file3.txt')
exe "normal \<Enter>"
if winnr() == 1 && winnr('$') == 2 &&
            \ fnamemodify(bufname('%'), ':p:t') ==# 'file3.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" Discard changes in the new buffer
wincmd b
enew!
only

" ==========================================================================
" Test8
" MRU opens a file selected with 'v' command in read-only mode in the current
" window.
" ==========================================================================
let test_name = 'test8'
enew | only

MRU
call search('file1.txt')
normal v
let r1 = &readonly
MRU
call search('file2.txt')
exe "normal \<Enter>"
let r2 = &readonly
MRU
call search('file1.txt')
exe "normal \<Enter>"
let r3 = &readonly
if r1 == 1 && r2 == 0 && r3 == 0
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test9
" Use 'O' in the MRU window to open a file in a veritcally split window
" ==========================================================================
let test_name = 'test9'
enew | only

edit file1.txt
MRU
call search('file2.txt')
normal O
let b1 = bufname('%')
wincmd h
let b2 = bufname('%')
wincmd l
let b3 = bufname('%')
if winnr('$') == 2 && b1 ==# 'file2.txt' && 
            \ b2 ==# 'file1.txt' && b3 ==# 'file2.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test10
" Use 'p' in the MRU window to open a file in the preview window
" ==========================================================================
let test_name = 'test10'
enew | only

MRU
call search('file3.txt')
normal p
wincmd P
let p1 = &previewwindow
let b1 = bufname('%')
if winnr('$') == 2 && &previewwindow && bufname('%') =~# 'file3.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif
pclose

" ==========================================================================
" Test11
" MRU opens a file selected with 't' command in a new tab and the tab
" is opened at the end
" ==========================================================================
let test_name = 'test11'
enew | only

tabnew
tabnew
tabnew
tabfirst
MRU
call search('file3.txt')
normal t
if fnamemodify(bufname('%'), ':p:t') ==# 'file3.txt' && tabpagenr() == 5
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
    call LogResult(test_name, "file = " . fnamemodify(bufname('%'), ':p:t'))
    call LogResult(test_name, "tab page = " . tabpagenr())
endif

tabonly

" ==========================================================================
" Test12
" The 'q' command closes the MRU window
" ==========================================================================
let test_name = 'test12'
enew | only

MRU
normal q
if bufwinnr(g:MRU_buffer_name) == -1
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test13
" A selected file is opened in a new window if the previous window is a
" preview window
" ==========================================================================
let test_name = 'test13'
enew | only

setlocal previewwindow
MRU
call search('file2.txt')
exe "normal \<Enter>"
if winnr() == 1 && winnr('$') == 2 &&
            \ &previewwindow == 0 &&
            \ fnamemodify(bufname('%'), ':p:t') ==# 'file2.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" Close the preview window created by this test
new
only

" ==========================================================================
" Test14
" A selected file is opened in a new window if the previous window contains
" a special buffer (used by some other plugin)
" ==========================================================================
let test_name = 'test14'
enew | only

setlocal buftype=nofile
MRU
call search('file3.txt')
exe "normal \<Enter>"
if winnr() == 1 && winnr('$') == 2 &&
            \ &buftype == '' &&
            \ fnamemodify(bufname('%'), ':p:t') ==# 'file3.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" Discard the special buffer
enew

" ==========================================================================
" Test15
" If a file selected using the 't' command is already opened in a tab,
" then jump to that tab (instead of opening a new tab)
" ==========================================================================
let test_name = 'test15'
enew | only

" Open the test files in the middle window with empty windows at the top and
" bottom
edit file1.txt
above new
botright new
tabedit file2.txt
above new
botright new
tabedit file3.txt
above new
botright new
tabfirst

MRU
call search('file3.txt')
exe "normal t"
if tabpagenr() != 3
            \ || fnamemodify(bufname('%'), ':p:t') !=# 'file3.txt'
            \ || winnr() != 2
    call LogResult(test_name, "FAIL (1)")
else
    MRU
    call search('file1.txt')
    exe "normal t"
    if tabpagenr() != 1
                \ || fnamemodify(bufname('%'), ':p:t') !=# 'file1.txt'
                \ || winnr() != 2
        call LogResult(test_name, "FAIL (2)")
    else
        MRU
        call search('file2.txt')
        exe "normal t"
        if tabpagenr() != 2
                    \ || fnamemodify(bufname('%'), ':p:t') !=# 'file2.txt'
                    \ || winnr() != 2
            call LogResult(test_name, "FAIL (3)")
        else
            call LogResult(test_name, 'pass')
        endif
    endif
endif

" Close all the other tabs
tabonly
enew
only

" ==========================================================================
" Test16
" Open multiple files from the MRU window using the visual mode and by using a
" count.  Each file should be opened in a separate window.
" ==========================================================================
let test_name = 'test16'
enew | only

edit file3.txt
edit file2.txt
edit file1.txt
enew
MRU
exe "normal 3\<Enter>"
if winnr('$') == 3 &&
            \ bufwinnr('file3.txt') == 1 &&
            \ bufwinnr('file2.txt') == 2 &&
            \ bufwinnr('file1.txt') == 3
    let test_result = 'pass'
else
    let test_result = 'FAIL'
endif

only | enew

if test_result == 'pass'
    MRU
    exe "normal V2j\<Enter>"
    if winnr('$') == 3 &&
                \ bufwinnr('file1.txt') == 1 &&
                \ bufwinnr('file2.txt') == 2 &&
                \ bufwinnr('file3.txt') == 3
        let test_result = 'pass'
    else
        let test_result = 'FAIL'
    endif
endif

if test_result == 'pass'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test17
" When the MRU list is updated, the MRU file also should updated.
" ==========================================================================
let test_name = 'test17'
enew | only

edit file1.txt
let l = readfile(g:MRU_File)
if l[1] =~# 'file1.txt'
    edit file2.txt
    let l = readfile(g:MRU_File)
    if l[1] =~# 'file2.txt'
        edit file3.txt
        let l = readfile(g:MRU_File)
        if l[1] =~# 'file3.txt'
            call LogResult(test_name, 'pass')
        else
            call LogResult(test_name, "FAIL (3)")
        endif
    else
        call LogResult(test_name, "FAIL (2)")
    endif
else
    call LogResult(test_name, "FAIL (1)")
endif

" MRU_Test_Add_Files
" Add the supplied List of files to the beginning of the MRU file
function! s:MRU_Test_Add_Files(fnames)
    let l = readfile(g:MRU_File)
    call extend(l, a:fnames, 1)
    call writefile(l, g:MRU_File)
endfunction

" ==========================================================================
" Test18
" When the MRU file is updated by another Vim instance, the MRU plugin
" should update the MRU list
" ==========================================================================
let test_name = 'test18'
enew | only

call s:MRU_Test_Add_Files(['/software/editors/vim',
            \ '/software/editors/emacs',
            \ '/software/editors/nano'])
MRU
if getline(1) ==# 'vim (/software/editors/vim)'
            \ && getline(2) ==# 'emacs (/software/editors/emacs)'
            \ && getline(3) ==# 'nano (/software/editors/nano)'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" Close the MRU window
close

" ==========================================================================
" Test19
" When the MRU file is updated by another Vim instance, the MRU file names
" from the current instance should be merged with that list
" ==========================================================================
let test_name = 'test19'
enew | only

" Remove all the files from the MRU file
let l = readfile(g:MRU_File)
call remove(l, 1, -1)
call writefile(l, g:MRU_File)
edit file1.txt
call s:MRU_Test_Add_Files(['/software/os/unix'])
edit file2.txt
call s:MRU_Test_Add_Files(['/software/os/windows'])
edit file3.txt
call s:MRU_Test_Add_Files(['/software/os/osx'])
MRU
if getline(1) ==# 'osx (/software/os/osx)'
            \ && getline(2) =~# 'file3.txt'
            \ && getline(3) ==# 'windows (/software/os/windows)'
            \ && getline(4) =~# 'file2.txt'
            \ && getline(5) ==# 'unix (/software/os/unix)'
            \ && getline(6) =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif
close

" ==========================================================================
" Test20
" When the MRU list has more than g:MRU_Max_Entries, the list should be
" trimmed. The last entries should be removed.
" ==========================================================================
let test_name = 'test20'
enew | only

"  Create a MRU list with MRU_Max_Entries
let flist = []
for i in range(1, g:MRU_Max_Entries)
    let flist += ['/usr/share/mru_test/mru_file' . i . '.abc']
endfor

" Modify the MRU file to contain max entries
let l = readfile(g:MRU_File)
call remove(l, 1, -1)
call extend(l, flist)
call writefile(l, g:MRU_File)

enew
edit file1.txt
let l = readfile(g:MRU_File)
if len(l) == (g:MRU_Max_Entries + 1) &&
            \ l[g:MRU_Max_Entries] != '/usr/share/mru_test/mru_file9.abc'
    call LogResult(test_name, "FAIL (1)")
else
    edit file2.txt
    let l = readfile(g:MRU_File)
    if len(l) == (g:MRU_Max_Entries + 1) &&
                \ l[g:MRU_Max_Entries] != '/usr/share/mru_test/mru_file8.abc'
        call LogResult(test_name, "FAIL (2)")
    else
        edit file3.txt
        let l = readfile(g:MRU_File)
        if len(l) == (g:MRU_Max_Entries + 1) &&
                \ l[g:MRU_Max_Entries] != '/usr/share/mru_test/mru_file7.abc'
            call LogResult(test_name, "FAIL (3)")
        else
            call LogResult(test_name, 'pass')
        endif
    endif
endif

" ==========================================================================
" Test21
" When an filename (already present in the MRU list) is specified to the MRU
" command, it should edit the file.
" ==========================================================================
let test_name = 'test21'
enew | only

edit file1.txt
edit file2.txt
edit file3.txt
enew
MRU file2.txt
if fnamemodify(bufname('%'), ':p:t') ==# 'file2.txt' && winnr('$') == 1
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test22
" When a pattern (matching multiple filenames) is specified to the MRU
" command, then the MRU window should be opened with all the matching
" filenames
" ==========================================================================
let test_name = 'test22'
enew | only

edit file1.txt
edit file2.txt
edit file3.txt
only
MRU file.*
if bufname('%') != g:MRU_buffer_name
    call LogResult(test_name, 'FAIL')
else
    let l = getline(1, "$")
    if l[0] =~# "file3.txt" && l[1] =~# "file2.txt" && l[2] =~# "file1.txt"
        call LogResult(test_name, 'pass')
    else
        call LogResult(test_name, 'FAIL')
    endif
endif
close

" ==========================================================================
" Test23
" When a partial filename (matching multiple filenames) is specified to the
" MRU command, then the MRU window should be opened with all the matching
" filenames
" ==========================================================================
let test_name = 'test23'
enew | only

edit file1.txt
edit file2.txt
edit file3.txt
only
MRU file
if bufname('%') != g:MRU_buffer_name
    call LogResult(test_name, 'FAIL')
else
    let l = getline(1, "$")
    if l[0] =~# "file3.txt" && l[1] =~# "file2.txt" && l[2] =~# "file1.txt"
        call LogResult(test_name, 'pass')
    else
        call LogResult(test_name, 'FAIL')
    endif
endif
close

" ==========================================================================
" Test24
" When a non-existing filename is specified to the MRU command, an error
" message should be displayed.
" ==========================================================================
let test_name = 'test24'

redir => msg
MRU nonexistingfile.txt
redir END
if bufname('%') == g:MRU_buffer_name ||
            \ msg !~# "MRU file list doesn't contain files " .
                   \ "matching nonexistingfile.txt"
    call LogResult(test_name, 'FAIL')
else
    call LogResult(test_name, 'pass')
endif

" ==========================================================================
" Test25
" The MRU command should support filename completion. Supply a partial file
" name to the MRU command and complete the filenames.
" ==========================================================================
let test_name = 'test25'
enew | only

edit file1.txt
edit file2.txt
edit file3.txt
exe 'normal! :MRU file' . "\<C-A>" . "\<Home>let m='\<End>'\<CR>"
let fnames = split(m)
if fnames[1] =~# 'file3.txt' && fnames[2] =~# 'file2.txt' &&
            \ fnames[3] =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test26
" When trying to complete filenames for the MRU command without specifying
" any text should return the the entire MRU list.
" ==========================================================================
let test_name = 'test26'
enew | only

call delete(MRU_File)
edit file1.txt
edit file2.txt
edit file3.txt

exe 'normal! :MRU ' . "\<C-A>" . "\<Home>let m='\<End>'\<CR>"
let fnames = split(m)
if fnames[1] =~# 'file3.txt' && fnames[2] =~# 'file2.txt' &&
            \ fnames[3] =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test27
" When the current file/buffer has unsaved changes, MRU should open a selected
" file in a new window (if the 'hidden' option is not set)
" ==========================================================================
let test_name = 'test27'
enew | only

edit file1.txt
edit file2.txt
call append(line('$'), 'Temporary changes to buffer')
MRU
call search('file1.txt')
exe "normal \<Enter>"
if winnr() == 1 && winnr('$') == 2 &&
            \ fnamemodify(bufname('%'), ':p:t') ==# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

close
edit!

" ==========================================================================
" Test28
" When the current file/buffer has unsaved changes and the 'hidden' option is
" set, then MRU should open a selected file in the current  window
" ==========================================================================
let test_name = 'test28'
enew | only

edit file2.txt
edit file1.txt
call append(line('$'), 'Temporary changes to buffer')
set hidden

MRU
call search('file2.txt')
exe "normal \<Enter>"
if winnr('$') == 1 &&
            \ fnamemodify(bufname('%'), ':p:t') ==# 'file2.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

edit file1.txt
edit!
set nohidden

" ==========================================================================
" Test29
" Every edited file is added to the top of the MRU list. If a file is already
" present in the MRU list, then it is moved to the top of the list.
" ==========================================================================
let test_name = 'test29'
enew | only

edit file1.txt
let f1 = readfile(g:MRU_File, '', 2)
edit file2.txt
let f2 = readfile(g:MRU_File, '', 2)
edit file3.txt
let f3 = readfile(g:MRU_File, '', 2)
edit file1.txt
let f4 = readfile(g:MRU_File, '', 2)
if f1[1] =~# 'file1.txt' && f2[1] =~# 'file2.txt' && f3[1] =~# 'file3.txt' &&
            \ f4[1] =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test30
" Only file names matching the regular expression in the MRU_Include_Files
" variable should be added to the MRU list.
" ==========================================================================
let test_name = 'test30'
enew | only

edit file1.txt
let MRU_Include_Files='\.c'
edit abc.c
let f1 = readfile(g:MRU_File, '', 2)
edit file1.txt
let f2 = readfile(g:MRU_File, '', 2)
edit def.c
let f3 = readfile(g:MRU_File, '', 2)
if f1[1] =~# 'abc.c' && f2[1] =~# 'abc.c' && f3[1] =~# 'def.c'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif
let MRU_Include_Files=''

" ==========================================================================
" Test31
" File names matching the regular expression in the MRU_Exclude_Files
" variable should not be added to the MRU list.
" ==========================================================================
let test_name = 'test31'
enew | only

let MRU_Exclude_Files='\.txt'
edit abc.c
let f1 = readfile(g:MRU_File, '', 2)
edit file1.txt
edit file2.txt
edit file3.txt
let f2 = readfile(g:MRU_File, '', 2)
edit def.c
let f3 = readfile(g:MRU_File, '', 2)
let MRU_Exclude_Files=''
edit file1.txt
let f4 = readfile(g:MRU_File, '', 2)
if f1[1] =~# 'abc.c' && f2[1] =~# 'abc.c' && f3[1] =~# 'def.c' &&
            \ f4[1] =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test32
" If the MRU window is open, when adding a file name to the list, the MRU
" window should be refreshed.
" ==========================================================================
let test_name = 'test32'
enew | only

MRU
wincmd p
edit abc.c
wincmd p
let s1 = getline(1)
wincmd p
edit file1.txt
wincmd p
let s2 = getline(1)
close
if s1 =~# 'abc.c' && s2 =~# 'file1.txt'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" ==========================================================================
" Test33
" When MRU_Use_Current_Window is set, the MRU list should be displayed in
" the current window.
" Selecting a file from the MRU window should replace
" the MRU buffer with the selected file.
" ==========================================================================
let test_name = 'test33'
enew | only

edit file1.txt
let MRU_Use_Current_Window=1
MRU
if winnr('$') == 1 && bufname('%') == g:MRU_buffer_name
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif
let MRU_Use_Current_Window=0

" ==========================================================================
" Test34
" When MRU_Use_Current_Window is set, selecting a file from the MRU window
" should replace the MRU buffer with the selected file.
" ==========================================================================
let test_name = 'test34'
enew | only

let MRU_Use_Current_Window=1
let w:marker=1
MRU
if winnr('$') == 1 && w:marker && bufname('%') == g:MRU_buffer_name
    call search('file2.txt')
    exe "normal \<Enter>"
    if winnr('$') == 1 && w:marker && bufname('%') == 'file2.txt'
        call LogResult(test_name, 'pass')
    else
        call LogResult(test_name, 'FAIL')
    endif
else
    call LogResult(test_name, 'FAIL')
endif
unlet w:marker
let MRU_Use_Current_Window=0

" ==========================================================================
" Test35
" When MRU_Auto_Close is not set, the MRU window should not automatically
" close when a file is selected. The MRU window should be kept open.
" ==========================================================================
let test_name = 'test35'
enew | only

let MRU_Auto_Close=0
new
MRU
call search('file1.txt')
exe "normal \<Enter>"
2wincmd w
MRU
call search('file2.txt')
exe "normal \<Enter>"
if winnr('$') == 3 &&
            \ bufwinnr('file1.txt') == 1 &&
            \ bufwinnr('file2.txt') == 2 &&
            \ bufwinnr(g:MRU_buffer_name) == 3
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

wincmd b
close
let MRU_Auto_Close=1
only

" ==========================================================================
" Test36
" When MRU_Open_File_Use_Tabs is set, a selected file should be opened in a
" tab. If the file is already opened in a tab, then the focus should be moved
" to that tab.
" ==========================================================================
let test_name = 'test36'
enew | only

let MRU_Open_File_Use_Tabs=1
edit file1.txt
MRU
call search('file2.txt')
exe "normal \<Enter>"
MRU
call search('file3.txt')
exe "normal \<Enter>"
MRU file1.txt
let t1 = tabpagenr()
MRU
call search('file2.txt')
exe "normal \<Enter>"
let t2 = tabpagenr()
MRU
call search('file3.txt')
exe "normal \<Enter>"
let t3 = tabpagenr()

tabonly | enew

if t1 == 1 && t2 == 2 && t3 == 3
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

let MRU_Open_File_Use_Tabs=0

" ==========================================================================
" Test37
" If the MRU_Window_Open_Always is set to 0, when the MRU command finds a
" single matching file name, then it should open the MRU window. If this
" variable is set to 1, then the file should be opened without opening the MRU
" window.
" ==========================================================================
let test_name = 'test37'
enew | only

edit file3.txt
enew

let MRU_Window_Open_Always=1
MRU file3.txt
if winnr('$') == 2 &&
            \ bufwinnr(g:MRU_buffer_name) == 2
    let test_result = 'pass'
else
    let test_result = 'FAIL'
endif
close

enew | only

if test_result == 'pass'
    let MRU_Window_Open_Always=0
    MRU file3.txt
    if winnr('$') == 1 &&
                \ bufwinnr('file3.txt') == 1
        let test_result = 'pass'
    else
        let test_result = 'FAIL'
    endif
endif

let MRU_Window_Open_Always=0

if test_result == 'pass'
    call LogResult(test_name, 'pass')
else
    call LogResult(test_name, 'FAIL')
endif

" TODO:
" 1. When the MRU list is modified, the MRU menu should be refreshed.
" 2. Lock and Unlock the MRU list.
" 3. Try to jump to an already open file from the MRU window and using the
"     MRU command.
" 4. Open an existing file but not present in the MRU list using the MRU command
" 5. Split open a file in readonly mode.

" Cleanup the files used by the tests
call delete('file1.txt')
call delete('file2.txt')
call delete('file3.txt')
call delete('abc.c')
call delete('def.c')
call delete(MRU_File)

" End of unit test execution
qall
