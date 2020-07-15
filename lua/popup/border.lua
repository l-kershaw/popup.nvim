package.loaded['popup.border'] = nil

local utils = require('popup.utils')

local Border = {}

Border.__index = Border

Border._default_thickness = {
  top = 1,
  right = 1,
  bot = 1,
  left = 1,
}

function Border._create_lines(content_win_options, border_win_options)
  -- TODO: Handle border width, which I haven't right here.
  local thickness = border_win_options.border_thickness

  local top_enabled = thickness.top == 1
  local right_enabled = thickness.right == 1
  local bot_enabled = thickness.bot == 1
  local left_enabled = thickness.left == 1

  local border_lines = {}

  local topline = nil

  local topleft = (left_enabled and border_win_options.topleft) or ''
  local topright = (right_enabled and border_win_options.topright) or ''

  if border_win_options.title then
    local title = string.format(" %s ", border_win_options.title)
    local title_len = string.len(title)

    local midpoint = math.floor(content_win_options.width / 2)
    local left_start = midpoint - math.floor(title_len / 2)

    topline = string.format("%s%s%s%s%s",
      topleft,
      string.rep(border_win_options.top, left_start),
      title,
      string.rep(border_win_options.top, content_win_options.width - title_len - left_start),
      topright
    )
  else
    if top_enabled then
      topline = topleft
        .. string.rep(border_win_options.top, content_win_options.width)
        .. topright
    end
  end

  if topline then
    table.insert(border_lines, topline)
  end

  local middle_line = string.format(
    "%s%s%s",
    (left_enabled and border_win_options.left) or '',
    string.rep(' ', content_win_options.width),
    (right_enabled and border_win_options.right) or ''
  )

  for _ = 1, content_win_options.height do
    table.insert(border_lines, middle_line)
  end

  if bot_enabled then
    table.insert(border_lines,
      string.format(
        "%s%s%s",
        (left_enabled and border_win_options.botleft) or '',
        string.rep(border_win_options.bot, content_win_options.width),
        (right_enabled and border_win_options.botright) or ''
      )
    )
  end

  return border_lines
end

function Border:new(content_buf_id, content_win_id, content_win_options, border_win_options)
  assert(type(content_win_id) == 'number', "Must supply a valid win_id. It's possible you forgot to call with ':'")

  border_win_options = utils.apply_defaults(border_win_options, {
    border_thickness = Border._default_thickness,

    -- Border options, could be passed as a list?
    topleft  = '╔',
    topright = '╗',
    top      = '═',
    left     = '║',
    right    = '║',
    botleft  = '╚',
    botright = '╝',
    bot      = '═',
  })

  local obj = {}

  obj.content_win_id = content_win_id
  obj.content_win_options = content_win_options
  obj._border_win_options = border_win_options


  obj.buf_id = vim.api.nvim_create_buf(false, true)
  assert(obj.buf_id, "Failed to create border buffer")

  obj.contents = Border._create_lines(content_win_options, border_win_options)
  vim.api.nvim_buf_set_lines(obj.buf_id, 0, -1, false, obj.contents)

  local thickness = border_win_options.border_thickness

  obj.win_id = vim.api.nvim_open_win(obj.buf_id, false, {
    anchor = content_win_options.anchor,
    relative = content_win_options.relative,
    style = "minimal",
    row = content_win_options.row - thickness.top,
    col = content_win_options.col - thickness.left,
    width = content_win_options.width + thickness.left + thickness.right,
    height = content_win_options.height + thickness.top + thickness.bot,
  })

  local silent = true
  vim.cmd(
    string.format(
      "autocmd WinLeave,BufLeave,BufDelete <buffer=%s> ++once ++nested %s call nvim_win_close(%s, v:true)",
      content_buf_id,
      (silent and "silent!") or "",
      obj.win_id
    )
  )

  setmetatable(obj, Border)

  return obj
end


return Border
