" Description: c preprocessor commenting 
" Author: Michael Geddes <michaelrgeddes@optushome.com.au>
" Modified: Dec2002 
" Version: 1.3

" Usage: Call CIfDef() after sourcing the c/cpp syntax file. 
" Call Define() to mark a preprocessor symbol as being defined.
" Call Undefine() to mark a preprocessor symbol as not being defined.  
" call Undefine('\k\+') will mark all words that aren't explicitly 'defined' as undefined.
"
" History:
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
"

let cpreproc_comment=0
let c_no_if0=1
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
  " CGS Error &c additions
"  syn cluster ifdefGoodIfExclude add=CGS.*

  " Specific to this problem
  syn cluster ifdefGoodIfExclude add=ifdefInElse,ifdefOutComment,ifdefOutIf,ifdefOutPreCondit,cErrInBracket
"  syn cluster ifdefGoodIfExclude add=doxygen.*
"  syn cluster ifdefGoodIfExclude add=fortify.*

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

"  hi default ifdefIfZero term=bold ctermfg=1 gui=italic guifg=DarkSeaGreen 
hi default link ifdefIfZero Comment
hi default link ifdefIfOut Debug
hi default link ifdefOutIf ifdefIfZero
hi default link ifdefOutElse ifdefIfOut
hi default link ifdefIDefine PreCondit
hi default link ifdefInBadPreCondit PreCondit
hi default link ifdefOutComment ifdefInBadPreCondit
hi default link ifdefPreCondit1 PreCondit
hi default link ifdefPreCondit2 ifdefInBadPreCondit
hi default link ifdefPreCondit3 ifdefPreCondit1
hi default link ifdefPreCondit4 ifdefPreCondit1
hi default link ifdefPreCondit5 ifdefPreCondit1
hi default link ifdefPreCondit6 ifdefPreCondit1
hi default link ifdefInclude Include

call s:CIfDef(1)

" call Define('TEST')
