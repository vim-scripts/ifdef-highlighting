" Description: C Preprocessor Highlighting
" Author: Michael Geddes <michaelrgeddes@optushome.com.au>
" Modified: Jan2004
" Version: 2.3
" Copyright 2002, 2003 Michael Geddes
" Please feel free to use, modify & distribute all or part of this script,
" providing this copyright message remains.
" I would appreciate being acknowledged in any derived scripts, and would
" appreciate and welcome any updates, modifications or suggestions.

" Usage:
" Use as a syntax plugin (source ifdef.vim from ~/vimfiles/after/syntax/cpp.vim -
" also c.vim and idl.vim )
"
" #ifdef defintions are considered to be in 1 of 3 states, defined, not-defined
" or don't know (the default).
"
" To specify which defines are valid/invalid, the scripts searches two places.
"   * Firstly, the current directory, and all higher directories are search for
"     the file specified in g:ifdef_filename - which defaults to '.defines'
"     (first one found gets used)
"   * Secondly, modelines prefixed by 'vim_ifdef:' are searched for within the
"     current file being loaded.  You can either use the vim default settings
"     for modeline/modelines, or these can be overridden by using
"     ifdef_modeline and ifdef_modelines.
" The defines/undefines are addeded in order.  Lines must be prefixed with
" 'defined=' or 'undefined=' and contain a ';' or ',' separated list of keywords.
" Keywords may be regular expressions, though use of '\k' rather than '.' is
" highly recommended.
"
" Specifying '*' by itself equates to '\k\+' and allows
" setting of the default to be defined/undefined.
"
" NB: On 16bit and win32s windows builds, the default for ifdef_filename is
" '_defines'.  I've assumed that win32 apps can handle '.defines'.
"
" Examples:
" ----.defines-------
" undefined=*
" defined=WIN32;__MT
" ----.defines----------
" undefined=DEBUG,DBG
" ----(modelines) samples.cpp-------
" /* vim_ifdef: defined=WIN32 */
" // vim_ifdef: undefine=DBG
"
" Settings:
" g:ifdef_modeline overrides &modeline for whether to use the ifdef modelines.
" g:ifdef_modelines overrides &modelines for how many lines to look at.
"
" Hilighting:
" ifdefIfZero (default Comment)          - Inside #if 0 hilighting
" ifdefIfOut (default Debug)             - The #ifdef/#else/#endif/#elseif
" ifdefIDefine (default PreCondit)       - Other defines where the defines are valid
" ifdefInBadPreCondit (default PreCondit)- The #ifdef/#else/#endif/#elseif in an invalid section.
" ifdefOutComment (default ifdefIfOut)   - A C/C++ comment inside a an invalid section
" ifdefPreCondit1 (defualt PreCondit)    - The #ifdef/#else/#endif/#elseif in a valid section
" ifdefInclude (default Include)         - #include hilighting
"
" ------------------------------
" Alternate (old) usage.
" Call CIfDef() after sourcing the c/cpp syntax file.
" Call Define(keyword) to mark a preprocessor symbol as being defined.
" Call Undefine(keyword) to mark a preprocessor symbol as not being defined.
" call Undefine('\k\+') will mark all words that aren't explicitly 'defined' as undefined.
"
"
" History:
" 2.3
"   - Clean up some of the comments
"   - Ignore whitespace in .defines files. (TODO: Credit person who suggested this!)
"   - Add comments for hilighting groups.
" 2.2
"   - Add support for idl files.
"   - Suggestions from
"     - Check for 'shell' type and 'shellslash'
"     - Don't use has("windows"), which is different.
" 2.1
"   - Fixes from Erik Remmelzwaal
"     - Need to use %:p:h instead of %:h to get directory
"     - Documentation fixes/updates
"     - Added ability to parse ',' or ';' separated lists instead of fixing
"       the documentation ;)
" 2.0:
"   - Added loading of ifdefs
"     - via ifdef modelines
"     - via .defines files
"   - Added missing highlight link.. relinked ifdefed out comments to special
"   - Conditional loading of functions
" 1.3:
"   - Fix some group names
" 1.2:
"   - Fix some errors in the tidy-up with group names
"   - Make it a propper syntax file - to be added onto c.vim / cpp.vim
"   - Use standard highlight groups - PreProc, Comment and Debug
"   - Use 'default' highlight syntax.
" 1.1:
"   - Tidy-up
"   - Make sure CIfDef gets called.
"   - Turn of #if 0 properly - this script handles it!
"   - prefix 'ifdef' to all groups
"   - Use some c 'clusters' to get rid of some inhouse code
"
"   TODO: (Feel free to contact me with suggestions)
"     - Allow defined= and undefined= on the same line in modelines.
"

"

" Settings for the c.vim hilighting .. disable the default preprocessor handling.
let cpreproc_comment=0
let c_no_if0=1

" Reload protection
if !exists('ifdef_loaded') || exists('ifdef_debug')
  let ifdef_loaded=1
else
  call s:CIfDef(1)
  call IfdefLoad()
  finish
endif

if !exists('ifdef_filename')
  if has('dos16') || has('gui_win32s') || has('win16')
    let ifdef_filename='_defines'
  else
    let ifdef_filename='.defines'
  endif
endif

" Reload CIfDef - backwards compatible
function! CIfDef()
  call s:CIfDef(0)
endfun

" Load the C ifdef hilighting.
function! s:CIfDef(force)
  if ! a:force &&  exists('b:ifdef_syntax')
      return
  endif
  let b:ifdef_syntax=1
  " Redefine some standards - defines/pragmas/lines/warnings etc.
  syn region  ifdefIDefine    start="^\s*#\s*\(define\|undef\)\>" skip="\\$" end="$" contained contains=ALLBUT,@cPreProcGroup keepend
  syn region  ifdefPreProc  start="^\s*#\s*\(pragma\>\|line\>\|warning\>\|warn\>\|error\>\)" skip="\\$" end="$" contained contains=ALLBUT,@cPreProcGroup keepend
  syn match ifdefInclude  "^\s*#\s*include\>\s*["<]" contained contains=cIncluded

  "Standards
  syn cluster ifdefGoodIfExclude contains=ifdefInParen,cUserLabel,cppMethodWrapped,ifdefOutIf,cIncluded,cErrInParen,cErrInBracket,cCppOut2,@cPreProcGroup,@cParenGroup
  " Bad spaces additions
  syn cluster ifdefGoodIfExclude add=cErrInBracket

  " Specific to this problem
  syn cluster ifdefGoodIfExclude add=ifdefInElse,ifdefOutComment,ifdefOutIf,ifdefOutPreCondit,cErrInBracket

  " Now add to all the c/rc/idl clusters
  syn cluster cParenGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster cPreProcGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster cMultiGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster rcParenGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster rcGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster idlCommentable add=ifdefOutComment,ifdefOutIf,ifdefInElse

  " #if .. #endif  nesting
  syn region ifdefInIf matchgroup=ifdefPreCondit1 start="^\s*#\s*\(if\>\|ifdef\>\|ifndef\>\).*$" matchgroup=ifdefPreCondit1 end="^\s*#\s*endif\>.*$" contained contains=ALLBUT,@ifdefGoodIfExclude

  syn region ifdefOutIf matchgroup=ifdefPreCondit2 start="^\s*#\s*\(if\>\|ifdef\>\|ifndef\>\).*$" matchgroup=ifdefPreCondit2 end="^\s*#\s*endif\>.*$" contained contains=ifdefOutIf,ifdefOutComment,ifdefOutPreCondit

  " #else hilighting for nesting
  syn region ifdefInPreCondit start="^\s*#\s*\(elif\>\|else\>\)" skip="\\$" end="$" contained contains=cComment,cSpaceError
  syn region ifdefOutPreCondit start="^\s*#\s*\(elif\>\|else\>\)" skip="\\$" end="$" contained contains=cComment,cSpaceError

  " #if 0 matching
  syn region ifdefIfOut  matchgroup=ifdefPreCondit4 start="^\s*#\s*if\s\+0\>" matchgroup=ifdefPreCondit4 end="^\s*#\s*endif" contains=ifdefOutIf,ifdefInBadPreCondit,cComment,ifdefInElse

  " #else handling .. switching to out group
  syn region ifdefOutElse matchgroup=ifdefPreCondit3 start="^\s*#\s*else" end="^\s*#\s*endif"me=s-1 contained contains=ifdefOutIf,ifdefInBadPreCondit,ifdefOutComment

  syn region ifdefInElse matchgroup=ifdefPreCondit6 start="^\s*#\s*else" end="^\s*#\s*endif"me=s-1 contained contains=ALLBUT,@ifdefGoodIfExclude

  " comment hilighting
  syntax region ifdefOutComment start="/\*" end="\*/" contained contains=cCharacter,cNumber,cFloat,cSpaceError
  syntax match  ifdefOutComment "//.*" contained contains=cCharacter,cNumber,cSpaceError

  " Start sync from scratch
  syn sync fromstart

endfunction

" Mark a (regexp) definition as defined.
" Note that the regular expression is use with \< \> arround it.
fun! Define(define)
  call CIfDef()
  exe 'syn region ifdefIfOut  matchgroup=ifdefPreCondit4 start="^\s*#\s*ifndef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit4 end="^\s*#\s*endif" contains=ifdefOutIf,ifdefInBadPreCondit,ifdefOutComment,ifdefInElse'
  exe 'syn region ifdefIfIn matchgroup=ifdefPreCondit5 start="^\s*#\s*ifdef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit5 end="^\s*#\s*endif" contains=ALLBUT,@ifdefGoodIfExclude'
endfun

" Mark a (regexp) definition as not defined.
" Note that the regular expression is use with \< \> arround it.
fun! Undefine(define)
  call CIfDef()
  exe 'syn region ifdefIfOut  matchgroup=ifdefPreCondit4 start="^\s*#\s*ifdef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit4 end="^\s*#\s*endif" contains=ifdefOutIf,ifdefInBadPreCondit,ifdefOutComment,ifdefInElse'
  exe 'syn region ifdefIfIn matchgroup=ifdefPreCondit5 start="^\s*#\s*ifndef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit5 end="^\s*#\s*endif" contains=ALLBUT,@ifdefGoodIfExclude'

endfun

" Find the modelines for vim_ifdef between l1 and l2.
fun! s:GetModelines( l1, l2)
  if a:l1==0 | return ''| endif
  let c=a:l1
  let lines=''
  let reA='\<vim_ifdef:'
  let reB='\<vim_ifdef:\s*\zs\(.\{-}\)\ze\s*\(\*/\s*\)\=$'
  while c <= a:l2
    let l=getline(c)
    if l =~reA
      let lines=lines.matchstr(l,reB)."\n"
    endif
    let c=c+1
  endwhile
  return lines
endfun

" Return the modelines based on the settings.
fun! s:ReadDefineModeline()
  " Check for modeline=enable/disable
  if (exists('g:ifdef_modeline') ? (g:ifdef_modeline==0):(!&modeline)) | return | endif
  let defmodelines= (exists('g:ifdef_modelines')?(g:ifdef_modelines):(&modelines))
  if ((2*defmodelines)>=line('$'))
    " Check whole file
    return s:GetModelines( 1,line('$'))
  else
    " Check top & bottom
    return s:GetModelines( 1,defmodelines).s:GetModelines(line('$')-defmodelines,line('$'))
  endif
endfun

" Check a directory for the specified file
function! s:CheckDirForFile(directory,file)
  let aborted=0
  let cur=a:directory
  let slsh= ((cur=~'[/\\]$') ? '' : '/')
  while !filereadable(cur.slsh.a:file)
    let nxt=fnamemodify(cur,':h')
    let aborted=(nxt==cur)
    if aborted!=0 | break |endif
    let cur=nxt
    let slsh=((cur=~'[/\\]$') ? '' : '/')
  endwhile
  " Check the two cases we haven't tried
  if aborted | let aborted=!filereadable(cur.slsh.a:file) | endif
  return ((aborted==0) ? cur.slsh : '')
endfun

" Read a .defines file in the specified (or higher) directory
fun! s:ReadFile( dir, filename)
  let realdir= s:CheckDirForFile( a:dir, a:filename )
  if realdir=='' | return '' | endif
  " if has('dos16') || has('gui_win32s') || has('win16') || ha
  if !has('unix') && !&shellslash && &shell !~ 'sh[a-z.]*$'
    return system('type "'.fnamemodify(realdir,':gs?/?\\?.').a:filename.'"')
  else
    return system( 'cat "'.escape(realdir.a:filename,'\$*').'"' )
  endif
endfun

" Define/undefine a ';' or ',' separated list
fun! s:DoDefines( define, defines)
  let reBreak='[^;,]*'
  let here=0
  let back=strlen(a:defines)
  while here<back
    let idx=matchend(a:defines,reBreak,here)+1
    if idx<0 | let idx=back|endif
    let part=strpart(a:defines,here,(idx-here)-1)
    let part=substitute(substitute(part,'^\s*','',''),'\s*$','','')
    if part != ''
      if part=='*' | let part='\k\+' | endif
      if a:define
        call Define(part)
      else
        call Undefine(part)
      endif
    endif
    let here=idx
  endwhile
endfun

" Load ifdefs for a file
fun! IfdefLoad()
  let txt=s:ReadFile(expand('%:p:h'),g:ifdef_filename)
  if txt!='' && txt !~"[\r\n]$" | let txt=txt."\n" | endif
  let txt=txt.s:ReadDefineModeline()
  let reCr="[^\n\r]*[\r\n]*"
  let reDef='^\s*\(un\)\=defined\=\s*=\s*'
  let back=strlen(txt)
  let here=0
  while here < back
    let idx=matchend(txt,reCr,here)
    if idx < 0 | let idx=back|endif
    let part=strpart(txt,here,(idx-here))
    if part=~reDef
      let un=(part[0]=='u')
      let rest=substitute(strpart(part,matchend(part,reDef)),"[\r\n]*$",'','')
      call s:DoDefines(!un , rest)
    endif
    let here=idx
  endwhile
endfun

"  hi default ifdefIfZero term=bold ctermfg=1 gui=italic guifg=DarkSeaGreen
hi default link ifdefIfZero Comment
hi default link ifdefIfOut Debug
hi default link ifdefOutIf ifdefIfOut
hi default link ifdefOutElse ifdefIfOut
hi default link ifdefIDefine PreCondit
hi default link ifdefInBadPreCondit PreCondit
hi default link ifdefOutComment ifdefIfOut
hi default link ifdefOutPreCondit ifdefInBadPreCondit
hi default link ifdefPreCondit1 PreCondit
hi default link ifdefPreCondit2 ifdefInBadPreCondit
hi default link ifdefPreCondit3 ifdefPreCondit1
hi default link ifdefPreCondit4 ifdefPreCondit1
hi default link ifdefPreCondit5 ifdefPreCondit1
hi default link ifdefPreCondit6 ifdefPreCondit1
hi default link ifdefInclude Include

call s:CIfDef(1)
call IfdefLoad()

" vim:ts=2 sw=2 et
