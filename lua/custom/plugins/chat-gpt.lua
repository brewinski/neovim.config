local M = {}

-- TODO: cleanup and organise the code
-- TODO: I can't update the input to make the chat area larger, however I can add some custom buffers to help with that.
-- TODO: setup tracking and rendering chat history. (do this after implementing different model modules)

-- Utility to make async HTTP requests
local Job = require 'plenary.job'

-- Telescope picker UI
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'
local state = require 'telescope.state'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local api_key = os.getenv 'GEMINI_API_KEY'
-- set the api key to an empty key when not set
if api_key == nil then
  api_key = 'default_value'
end

local llm_api_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=' .. api_key

-- Store chat messages
local chat = {
  list = {},
  chats = {},
  active = '',
  in_progress = false,
}

local function new_chat_session()
  vim.ui.input({
    prompt = 'New Chat: ',
  }, function(chat_session_name)
    -- skip ading if it already exists
    for _, v in ipairs(chat.list) do
      if v == chat_session_name then
        return
      end
    end

    -- create the table list
    table.insert(chat.list, 1, chat_session_name)
    -- initialize the chat history
    chat.chats[chat_session_name] = {}
    -- set the new chat as the active chat
    chat.active = chat_session_name
  end)
end

local function new_chat_session_v2()
  local session_name = action_state.get_current_line() -- Get user input from prompt

  if session_name == nil or session_name == '' then
    return new_chat_session()
  end

  -- skip adding if it already exists
  for _, v in ipairs(chat.list) do
    if v == session_name then
      return
    end
  end

  -- create the table list
  table.insert(chat.list, 1, session_name)
  -- initialize the chat history
  chat.chats[session_name] = {}
  -- set the new chat as the active chat
  chat.active = session_name
end

-- Helper function to split multiline text into separate lines
local function split_lines(input)
  local lines = {}
  for line in input:gmatch '[^\r\n]+' do
    table.insert(lines, line)
  end
  return lines
end

-- Append each line of message to chat history and update results
local function append_message(sender, message)
  if chat.active == '' then
    print 'no active chats, start a new chat with <C-n>'
    return
  end

  local lines = split_lines(message) -- Split multiline message into individual lines

  table.insert(chat.chats[chat.active], sender .. ': ')

  for _, line in ipairs(lines) do
    table.insert(chat.chats[chat.active], '' .. line)
  end

  table.insert(chat.chats[chat.active], '')
end

-- Define a custom highlight group for "You:" and "Bot:"
local function set_highlight_groups()
  -- Set highlight for "You:"
  vim.api.nvim_set_hl(0, 'HighlightYou', { fg = '#8839ef', bold = true }) -- Green and bold
  -- Set highlight for "Bot:"
  vim.api.nvim_set_hl(0, 'HighlightBot', { fg = '#7287fd', bold = true }) -- Red and bold
end

-- Function to highlight every instance of "You:" and "Bot:" in the buffer
local function highlight_you_and_bot(bufnr)
  -- Set up the highlight groups
  set_highlight_groups()

  -- Get the number of lines in the buffer
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  -- Iterate over each line in the buffer
  for i = 0, line_count - 1 do
    -- Get the content of the current line
    local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1]

    -- Find all instances of "You:" and highlight them
    local start_you, end_you = line:find 'You:'
    if start_you then
      vim.api.nvim_buf_add_highlight(bufnr, -1, 'HighlightYou', i, start_you - 1, end_you)
    end

    -- Find all instances of "Bot:" and highlight them
    local start_bot, end_bot = line:find 'Bot:'
    if start_bot then
      vim.api.nvim_buf_add_highlight(bufnr, -1, 'HighlightBot', i, start_bot - 1, end_bot)
    end
  end
end

-- Function to make a request to the LLM API
local function request_llm(prompt, callback)
  -- Prepare request body
  local body = vim.json.encode {
    contents = {
      {
        parts = {
          { text = prompt },
        },
      },
    },
  }

  -- Make HTTP request to OpenAI API using curl
  Job:new({
    command = 'curl',
    args = {
      '-X',
      'POST',
      llm_api_url,
      '-H',
      'Content-Type: application/json',
      '-d',
      body,
    },
    on_exit = function(j, return_val)
      if return_val == 0 then
        local result = table.concat(j:result(), '\n')
        local response = vim.json.decode(result)

        if response and response.candidates and response.candidates[1] and response.candidates[1].content and response.candidates[1].content.parts[1] then
          local message = response.candidates[1].content.parts[1].text
          callback(message)
        else
          callback 'Error: No valid response from API.'
        end
      else
        callback 'Error: Failed to reach API.'
      end
    end,
  }):start()
  -- :sync(10000, 1000)
end

local function get_previwer()
  return previewers.new_buffer_previewer {
    define_preview = function(self, entry, status)
      -- Enable linebreak to ensure wrapping at word boundaries
      -- vim.api.nvim_win_set_option(status.preview_win, 'linebreak', true)
      -- Enable wrapping in the window
      vim.api.nvim_win_set_option(status.preview_win, 'wrap', true)

      -- Set the preview content to the map value for the selected key
      local content = chat.chats[entry[1]]
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)

      -- Set the filetype to 'markdown' to enable Markdown syntax highlighting
      vim.api.nvim_buf_set_option(self.state.bufnr, 'filetype', 'markdown')

      highlight_you_and_bot(self.state.bufnr)

      local preview_win = status.preview_win
      local rows = vim.api.nvim_buf_line_count(self.state.bufnr)

      if preview_win ~= nil and rows > 5 then
        -- TODO: should this actually be a vim.defer_fn?
        vim.schedule(function()
          vim.api.nvim_win_set_cursor(preview_win, { rows - 1, 1 })
        end)
      end
    end,
  }
end

-- Function to pop the preview content into a new buffer
local function pop_preview_to_buffer(entry)
  -- Create a new buffer and set its content
  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = chat.chats[entry.value]
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set syntax highlighting to markdown (if needed)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')

  local relative_win_size = 0.75

  local cols = vim.o.columns
  local rows = vim.o.lines

  local win_width = math.floor(cols * relative_win_size)
  local win_height = math.floor(rows * relative_win_size)

  local start_col = math.floor((cols - win_width) / 2)
  local start_row = math.floor((rows - win_height) / 2)

  -- Open the buffer in a new split window
  vim.api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    width = win_width,
    height = win_height, -- 80% of the screen height
    row = start_row,
    col = start_col,
    border = 'rounded',
  })
end

-- Function to render chat window
local function chat_window()
  local picker = pickers.new({
    prompt_title = 'test',
    layout_config = {
      preview_width = 0.65,
    },
  }, {
    prompt_title = 'Send message for: ' .. chat.active,
    finder = finders.new_table {
      results = chat.list,
    },
    previewer = get_previwer(),
    attach_mappings = function(prompt_bufnr, map)
      -- Bind a key to pop out the preview content (let's say <C-b>)
      map('i', '<C-b>', function()
        local entry = action_state.get_selected_entry()
        pop_preview_to_buffer(entry)
      end)

      map('i', '<C-n>', function()
        new_chat_session_v2()
        -- re-render
        actions.close(prompt_bufnr)
        chat_window()
      end)

      map('n', 'n', function()
        new_chat_session()
        -- re-render
        actions.close(prompt_bufnr)
        chat_window()
      end)

      -- Map Enter key to send message
      map('i', '<CR>', function()
        local input = action_state.get_current_line() -- Get user input from prompt
        local entry = action_state.get_selected_entry()

        -- if the hovered chat is different then update the selected chat.
        if entry[1] ~= nil and entry[1] ~= '' and entry[1] ~= chat.active then
          chat.active = entry[1]
          chat.list[1], chat.list[entry.index] = chat.list[entry.index], chat.list[1]
        end

        if table.getn(chat.list) <= 0 then
          new_chat_session_v2()
        end

        -- if we have input and we're not already makeing an api request, make a request.
        if input and input ~= '' and chat.in_progress == false then
          append_message('You', input) -- Append input to chat history

          chat.in_progress = true
          -- Make the LLM API request
          request_llm(input, function(bot_response)
            vim.schedule(function()
              chat.in_progress = false
              append_message('Bot', bot_response)
              actions.close(prompt_bufnr)
              chat_window()
            end)
          end)
        end

        -- if we're here and we aren't waiting for a chat, then let's re-render and make sure we're displaying
        -- up to date user interfaces
        if chat.in_progress ~= true then
          actions.close(prompt_bufnr)
          chat_window()
        end
      end)

      -- Allow normal closing (Escape key)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
      end)

      return true
    end,
  })

  picker:find()
end

-- Open chat window

M.setup = function()
  -- Optional keybinding
  vim.keymap.set('n', '<leader>ch', chat_window, { noremap = true, silent = true })
end

M.setup()

return {
  dir = '~/noop',
  dev = true,
}
