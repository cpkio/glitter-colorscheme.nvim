-- vim:noexpandtab:tabstop=8:shiftwidth=8

package.loaded["glitter"] = nil

local colors = require('colors')

local glitter = {}

local debug = false

local logfile = nil

if debug then
  logfile = io.open('r:\\colorlog.txt', "a")
  io.output(logfile)
end

glitter.palette = {
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
  -- none = { -1, "NONE"}
}

function clone(t)
	local u = setmetatable({}, getmetatable(t))
	for i, v in pairs(t) do
		u[i] = v
	end
	return u
end

function glitter.transform (tbl)
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

-------------------------------------------
-- Новая версия фильтров
-------------------------------------------

function dark(tbl, value)
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

function light(tbl, value)
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

function dull(tbl, value)
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

function colorful(tbl, value)
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
function hue(tbl, angle, spread)
	if debug then io.write('filter by hue') end
	local result = {}
	angle = angle or 180
	spread = spread or hue_spread
	::reiterate::
	local anglePlus = nil
	local angleMinus = nil
	if (angle + spread >= 360) then anglePlus = angle + spread - 360 else anglePlus = angle + spread end
	if (angle - spread < 0) then angleMinus = angle - spread + 360 else angleMinus = angle - spread end
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
	if #result == 0 then spread = spread * 1.2; goto reiterate end
	return result
end

-- Pick @amount top table entries
function pop(tbl, amount)
	if debug then io.write('take N top elements') end
	local result = {}
	amount = amount or 1
	for i = 1, amount do table.insert(result, tbl[i]) end
	return result
end

function slice(tbl)
end

-- Pick @amount bottom entries
function pop_back(tbl, amount)
	if debug then io.write('take N bottom elements') end
	local result = {}
	amount = amount or 1
	for i = #tbl - amount + 1, #tbl do table.insert(result, tbl[i]) end
	return result
end

function r(tbl, value)
end

function g(tbl, value)
end

function b(tbl, value)
end

function sort_by_hue(tbl)
	if debug then io.write('sort by hue') end
	local result = clone(tbl)
	table.sort(tbl, function(e1, e2)
		h1, _, _ = colors.rgb_string_to_hsl(e1[2])
		h2, _, _ = colors.rgb_string_to_hsl(e2[2])
		return h1 < h2
	end)
	return result
end

function sort_by_saturation(tbl)
	if debug then io.write('sort by saturation') end
	local result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, s1, _ = colors.rgb_string_to_hsl(e1[2])
		_, s2, _ = colors.rgb_string_to_hsl(e2[2])
		return s1 < s2
	end)
	return result
end

function sort_by_lightness(tbl)
	if debug then io.write('sort by lightness') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, _, l1 = colors.rgb_string_to_hsl(e1[2])
		_, _, l2 = colors.rgb_string_to_hsl(e2[2])
		return l1 < l2
	end)
	return result
end

function sort_by_red(tbl)
	if debug then io.write('sort by red') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		r1, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
		r2, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
		return r1 < r2
	end)
	return result
end

function sort_by_green(tbl)
	if debug then io.write('sort by green') end
	result = clone(tbl)
	table.sort(result, function(e1, e2)
		_, g1, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
		_, g2, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
		return g1 < g2
	end)
	return result
end

function sort_by_blue(tbl)
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
function distanceHSL(tbl, index, value)
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

function distanceHL(tbl, index, value)
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

function distanceHS(tbl, index, value)
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

function distanceSL(tbl, index, value)
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

function print_colors(tbl, text)
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

function filter(filtername, tbl, ...)
	if debug then io.write('\nNEW FILTER CHAIN: ', filtername, '\n') end
	local result = clone(tbl)
	for i, fn in ipairs({...}) do
		local func = fn[1]
		local param = fn[2]
		local param2 = fn[3]
		result = func(result, param, param2)
	if debug then io.write(print_colors(result, string.format('\ncall #%d %s ------------\n', i, vim.inspect(fn)))) end
	end
	return result
end

function glitter.highlight(group, color)
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

-- SELECTING THE COLORS FROM PALETTE

glitter.none = {{"NONE", "NONE"}}
glitter.underline = {{"underline", "undercurl"}}
glitter.reverse = {{"reverse", "reverse"}}
glitter.italic = {{"italic", "italic"}}

glitter.default_fg = filter('Default Foreground', glitter.palette, {light}, {sort_by_lightness}, {pop_back, 2}, {pop})
glitter.default_bg = filter('Default Background', glitter.palette, {dark}, {sort_by_lightness}, {pop, 2}, {pop_back})

glitter.dark = filter('Darkest color', glitter.palette, {dark}, {sort_by_lightness}, {pop})

glitter.bright_fg = filter('Bright Foreground', glitter.palette, {light}, {sort_by_lightness}, {pop_back})
glitter.bright_bg = filter('Bright Background', glitter.palette, {dark}, {sort_by_lightness}, {pop, 3}, {pop_back})
glitter.bright_bg2 = filter('Bright Background 2', glitter.palette, {dark}, {sort_by_lightness}, {pop, 4}, {pop_back})

glitter.red = filter('Reddish Colors', glitter.palette, {light}, {hue, 0}, { pop_back, 1 })
glitter.red_bright = filter('Bright Red', glitter.palette, {light}, {hue, 0}, { sort_by_lightness }, { pop_back, 1 })
glitter.blue = filter('Blueish Colors', glitter.palette, {colorful}, {sort_by_blue}, {pop_back, 2})
glitter.green = filter('Greenish Colors', glitter.palette, {dark, 0.7}, {sort_by_green}, {pop_back, 2})
glitter.green_bright = filter('Bright Green', glitter.palette, {dark, 0.8}, {sort_by_lightness}, {hue, 40}, {pop_back, 2}, {pop})

glitter.purple = filter('Purple', glitter.palette, {hue, 300})

glitter.insert = filter('INSERT Mode Color', glitter.blue, {sort_by_blue}, {pop_back, 2}, {pop})
glitter.replace = filter('REPLACE Mode Color', glitter.red, {sort_by_red}, {pop_back, 2}, {pop})
glitter.visual = filter('VISUAL Mode Color', glitter.green, {sort_by_green}, {pop_back, 2}, {pop})

glitter.gray = filter('Gray', glitter.palette, {sort_by_saturation}, {pop, 5}, {sort_by_lightness}, {pop_back, 2}, {pop})
glitter.gray2 = filter('Gray2', glitter.palette, {sort_by_saturation}, {pop, 5}, {sort_by_lightness}, {pop_back, 3}, {pop})

glitter.pool = filter('Random Colors Pool', glitter.palette, {colorful, 0.4}, {light, 0.5}, {dark, 0.7})

function glitter.load_syntax()
	local syntax = {
		Normal =			{fg = glitter.default_fg,				bg = glitter.default_bg},
		Terminal =			{fg = glitter.default_fg,				bg = glitter.none},
		SignColumn =			{fg = glitter.default_fg,				bg = glitter.none},
		FoldColumn =			{fg = glitter.default_fg,				bg = glitter.none},
		VertSplit =			{fg = glitter.dark,					bg = glitter.none},
		FloatBorder =			{fg = glitter.default_fg,				bg = glitter.dark},
		Folded =			{fg = glitter.bright_fg,				bg = glitter.none},
		EndOfBuffer =			{fg = glitter.default_bg,				bg = glitter.none},
		Search =			{fg = glitter.dark,					bg = glitter.default_fg},
		IncSearch =			{fg = glitter.dark,					bg = glitter.green},
		-- ColorColumn 			{fg = lvim.none,					bg = lvim.bg_highlight},
		-- Conceal =			{fg = lvim.color_12,					bg = lvim.none},
		-- Cursor =			{fg = lvim.none,					bg = lvim.none,					style = "reverse"},
		-- vCursor =			{fg = lvim.none,					bg = lvim.none,					style = "reverse"},
		-- iCursor =			{fg = lvim.none,					bg = lvim.none,					style = "reverse"},
		-- lCursor =			{fg = lvim.none,					bg = lvim.none,					style = "reverse"},
		-- CursorIM =			{fg = lvim.none,					bg = lvim.none,					style = "reverse"},
		-- CursorColumn =		{fg = lvim.none,					bg = lvim.bg_highlight},
		CursorLine =			{fg = glitter.bright_fg,				bg = glitter.bright_bg,				style = glitter.none},
		LineNr =			{fg = glitter.gray},
		-- qfLineNr =			{fg = lvim.color_10},
		CursorLineNr =			{fg = glitter.gray,											style = glitter.reverse},
		DiffAdd =			{fg = glitter.green_bright,				bg = glitter.none},
		DiffChange =			{fg = glitter.red,					bg = glitter.none},
		DiffDelete =			{fg = glitter.red_bright,				bg = glitter.none},
		DiffText =			{fg = glitter.blue,					bg = glitter.none},
		-- Directory =			{fg = glitter.color_8,					bg = glitter.none},
		ErrorMsg =			{fg = glitter.dark,					bg = glitter.red},
		WarningMsg =			{fg = glitter.red,					bg = glitter.none},
		-- ModeMsg =			{fg = lvim.color_6,					bg = lvim.none},
		MatchParen =			{fg = glitter.bright_fg},
		NonText =			{fg = glitter.gray}, -- отвечает за символы конца строки
		Whitespace =			{fg = glitter.gray}, -- отвечает за показ непечатаемых символов (пробелов и прочих)
		SpecialKey =			{fg = glitter.red},
		Pmenu =				{fg = glitter.default_fg,				bg = glitter.bright_bg},
		PmenuSel =			{fg = glitter.bright_fg,				bg = glitter.gray},
		PmenuSelBold =			{fg = glitter.bright_fg},
		PmenuSbar =			{fg = glitter.gray},
		PmenuThumb =			{fg = glitter.bright_fg,				bg = glitter.gray},
		-- WildMenu =			{fg = lvim.color_10,					bg = lvim.color_5},
		-- Question =			{fg = lvim.color_3},
		NormalFloat =			{fg = glitter.default_fg,				bg = glitter.bright_bg},
		TabLine =			{fg = glitter.default_fg,				bg = glitter.gray },
		TabLineFill =			{bg = glitter.dark,											style = glitter.none},
		TabLineSel =			{fg = glitter.bright_fg,				bg = glitter.default_bg,				style = glitter.none},
		StatusLine =			{fg = glitter.default_fg,				bg = glitter.dark,				style = glitter.none},
		StatusLineNC =			{fg = glitter.gray,					bg = glitter.dark,				style = glitter.none},
		SpellBad =			{fg = glitter.red,					bg = glitter.none,				style = glitter.underline},
		SpellCap =			{fg = glitter.purple,					bg = glitter.none,				style = glitter.underline},
		SpellLocal =			{fg = glitter.red,					bg = glitter.none,				style = glitter.underline},
		SpellRare =			{fg = glitter.blue,					bg = glitter.none,				style = glitter.underline},
		Visual =			{fg = glitter.dark,					bg = glitter.blue},
		-- VisualNOS =			{fg = glitter.dark,					bg = glitter.blue},
		-- QuickFixLine =		{fg = lvim.color_9},
		-- Debug =			{fg = lvim.color_2},
		-- debugBreakpoint =		{fg = lvim.bg,						bg = lvim.color_0},
		Boolean =			{ fg = glitter.pool,											style = glitter.none },
		Character =			{ fg = glitter.pool,											style = glitter.none },
		Comment =			{ fg = glitter.gray,											style = glitter.none },
		Conditional =			{ fg = glitter.pool,											style = glitter.none },
		Constant =			{ fg = glitter.pool,											style = glitter.none },
		Define =			{ fg = glitter.pool,											style = glitter.none },
		Delimiter =			{ fg = glitter.bright_fg,										style = glitter.none },
		Error =				{ fg = glitter.pool,											style = glitter.none },
		Exception =			{ fg = glitter.pool,											style = glitter.none },
		Float =				{ fg = glitter.pool,											style = glitter.none },
		Function =			{ fg = glitter.pool,											style = glitter.none },
		Identifier =			{ fg = glitter.pool,											style = glitter.none },
		Ignore =			{ fg = glitter.pool,											style = glitter.none },
		Include =			{ fg = glitter.pool,											style = glitter.none },
		Keyword =			{ fg = glitter.pool,											style = glitter.italic },
		Label =				{ fg = glitter.pool,											style = glitter.none },
		Macro =				{ fg = glitter.pool,											style = glitter.none },
		Number =			{ fg = glitter.pool,											style = glitter.none },
		Operator =			{ fg = glitter.pool,											style = glitter.none },
		PreCondit =			{ fg = glitter.pool,											style = glitter.none },
		PreProc =			{ fg = glitter.pool,											style = glitter.none },
		Repeat =			{ fg = glitter.pool,											style = glitter.none },
		Special =			{ fg = glitter.pool,											style = glitter.none },
		SpecialChar =			{ fg = glitter.pool,											style = glitter.none },
		SpecialComment =		{ fg = glitter.pool,											style = glitter.none },
		Statement =			{ fg = glitter.pool,											style = glitter.none },
		StorageClass =			{ fg = glitter.pool,											style = glitter.none },
		String =			{ fg = glitter.pool,											style = glitter.none },
		Structure =			{ fg = glitter.pool,											style = glitter.none },
		Tag =				{ fg = glitter.pool,											style = glitter.none },
		Title =				{ fg = glitter.bright_fg,										style = glitter.none },
		Todo =				{ fg = glitter.pool,											style = glitter.none },
		Type =				{ fg = glitter.pool,											style = glitter.none },
		Typedef =			{ fg = glitter.pool,											style = glitter.none },
		Underlined =			{ fg = glitter.none,											style = glitter.underline},
	}
	return syntax
end

function glitter.load_plugin_syntax()
	local plugin_syntax = {
		TSAnnotation =			{ fg = glitter.pool,											style = glitter.none },
		TSAttribute =			{ fg = glitter.pool,											style = glitter.none },
		TSBoolean =			{ fg = glitter.pool,											style = glitter.none },
		TSCharacter =			{ fg = glitter.pool,											style = glitter.none },
		-- TSComment
		TSConditional =			{ fg = glitter.pool,											style = glitter.none },
		TSConstant =			{ fg = glitter.pool,											style = glitter.none },
		-- TSConstBuiltin xxx links to Special
		-- TSConstMacro   xxx links to Define
		TSConstructor =			{ fg = glitter.pool,											style = glitter.none },
		-- TSDanger
		TSEmphasis =			{ fg = glitter.green,											style = glitter.none },
		-- TSEnvironment
		-- TSEnvironmentName
		TSError =			{ fg = glitter.pool,											style = glitter.none },
		TSException =			{ fg = glitter.pool,											style = glitter.none },
		TSField =			{ fg = glitter.pool,											style = glitter.none },
		TSFloat =			{ fg = glitter.pool,											style = glitter.none },
		TSFuncBuiltin =			{ fg = glitter.pool,											style = glitter.none },
		TSFuncMacro =			{ fg = glitter.pool,											style = glitter.none },
		TSFunction =			{ fg = glitter.red,											style = glitter.none },
		TSInclude =			{ fg = glitter.pool,											style = glitter.none },
		TSKeyword =			{ fg = glitter.pool,											style = glitter.italic },
		TSKeywordFunction =		{ fg = glitter.pool,											style = glitter.italic },
		-- TSKeywordOperator
		-- TSKeywordReturn
		TSLabel =			{ fg = glitter.pool,											style = glitter.none },
		TSLiteral =			{ fg = glitter.green,											style = glitter.none },
		-- TSMath
		TSMethod =			{ fg = glitter.pool,											style = glitter.none },
		TSNamespace =			{ fg = glitter.pool,											style = glitter.none },
		-- TSNone
		-- TSNote
		TSNumber =			{ fg = glitter.blue,											style = glitter.none },
		TSOperator =			{ fg = glitter.bright_fg,										style = glitter.none },
		TSParameter =			{ fg = glitter.pool,											style = glitter.none },
		TSParameterReference =		{ fg = glitter.pool,											style = glitter.none },
		TSProperty =			{ fg = glitter.pool,											style = glitter.none },
		TSPunctBracket =		{ fg = glitter.pool,											style = glitter.none },
		TSPunctDelimiter =		{ fg = glitter.pool,											style = glitter.none },
		-- TSPunctSpecial оформляет в том числе строку символов заголовка в RST
		-- поэтому делаем его идентичным TSTitle
		TSPunctSpecial =		{ fg = glitter.bright_fg,										style = glitter.none },
		TSRepeat =			{ fg = glitter.pool,											style = glitter.none },
		-- TSStrike
		TSString =			{ fg = glitter.green,											style = glitter.none },
		TSStringEscape =		{ fg = glitter.red,											style = glitter.none },
		TSStringRegex =			{ fg = glitter.blue,											style = glitter.none },
		-- TSStringSpecial
		TSStrong =			{ fg = glitter.green_bright,										style = glitter.none },
		TSStructure =			{ fg = glitter.pool,											style = glitter.none },
		-- TSSymbol
		TSTag =				{ fg = glitter.pool,											style = glitter.none },
		-- TSTagAttribute
		TSTagDelimiter =		{ fg = glitter.bright_fg,										style = glitter.none },
		TSText =			{ fg = glitter.default_fg,										style = glitter.none },
		TSTextReference =		{ fg = glitter.red,											style = glitter.none },
		TSTitle =			{ fg = glitter.bright_fg,										style = glitter.none },
		TSType =			{ fg = glitter.pool,											style = glitter.none },
		TSTypeBuiltin =			{ fg = glitter.pool,											style = glitter.none },
		TSURI =				{ fg = glitter.blue,											style = glitter.none },
		TSUnderline =			{ fg = glitter.none,											style = glitter.underline },
		TSVariable =			{ fg = glitter.blue,											style = glitter.none },
		TSVariableBuiltin =		{ fg = glitter.blue,												style = glitter.none },
		-- TSWarning
		statusOuter =			{ fg = glitter.dark,					bg = glitter.gray },
		statusMiddle =			{ fg = glitter.green,					bg = glitter.bright_bg2 },
		statusInner =			{ fg = glitter.default_fg,				bg = glitter.bright_bg },
		statusInsert =			{ fg = glitter.dark,					bg = glitter.insert},
		statusReplace =			{ fg = glitter.dark,					bg = glitter.replace},
		statusVisual =			{ fg = glitter.dark,					bg = glitter.visual},
		statusInactive =		{ fg = glitter.gray,					bg = glitter.bright_bg },
		statusCommand =			{ fg = glitter.dark,					bg = glitter.bright_fg },
		statusChanged =			{ fg = glitter.bright_fg,				bg = glitter.red },

		IndentBlanklineChar =		{ fg = glitter.gray2,											style = {{"nocombine", "nocombine"}}},
		IndentBlanklineContextChar =	{ fg = glitter.purple,											style = {{"nocombine", "nocombine"}} },
		IndentBlanklineContextStart =	{ fg = glitter.purple,											style = {{"nocombine", "nocombine"}} },
		IndentBlanklineSpaceChar =	{													style = {{"nocombine", "nocombine"}} },
		IndentBlanklineSpaceCharBlankline = {													style = {{"nocombine", "nocombine"}} },

		DiagnosticHint =	{ fg = glitter.gray2, bg = glitter.bright_bg2 },
		DiagnosticError =	{ fg = glitter.red, bg = glitter.bright_bg2 },
		DiagnosticWarning =	{ fg = glitter.green, bg = glitter.bright_bg2 },
		DiagnosticInformation = { fg = glitter.blue, bg = glitter.bright_bg2},
		DiagnosticVirtualtextHint =	{ fg = glitter.gray2, bg = glitter.none },
		DiagnosticVirtualtextError =	{ fg = glitter.red, bg = glitter.none },
		DiagnosticVirtualtextWarning =	{ fg = glitter.green, bg = glitter.none },
		DiagnosticVirtualtextInformation = { fg = glitter.blue, bg = glitter.none},
		DiagnosticSignHint =	{ fg = glitter.gray2, bg = glitter.none },
		DiagnosticSignError =	{ fg = glitter.red, bg = glitter.none },
		DiagnosticSignWarning =	{ fg = glitter.green, bg = glitter.none },
		DiagnosticSignInformation = { fg = glitter.blue, bg = glitter.none},

		LspDiagnosticsDefaultHint =	{ fg = glitter.gray2 },
		LspDiagnosticsDefaultError =	{ fg = glitter.red },
		LspDiagnosticsDefaultWarning =	{ fg = glitter.green },
		LspDiagnosticsDefaultInformation = { fg = glitter.blue},
		LspDiagnosticsUnderlineError =	{													style = glitter.reverse },
		LspDiagnosticsUnderlineWarning = { fg = glitter.red,											style = glitter.underline },
		LspDiagnosticsUnderlineInformation = {													style = glitter.underline },
		LspDiagnosticsUnderlineHint =	 {													style = glitter.underline },
		LspDiagnosticsFloatingError =	{ fg = glitter.bright_fg,				},
		LspDiagnosticsFloatingHint =	{ fg = glitter.bright_fg,				},
		LspDiagnosticsFloatingInformation =	{ fg = glitter.bright_fg,			},
		LspDiagnosticsFloatingWarning =	{ fg = glitter.bright_fg,				},
		-- LspDiagnosticsSignError
		-- LspDiagnosticsSignHint
		-- LspDiagnosticsSignInformation
		-- LspDiagnosticsSignWarning
		-- LspDiagnosticsVirtualTextError
		-- LspDiagnosticsVirtualTextHint
		-- LspDiagnosticsVirtualTextInformation
		-- LspDiagnosticsVirtualTextWarning

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
		asciidocQuotedEmphasizedItalic = { fg = glitter.bright_fg},
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
		rcCaptionParam =	{ fg = glitter.green	},
		-- rcCharacter
		-- rcComment
		-- rcComment2String
		-- rcCommentError
		-- rcCommentSkip
		-- rcCommentString
		rcCommonAttribute =	{ fg = glitter.red	},
		-- rcDefine
		-- rcError
		-- rcFloat
		-- rcInParen
		-- rcInclude
		-- rcIncluded
		rcLanguage =	{ fg = glitter.red,					style = glitter.reverse},
		rcMainObject =	{ fg = glitter.default_fg	},
		-- rcNumber
		-- rcOctalError
		rcParam =	{ fg = glitter.green_bright	},
		-- rcParen
		-- rcParenError
		-- rcPreCondit
		-- rcPreProc
		-- rcSpecial
		-- rcSpecialCharacter
		rcStatement =	{ fg = glitter.blue		},
		-- rcStdId
		-- rcString
		rcSubObject = { fg = glitter.bright_fg		},
		-- rcTodo
		-- GitGutterAdd = {fg = lvim.color_add},
		-- GitGutterChange = {fg = lvim.color_change},
		-- GitGutterDelete = {fg = lvim.color_delete},
		-- GitGutterChangeDelete = {fg = lvim.color_change_delete},
		-- GitSignsAdd = {fg = lvim.color_add},
		-- GitSignsChange = {fg = lvim.color_change},
		-- GitSignsDelete = {fg = lvim.color_delete},
		-- GitSignsAddNr = {fg = lvim.color_add},
		-- GitSignsChangeNr = {fg = lvim.color_change},
		-- GitSignsDeleteNr = {fg = lvim.color_delete},
		-- GitSignsAddLn = {fg = lvim.color_add},
		-- GitSignsChangeLn = {fg = lvim.color_change},
		-- GitSignsDeleteLn = {fg = lvim.color_delete},
		-- SignifySignAdd = {fg = lvim.color_add},
		-- SignifySignChange = {fg = lvim.color_change},
		-- SignifySignDelete = {fg = lvim.color_delete},
		-- LvimHelperNormal = {fg = lvim.color_6, bg = lvim.base2},
		-- LvimHelperTitle = {fg = lvim.color_9, bg = lvim.none},
		-- NvimTreeNormal = {bg = lvim.black_background},
		-- NvimTreeFolderName = {fg = lvim.color_4},
		-- NvimTreeOpenedFolderName = {fg = lvim.color_11},
		-- NvimTreeEmptyFolderName = {fg = lvim.color_4},
		-- NvimTreeRootFolder = {fg = lvim.color_4},
		-- NvimTreeSpecialFile = {fg = lvim.fg, bg = lvim.none, style = "NONE"},
		-- NvimTreeFolderIcon = {fg = lvim.color_4},
		-- NvimTreeIndentMarker = {fg = lvim.hl},
		-- NvimTreeSignError = {fg = lvim.color_error},
		-- NvimTreeSignWarning = {fg = lvim.color_warning},
		-- NvimTreeSignInformation = {fg = lvim.color_info},
		-- NvimTreeSignHint = {fg = lvim.color_info},
		-- NvimTreeLspDiagnosticsError = {fg = lvim.color_error},
		-- NvimTreeLspDiagnosticsWarning = {fg = lvim.color_warning},
		-- NvimTreeLspDiagnosticsInformation = {fg = lvim.color_info},
		-- NvimTreeLspDiagnosticsHint = {fg = lvim.color_info},
		-- NvimTreeWindowPicker = {gui = "bold", fg = lvim.bg, bg = lvim.color_9},
		-- TroubleNormal = {bg = lvim.black_background},
		-- TelescopeBorder = {fg = lvim.color_11},
		-- TelescopePromptBorder = {fg = lvim.color_3},
		-- TelescopeMatching = {fg = lvim.color_11},
		-- TelescopeSelection = {fg = lvim.color_3, bg = lvim.bg_highlight},
		-- TelescopeSelectionCaret = {fg = lvim.color_3},
		-- TelescopeMultiSelection = {fg = lvim.color_11},
		-- Floaterm = {fg = lvim.color_9},
		-- FloatermBorder = {fg = lvim.color_1},
		VimwikiItalic = { fg = glitter.red_bright },
		VimwikiBold = { fg = glitter.green_bright },
		NvimCmpGhostText = { fg = glitter.bright_bg2 }
	}
	return plugin_syntax
end

function InsertStatusColor(mode)
	if (mode == 'i') then
		glitter.highlight('LineNr', {fg = glitter.insert})
		glitter.highlight('CursorLineNr', {fg = glitter.insert, style = glitter.reverse})
	elseif (mode == 'r') then
		glitter.highlight('LineNr', {fg = glitter.replace})
		glitter.highlight('CursorLineNr', {fg = glitter.replace, style = glitter.reverse})
	else
		glitter.highlight('LineNr', {fg = glitter.gray})
		glitter.highlight('CursorLineNr', {fg = glitter.gray, style = glitter.reverse})
	end
end

local async_load_plugin

async_load_plugin = vim.loop.new_async(vim.schedule_wrap(function()
	local syntax = glitter.load_plugin_syntax()
	for group, color in pairs(syntax) do glitter.highlight(group, color) end
	async_load_plugin:close()
end))

function glitter.colorscheme()
	glitter.transform(glitter.palette)
	vim.api.nvim_command("hi clear")
	if vim.fn.exists("syntax_on") then vim.api.nvim_command("syntax reset") end
	vim.g.colors_name = "glitter"
	local syntax = glitter.load_syntax()
	vim.api.nvim_command("autocmd InsertEnter,InsertChange * lua InsertStatusColor(vim.api.nvim_get_vvar('insertmode'))")
	vim.api.nvim_command("autocmd InsertLeave * lua InsertStatusColor('n')")
	for group, color in pairs(syntax) do glitter.highlight(group, color) end
	async_load_plugin:send()
end

if debug then io.close(logfile) end

glitter.colorscheme()

return glitter
