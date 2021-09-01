-- vim:tabstop=4

package.loaded["one"] = nil

local colors = require('colors')

local one = {}

one.palette = {
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
function one.transform (tbl)
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
	local result = clone(tbl)
	value = value or colorful_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, s, l = colors.rgb_string_to_hsl(item[2])
		if not (s <= value + spread) or not (l >= 0.9)  then table.remove(result, i); goto restart end
	end
	return result
end

function colorful(tbl, value)
	local result = clone(tbl)
	value = value or colorful_threshold
	::restart::
	for i, item in ipairs(result) do
		local _, s, l = colors.rgb_string_to_hsl(item[2])
		if not (s >= value - spread) or (l >= 0.9) then table.remove(result, i); goto restart end
	end
	return result
end

function hue(tbl, angle)
	local result = clone(tbl)
	angle = angle or 180
	::reiterate::
	local anglePlus = angle + hue_spread
	local angleMinus = angle - hue_spread
	if (angle + hue_spread > 360) then anglePlus = angle + hue_spread - 360 end
	if (angle - hue_spread < 0) then angleMinus = angle - hue_spread + 360 end
	::restart::
	for i, item in ipairs(result) do
		local h, _, _ = colors.rgb_string_to_hsl(item[2])
		if not (h <= anglePlus) and not (h >= angleMinus) then table.remove(result, i); goto restart end
	end
	if #result == 0 then hue_spread = hue_spread + 12; goto reiterate end
	return result
end

-- Взятие верхних позиций таблицы
function pop(tbl, amount)
	local result = {}
	amount = amount or 1
	for i = 1, amount do table.insert(result, tbl[i]) end
	return result
end

function slice(tbl)
end

-- Взятие нижних позиций из таблицы
function pop_back(tbl, amount)
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
  result = clone(tbl)
  table.sort(tbl, function(e1, e2)
	h1, _, _ = colors.rgb_string_to_hsl(e1[2])
	h2, _, _ = colors.rgb_string_to_hsl(e2[2])
	return h1 < h2
  end)
  return result
end

function sort_by_saturation(tbl)
  result = clone(tbl)
  table.sort(result, function(e1, e2)
	_, s1, _ = colors.rgb_string_to_hsl(e1[2])
	_, s2, _ = colors.rgb_string_to_hsl(e2[2])
	return s1 < s2
  end)
  return result
end

function sort_by_lightness(tbl)
  result = clone(tbl)
  table.sort(result, function(e1, e2)
	_, _, l1 = colors.rgb_string_to_hsl(e1[2])
	_, _, l2 = colors.rgb_string_to_hsl(e2[2])
	return l1 < l2
  end)
  return result
end

function sort_by_red(tbl)
  result = clone(tbl)
  table.sort(result, function(e1, e2)
	r1, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	r2, _, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return r1 < r2
  end)
  return result
end

function sort_by_green(tbl)
  result = clone(tbl)
  table.sort(result, function(e1, e2)
	_, g1, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e1[2]))
	_, g2, _ = colors.hsl_to_rgb(colors.rgb_string_to_hsl(e2[2]))
	return g1 < g2
  end)
  return result
end

function sort_by_blue(tbl)
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

function filter(tbl, ...)
	local result = clone(tbl)
	local file = io.open('r:\\colorlog.txt', "a")
	io.output(file)
	for i, fn in ipairs({...}) do
		local func = fn[1]
		local param = fn[2]
		local param2 = fn[3]
		result = func(result, param, param2)
	  	io.write(print_colors(result, string.format('\ncall #%d -------------\n', i)))
	end
	io.close(file)
	return result
end

function one.highlight(group, color)
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

one.none = {{"NONE", "NONE"}}
one.underline = {{"underline", "undercurl"}}

one.default_fg = filter(one.palette, {light}, {sort_by_lightness}, {pop_back, 2}, {pop})
one.default_bg = filter(one.palette, {dark}, {sort_by_lightness}, {distanceSL, 2, 0.1}, {pop_back, 2}, {pop})

one.brighter_bg = filter(one.palette, {dark}, {sort_by_lightness}, {distanceSL, 2, 0.1}, {pop_back})

one.dark_bg = filter(one.palette, {dark}, {sort_by_lightness}, {pop})
one.bright_fg = filter(one.palette, {light}, {sort_by_lightness}, {pop_back})

one.red = filter(one.palette, {light}, {hue, 0}, { pop_back, 2 })
one.blue = filter(one.palette, {colorful}, {sort_by_blue}, { pop_back, 2 })

one.gray = filter(one.palette, { sort_by_saturation }, { pop })

function one.load_syntax()
	local syntax = {
		Normal =		{fg = one.default_fg, bg = one.default_bg},
		Terminal =		{fg = one.default_fg, bg = one.none},
		SignColumn =	{fg = one.default_fg, bg = one.none},
		FoldColumn =	{fg = one.default_fg, bg = one.none},
		VertSplit =	{fg = one.dark_bg, bg = one.none},
		-- Folded =	{fg = lvim.color_12, bg = lvim.bg_highlight},
		EndOfBuffer =			{fg = one.default_bg, bg = one.none},
		-- IncSearch =	{fg = lvim.base0, bg = lvim.color_13, style = lvim.none},
		-- Search =	{fg = lvim.base0, bg = lvim.color_13},
		-- ColorColumn =			{fg = lvim.none, bg = lvim.bg_highlight},
		-- Conceal =	{fg = lvim.color_12, bg = lvim.none},
		-- Cursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- vCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- iCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- lCursor =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- CursorIM =	{fg = lvim.none, bg = lvim.none, style = "reverse"},
		-- CursorColumn =			{fg = lvim.none, bg = lvim.bg_highlight},
		CursorLine =			{fg = one.bright_fg, bg = one.brighter_bg, style=one.none},
		LineNr =	{fg = one.default_fg},
		-- qfLineNr =	{fg = lvim.color_10},
		CursorLineNr =			{fg = one.bright_fg},
		-- DiffAdd =	{fg = lvim.black, bg = lvim.color_6},
		-- DiffChange =			{fg = lvim.black, bg = lvim.color_3},
		-- DiffDelete =			{fg = lvim.black, bg = lvim.color_0},
		-- DiffText =	{fg = lvim.black, bg = lvim.fg},
		-- Directory =	{fg = lvim.color_8, bg = lvim.none},
		ErrorMsg =			{fg = one.dark_bg, bg = one.red},
		WarningMsg =			{fg = one.red, bg = one.none},
		-- ModeMsg =	{fg = lvim.color_6, bg = lvim.none},
		-- FocusedSymbol =			{fg = lvim.color_5},
		MatchParen =			{fg = one.bright_fg},
		-- NonText =	{fg = lvim.bg1},
		-- Whitespace =			{fg = lvim.base2},
		-- SpecialKey =			{fg = lvim.bg1},
		Pmenu =					{fg = one.default_fg, bg = one.brighter_bg},
		PmenuSel =				{fg = one.bright_fg, bg = one.gray },
		PmenuSelBold =			{fg = one.bright_fg},
		PmenuSbar =				{fg = one.gray},
		PmenuThumb =			{fg = one.bright_fg, bg = one.gray},
		-- WildMenu =	{fg = lvim.color_10, bg = lvim.color_5},
		-- Question =	{fg = lvim.color_3},
		-- NormalFloat =			{fg = lvim.bg_visual, bg = lvim.base2},
		Tabline =				{fg = one.gray, bg = one.dark_bg},
		TabLineFill =			{bg = one.dark_bg, style = one.none},
		TabLineSel =			{fg = one.bright_fg, bg = one.default_bg, style = one.none},
		StatusLine =			{fg = one.default_fg, bg = one.brighter_bg, style = one.none},
		StatusLineNC =			{fg = one.default_bg, bg = one.brighter_bg, style = one.none},
		SpellBad =				{fg = one.red, bg = one.none, style = one.underline},
		SpellCap =				{fg = one.red, bg = one.none, style = one.underline},
		SpellLocal =			{fg = one.red, bg = one.none, style = one.underline},
		SpellRare =				{fg = one.blue, bg = one.none, style = one.underline},
		-- Visual =	{fg = lvim.color_12, bg = lvim.black},
		-- VisualNOS =	{fg = lvim.color_12, bg = lvim.black},
		-- QuickFixLine =			{fg = lvim.color_9},
		-- Debug =		{fg = lvim.color_2},
		-- debugBreakpoint =		{fg = lvim.bg, bg = lvim.color_0},
		-- Boolean =	{fg = lvim.color_2},
		-- Number =	{fg = lvim.color_13},
		-- Float =		{fg = lvim.color_13},
		-- PreProc =	{fg = lvim.color_9},
		-- PreCondit =	{fg = lvim.color_9},
		-- Include =	{fg = lvim.color_9},
		-- Define =	{fg = lvim.color_3},
		-- Conditional =			{fg = lvim.color_5},
		-- Repeat =	{fg = lvim.color_10},
		-- Keyword =	{fg = lvim.color_2},
		-- Typedef =	{fg = lvim.color_0},
		-- Exception =	{fg = lvim.color_0},
		-- Statement =	{fg = lvim.color_0},
		-- Error =		{fg = lvim.color_error},
		-- StorageClass =			{fg = lvim.color_2},
		-- Tag =		{fg = lvim.color_8},
		-- Label =		{fg = lvim.color_2},
		-- Structure =	{fg = lvim.color_2},
		-- Operator =	{fg = lvim.color_5},
		-- Title =		{fg = lvim.color_2},
		-- Special =	{fg = lvim.fg, style = "bold"},
		-- SpecialChar =			{fg = lvim.fg, style = "bold"},
		-- Type =		{fg = lvim.color_11},
		-- Function =	{fg = lvim.color_3},
		-- String =	{fg = lvim.color_4},
		-- Character =	{fg = lvim.color_5},
		-- Constant =	{fg = lvim.color_7},
		-- Macro =		{fg = lvim.color_7},
		-- Identifier =			{fg = lvim.color_8},
		-- Comment =	{fg = lvim.color_6},
		-- SpecialComment	{fg = lvim.color_6},
		-- Todo =		{fg = lvim.color_6},
		-- Delimiter =	{fg = lvim.color_5},
		-- Ignore =	{fg = lvim.color_12},
		-- Underlined =			{fg = lvim.none, style = "underline"},
	}
	return syntax
end

function one.load_plugin_syntax()
	local plugin_syntax = {
		-- TSAnnotation = {fg = lvim.color_0},
		-- TSAttribute = {fg = lvim.color_1},
		-- TSBoolean = {fg = lvim.color_2},
		-- TSCharacter = {fg = lvim.color_3},
		-- TSConditional = {fg = lvim.color_4},
		-- TSConstant = {fg = lvim.color_5},
		-- TSEmphasis = {fg = lvim.color_3},
		-- TSError = {fg = lvim.color_7},
		-- TSException = {fg = lvim.color_1},
		-- TSField = {fg = lvim.color_9},
		-- TSFloat = {fg = lvim.color_10},
		-- TSFuncBuiltin = {fg = lvim.color_3},
		-- TSFuncMacro = {fg = lvim.color_12},
		-- TSKeywordFunction = {fg = lvim.color_3},
		-- TSLiteral = {fg = lvim.color_10},
		-- TSNamespace = {fg = lvim.color_0},
		-- TSNumber = {fg = lvim.color_1},
		-- TSParameterReference = {fg = lvim.color_2},
		-- TSPunctSpecial = {fg = lvim.color_3},
		-- TSRepeat = {fg = lvim.color_4},
		-- TSString = {fg = lvim.color_5},
		-- TSStringEscape = {fg = lvim.color_6},
		-- TSStringRegex = {fg = lvim.color_7},
		-- TSStrong = {fg = lvim.color_1},
		-- TSStructure = {fg = lvim.color_9},
		-- TSText = {fg = lvim.color_10},
		-- TSTitle = {fg = lvim.color_11},
		-- TSTypeBuiltin = {fg = lvim.color_3},
		-- TSUnderline = {fg = lvim.color_13},
		-- TSURI = {fg = lvim.color_10},
		-- TSInclude = {fg = lvim.color_0},
		-- TSPunctBracket = {fg = lvim.color_2},
		-- TSPunctDelimiter = {fg = lvim.color_2},
		-- TSType = {fg = lvim.color_11},
		-- TSFunction = {fg = lvim.color_9},
		-- TSTagDelimiter = {fg = lvim.color_6},
		-- TSProperty = {fg = lvim.color_3},
		-- TSMethod = {fg = lvim.color_1},
		-- TSParameter = {fg = lvim.color_9},
		-- TSConstructor = {fg = lvim.color_3},
		-- TSVariable = {fg = lvim.color_9},
		-- TSOperator = {fg = lvim.color_3},
		-- TSKeyword = {fg = lvim.color_0},
		-- TSVariableBuiltin = {fg = lvim.color_10},
		-- TSTag = {fg = lvim.color_3},
		-- TSLabel = {fg = lvim.color_1},
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
		-- LspDiagnosticsSignError = {fg = lvim.color_error},
		-- LspDiagnosticsSignWarning = {fg = lvim.color_warning},
		-- LspDiagnosticsSignInformation = {fg = lvim.color_info},
		-- LspDiagnosticsSignHint = {fg = lvim.color_info},
		-- LspDiagnosticsVirtualTextError = {fg = lvim.color_error},
		-- LspDiagnosticsVirtualTextWarning = {fg = lvim.color_warning},
		-- LspDiagnosticsVirtualTextInformation = {fg = lvim.color_info},
		-- LspDiagnosticsVirtualTextHint = {fg = lvim.color_info},
		-- LspSignatureActiveParameter = {fg = lvim.color_info},
		-- LspDiagnosticsUnderlineError = {
			-- style = "undercurl",
			-- sp = lvim.color_error
		-- },
		-- LspDiagnosticsUnderlineWarning = {
			-- style = "undercurl",
			-- sp = lvim.color_warning
		-- },
		-- LspDiagnosticsUnderlineInformation = {
			-- style = "undercurl",
			-- sp = lvim.color_info
		-- },
		-- LspDiagnosticsUnderlineHint = {
			-- style = "undercurl",
			-- sp = lvim.color_info
		-- },
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
	}
	return plugin_syntax
end

local async_load_plugin

async_load_plugin = vim.loop.new_async(vim.schedule_wrap(function()
	local syntax = one.load_plugin_syntax()
	for group, colors in pairs(syntax) do one.highlight(group, colors) end
	async_load_plugin:close()
end))

function one.colorscheme()
	one.transform(one.palette)
	vim.api.nvim_command("hi clear")
	if vim.fn.exists("syntax_on") then vim.api.nvim_command("syntax reset") end
	vim.g.colors_name = "one"
	local syntax = one.load_syntax()
	for group, colors in pairs(syntax) do one.highlight(group, colors) end
	async_load_plugin:send()
end

one.colorscheme()

return one
