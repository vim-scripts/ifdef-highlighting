" Description: c preprocessor commenting 
" Author: Michael Geddes <michaelrgeddes@optushome.com.au>
" Modified: Dec2002 
" Version: 2.0

" Usage:
" Use as a syntax plugin (source ifdef.vim from ~/vimfiles/syntax/cpp.vim -
" also c.vim and idl.vim )
" To specify which defines are valid/invalid, the scripts searches two places.
" 	* Firstly, the current directory, and all higher directories are search for
" 	  the file '.defines' (first one found gets used)
" 	* Secondly, modelines prefixed by 'vim_ifdef:' are searched for within the
" 	  current file being loaded.  You can either use the vim default settings
" 	  for modeline/modelines, or these can be overridden by using
" 	  ifdef_modeline and ifdef_modelines.
" The defines/undefines are addeded in order.  Lines must be prefixed with
" 'defined=' or 'undefined=' and contain a ';' separated list of keywords.
" Keywords may be regular expressions, though use of '\k' rather than '.' is
" highly recommended. 
"
" Specifying '*' by itself equates to '\k\+' and allows
" setting of the default to be defined/undefined.
"
" Examples: 
" ----.defines-------
" 	undefined=*
" 	defined=WIN32;__MT
" ----.defines----------
"  undefined=DEBUG,DBG
" ----(modelines) samples.cpp-------
"  /* vim_ifdef: defined=WIN32 */
"  // vim_ifdef: undefine=DBG
" 
" ------------------------------
" Alternate (old) usage.
" Call CIfDef() after sourcing the c/cpp syntax file. 
" Call Define(keyword) to mark a preprocessor symbol as being defined.
" Call Undefine(keyword) to mark a preprocessor symbol as not being defined.  
" call Undefine('\k\+') will mark all words that aren't explicitly 'defined' as undefined.
"
" g:ifdef_modeline overrides &modeline for whether to use the ifdef modelines.
" g:ifdef_modelines overrides &modelines for how many lines to look at.
"
" History:
" 2.0:
" 	- Added loading of ifdefs
" 		- via ifdef modelines
" 		- via .defines files
" 	- Added missing highlight link.. relinked ifdefed out comments to special
" 	- Conditional loading of functions
" 1.3:
" 	- Fix some group names
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

let cpreproc_comment=0
let c_no_if0=1

if !exists('ifdef_loaded') || exists('ifdef_debug')
	let ifdef_loaded=1

if !exists('ifdef_filename')
	if has('dos16') || has('gui_win32s') || has('win16')
		let ifdef_filename='_defines'
	else
		let ifdef_filename='.defines'
	endif
endif

function! CIfDef()
    call s:CIfDef(0)
endfun
function! s:CIfDef(force)
  if ! a:force &&  exists('b:ifdef_syntax')
      return
  endif
  let b:ifdef_syntax=1
  " Redefine some standards
  syn region	ifdefIDefine		start="^\s*#\s*\(define\|undef\)\>" skip="\\$" end="$" contained contains=ALLBUT,@cPreProcGroup keepend
  syn region	ifdefPreProc	start="^\s*#\s*\(pragma\>\|line\>\|warning\>\|warn\>\|error\>\)" skip="\\$" end="$" contained contains=ALLBUT,@cPreProcGroup keepend
  syn match	ifdefInclude	"^\s*#\s*include\>\s*["<]" contained contains=cIncluded

  "Standards
  syn cluster ifdefGoodIfExclude contains=ifdefInParen,cUserLabel,cppMethodWrapped,ifdefOutIf,cIncluded,cErrInParen,cErrInBracket,cCppOut2,@cPreProcGroup,@cParenGroup
  " Bad spaces additions
  syn cluster ifdefGoodIfExclude add=cErrInBracket

  " Specific to this problem
  syn cluster ifdefGoodIfExclude add=ifdefInElse,ifdefOutComment,ifdefOutIf,ifdefOutPreCondit,cErrInBracket

  " Now add to all the c clusters
  syn cluster cParenGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster cPreProcGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster cMultiGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster rcParenGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse
  syn cluster rcGroup add=ifdefOutComment,ifdefOutIf,ifdefInElse

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
  syntax region ifdefOutComment	start="/\*" end="\*/" contained contains=cCharacter,cNumber,cFloat,cSpaceError
  syntax match  ifdefOutComment	"//.*" contained contains=cCharacter,cNumber,cSpaceError

  " Start sync from scratch
  syn sync fromstart

endfunction

fun! Define(define)
  call CIfDef()
  exe 'syn region ifdefIfOut  matchgroup=ifdefPreCondit4 start="^\s*#\s*ifndef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit4 end="^\s*#\s*endif" contains=ifdefOutIf,ifdefInBadPreCondit,ifdefOutComment,ifdefInElse'
  exe 'syn region ifdefIfIn matchgroup=ifdefPreCondit5 start="^\s*#\s*ifdef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit5 end="^\s*#\s*endif" contains=ALLBUT,@ifdefGoodIfExclude'

endfun
fun! Undefine(define)
  call CIfDef()
  exe 'syn region ifdefIfOut  matchgroup=ifdefPreCondit4 start="^\s*#\s*ifdef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit4 end="^\s*#\s*endif" contains=ifdefOutIf,ifdefInBadPreCondit,ifdefOutComment,ifdefInElse'
  exe 'syn region ifdefIfIn matchgroup=ifdefPreCondit5 start="^\s*#\s*ifndef\s\+'.a:define.'\>" matchgroup=ifdefPreCondit5 end="^\s*#\s*endif" contains=ALLBUT,@ifdefGoodIfExclude'

endfun

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
	if has('windows')
		return system('type "'.fnamemodify(realdir,':gs?/?\\?.').a:filename.'"')
	else
		return system( 'cat "'.realdir.a:filename.'"' )
	endif
endfun

" Define/undefine a ';' separated list
fun! s:DoDefines( define, defines)
	let reBreak='[^;]*'
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
	let txt=s:ReadFile(expand('%:h'),g:ifdef_filename)
	if txt!='' && txt !~"[\r\n]$" | let txt=txt."\n" | endif
	let txt=txt.s:ReadDefineModeline()
	let reCr="[^\n\r]*[\r\n]*"
	let reDef='^\(un\)\=defined\=='
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

endif

call s:CIfDef(1)
call IfdefLoad()

