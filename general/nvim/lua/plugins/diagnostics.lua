-- Neovim's built-in virtual_lines always start a message under its error and
-- never wrap it, so errors near the right edge get cut off. This handler draws
-- the cursor line's diagnostics the same way, but wraps each message to the
-- window and, when there isn't enough room right of the error, moves the
-- message left and draws a connector back up to the error.

local ns = vim.api.nvim_create_namespace("wrapped_diagnostic_lines")
-- Per buffer, per diagnostic namespace: what vim.diagnostic last asked us to show
local shown = {} ---@type table<integer, table<integer, vim.Diagnostic[]>>

local CONNECTOR_WIDTH = 6 -- "└──── "
-- Wrap to the right of the error as long as at least this many columns are free
local MIN_ROOM = 40

local function highlight(diagnostic)
  local name = vim.diagnostic.severity[diagnostic.severity]
  return "DiagnosticVirtualLines" .. name:sub(1, 1) .. name:sub(2):lower()
end

local function widest_line(text)
  local widest = 0
  for line in text:gmatch("[^\n]+") do
    widest = math.max(widest, vim.fn.strdisplaywidth(line))
  end
  return widest
end

-- Word wrap that keeps a paragraph's indentation and splits words that are
-- longer than the whole width, so every line is guaranteed to fit.
local function wrap(message, width)
  local lines = {}
  for paragraph in message:gmatch("[^\n]+") do
    local indent = paragraph:match("^%s*")
    if #indent >= width then
      indent = ""
    end
    local line = ""
    for word in paragraph:gmatch("%S+") do
      while vim.fn.strdisplaywidth(indent .. word) > width do
        if line ~= "" then
          table.insert(lines, line)
          line = ""
        end
        local room = width - #indent
        table.insert(lines, indent .. vim.fn.strcharpart(word, 0, room))
        word = vim.fn.strcharpart(word, room)
      end
      local candidate = line == "" and (indent .. word) or (line .. " " .. word)
      if line ~= "" and vim.fn.strdisplaywidth(candidate) > width then
        table.insert(lines, line)
        candidate = indent .. word
      end
      line = candidate
    end
    if line ~= "" then
      table.insert(lines, line)
    end
  end
  return lines
end

-- A row is a sparse map of screen column -> {text, highlight}; turn it into
-- virt_lines chunks, padding the gaps with spaces.
local function to_chunks(row)
  local columns = vim.tbl_keys(row)
  table.sort(columns)
  local chunks, at = {}, 0
  for _, column in ipairs(columns) do
    if column >= at then
      if column > at then
        table.insert(chunks, { string.rep(" ", column - at), "" })
      end
      table.insert(chunks, row[column])
      at = column + vim.fn.strdisplaywidth(row[column][1])
    end
  end
  return chunks
end

local function is_free(row, column)
  for at, cell in pairs(row) do
    if column >= at and column < at + vim.fn.strdisplaywidth(cell[1]) then
      return false
    end
  end
  return true
end

local function render(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr or not shown[bufnr] then
    return
  end

  local info = vim.fn.getwininfo(win)[1]
  local text_width = info.width - info.textoff
  local leftcol = vim.api.nvim_win_call(win, function()
    return vim.fn.winsaveview().leftcol
  end)
  local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1

  -- Screen column of each error, counting tabs and inlay hints like Neovim does
  local items, anchor = {}, lnum
  for _, list in pairs(shown[bufnr]) do
    for _, diagnostic in ipairs(list) do
      if diagnostic.lnum == lnum and not diagnostic.message:find("^%s*$") then
        local column = vim.api.nvim_win_call(win, function()
          return vim.fn.virtcol({ lnum + 1, diagnostic.col + 1 }) - 1
        end)
        table.insert(items, {
          diagnostic = diagnostic,
          column = math.min(math.max(column - leftcol, 0), text_width - 1),
          hl = highlight(diagnostic),
        })
        anchor = math.max(anchor, diagnostic.end_lnum or lnum)
      end
    end
  end
  if #items == 0 then
    return
  end

  -- Rightmost first, like Neovim, so connectors of errors further left can
  -- pass through the rows drawn above them.
  table.sort(items, function(a, b)
    if a.column ~= b.column then
      return a.column > b.column
    end
    return a.diagnostic.severity > b.diagnostic.severity
  end)

  local indent = math.max(vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.indent(lnum + 1)
  end) - leftcol, 0)

  local virt_lines = {}
  for i, item in ipairs(items) do
    local diagnostic, column, hl = item.diagnostic, item.column, item.hl
    local message = diagnostic.code and (diagnostic.code .. ": " .. diagnostic.message) or diagnostic.message
    local wanted = math.min(widest_line(message), text_width - indent - 1)
    local room_right = text_width - column - CONNECTOR_WIDTH - 1

    local shares_column = false
    for j = i + 1, #items do
      shares_column = shares_column or items[j].column == column
    end

    local rows = {}
    if room_right >= math.min(wanted, MIN_ROOM) then
      local connector = (shares_column and "├" or "└") .. "──── "
      for n, line in ipairs(wrap(message, room_right)) do
        local row = { [column + CONNECTOR_WIDTH] = { line, hl } }
        if n == 1 then
          row[column] = { connector, hl }
        end
        table.insert(rows, row)
      end
    else
      -- Not enough room right of the error: start the message further left,
      -- no further than the code's indentation, and connect it back up.
      local start = math.max(indent, math.min(column, text_width - wanted - 1))
      local connector = start < column and ("┌" .. string.rep("─", column - start - 1) .. "┘") or "│"
      table.insert(rows, { [start] = { connector, hl } })
      for _, line in ipairs(wrap(message, text_width - start - 1)) do
        table.insert(rows, { [start] = { line, hl } })
      end
    end

    -- Errors still to be drawn (further left) get a vertical line through
    -- these rows wherever their column is free.
    for _, row in ipairs(rows) do
      for j = i + 1, #items do
        if is_free(row, items[j].column) then
          row[items[j].column] = { "│", items[j].hl }
        end
      end
      table.insert(virt_lines, to_chunks(row))
    end
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, anchor, 0, { virt_lines = virt_lines })
end

vim.diagnostic.handlers.wrapped_lines = {
  show = function(namespace, bufnr, diagnostics)
    shown[bufnr] = shown[bufnr] or {}
    shown[bufnr][namespace] = diagnostics
    render(bufnr)
  end,
  hide = function(namespace, bufnr)
    if shown[bufnr] then
      shown[bufnr][namespace] = nil
    end
    render(bufnr)
  end,
}

local group = vim.api.nvim_create_augroup("wrapped_diagnostic_lines", { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled", "WinResized", "BufEnter" }, {
  group = group,
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if shown[bufnr] then
      render(bufnr)
    end
  end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    shown[args.buf] = nil
  end,
})

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        -- Short inline hint on other lines; the cursor line gets the full
        -- message from the handler above instead.
        virtual_text = { current_line = false },
        virtual_lines = false,
        wrapped_lines = {},
      },
    },
  },
}
