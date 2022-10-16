" MRU plugin unit-tests

" MRU plugin settings
let MRU_File='vim_mru_file'
let MRU_Auto_Close=1
let MRU_Max_Entries=10
let MRU_buffer_name = '-RecentFiles-'

" Set the $MRU_PROFILE environment variable to profile the MRU plugin
let s:do_profile = 0
if exists('$MRU_PROFILE')
  let s:do_profile = 1
endif

" Profile the MRU plugin
if s:do_profile
  profile start mru_profile.txt
  profile! file */mru.vim
endif

" Tests assume that 'hidden' option is not set
set nohidden

source ../plugin/mru.vim

let s:builtin_assert = 0
if exists('*assert_match')
  " Vim supports builtin assert_xxx() functions
  let s:builtin_assert = 1
endif

" Function to log test results
func! LogResult(test, result)
  call add(g:results, a:test . ': ' . a:result)
endfunc

let s:errors = []

func! MRU_assert_compare(match, expected, actual, msg)
  if a:match
    let passed = a:actual =~# a:expected
  else
    let passed = a:actual ==# a:expected
  endif
  if !passed
    let t = ''
    if msg != ''
      let t = msg . ': '
    endif
    if a:match
      let t = t . 'Pattern ' . string(a:expected) . ' does not match ' .
            \ string(a:actual)
    else
      let t = t . 'Expected ' . string(a:expected) . ', but got ' .
            \ string(a:actual)
    endif
    call add(s:errors, t)
  endif
endfunc

func! MRU_assert_equal(expected, actual, ...)
  let msg = ''
  if a:0 == 1
    let msg = a:1
  endif
  call MRU_assert_compare(0, a:expected, a:actual, msg)
endfunc

func! MRU_assert_match(expected, actual, ...)
  let msg = ''
  if a:0 == 1
    let msg = a:1
  endif
  call MRU_assert_compare(1, a:expected, a:actual, msg)
endfunc

func! MRU_assert_true(result, ...)
  let msg = ''
  if a:0 == 1
    let msg = a:1
  endif
  if !a:result
    let t = ''
    if msg != ''
      let t = msg . ': '
    endif
    let t = t . "Expected 'True' but got " . string(a:result)
    call add(s:errors, t)
  endif
endfunc

if s:builtin_assert
  " Vim has support for the assert_xxx() functions
  let s:Assert_equal = function('assert_equal')
  let s:Assert_match = function('assert_match')
  let s:Assert_true = function('assert_true')
else
  " Vim doesn't have support for the assert_xxx() functions
  let s:Assert_equal = function('MRU_assert_equal')
  let s:Assert_match = function('MRU_assert_match')
  let s:Assert_true = function('MRU_assert_true')
endif

" ==========================================================================
" Test1
" When the MRU list is empty, invoking the MRU command should return an error
" ==========================================================================
func Test_01()
  redir => msg
  MRU
  redir END

  call s:Assert_match('MRU file list is empty', msg)
endfunc

" ==========================================================================
" Test2
" Open the MRU window and check the order of files listed in the window
" Open the MRU window when the window is already opened.
" ==========================================================================
func Test_02()
  edit file1.txt
  edit file2.txt
  edit file3.txt
  edit file2.txt
  edit file1.txt

  MRU
  MRU

  let l = getline(1, '$')
  call s:Assert_match('file1.txt', l[0])
  call s:Assert_match('file2.txt', l[1])
  call s:Assert_match('file3.txt', l[2])
endfunc

" ==========================================================================
" Test3
" Select a file from the MRU window and check whether it is opened
" ==========================================================================
func Test_03()
  " Go to the last but one line
  $

  " Select the last file in the MRU window
  exe "normal \<Enter>"

  call s:Assert_equal('file3.txt', expand('%:p:t'))

  " Make sure the MRU window is closed
  call s:Assert_equal(-1, bufwinnr(g:MRU_buffer_name))
endfunc

" ==========================================================================
" Test4
" MRU opens a selected file in the previous/last window
" ==========================================================================
func Test_04()
  " Edit a file and then open a new window, open the MRU window and select the
  " file
  split file1.txt
  only
  below new

  MRU
  call search('file2.txt')
  exe "normal \<Enter>"

  call s:Assert_equal(2, winnr())
  close
endfunc

" ==========================================================================
" Test5
" MRU opens a selected file in the same window if the file is already opened
" ==========================================================================
func Test_05()
  edit file1.txt
  only
  below split file2.txt
  below split file3.txt

  MRU
  call search('file1.txt')
  exe "normal \<Enter>"

  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file1.txt', expand('%:p:t'))

  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(2, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))

  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(3, winnr())
  call s:Assert_equal('file3.txt', expand('%:p:t'))
endfunc

" ==========================================================================
" Test6
" MRU opens a file selected with 'o' command in a new window
" ==========================================================================
func Test_06()
  enew | only

  edit file1.txt
  below new

  MRU
  normal o

  call s:Assert_equal(3, winnr())
  call s:Assert_equal('file1.txt', expand('%:p:t'))
endfunc

" ==========================================================================
" Test7
" MRU opens the selected file in a new window if the previous buffer is
" modified.
" ==========================================================================
func Test_07()
  enew | only

  call setline(1, ['MRU plugin test'])
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr())
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal('file3.txt', expand('%:p:t'))

  " Discard changes in the new buffer
  wincmd b
  enew!
  only
endfunc

" ==========================================================================
" Test8
" MRU opens a file selected with 'v' command in read-only mode in the current
" window.
" ==========================================================================
func Test_08()
  enew | only

  MRU
  call search('file1.txt')
  normal v
  call s:Assert_true(&readonly)
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_true(!&readonly)
  MRU
  call search('file1.txt')
  exe "normal \<Enter>"
  call s:Assert_true(&readonly)
endfunc

" ==========================================================================
" Test9
" Use 'O' in the MRU window to open a file in a vertically split window
" ==========================================================================
func Test_09()
  enew | only

  edit file1.txt
  MRU
  call search('file2.txt')
  normal O
  call s:Assert_equal('file2.txt', @%)
  wincmd h
  call s:Assert_equal('file1.txt', @%)
  wincmd l
  call s:Assert_equal('file2.txt', @%)
  call s:Assert_equal(2, winnr('$'))
endfunc

" ==========================================================================
" Test10
" Use 'p' in the MRU window to open a file in the preview window
" ==========================================================================
func Test_10()
  enew | only

  MRU
  call search('file3.txt')
  normal p
  wincmd P
  let p1 = &previewwindow
  let b1 = @%
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_true(&previewwindow)
  call s:Assert_match('file3.txt', @%)
  pclose
endfunc

" ==========================================================================
" Test11
" MRU opens a file selected with 't' command in a new tab and the tab
" is opened at the end
" ==========================================================================
func Test_11()
  enew | only

  edit a1.txt
  tabnew a2.txt
  tabnew a3.txt
  tabnew a4.txt
  tabfirst
  MRU
  call search('file3.txt')
  normal t
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  call s:Assert_equal(5, tabpagenr())

  tabonly
endfunc

" ==========================================================================
" Test12
" The 'q' command closes the MRU window
" ==========================================================================
func Test_12()
  enew | only

  MRU
  normal q
  call s:Assert_equal(-1, bufwinnr(g:MRU_buffer_name))
endfunc

" ==========================================================================
" Test13
" A selected file is opened in a new window if the previous window is a
" preview window
" ==========================================================================
func Test_13()
  enew | only

  setlocal previewwindow
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr())
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_true(!&previewwindow)
  call s:Assert_equal('file2.txt', expand('%:p:t'))

  " Close the preview window created by this test
  new
  only
endfunc

" ==========================================================================
" Test14
" A selected file is opened in a new window if the previous window contains
" a special buffer (used by some other plugin)
" ==========================================================================
func Test_14()
  enew | only

  setlocal buftype=nofile
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr())
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal('', &buftype)
  call s:Assert_equal('file3.txt', expand('%:p:t'))

  " Discard the special buffer
  enew
endfunc

" ==========================================================================
" Test15
" If a file selected using the 't' command is already opened in a tab,
" then jump to that tab (instead of opening a new tab)
" ==========================================================================
func Test_15()
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
  exe 'normal t'
  call s:Assert_equal(3, tabpagenr())
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  call s:Assert_equal(2, winnr())

  MRU
  call search('file1.txt')
  exe 'normal t'
  call s:Assert_equal(1, tabpagenr())
  call s:Assert_equal('file1.txt', expand('%:p:t'))
  call s:Assert_equal(2, winnr())

  MRU
  call search('file2.txt')
  exe 'normal t'
  call s:Assert_equal(2, tabpagenr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  call s:Assert_equal(2, winnr())

  " Close all the other tabs
  tabonly
  enew
  only
endfunc

" ==========================================================================
" Test16
" Open multiple files from the MRU window using the visual mode and by using a
" count.  Each file should be opened in a separate window.
" ==========================================================================
func Test_16()
  enew | only

  edit file3.txt
  edit file2.txt
  edit file1.txt
  enew
  MRU
  exe "normal 3\<Enter>"
  call s:Assert_equal(3, winnr('$'))
  call s:Assert_equal(1, bufwinnr('file3.txt'))
  call s:Assert_equal(2, bufwinnr('file2.txt'))
  call s:Assert_equal(3, bufwinnr('file1.txt'))

  only | enew

  MRU
  exe "normal V2j\<Enter>"
  call s:Assert_equal(3, winnr('$'))
  call s:Assert_equal(1, bufwinnr('file1.txt'))
  call s:Assert_equal(2, bufwinnr('file2.txt'))
  call s:Assert_equal(3, bufwinnr('file3.txt'))
endfunc

" ==========================================================================
" Test17
" When the MRU list is updated, the MRU file also should updated.
" ==========================================================================
func Test_17()
  enew | only

  edit file1.txt
  let l = readfile(g:MRU_File)
  call s:Assert_match('file1.txt', l[1])

  edit file2.txt
  let l = readfile(g:MRU_File)
  call s:Assert_match('file2.txt', l[1])

  edit file3.txt
  let l = readfile(g:MRU_File)
  call s:Assert_match('file3.txt', l[1])
endfunc

" MRU_Test_Add_Files
" Add the supplied List of files to the beginning of the MRU file
func! s:MRU_Test_Add_Files(fnames)
  let l = readfile(g:MRU_File)
  call extend(l, a:fnames, 1)
  call writefile(l, g:MRU_File)
endfunc

" ==========================================================================
" Test18
" When the MRU file is updated by another Vim instance, the MRU plugin
" should update the MRU list
" ==========================================================================
func Test_18()
  enew | only

  call s:MRU_Test_Add_Files(['/software/editors/vim',
        \ '/software/editors/emacs',
        \ '/software/editors/nano'])
  MRU
  call s:Assert_equal('vim (/software/editors/vim)', getline(1))
  call s:Assert_equal('emacs (/software/editors/emacs)', getline(2))
  call s:Assert_equal('nano (/software/editors/nano)', getline(3))

  " Close the MRU window
  close
endfunc

" ==========================================================================
" Test19
" When the MRU file is updated by another Vim instance, the MRU file names
" from the current instance should be merged with that list
" ==========================================================================
func Test_19()
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
  call s:Assert_equal('osx (/software/os/osx)', getline(1))
  call s:Assert_match('file3.txt', getline(2))
  call s:Assert_equal('windows (/software/os/windows)', getline(3))
  call s:Assert_match('file2.txt', getline(4))
  call s:Assert_equal('unix (/software/os/unix)', getline(5))
  call s:Assert_match('file1.txt', getline(6))
  close
endfunc

" ==========================================================================
" Test20
" When the MRU list has more than g:MRU_Max_Entries, the list should be
" trimmed. The last entries should be removed.
" ==========================================================================
func Test_20()
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
  call s:Assert_equal((g:MRU_Max_Entries + 1), len(l))
  call s:Assert_equal('/usr/share/mru_test/mru_file9.abc',
        \ l[g:MRU_Max_Entries])

  edit file2.txt
  let l = readfile(g:MRU_File)
  call s:Assert_equal((g:MRU_Max_Entries + 1), len(l))
  call s:Assert_equal('/usr/share/mru_test/mru_file8.abc',
        \ l[g:MRU_Max_Entries])

  edit file3.txt
  let l = readfile(g:MRU_File)
  call s:Assert_equal((g:MRU_Max_Entries + 1), len(l))
  call s:Assert_equal('/usr/share/mru_test/mru_file7.abc',
        \ l[g:MRU_Max_Entries])
endfunc

" ==========================================================================
" Test21
" When an filename (already present in the MRU list) is specified to the MRU
" command, it should edit the file.
" ==========================================================================
func Test_21()
  enew | only
  edit file1.txt
  edit file2.txt
  edit file3.txt
  enew
  MRU file2.txt
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  call s:Assert_equal(1, winnr('$'))
endfunc

" ==========================================================================
" Test22
" When a pattern (matching multiple filenames) is specified to the MRU
" command, then the MRU window should be opened with all the matching
" filenames
" ==========================================================================
func Test_22()
  enew | only
  edit file1.txt
  edit file2.txt
  edit file3.txt
  only
  MRU file.*
  call s:Assert_equal(g:MRU_buffer_name, @%)

  let l = getline(1, '$')
  call s:Assert_match('file3.txt', l[0])
  call s:Assert_match('file2.txt', l[1])
  call s:Assert_match('file1.txt', l[2])
  close
endfunc

" ==========================================================================
" Test23
" When a partial filename (matching multiple filenames) is specified to the
" MRU command, then the MRU window should be opened with all the matching
" filenames
" ==========================================================================
func Test_23()
  enew | only
  let g:MRU_FuzzyMatch = 0
  edit file1.txt
  edit file2.txt
  edit file3.txt
  only
  MRU file
  call s:Assert_equal(g:MRU_buffer_name, @%)
  let l = getline(1, '$')
  call s:Assert_match('file3.txt' , l[0])
  call s:Assert_match('file2.txt' , l[1])
  call s:Assert_match('file1.txt' , l[2])
  close
endfunc

" ==========================================================================
" Test24
" When a non-existing filename is specified to the MRU command, an error
" message should be displayed.
" ==========================================================================
func Test_24()
  let g:MRU_FuzzyMatch = 0
  redir => msg
  MRU nonexistingfile.txt
  redir END
  call s:Assert_true(g:MRU_buffer_name !=? @%)
  call s:Assert_match("MRU file list doesn't contain files " .
        \ 'matching nonexistingfile.txt', msg)
endfunc

" ==========================================================================
" Test25
" The MRU command should support filename completion. Supply a partial file
" name to the MRU command and complete the filenames.
" ==========================================================================
func Test_25()
  enew | only
  edit file1.txt
  edit file2.txt
  edit file3.txt
  exe 'normal! :MRU file' . "\<C-A>" . "\<Home>let m='\<End>'\<CR>"
  let fnames = split(m)
  call s:Assert_match('file3.txt', fnames[1])
  call s:Assert_match('file2.txt', fnames[2])
  call s:Assert_match('file1.txt', fnames[3])
endfunc

" ==========================================================================
" Test26
" When trying to complete filenames for the MRU command without specifying
" any text should return the entire MRU list.
" ==========================================================================
func Test_26()
  enew | only
  call delete(g:MRU_File)
  edit file1.txt
  edit file2.txt
  edit file3.txt
  exe 'normal! :MRU ' . "\<C-A>" . "\<Home>let m='\<End>'\<CR>"
  let fnames = split(m)
  call s:Assert_match('file3.txt', fnames[1])
  call s:Assert_match('file2.txt', fnames[2])
  call s:Assert_match('file1.txt', fnames[3])
endfunc

" ==========================================================================
" Test27
" When the current file/buffer has unsaved changes, MRU should open a selected
" file in a new window (if the 'hidden' option is not set)
" ==========================================================================
func Test_27()
  enew | only
  edit file1.txt
  edit file2.txt
  call append(line('$'), 'Temporary changes to buffer')
  MRU
  call search('file1.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr())
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal('file1.txt', expand('%:p:t'))
  close
  edit!
endfunc

" ==========================================================================
" Test28
" When the current file/buffer has unsaved changes and the 'hidden' option is
" set, then MRU should open a selected file in the current  window
" ==========================================================================
func Test_28()
  enew | only
  edit file2.txt
  edit file1.txt
  call append(line('$'), 'Temporary changes to buffer')
  set hidden
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr('$'))
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  edit file1.txt
  edit!
  set nohidden
  %bw!
endfunc

" ==========================================================================
" Test29
" Every edited file is added to the top of the MRU list. If a file is already
" present in the MRU list, then it is moved to the top of the list.
" ==========================================================================
func Test_29()
  enew | only
  edit file1.txt
  let f1 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('file1.txt', f1[1])
  edit file2.txt
  let f2 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('file2.txt', f2[1])
  edit file3.txt
  let f3 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('file3.txt', f3[1])
  edit file1.txt
  let f4 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('file1.txt', f4[1])
endfunc

" ==========================================================================
" Test30
" Only file names matching the regular expression in the MRU_Include_Files
" variable should be added to the MRU list.
" ==========================================================================
func Test_30()
  enew | only
  edit file1.txt
  let g:MRU_Include_Files='\.c'
  edit abc.c
  let f1 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('abc.c', f1[1])
  edit file1.txt
  let f2 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('abc.c', f2[1])
  edit def.c
  let f3 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('def.c', f3[1])
  let g:MRU_Include_Files=''
endfunc

" ==========================================================================
" Test31
" File names matching the regular expression in the MRU_Exclude_Files
" variable should not be added to the MRU list.
" ==========================================================================
func Test_31()
  enew | only
  let g:MRU_Exclude_Files='\.txt'
  edit abc.c
  let f1 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('abc.c', f1[1])
  edit file1.txt
  edit file2.txt
  edit file3.txt
  let f2 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('abc.c', f2[1])
  edit def.c
  let f3 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('def.c', f3[1])
  let g:MRU_Exclude_Files=''
  edit file1.txt
  let f4 = readfile(g:MRU_File, '', 2)
  call s:Assert_match('file1.txt', f4[1])
endfunc

" ==========================================================================
" Test32
" If the MRU window is open, when adding a file name to the list, the MRU
" window should be refreshed.
" ==========================================================================
func Test_32()
  enew | only
  MRU
  wincmd p
  edit abc.c
  wincmd p
  let s1 = getline(1)
  call s:Assert_match('abc.c', s1)
  wincmd p
  edit file1.txt
  wincmd p
  let s2 = getline(1)
  call s:Assert_match('file1.txt', s2)
  close
endfunc

" ==========================================================================
" Test33
" When MRU_Use_Current_Window is set, the MRU list should be displayed in
" the current window.
" Selecting a file from the MRU window should replace
" the MRU buffer with the selected file.
" ==========================================================================
func Test_33()
  enew | only
  edit file1.txt
  let g:MRU_Use_Current_Window=1
  MRU
  call s:Assert_equal(1, winnr('$'))
  call s:Assert_equal(g:MRU_buffer_name, @%)
  let g:MRU_Use_Current_Window=0
endfunc

" ==========================================================================
" Test34
" When MRU_Use_Current_Window is set, selecting a file from the MRU window
" should replace the MRU buffer with the selected file.
" ==========================================================================
func Test_34()
  enew | only
  let g:MRU_Use_Current_Window=1
  let w:marker=1
  MRU
  call s:Assert_equal(1, winnr('$'))
  call s:Assert_equal(g:MRU_buffer_name, @%)
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(1, winnr('$'))
  call s:Assert_equal(1, w:marker)
  call s:Assert_equal('file2.txt', @%)
  unlet w:marker
  let g:MRU_Use_Current_Window=0
endfunc

" ==========================================================================
" Test35
" When MRU_Use_Current_Window is set, if the current buffer has unsaved
" changes, then the MRU window should be opened in a split window
" ==========================================================================
func Test_35()
  enew | only
  let g:MRU_Use_Current_Window=1
  set modified
  MRU
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(2, winnr())
  call s:Assert_equal(g:MRU_buffer_name, @%)
  close
  set nomodified
  let g:MRU_Use_Current_Window=0
  enew | only
endfunc

" ==========================================================================
" Test36
" When MRU_Auto_Close is not set, the MRU window should not automatically
" close when a file is selected. The MRU window should be kept open.
" ==========================================================================
func Test_36()
  enew | only
  let g:MRU_Auto_Close=0
  new
  MRU
  call search('file1.txt')
  exe "normal \<Enter>"
  2wincmd w
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(3, winnr('$'))
  call s:Assert_equal(1, bufwinnr('file1.txt'))
  call s:Assert_equal(2, bufwinnr('file2.txt'))
  call s:Assert_equal(3, bufwinnr(g:MRU_buffer_name))
  wincmd b
  close
  let g:MRU_Auto_Close=1
  only
endfunc

" ==========================================================================
" Test37
" When MRU_Open_File_Use_Tabs is set, a selected file should be opened in a
" tab. If the file is already opened in a tab, then the focus should be moved
" to that tab.
" ==========================================================================
func Test_37()
  enew | only
  let g:MRU_Open_File_Use_Tabs=1
  edit file1.txt
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  MRU file1.txt
  call s:Assert_equal(1, tabpagenr())
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(2, tabpagenr())
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal(3, tabpagenr())
  tabonly | enew
  let g:MRU_Open_File_Use_Tabs=0
endfunc

" ==========================================================================
" Test38
" If the MRU_Window_Open_Always is set to 0, when the MRU command finds a
" single matching file name, then it should open the MRU window. If this
" variable is set to 1, then the file should be opened without opening the MRU
" window.
" ==========================================================================
func Test_38()
  enew | only

  edit file3.txt
  enew
  let g:MRU_Window_Open_Always=1
  MRU file3.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(2, bufwinnr(g:MRU_buffer_name))
  close

  enew | only
  let g:MRU_Window_Open_Always=0
  MRU file3.txt
  call s:Assert_equal(1, winnr('$'))
  call s:Assert_equal(1, bufwinnr('file3.txt'))

  let g:MRU_Window_Open_Always=0
endfunc

" ==========================================================================
" Test39
" If the current tabpage is empty, then pressing 't' in the MRU window
" should open the file in the current tabpage.
" ==========================================================================
func Test_39()
  enew | only | tabonly
  tabnew
  tabnew
  tabnext 2
  MRU
  call search('file2.txt')
  normal t
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  call s:Assert_equal(2, tabpagenr())
  tabonly
endfunc

" ==========================================================================
" Test40
" Pressing 'd' in the MRU window should delete the file under the cursor
" from the MRU list
" ==========================================================================
func Test_40()
  edit file2.txt
  enew
  MRU
  call search('file2.txt')
  normal d
  close
  let l = readfile(g:MRU_File)
  call s:Assert_true(match(l, 'file2.txt') == -1)
endfunc

" ==========================================================================
" Test41
" Running the :vimgrep command should not add the files to the MRU list
" ==========================================================================
func Test_41()
  call writefile(['bright'], 'dummy1.txt')
  call writefile(['bright'], 'dummy2.txt')
  vimgrep /bright/j dummy*
  let l = readfile(g:MRU_File)
  call s:Assert_equal(-1, match(l, 'dummy'))
  call delete('dummy1.txt')
  call delete('dummy2.txt')
endfunc

" ==========================================================================
" Test42
" Using a command modifier with the MRU command to open the MRU window
" ==========================================================================
func Test_42()
  if v:version < 800
    " The <mods> command modifier is supported only by Vim 8.0 and above
    return
  endif
  enew | only
  topleft MRU
  call s:Assert_equal(1, winnr())
  call s:Assert_equal(2, winnr('$'))
  enew | only
  botright MRU
  call s:Assert_equal(2, winnr())
  call s:Assert_equal(2, winnr('$'))
  enew | only
  botright MRU
  call s:Assert_equal(2, winnr())
  call s:Assert_equal(2, winnr('$'))
  enew | only
endfunc

" ==========================================================================
" Test43
" Opening a file using the MRU command should jump to the window containing
" the file (if it is already opened).
" ==========================================================================
func Test_43()
  only
  edit file3.txt
  below split file2.txt
  below split file1.txt
  wincmd t
  MRU file1.txt
  call s:Assert_equal(3, winnr())
  call s:Assert_equal('file1.txt', expand('%:p:t'))
  MRU file2.txt
  call s:Assert_equal(2, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  MRU file3.txt
  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  enew | only
endfunc

" ==========================================================================
" Test44
" Opening a file using the MRU command should open the file in a new window if
" the current buffer has unsaved changes.
" ==========================================================================
func Test_44()
  only
  set modified
  MRU file2.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  close
  set nomodified
endfunc

" ==========================================================================
" Test45
" Opening a file from the MRU window using 'v' should open the file in a new
" window if the current buffer has unsaved changes.
" ==========================================================================
func Test_45()
  only
  set modified
  MRU
  call search('file3.txt')
  normal v
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  call s:Assert_true(&readonly)
  close
  set nomodified
endfunc

" ==========================================================================
" Test46
" Specify a count to the :MRU command to set the MRU window height/width
" ==========================================================================
func Test_46()
  only
  " default height is 8
  MRU
  call s:Assert_equal(2, winnr())
  call s:Assert_equal(8, winheight(0))
  close

  " use a specific height value
  15MRU
  call s:Assert_equal(2, winnr())
  call s:Assert_equal(15, winheight(0))
  close

  if v:version >= 800
    " use a specific height value with a command modifier
    topleft 12MRU
    call s:Assert_equal(1, winnr())
    call s:Assert_equal(12, winheight(0))
    close

    " check for the width (leftmost window)
    vertical topleft 20MRU
    call s:Assert_equal(1, winnr())
    call s:Assert_equal(20, winwidth(0))
    close

    " check for the width (rightmost window)
    vertical botright 25MRU
    call s:Assert_equal(2, winnr())
    call s:Assert_equal(25, winwidth(0))
    close
  endif
endfunc

" ==========================================================================
" Test47
" The height of the MRU window should be MRU_Window_Height
" ==========================================================================
func Test_47()
  only

  " default height is 8
  MRU
  call s:Assert_equal(8, winheight(0))
  close
  let g:MRU_Window_Height = 2
  MRU
  call s:Assert_equal(2, winheight(0))
  close
  let g:MRU_Window_Height = 12
  MRU
  call s:Assert_equal(12, winheight(0))
  close
  let g:MRU_Window_Height = 8
endfunc

" ==========================================================================
" Test48
" Fuzzy search file names with MRU_FuzzyMatch set to 1.
" ==========================================================================
func Test_48()
  if !exists('*matchfuzzy')
    return
  endif

  enew | only
  let g:MRU_FuzzyMatch = 1
  MRU F1
  call s:Assert_equal('file1.txt', expand('%:p:t'))
  call s:Assert_equal(1, winnr('$'))

  let g:MRU_FuzzyMatch = 0
  redir => msg
  MRU F1
  redir END
  call s:Assert_match("MRU file list doesn't contain files matching F1", msg)
  let g:MRU_FuzzyMatch = 1
endfunc

" ==========================================================================
" Test49
" Test for creating a new file by saving an unnamed buffer.
" ==========================================================================
func Test_49()
  enew | only
  call setline(1, 'sample file')
  write sample.txt
  let l = readfile(g:MRU_File)
  call s:Assert_true(match(l, 'sample.txt') != -1)
  call delete('sample.txt')
  bwipe sample.txt
endfunc

" ==========================================================================
" Test50
" Test for the MruGetFiles() function
" ==========================================================================
func Test_50()
  enew | only
  let list1 = MruGetFiles()
  let list2 = readfile(g:MRU_File)
  call s:Assert_equal(list2[1:], list1)
  call s:Assert_equal([], MruGetFiles('x1y2z3'))
endfunc

" ==========================================================================
" Test51
" Test for the :MruRefresh command
" ==========================================================================
func Test_51()
  enew | only
  call s:Assert_true(match(MruGetFiles(), 'sample.txt') != -1)
  MruRefresh
  call s:Assert_equal(-1, match(MruGetFiles(), 'sample.txt'))
endfunc

" ==========================================================================
" Test52
" Test for the re-opening a deleted buffer from the MRU list
" ==========================================================================
func Test_52()
  edit file1.txt
  edit file2.txt
  bd
  " select the file from the MRU window
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_true(&buflisted)
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  " open the file directly using the command
  bw file1.txt file2.txt
  edit file2.txt
  edit file1.txt
  bd
  MRU file1.txt
  call s:Assert_true(&buflisted)
  call s:Assert_equal('file1.txt', expand('%:p:t'))
endfunc

" ==========================================================================
" Test53
" Test for using a command modifier when directly opening a file using the
" MRU command.
" ==========================================================================
func Test_53()
  if v:version < 800
    return
  endif
  %bw!
  topleft MRU file2.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  wincmd j
  call s:Assert_equal(2, winnr())
  %bw
  belowright MRU file2.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(2, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  wincmd k
  call s:Assert_equal(1, winnr())
  %bw
  vertical topleft MRU file2.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(1, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  wincmd l
  call s:Assert_equal(2, winnr())
  %bw
  vertical belowright MRU file2.txt
  call s:Assert_equal(2, winnr('$'))
  call s:Assert_equal(2, winnr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  wincmd h
  call s:Assert_equal(1, winnr())
  %bw
  tab MRU file2.txt
  call s:Assert_equal(2, tabpagenr())
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  %bw
endfunc

" ==========================================================================
" Test54
" Test for the :MRUToggle command.
" ==========================================================================
func Test_54()
  only
  " open the MRU window
  MRUToggle
  call s:Assert_equal(2, bufwinnr(g:MRU_buffer_name))
  call s:Assert_equal(2, winnr())
  " close the MRU window
  MRUToggle
  call s:Assert_equal(-1, bufwinnr(g:MRU_buffer_name))
  call s:Assert_equal(1, winnr())
  " close the MRU window from some other window
  MRUToggle
  wincmd k
  MRUToggle
  call s:Assert_equal(-1, bufwinnr(g:MRU_buffer_name))
  call s:Assert_equal(1, winnr())
endfunc

" ==========================================================================
" Test55
" Editing a file selected from the MRU window should set the current file to
" be the alternate file.
" ==========================================================================
func Test_55()
  silent! bw file1.txt file2.txt file3.txt
  new
  edit file1.txt
  edit file2.txt
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  call s:Assert_equal('file2.txt', expand('#:p:t'))
endfunc

" ==========================================================================
" Test56
" With MRU_Use_Current_Window set to 1, editing a file from the MRU list
" should not change the alternate file.
" ==========================================================================
func Test_56()
  let g:MRU_Use_Current_Window = 1
  bw file1.txt file2.txt file3.txt
  new
  edit file3.txt
  edit file1.txt
  edit file2.txt
  MRU
  call search('file3.txt')
  exe "normal \<Enter>"
  call s:Assert_equal('file3.txt', expand('%:p:t'))
  call s:Assert_equal('file2.txt', expand('#:p:t'))
  " try viewing a file
  MRU
  call search('file1.txt')
  normal v
  call s:Assert_equal('file1.txt', expand('%:p:t'))
  call s:Assert_equal('file3.txt', expand('#:p:t'))
  call s:Assert_true(&readonly)
  " try opening a wiped out buffer
  bw file2.txt
  MRU
  call search('file2.txt')
  exe "normal \<Enter>"
  call s:Assert_equal('file2.txt', expand('%:p:t'))
  call s:Assert_equal('file1.txt', expand('#:p:t'))
  call s:Assert_true(!&readonly)
  let g:MRU_Use_Current_Window = 0
  bw!
endfunc

" ==========================================================================
" Test57
" When the MRU window is closed, the MRU buffer should be unloaded.
" If 'MRU_Use_Current_Window' is set, then the MRU buffer should be wiped out.
" ==========================================================================
func Test_57()
  MRU
  let mrubnum = bufnr('')
  close
  call s:Assert_true(!bufloaded(mrubnum))
  let g:MRU_Use_Current_Window = 1
  new
  edit Xfile
  MRU
  let mrubnum = bufnr('')
  edit #
  call s:Assert_true(!bufexists(mrubnum))
  call s:Assert_equal('Xfile', @%)
  let g:MRU_Use_Current_Window = 0
  bw!
endfunc

" ==========================================================================
" Test58
" When the MRU window is toggled with MRU_Use_Current_Window set to 1, the
" previous buffer should be loaded.
" ==========================================================================
func Test_58()
  let g:MRU_Use_Current_Window = 1
  new
  edit Xfile
  MRUToggle
  call s:Assert_equal(g:MRU_buffer_name, @%)
  call s:Assert_equal(2, winnr('$'))
  MRUToggle
  call s:Assert_equal('Xfile', @%)
  call s:Assert_equal(2, winnr('$'))
  let g:MRU_Use_Current_Window = 0
  bw!
endfunc

" ==========================================================================
" Test59
" When the MRU_Set_Alternate_File is set to 1, on plugin startup, the
" alternate file should be set to the first file in the MRU list.
" ==========================================================================
func Test_59()
  if v:version < 802
    return
  endif
  call writefile([], 'Xfirstfile')
  edit Xfirstfile
  call writefile([
        \ "let MRU_File='vim_mru_file'",
        \ 'let MRU_Set_Alternate_File=1',
        \ 'source ../plugin/mru.vim',
        \ "call writefile([@#], 'Xoutput')"
        \ ], 'Xscript')
  silent! !vim -u NONE --noplugin -i NONE -N -S Xscript -c "qa"
  call s:Assert_true(filereadable('Xoutput'))
  let lines = readfile('Xoutput')
  call s:Assert_true(1, len(lines))
  call s:Assert_match('Xfirstfile$', lines[0])
  call delete('Xscript')
  call delete('Xoutput')
  call delete('Xfirstfile')
endfunc

" ==========================================================================
" Test60
" With MRU_Use_Current_Window set to 1, MRU opens a selected file in the
" current window, even when the file is already open in another window
" ==========================================================================
func Test_60()
  let g:MRU_Use_Current_Window = 1

  edit file1.txt
  let bnum = bufnr('')
  only
  below split file2.txt

  MRU
  call search('file1.txt')
  exe "normal \<Enter>"

  call s:Assert_equal(2, winnr())
  call s:Assert_equal(bnum, winbufnr(1))
  call s:Assert_equal(bnum, winbufnr(2))

  let g:MRU_Use_Current_Window = 0
endfunc

" ==========================================================================
" Test61
" The :MRU command should do case-insensitive file name comparison
" Works only in Unix-like systems.
" ==========================================================================
func Test_61()
  if !has('unix')
    return
  endif

  let l = readfile(g:MRU_File)
  call remove(l, 1, -1)
  call writefile(l, g:MRU_File)
  call s:MRU_Test_Add_Files(['/my/home/my1298file',
        \ '/my/home/mY1298fIlE', '/my/home/MY1298FILE', '/my/home/My1298File'])

  let expected = [
        \ 'my1298file (/my/home/my1298file)',
        \ 'mY1298fIlE (/my/home/mY1298fIlE)',
        \ 'MY1298FILE (/my/home/MY1298FILE)',
        \ 'My1298File (/my/home/My1298File)'
        \ ]

  let g:MRU_FuzzyMatch = 0

  try
    for p in ['my12', 'mY1298', 'MY1298', 'My1298File']
      exe 'MRU ' . p
      let lines = getline(1, '$')
      call s:Assert_equal(expected, lines, p)
      close
    endfor
  finally
    let g:MRU_FuzzyMatch = 1
  endtry
endfunc

" ==========================================================================
" Test62
" When using fuzzy match, the order of the file names in the MRU list should
" be maintained in the returned list.
" Works only in Unix-like systems.
" ==========================================================================
func Test_62()
  if !has('unix') || !exists('*matchfuzzy')
    return
  endif

  let l = readfile(g:MRU_File)
  call remove(l, 1, -1)
  call writefile(l, g:MRU_File)
  call s:MRU_Test_Add_Files(['a111b222c', 'a11b22c', 'abc123', 'a1b2c'])

  " Test for command-line expansion
  exe 'normal! :MRU abc' . "\<C-A>\<Home>let m='\<End>'\<CR>"
  call s:Assert_equal('MRU a111b222c a11b22c abc123 a1b2c', m)

  " Test for MruGetFiles()
  let l = MruGetFiles('abc')
  call s:Assert_equal(['a111b222c', 'a11b22c', 'abc123', 'a1b2c'], l)

  " Test for MRU window
  MRU abc
  let l = getline(1, '$')
  call s:Assert_match('a111b222c', l[0])
  call s:Assert_match('a11b22c', l[1])
  call s:Assert_match('abc123', l[2])
  call s:Assert_match('a1b2c', l[3])
  close
endfunc

" ==========================================================================

" Create the files used by the tests
call writefile(['MRU test file1'], 'file1.txt')
call writefile(['MRU test file2'], 'file2.txt')
call writefile(['MRU test file3'], 'file3.txt')

call writefile(['#include <stdio.h', 'int main(){}'], 'abc.c')
call writefile(['#include <stdlib.h', 'int main(){}'], 'def.c')

" Remove the results from the previous test runs
call delete('test.log')
call delete(g:MRU_File)
let results = []

" Generate a sorted list of Test_ functions to run
redir @q
silent function /^Test_
redir END
let s:tests = split(substitute(@q, '\(function\) \(\k*()\)', '\2', 'g'))

" Run the tests
set nomore
set debug=beep
for one_test in sort(s:tests)
  echo 'Executing ' . one_test
  if s:builtin_assert
    let v:errors = []
    let errs = v:errors
  else
    let s:errors = []
    let errs = s:errors
  endif
  try
    exe 'call ' . one_test
  catch
    call add(errs, "Error: Test " . one_test . " failed with exception " . v:exception . " at " . v:throwpoint)
  endtry
  if empty(errs)
    call LogResult(one_test, 'pass')
  else
    call LogResult(one_test, 'FAIL ' . string(errs))
  endif
endfor
set more

call writefile(results, 'test.log')

" TODO:
" Add the following tests:
" 1. When the MRU list is modified, the MRU menu should be refreshed.
" 2. Try to jump to an already open file from the MRU window and using the
"     MRU command.

" Cleanup the files used by the tests
call delete('file1.txt')
call delete('file2.txt')
call delete('file3.txt')
call delete('abc.c')
call delete('def.c')
call delete(g:MRU_File)

" End of unit test execution
qall

" vim: shiftwidth=2 sts=2 expandtab
