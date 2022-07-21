Red [
	Title: "Help system"
	Needs: 'View
]
help: context [
	page-size: 600x650
	list-width: 220
	code: text: layo: xview: none
	sections: make block! 50
	layouts: make block! 50
	xy: none
	page: none
	links: clear []
	sizes: clear []
	
	content: #include %help.txt

	rt: make face! [type: 'rich-text size: page-size - 20 line-spacing: 15] ;480x460
	text-size: func [text][
		rt/text: text
		size-text rt
	]
	detab: function [
		{Converts tabs in a string to spaces. (tab size 4)}
		str [string!] 
		/size sz [integer!]
	][
		sz: max 1 any [sz 2]
		buf: append/dup clear "    " #" " sz
		replace/all str #"^-" copy buf
	]

	;rt-ops: [#"*" <b> #"/" <i> #"_" <u>] 
	inside-b?: inside-i?: inside-u?: no 
	special: charset "*_/\{[<"
	line-end: [space some space newline]
	digit: charset "0123456789"
	int: [some digit]
	alpha: charset [#"a" - #"z" #"A" - #"Z"]
	str: [#"^"" some [alpha | space] #"^""]
	font-rule: [#"[" copy fnt to #"]" skip]
	link-rule: [#"<" copy txt to ">(" 2 skip copy adr to #")" skip]
	rt-rule: [;(inside?: no)
		collect some [
			#"\" keep skip
		|	[
				#"*" keep (also either inside-b? [</b>][<b>] inside-b?: not inside-b?) 
			|	#"/" keep (also either inside-i? [</i>][<i>] inside-i?: not inside-i?) 
			|	#"_" keep (also either inside-u? [</u>][<u>] inside-u?: not inside-u?)
			|	"{#}" keep (</bg>)
			|	"{#" copy bg to "#}" keep (<bg>) keep (to-word bg) 2 skip 
			|	"[]" keep (</font>)
			|	font-rule keep (<font>) keep (load fnt);(either single? fnt: load/all fnt [first fnt][fnt]) 
			|	link-rule keep ('u/blue) keep (reduce [txt])(
					repend links [length? sections 0x0 txt adr]
				)
			|	#"{" copy clr to #"}" keep (to-word clr) skip
			] 
		|	line-end keep (#"^/")
		|	newline keep (" ")
		|	keep copy _ to [line-end | special | newline | end]
		] 
	]
	
	space: charset " ^-"
	chars: complement charset " ^-^/"

	rules: [title some parts]

	title: [text-line (title-line: text)]

	parts: [
		  newline
		| "===" section
		| "---" subsect
		| "!" note
		| example
		| paragraph
	]
	text-line: [copy text to newline newline]
	indented:  [some space thru newline]
	paragraph: [copy para some [chars thru newline] (emit-para para)]
	note: [copy para some [chars thru newline] (emit-note para)]
	example: [
		copy code some [any newline indented];[indented | some newline indented]
		(emit-code code)
	]
	section: [
		text-line (
			append sections text
			append/only layouts layo: copy []
			append sizes 0
			blk: copy [<font> 16 </font>]
			insert at blk 3 text
			rtb: rtd-layout blk 
			rtb/size/x: page-size/x - 40;460
			repend layo ['text 10x5 rtb]
			sz: size-text rtb
			pos-y: 5 + sz/y + 10
			poke sizes length? sizes pos-y
		) newline
	]
	subsect: [text-line (
		blk: copy [<b><font> 12 </font></b>] 
		insert at blk 4 text
		rtb: rtd-layout blk
		rtb/size/x: page-size/x - 40;460
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10
		poke sizes length? sizes pos-y
	)]

	;emit: func ['style data] [repend layo [style data]]

	emit-para: func [data][ 
		remove back tail data
		blk: parse data rt-rule
		if " " = first blk [remove blk]
		insert blk [<font> 12]
		append blk [</font>]
		rtb: rtd-layout blk
		rtb/size/x: page-size/x - 40;460
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10
		poke sizes length? sizes pos-y
	]

	emit-code: func [code] [
		remove back tail code
		blk: reduce [<b> code </b>] 
		rtb: rtd-layout blk
		rtb/size/x: page-size/x - 20;480
		append rtb/data reduce [as-pair 1 length? rtb/text "Consolas"]
		sz: size-text rtb
		repend layo [
			'fill-pen silver 
			'box pos: as-pair 10 pos-y as-pair page-size/x - 20 pos/y + sz/y + 14 ;480
			'fill-pen black
		]
		repend layo ['text as-pair 15 pos-y + 7 rtb]
		pos-y: pos-y + sz/y + 27
		poke sizes length? sizes pos-y
	]

	emit-note: func [code] [
		remove back tail code
		blk: parse code rt-rule
		if " " = first blk [remove blk]
		append insert blk [b][/b]
		rtb: rtd-layout blk
		append rtb/data reduce [as-pair 1 length? rtb/text 150.0.0]
		rtb/size/x: page-size/x - 40;460
		repend layo ['text as-pair 10 pos-y rtb]
		sz: size-text rtb
		pos-y: pos-y + sz/y + 10
		poke sizes length? sizes pos-y
	]

	show-example: func [code][
		if xview [xy: xview/offset - 3x26  unview/only xview]
		xcode: load/all code;face/text
		if not block? xcode [xcode: reduce [xcode]] 
		either here: select xcode either find [layout compose] what: second xcode [what]['view][
			xcode: here
		][
			unless find [title backdrop size] first xcode [insert xcode 'below]
		]
		xview: view/no-wait/options compose xcode [offset: xy]  
	]

	show-edit-box: func [code sz][
		if xview [xy: xview/offset - 8x31  unview/only xview]
		xcode: load/all code;face/text
		if not block? xcode [xcode: reduce [xcode]] 
		either here: select xcode either find [layout compose] what:  second xcode [what]['view][
			xcode: here
		][
			unless find [title backdrop size] first xcode [insert xcode 'below]
		]
		view-cmd: copy "view "
		if find xcode paren! [append view-cmd "compose "]
		xcode: head insert mold xcode view-cmd
		xview: view/no-wait/flags/options compose [
			title "Play with code"
			on-resizing [
				win: face
				foreach-face face [
					switch face/type [
						area [face/size: win/size - face/offset - 45 ]
						button [face/offset/y: win/size/y - face/size/y - 10]
					]
				]
			]
			below 
			ar: area focus (xcode) (sz) 
			across 
			button "Show" [do ar/text]
			button "Close" [unview]
		] 'resize [offset: xy]
	]
	clear sizes
	parse detab/size content 3 rules  

	show-page: func [i /local blk][
		page: i: max 1 min length? sections i
		if blk: pick layouts this-page: i [
			tl/selected: this-page
			f-box/size/y: sizes/:i
			f-box/offset/y: 0
			f-box/draw: blk ;show f-box
			hscv/selected: 1.0 * page-size/y / f-box/size/y
			hscv/visible?: f-box/size/y > page-size/y
		]
	]
	help-scroll: function [face step][
		f-box/offset/y: min 0 
		                max page-size/y - f-box/size/y
			                f-box/offset/y + step
		hscv/data: 1.0 * (absolute f-box/offset/y) / f-box/size/y
		face/draw: face/draw
	]

	main: layout compose [;/flags
		title "DiaGrammar help"
		on-key [
			switch event/key [
				up left [show-page this-page];[show-page this-page - 1]
				down right [show-page this-page];[show-page this-page + 1]
				home [show-page 1]
				end [show-page length? sections]
			] 
		]
		h4 title-line bold return
		tl: text-list bold select 1 white black data sections font [size: 12]
			with [size: as-pair list-width page-size/y] 
			on-change [;160x480
				show-page page: face/selected
			]
			on-over [if not event/away? [set-focus face]]
			on-wheel [
				face/selected: 	min length? sections 
								max 1 face/selected - to-integer event/picked
				show-page face/selected
			]
		panel page-size white [
			origin 0x0
			f-box: rich-text 600 white draw []
			on-down [;probe reduce [event/offset page]
				parse face/draw [any [
					'text s: pair! object! if (within? event/offset s/1 size-text s/2) (
						;probe s/2/data
						caret: offset-to-caret s/2 event/offset - s/1
						parse s/2/data [some [
							e: pair! 0.0.255 'underline 
							opt [if (all [caret >= e/1/1 caret <= (e/1/1 + e/1/2)])(
								text: copy/part at s/2/text e/1/1 e/1/2
								;probe links
								foreach [pg ofs txt lnk] links [
									if all [pg = page txt = text][
										lnk: load lnk
										switch type?/word lnk [
											url! [browse lnk]
											integer! [show-page page: lnk]
											 ;[show-page page: index? find sections to-string lnk]
											word! block! [show-page page: index? find sections form lnk]
										]
									]
								]
							)]
						|	skip
						]]
					)
				|	skip
				]]
				parse face/draw [some [
					bx*: 'box pair! pair! if (within? event/offset bx*/2 sz: bx*/3 - bx*/2) (
						code*: select first find bx* object! 'text
						either event/ctrl? [show-edit-box code* sz][show-example code*]
					)
				|	skip
				]]
			]
			on-wheel [
				help-scroll face to-integer 10 * event/picked
			]
			at 0x0 page-border: box with [
				size: page-size 
				draw: compose [pen gray box 0x0 (page-size - 1)]
			]
			at 583x1 hscv: scroller 
			with [
				size:      as-pair 16 page-size/y - 2
				visible?:  no
				vertical?: yes
			][
				f-box/offset/y: min 0
				                max page-size/y - f-box/size/y
								    to-integer 0 - (f-box/size/y * face/data)
			]
		]
		pad -51x-30
		space 4x10
		button 20 "<" [show-page this-page - 1]
		button 20 ">" [show-page this-page + 1]
		pad -140x5
		do [f-box/draw: compose [pen gray box 0x0 (f-box/size - 1)]]
	] ;'modal
	set 'show-help func [/page pg][
		view/no-wait main
		show-page self/page: any [pg 1]
		xy: main/offset + either system/view/screens/1/size/x > 900 [
			main/size * 1x0 + 8x0][300x300]
		do-events
	]
	set 'close-help does [unview/only main]
]
