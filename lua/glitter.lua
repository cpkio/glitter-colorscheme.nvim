-- vim:noexpandtab:tabstop=8:shiftwidth=8

package.loaded["glitter"] = nil

local colors = require('colors')

local debug = false

local logfile = nil

local function clone(t)
	local u = setmetatable({}, getmetatable(t))
	for i, v in pairs(t) do
		u[i] = v
	end
	return u
end

local function merge(x,y)
	for i, value in ipairs(y) do
		x[#x+i] = value
	end
	return x
end

local mt = {
	-- `+` is for color sets intersection
	__add = function(a,b)
		res = {}; setmetatable(res, mt)
		for j, v2 in ipairs(b) do
			for i, v1 in ipairs(a) do
				if a[i][2] == b[j][2] then
					table.insert(res, a[i])
				end
			end
		end
		return res
	end,

	-- `-` removes intersections and joins the remaining
	__sub = function(a,b)
		l = clone(a)
		r = clone(b)
		::restart::
		for j in ipairs(r) do
			for i in ipairs(l) do
				if l[i][2] == r[j][2] then
					table.remove(l,i)
					table.remove(r,j)
					goto restart
				end
			end
		end
		merge(l,r)
		return l
	end,

	-- `*` does something I didnt come up with
	__mul = function(a,b)
	end
}

local palette = {
	{0, '#282c34'},
	{1, '#61afef'},
	{2, '#98c379'},
	{3, '#56b6c2'},
	{4, '#d19a66'},
	{5, '#c678dd'},
	{6, '#e5c07b'},
	{7, '#5c6370'},
	{8, '#2c323c'},
	{9, '#528bff'},
	{10, '#181a1f'},
	{11, '#3e4452'},
	{12, '#e06c75'},
	{13, '#be5046'},
	{14, '#e2f9fc'},
	{15, '#abb2bf'},
}

local function transform(tbl)
	for _,item in ipairs(tbl) do
		if item[1] == 1 then item[1] = 4
		elseif item[1] == 3 then item[1] = 6
		elseif item[1] == 4 then item[1] = 1
		elseif item[1] == 6 then item[1] = 3
		elseif item[1] == 9 then item[1] = 12
		elseif item[1] == 11 then item[1] = 14
		elseif item[1] == 12 then item[1] = 9
		elseif item[1] == 14 then item[1] = 11 end
	end
end

local margin = 4

-- Let's introduce parameters for color selection
-- @saturation_threshold means everything below that is «grayish»
local saturation_threshold = 0.25

-- @lightness_threshold means everything up from that is considered light, and
-- vice versa
local lightness_threshold = 0.48

local colorful_threshold = 0.17

-- @hue_spread means color distance between colors
-- Has to be calculated with lightness in mind
local hue_spread = 24
local spread = 0.1

local function dark(tbl, value)
	if debug then io.write('filter by darkness') end
	local result = clone(tbl)
	value = value or lightness_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, _, l = colors.rgb_string_to_hsl(item[2])
		if not (l <= value + spread) then table.remove(result, i); goto restart end
	end
	return result
end

local function light(tbl, value)
	if debug then io.write('filter by lightness') end
	local result = clone(tbl)
	value = value or lightness_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, _, l = colors.rgb_string_to_hsl(item[2])
		if not (l >= value - spread) then table.remove(result, i); goto restart end
	end
	return result
end

local function dull(tbl, value)
	if debug then io.write('filter by color dullness') end
	local result = clone(tbl)
	value = value or colorful_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, s, l = colors.rgb_string_to_hsl(item[2])
		if not (s <= value) or not (l >= 0.9)  then table.remove(result, i); goto restart end
	end
	return result
end

local function colorful(tbl, value)
	if debug then io.write('filter by colofullness') end
	local result = clone(tbl)
	value = value or colorful_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, s, l = colors.rgb_string_to_hsl(item[2])
		if not (s >= value) or (l >= 0.9) then table.remove(result, i); goto restart end
	end
	return result
end

-- Pick colors from palette @tbl based on target hue @angle and spread
local function hue(tbl, angle, spr)
	if debug then io.write('filter by hue') end
	local result = {}
	angle = angle or 180
	spr = spr or hue_spread
	::reiterate::
	local anglePlus = nil
	local angleMinus = nil
	if (angle + spr >= 360) then anglePlus = angle + spr - 360 else anglePlus = angle + spr end
	if (angle - spr < 0) then angleMinus = angle - spr + 360 else angleMinus = angle - spr end
	if debug then io.write('anglePlus: ', anglePlus, '\n') end
	if debug then io.write('angleMinus: ', angleMinus, '\n') end
	for i = 1, #tbl do
		local h, _, _ = colors.rgb_string_to_hsl(tbl[i][2])
		if anglePlus > angleMinus then
			if (h >= angleMinus) and (h <= anglePlus) then table.insert(result, tbl[i]) end
		else
			if (h >= 0) and (h <= anglePlus) then table.insert(result, tbl[i]) end
			if (h <= 360) and (h >= angleMinus) then table.insert(result, tbl[i]) end
		end
	end
	if #result == 0 then spr = spr * 1.2; goto reiterate end
	return result
end

-- Pick @amount top table entries
local function pop(tbl, amount)
	if debug then io.write('take N top elements') end
	local result = {}
	amount = amount or 1
	for i = 1, amount do table.insert(result, tbl[i]) end
	return result
end

local function slice(tbl) end

-- Pick @amount bottom entries
local function pop_back(tbl, amount)
	if debug then io.write('take N bottom elements') end
	local result = {}
	amount = amount or 1
	for i = #tbl - amount + 1, #tbl do table.insert(result, tbl[i]) end
	return result
end

local function r(tbl, value)
end

local function g(tbl, value)
end

local function b(tbl, value)
end

local function sort_by_hue(tbl)
	if debug then io.write('sort by hue') end
	local result = clone(tbl)
	table.sort(result, function(e1, e2)
		h1, _, _ = colors.rgb_string_to_hsl(e1[2])
		h2, _, _ = colors.rgb_string_to_hsl(e2[2])
		return h1 < h2
	end)
	return result
end

local function sort_by_saturation(tbl)
	if debug then io.write('sort by saturation') end
	local result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, s1, _ = colors.rgb_string_to_hsl(e1[2])
		_, s2, _ = colors.rgb_string_to_hsl(e2[2])
		return s1 < s2
	end)
	return result
end

local function sort_by_lightness(tbl)
	if debug then io.write('sort by lightness') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, _, l1 = colors.rgb_string_to_hsl(e1[2])
		_, _, l2 = colors.rgb_string_to_hsl(e2[2])
		return l1 < l2
	end)
	return result
end

local function sort_by_red(tbl)
	if debug then io.write('sort by red') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		r1, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
		r2, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
		return r1 < r2
	end)
	return result
end

local function sort_by_green(tbl)
	if debug then io.write('sort by green') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, g1, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
		_, g2, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
		return g1 < g2
	end)
	return result
end

local function sort_by_blue(tbl)
	if debug then io.write('sort by blue') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, _, b1 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
		_, _, b2 = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
		return b1 < b2
	end)
	return result
end

-- @index is a base color, from which the distance is calculated
local function distanceHSL(tbl, index, value)
	if debug then io.write('get color in vicinity by Hue+Saturation+Lightness') end
	if index > #tbl then index = #tbl end
	local value = value or 1.2
	local h1, s1, l1 = colors.rgb_string_to_hsl(result[index][2])
	::restart::
	for i, item in ipairs(result) do
		local h2, s2, l2 = colors.rgb_string_to_hsl(result[i][2])
		local distance = math.sqrt((h2 - h1)^2 + (s2 - s1)^2 + (l2 - l1)^2)
		if (distance > value) then table.remove(result, i); goto restart end
	end
	return result
end

local function distanceHL(tbl, index, value)
	if debug then io.write('get color in vicinity by Hue+Lightness') end
	local result = clone(tbl)
	local index = index or 1
	if index > #tbl then index = #tbl end
	local value = value or 1.2
	local h1, _, l1 = colors.rgb_string_to_hsl(result[index][2])
	::restart::
	for i, item in ipairs(result) do
		local h2, _, l2 = colors.rgb_string_to_hsl(result[i][2])
		local distance = math.sqrt((h2 - h1)^2 + (l2 - l1)^2)
		if (distance > value) then table.remove(result, i); goto restart end
	end
	return result
end

local function distanceHS(tbl, index, value)
	if debug then io.write('get color in vicinity by Hue+Saturation') end
	local result = clone(tbl)
	local index = index or 1
	if index > #tbl then index = #tbl end
	local value = value or 1.2
	local h1, s1, _ = colors.rgb_string_to_hsl(result[index][2])
	::restart::
	for i, item in ipairs(result) do
		local h2, s2, _ = colors.rgb_string_to_hsl(result[i][2])
		local distance = math.sqrt((h2 - h1)^2 + (s2 - s1)^2)
		if (distance > value) then table.remove(result, i); goto restart end
	end
	return result
end

local function distanceSL(tbl, index, value)
	if debug then io.write('get color in vicinity by Saturation+Lighness') end
	local result = clone(tbl)
	local index = index or 1
	if index > #result then index = #result end
	local value = value or 1.2
	local _, s1, l1 = colors.rgb_string_to_hsl(result[index][2])
	::restart::
	for i, item in ipairs(result) do
		local _, s2, l2 = colors.rgb_string_to_hsl(item[2])
		local distance = math.sqrt((s2 - s1)^2 + (l2 - l1)^2)
		if (distance > value) then table.remove(result, i); goto restart end
	end
	return result
end

local function print_colors(tbl, text)
	local result = ""
	result = result .. text
	result = result .. string.format("%7s | %6s | %4s | %4s | %5s | %5s | %5s\n", "Hex", "H", "S", "L", "R", "G", "B")
	for _, item in ipairs(tbl) do
		h, s, l = colors.rgb_string_to_hsl(item[2])
		r, g, b = colors.hsl_to_rgb(colors.rgb_string_to_hsl(item[2]))
		result = result .. string.format("%7s | %-6.2f | %.2f | %.2f | %4.3f | %4.3f | %4.3f\n", item[2], h, s, l, r, g, b)
	end
	return result
end

local function filter(filtername, tbl, ...)
	if debug then io.write('\nNEW FILTER CHAIN: ', filtername, '\n') end
	local result = clone(tbl)
	for i, fn in ipairs({...}) do
		local f = fn[1]
		local param = fn[2]
		local param2 = fn[3]
		result = f(result, param, param2)
		if debug then io.write(print_colors(result, string.format('\ncall #%d %s ------------\n', i, vim.inspect(fn)))) end
	end
	setmetatable(result, mt)
	return result
end

local function highlight(group, color)
	local style = color.style and "cterm=" .. color.style[1][1] .. " gui=" .. color.style[1][2] or "cterm=NONE gui=NONE"

	local color_fg
	if color.fg then
			if #color.fg > 1 then color_fg = color.fg[math.random(1, #color.fg)] else color_fg = color.fg[1] end
	end
	local fg = color.fg and "ctermfg=" .. color_fg[1] .. " guifg=" .. color_fg[2] or "ctermfg=NONE guifg=NONE"

	local color_bg
	if color.bg then
			if #color.bg > 1 then color_bg = color.bg[math.random(1, #color.bg)] else color_bg = color.bg[1] end
		end
	local bg = color.bg and "ctermbg=" .. color_bg[1] .. " guibg=" .. color_bg[2] or "ctermbg=NONE guibg=NONE"

	local sp = color.sp and "guisp=" .. color.sp or ""

	vim.api.nvim_command("highlight " .. group .. " " .. style .. " " .. fg .. " " .. bg .. " " .. sp)
end

local none
local underline
local reverse
local italic
local default_fg
local default_bg
local darkest
local bright_fg
local bright_bg
local bright_bg2
local red
local red_bright
local blue
local blue_bright
local green
local green_bright
local purple
local insert
local replace
local visual
local gray
local gray2
local random

local function load_syntax()
	local syntax = {
		Normal =			{fg = default_fg,				bg = default_bg},
		Terminal =			{fg = default_fg,				bg = none},
		SignColumn =			{fg = default_fg,				bg = none},
		FoldColumn =			{fg = default_fg,				bg = none},
		VertSplit =			{fg = darkest,					bg = none},
		FloatBorder =			{fg = bright_fg,				bg = bright_bg},
		FloatTitle =			{fg = green_bright,				bg = bright_bg},
		Folded =			{fg = bright_fg,				bg = none},
		EndOfBuffer =			{fg = default_bg,				bg = none},
		Search =			{fg = darkest,					bg = default_fg},
		IncSearch =			{fg = darkest,					bg = green},
		ColorColumn =			{fg = none,					bg = bright_bg},
		-- Conceal =			{fg = color_12,					bg = none},
		-- Cursor =			{fg = none,					bg = none,					style = "reverse"},
		-- vCursor =			{fg = none,					bg = none,					style = "reverse"},
		-- iCursor =			{fg = none,					bg = none,					style = "reverse"},
		-- lCursor =			{fg = none,					bg = none,					style = "reverse"},
		-- CursorIM =			{fg = none,					bg = none,					style = "reverse"},
		-- CursorColumn =		{fg = none,					bg = bg_highlight},
		CursorLine =			{						bg = bright_bg,					style = none},
		LineNr =			{fg = gray},
		-- qfLineNr =			{fg = color_10},
		CursorLineNr =			{fg = gray,											style = reverse},
		DiffAdd =			{fg = green_bright,				bg = none},
		DiffChange =			{fg = red,					bg = none},
		DiffDelete =			{fg = red_bright,				bg = none},
		DiffText =			{fg = blue,					bg = none},
		Directory =			{fg = default_fg,					bg = none},
		ErrorMsg =			{fg = darkest,					bg = red},
		WarningMsg =			{fg = red,					bg = default_bg},
		ModeMsg =			{fg = default_fg,					bg = none},
		MatchParen =			{fg = bright_fg},
		NonText =			{fg = gray,					bg = default_bg	}, -- отвечает за символы конца строки
		Whitespace =			{fg = gray					}, -- отвечает за показ непечатаемых символов (пробелов и прочих)
		SpecialKey =			{fg = green_bright,				},
		Pmenu =				{fg = default_fg,				bg = bright_bg},
		PmenuSel =			{fg = bright_fg,				bg = gray},
		PmenuSelBold =			{fg = bright_fg},
		PmenuSbar =			{fg = gray},
		PmenuThumb =			{fg = bright_fg,				bg = gray},
		-- WildMenu =			{fg = color_10,					bg = color_5},
		Question =			{fg = green},
		NormalFloat =			{fg = default_fg,				bg = bright_bg},
		TabLine =			{fg = default_fg,				bg = gray },
		TabLineFill =			{fg = bright_fg,				bg = darkest,					style = none},
		TabLineSel =			{fg = bright_fg,				bg = default_bg,				style = none},
		StatusLine =			{fg = default_fg,				bg = darkest,				style = none},
		StatusLineNC =			{fg = gray,					bg = darkest,				style = none},
		SpellBad =			{fg = red,					bg = none,				style = underline},
		SpellCap =			{fg = purple,					bg = none,				style = underline},
		SpellLocal =			{fg = red,					bg = none,				style = underline},
		SpellRare =			{fg = blue,					bg = none,				style = underline},
		Visual =			{fg = darkest,					bg = visual },
		-- VisualNOS =			{fg = darkest,					bg = blue},
		-- QuickFixLine =		{fg = color_9},
		-- Debug =			{fg = color_2},
		-- debugBreakpoint =		{fg = bg,						bg = color_0},
		Boolean =			{ fg = random,											style = none },
		Character =			{ fg = random,											style = none },
		Comment =			{ fg = gray,											style = none },
		Conditional =			{ fg = random,											style = none },
		Constant =			{ fg = random,											style = none },
		Define =			{ fg = random,											style = none },
		Delimiter =			{ fg = bright_fg,										style = none },
		Error =				{ fg = red,											style = none },
		Exception =			{ fg = random,											style = none },
		Float =				{ fg = random,											style = none },
		Function =			{ fg = random,											style = none },
		Identifier =			{ fg = random,											style = none },
		Ignore =			{ fg = random,											style = none },
		Include =			{ fg = random,											style = none },
		Keyword =			{ fg = random,											style = italic },
		Label =				{ fg = green,											style = none },
		Macro =				{ fg = blue,											style = none },
		Number =			{ fg = random,											style = none },
		Operator =			{ fg = random,											style = none },
		PreCondit =			{ fg = random,											style = none },
		PreProc =			{ fg = random,											style = none },
		Repeat =			{ fg = random,											style = none },
		Special =			{ fg = purple,											style = none },
		SpecialChar =			{ fg = random,											style = none },
		SpecialComment =		{ fg = random,											style = none },
		Statement =			{ fg = random,											style = none },
		StorageClass =			{ fg = random,											style = none },
		String =			{ fg = random,											style = none },
		Structure =			{ fg = random,											style = none },
		Tag =				{ fg = random,											style = none },
		Title =				{ fg = bright_fg,										style = none },
		Todo =				{ fg = random,											style = none },
		Type =				{ fg = random,											style = none },
		Typedef =			{ fg = random,											style = none },
		Underlined =			{ fg = none,											style = underline},
	}
	return syntax
end

local function load_plugin_syntax()
	local plugin_syntax = {
		TSAnnotation =			{ fg = random,											style = none },
		TSAttribute =			{ fg = random,											style = none },
		TSBoolean =			{ fg = random,											style = none },
		TSCharacter =			{ fg = random,											style = none },
		-- TSComment
		TSConditional =			{ fg = random,											style = none },
		TSConstant =			{ fg = random,											style = none },
		-- TSConstBuiltin xxx links to Special
		-- TSConstMacro   xxx links to Define
		TSConstructor =			{ fg = random,											style = none },
		-- TSDanger
		TSEmphasis =			{ fg = green,											style = none },
		-- TSEnvironment
		-- TSEnvironmentName
		TSError =			{ fg = random,											style = none },
		TSException =			{ fg = random,											style = none },
		TSField =			{ fg = random,											style = none },
		TSFloat =			{ fg = random,											style = none },
		TSFuncBuiltin =			{ fg = random,											style = none },
		TSFuncMacro =			{ fg = random,											style = none },
		TSFunction =			{ fg = red,											style = none },
		TSInclude =			{ fg = random,											style = none },
		TSKeyword =			{ fg = random,											style = italic },
		TSKeywordFunction =		{ fg = random,											style = italic },
		-- TSKeywordOperator
		-- TSKeywordReturn
		TSLabel =			{ fg = random,											style = none },
		TSLiteral =			{ fg = green,											style = none },
		-- TSMath
		TSMethod =			{ fg = random,											style = none },
		TSNamespace =			{ fg = random,											style = none },
		-- TSNone
		-- TSNote
		TSNumber =			{ fg = blue,											style = none },
		TSOperator =			{ fg = bright_fg,										style = none },
		TSParameter =			{ fg = random,											style = none },
		TSParameterReference =		{ fg = random,											style = none },
		TSProperty =			{ fg = random,											style = none },
		TSPunctBracket =		{ fg = random,											style = none },
		TSPunctDelimiter =		{ fg = random,											style = none },
		-- TSPunctSpecial оформляет в том числе строку символов заголовка в RST
		-- поэтому делаем его идентичным TSTitle
		TSPunctSpecial =		{ fg = bright_fg,										style = none },
		TSRepeat =			{ fg = random,											style = none },
		-- TSStrike
		TSString =			{ fg = green,											style = none },
		TSStringEscape =		{ fg = red,											style = none },
		TSStringRegex =			{ fg = blue,											style = none },
		-- TSStringSpecial
		TSStrong =			{ fg = green_bright,										style = none },
		TSStructure =			{ fg = random,											style = none },
		-- TSSymbol
		TSTag =				{ fg = random,											style = none },
		-- TSTagAttribute
		TSTagDelimiter =		{ fg = bright_fg,										style = none },
		TSText =			{ fg = default_fg,										style = none },
		TSTextReference =		{ fg = red,											style = none },
		TSTitle =			{ fg = bright_fg,										style = none },
		TSType =			{ fg = random,											style = none },
		TSTypeBuiltin =			{ fg = random,											style = none },
		TSURI =				{ fg = blue,											style = none },
		TSUnderline =			{ fg = none,											style = underline },
		TSVariable =			{ fg = blue,											style = none },
		TSVariableBuiltin =		{ fg = blue,												style = none },
		-- TSWarning
		statusOuter =			{ fg = darkest,					bg = gray },
		statusMiddle =			{ fg = green,					bg = bright_bg2 },
		statusInner =			{ fg = default_fg,				bg = none },
		statusInsert =			{ fg = darkest,					bg = insert},
		statusReplace =			{ fg = darkest,					bg = replace},
		statusVisual =			{ fg = darkest,					bg = visual},
		statusInactive =		{ fg = gray,					},
		statusCommand =			{ fg = darkest,					bg = bright_fg},
		statusChanged =			{ fg = bright_fg,				bg = red },
		statusFileType =		{ fg = bright_fg,				},

		LineNrInsert =			{fg = insert},
		CursorLineNrInsert =		{fg = darkest,					bg = insert},
		LineNrReplace =			{fg = replace},
		CursorLineNrReplace =		{fg = darkest,					bg = replace},
		LineNrVisual =			{fg = visual},
		CursorLineNrVisual =		{fg = darkest,					bg = visual},

		IndentBlanklineChar =		{ fg = gray2,											style = {{"nocombine", "nocombine"}}},
		IndentBlanklineContextChar =	{ fg = bright_fg,											style = {{"nocombine", "nocombine"}} },
		IndentBlanklineContextStart =	{ fg = bright_fg,											style = {{"nocombine", "nocombine"}} },
		IndentBlanklineSpaceChar =	{													style = {{"nocombine", "nocombine"}} },
		IndentBlanklineSpaceCharBlankline = {													style = {{"nocombine", "nocombine"}} },

		DiagnosticHint =	{ fg = gray, bg = none },
		DiagnosticError =	{ fg = red, bg = none },
		DiagnosticWarning =	{ fg = green, bg = none },
		DiagnosticInformation = { fg = blue, bg = none },
		DiagnosticVirtualtextHint =	{ fg = gray2, bg = none },
		DiagnosticVirtualtextError =	{ fg = red, bg = none },
		DiagnosticVirtualtextWarning =	{ fg = green, bg = none },
		DiagnosticVirtualtextInformation = { fg = blue, bg = none },
		DiagnosticSignHint =	{ fg = gray2, bg = none },
		DiagnosticSignError =	{ fg = red, bg = none },
		DiagnosticSignWarning =	{ fg = green, bg = none },
		DiagnosticSignInformation = { fg = blue, bg = none },

		LspDiagnosticsDefaultHint =	{ fg = gray2 },
		LspDiagnosticsDefaultError =	{ fg = red },
		LspDiagnosticsDefaultWarning =	{ fg = green },
		LspDiagnosticsDefaultInformation = { fg = blue},
		LspDiagnosticsUnderlineError =	{													style = reverse },
		LspDiagnosticsUnderlineWarning = { fg = red,											style = underline },
		LspDiagnosticsUnderlineInformation = {													style = underline },
		LspDiagnosticsUnderlineHint =	 {													style = underline },
		LspDiagnosticsFloatingError =	{ fg = bright_fg,				},
		LspDiagnosticsFloatingHint =	{ fg = bright_fg,				},
		LspDiagnosticsFloatingInformation =	{ fg = bright_fg,			},
		LspDiagnosticsFloatingWarning =	{ fg = bright_fg,				},
		-- LspDiagnosticsSignError
		-- LspDiagnosticsSignHint
		-- LspDiagnosticsSignInformation
		-- LspDiagnosticsSignWarning
		-- LspDiagnosticsVirtualTextError
		-- LspDiagnosticsVirtualTextHint
		-- LspDiagnosticsVirtualTextInformation
		-- LspDiagnosticsVirtualTextWarning
		MarkSignHL = { fg = purple },
		MarkSignNumHL = { fg = none, bg = none},
		MarkVirtTextHL = { fg = gray },
		-- asciidocAdmonition
		-- asciidocAnchorMacro
		-- asciidocAttributeEntry
		-- asciidocAttributeList
		-- asciidocAttributeMacro
		-- asciidocAttributeRef
		-- asciidocBackslash
		-- asciidocBlockTitle
		-- asciidocCallout
		-- asciidocCommentBlock
		-- asciidocCommentLine
		-- asciidocDoubleDollarPassthrough
		-- asciidocEmail
		-- asciidocEntityRef
		-- asciidocExampleBlockDelimiter
		-- asciidocFilterBlock
		-- asciidocHLabel
		-- asciidocIdMarker
		-- asciidocIndexTerm
		-- asciidocLineBreak
		-- asciidocList
		-- asciidocListBullet
		-- asciidocListContinuation
		-- asciidocListLabel
		-- asciidocListNumber
		-- asciidocListingBlock
		-- asciidocLiteralBlock
		-- asciidocLiteralParagraph
		-- asciidocMacro
		-- asciidocMacroAttributes
		-- asciidocOneLineTitle
		-- asciidocOpenBlockDelimiter
		-- asciidocPagebreak
		-- asciidocPassthroughBlock
		-- asciidocQuoteBlockDelimiter
		-- asciidocQuotedAttributeList
		-- asciidocQuotedBold
		-- asciidocQuotedDoubleQuoted
		-- asciidocQuotedEmphasized
		-- asciidocQuotedEmphasized2
		asciidocQuotedEmphasizedItalic = { fg = bright_fg},
		-- asciidocQuotedMonospaced
		-- asciidocQuotedMonospaced2
		-- asciidocQuotedSingleQuoted
		-- asciidocQuotedSubscript
		-- asciidocQuotedSuperscript
		-- asciidocQuotedUnconstrainedBold
		-- asciidocQuotedUnconstrainedEmphasized
		-- asciidocQuotedUnconstrainedMonospaced
		-- asciidocRefMacro
		-- asciidocRuler
		-- asciidocSidebarDelimiter
		-- asciidocTableBlock
		-- asciidocTableBlock2
		-- asciidocTableDelimiter
		-- asciidocTableDelimiter2
		-- asciidocTablePrefix
		-- asciidocTablePrefix2
		-- asciidocTable_OLD
		-- asciidocTitleUnderline
		-- asciidocToDo
		-- asciidocTriplePlusPassthrough
		-- asciidocTwoLineTitle
		-- asciidocURL
		-- rcAttribute
		rcCaptionParam =	{ fg = green	},
		-- rcCharacter
		-- rcComment
		-- rcComment2String
		-- rcCommentError
		-- rcCommentSkip
		-- rcCommentString
		rcCommonAttribute =	{ fg = red	},
		-- rcDefine
		-- rcError
		-- rcFloat
		-- rcInParen
		-- rcInclude
		-- rcIncluded
		rcLanguage =	{ fg = red,					style = reverse},
		rcMainObject =	{ fg = default_fg	},
		-- rcNumber
		-- rcOctalError
		rcParam =	{ fg = green_bright	},
		-- rcParen
		-- rcParenError
		-- rcPreCondit
		-- rcPreProc
		-- rcSpecial
		-- rcSpecialCharacter
		rcStatement =	{ fg = blue		},
		-- rcStdId
		-- rcString
		rcSubObject = { fg = bright_fg		},
		-- rcTodo
		-- GitGutterAdd = {fg = color_add},
		-- GitGutterChange = {fg = color_change},
		-- GitGutterDelete = {fg = color_delete},
		-- GitGutterChangeDelete = {fg = color_change_delete},
		-- GitSignsAdd = {fg = color_add},
		-- GitSignsChange = {fg = color_change},
		-- GitSignsDelete = {fg = color_delete},
		-- GitSignsAddNr = {fg = color_add},
		-- GitSignsChangeNr = {fg = color_change},
		-- GitSignsDeleteNr = {fg = color_delete},
		-- GitSignsAddLn = {fg = color_add},
		-- GitSignsChangeLn = {fg = color_change},
		-- GitSignsDeleteLn = {fg = color_delete},
		-- SignifySignAdd = {fg = color_add},
		-- SignifySignChange = {fg = color_change},
		-- SignifySignDelete = {fg = color_delete},
		-- LvimHelperNormal = {fg = color_6, bg = base2},
		-- LvimHelperTitle = {fg = color_9, bg = none},
		-- NvimTreeNormal = {bg = black_background},
		-- NvimTreeFolderName = {fg = color_4},
		-- NvimTreeOpenedFolderName = {fg = color_11},
		-- NvimTreeEmptyFolderName = {fg = color_4},
		-- NvimTreeRootFolder = {fg = color_4},
		-- NvimTreeSpecialFile = {fg = fg, bg = none, style = "NONE"},
		-- NvimTreeFolderIcon = {fg = color_4},
		-- NvimTreeIndentMarker = {fg = hl},
		-- NvimTreeSignError = {fg = color_error},
		-- NvimTreeSignWarning = {fg = color_warning},
		-- NvimTreeSignInformation = {fg = color_info},
		-- NvimTreeSignHint = {fg = color_info},
		-- NvimTreeLspDiagnosticsError = {fg = color_error},
		-- NvimTreeLspDiagnosticsWarning = {fg = color_warning},
		-- NvimTreeLspDiagnosticsInformation = {fg = color_info},
		-- NvimTreeLspDiagnosticsHint = {fg = color_info},
		-- NvimTreeWindowPicker = { fg = bg, bg = color_9},
		-- TroubleNormal = {bg = black_background},
		-- TelescopeBorder = {fg = color_11},
		-- TelescopePromptBorder = {fg = color_3},
		-- TelescopeMatching = {fg = color_11},
		-- TelescopeSelection = {fg = color_3, bg = bg_highlight},
		-- TelescopeSelectionCaret = {fg = color_3},
		-- TelescopeMultiSelection = {fg = color_11},
		-- Floaterm = {fg = color_9},
		-- FloatermBorder = {fg = color_1},
		VimwikiItalic = { fg = red_bright },
		VimwikiBold = { fg = green_bright },
		VimwikiLink = { fg = blue, style = reverse },
		-- эти расцветки не использовать, потому что с имеющимися
		-- иконками эти иконки обрезаются из-за перемены цвета
		-- CmpItemKind = { fg = random },
		-- CmpItemKindClass = { fg = random },
		-- CmpItemKindColor = { fg = random },
		-- CmpItemKindConstant = { fg = random },
		-- CmpItemKindConstructor = { fg = random },
		-- CmpItemKindEnum = { fg = random },
		-- CmpItemKindEnumMember = { fg = random },
		-- CmpItemKindEvent = { fg = random },
		-- CmpItemKindField = { fg = random },
		-- CmpItemKindFile = { fg = random },
		-- CmpItemKindFolder = { fg = random },
		-- CmpItemKindFunction = { fg = random },
		-- CmpItemKindInterface = { fg = random },
		-- CmpItemKindKeyword = { fg = random },
		-- CmpItemKindMethod = { fg = random },
		-- CmpItemKindModule = { fg = random },
		-- CmpItemKindOperator = { fg = random },
		-- CmpItemKindProperty = { fg = random },
		-- CmpItemKindReference = { fg = random },
		-- CmpItemKindSnippet = { fg = random },
		-- CmpItemKindStruct = { fg = random },
		-- CmpItemKindText = { fg = random },
		-- CmpItemKindTypeParameter = { fg = random },
		-- CmpItemKindUnit = { fg = random },
		-- CmpItemKindValue = { fg = random },
		-- CmpItemKindVariable = { fg = random },
		NvimCmpGhostText = { fg = bright_bg2 }
	}
	return plugin_syntax
end

function LineNrColor(mode)
	if (mode == 'i') then
	    vim.cmd'setlocal winhighlight=LineNr:LineNrInsert,LineNrAbove:LineNrInsert,LineNrBelow:LineNrInsert,CursorLineNr:CursorLineNrInsert'
	elseif (mode == 'R') then
	    vim.cmd'setlocal winhighlight=LineNr:LineNrReplace,LineNrAbove:LineNrReplace,LineNrBelow:LineNrReplace,CursorLineNr:CursorLineNrReplace'
	elseif (mode == 'v' or mode == 'V') then
	    vim.cmd'setlocal winhighlight=LineNr:LineNrVisual,LineNrAbove:LineNrVisual,LineNrBelow:LineNrVisual,CursorLineNr:CursorLineNrVisual'
	else
	    vim.cmd'setlocal winhighlight='
	end
end

local async_load_plugin

async_load_plugin = vim.loop.new_async(vim.schedule_wrap(function()
	local syntax = load_plugin_syntax()
	for group, color in pairs(syntax) do highlight(group, color) end
	async_load_plugin:close()
end))

local function colorscheme()
	transform(palette)
	vim.api.nvim_command("hi clear")
	if vim.fn.exists("syntax_on") then vim.api.nvim_command("syntax reset") end
	vim.g.colors_name = "glitter"
	local syntax = load_syntax()
	vim.api.nvim_command("autocmd ModeChanged *:* lua LineNrColor(vim.api.nvim_get_mode().mode)")
	-- vim.api.nvim_command("autocmd InsertLeave * lua InsertStatusColor('n')")
	for group, color in pairs(syntax) do highlight(group, color) end
	async_load_plugin:send()
end

local function setup(pal)
	palette = pal or palette
	setmetatable(palette, mt)

	if debug then
		logfile = io.open('r:\\colorlog.txt', "a")
		io.output(logfile)
	end

	-- Selecting the colors from palette
	none = {{"NONE", "NONE"}}
	underline = {{"underline", "undercurl"}}
	reverse = {{"reverse", "reverse"}}
	italic = {{"italic", "italic"}}

	default_fg = filter('Default Foreground', palette, {light}, {sort_by_lightness}, {pop_back, 2}, {pop})
	default_bg = filter('Default Background', palette, {dark}, {sort_by_lightness}, {pop, 2}, {pop_back})

	darkest = filter('Darkest color', palette, {dark}, {sort_by_lightness}, {pop})

	bright_fg = filter('Bright Foreground', palette, {light}, {sort_by_lightness}, {pop_back})
	bright_bg = filter('Bright Background', palette, {dark}, {sort_by_lightness}, {pop, 3}, {pop_back})
	bright_bg2 = filter('Bright Background 2', palette, {dark}, {sort_by_lightness}, {pop, 4}, {pop_back})

	red = filter('Reddish Colors', palette, {dark, 0.7}, {hue,0}, {sort_by_red}, {pop_back, 2}, {sort_by_lightness}, {pop})
	red_bright = filter('Bright Red', palette, {dark, 0.7}, {hue,0}, {sort_by_red}, {pop_back, 2}, {sort_by_lightness}, {pop_back})

	blue = filter('Blueish Colors', palette, {dark, 0.7}, {hue,240,36}, {sort_by_blue}, {pop_back, 2}, {sort_by_lightness}, {pop})
	blue_bright = filter('Bright Blue', palette, {dark, 0.7}, {hue,240,36}, {sort_by_blue}, {pop_back, 2}, {sort_by_lightness}, {pop_back})

	green = filter('Greenish Colors', palette, {dark, 0.7}, {hue,120}, {sort_by_green}, {pop_back, 2}, {sort_by_lightness}, {pop})
	green_bright = filter('Bright Green', palette, {dark, 0.7}, {hue,120}, {sort_by_green}, {pop_back, 2}, {sort_by_lightness}, {pop_back})

	purple = filter('Purple', palette, {hue, 300})

	insert = filter('INSERT Mode Color', blue)
	replace = filter('REPLACE Mode Color', red)
	visual = filter('VISUAL Mode Color', green)

	gray = filter('Gray', palette, {sort_by_saturation}, {pop, 5}, {sort_by_lightness}, {pop_back, 2}, {pop})
	gray2 = filter('Gray2', palette, {sort_by_saturation}, {pop, 5}, {sort_by_lightness}, {pop_back, 3}, {pop})

	random = filter('Random Colors Pool', palette, {colorful, 0.4}, {light, 0.5}, {dark, 0.7})

	colorscheme()

	if debug then io.close(logfile) end
end

return {
	setup = setup
}
