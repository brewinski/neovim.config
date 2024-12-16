--aa- Documentation for setting up Sourcegraph Cody
--- Generating an access token: https://sourcegraph.com/docs/cli/how-tos/creating_an_access_token

---@class AvanteProviderFunctor
local M = {}

M.endpoint = 'https://sourcegraph.com'
M.api_key_name = 'SRC_ACCESS_TOKEN'
M.max_tokens = 7000
M.max_output_tokens = 4000
M.stream = true
M.topK = -1
M.topP = -1
M.model = 'anthropic::2024-10-22::claude-3-5-sonnet-latest'
M.proxy = nil
M.allow_insecure = false -- Allow insecure server connections
M.timeout = 30000 -- Timeout in milliseconds
M.temperature = 0

M.cody_context = {}

M.role_map = {
  user = 'human',
  assistant = 'assistant',
  system = 'system',
}

M.parse_context_messages = function(context)
  local codebase_context = {}

  for _, blob in ipairs(context) do
    local path = blob.blob.path
    local file_content = blob.chunkContent

    table.insert(codebase_context, {
      speaker = M.role_map.user,
      -- text = 'FILEPATH: ' .. path .. '\nCode:\n' .. file_content,
      text = 'FILEPATH: ' .. vim.inspect(blob),
    })
    table.insert(codebase_context, {
      speaker = M.role_map.assistant,
      text = 'Ok.',
    })
  end

  return codebase_context
end

M.parse_messages = function(opts)
  local messages = {
    { role = 'system', text = opts.system_prompt },
  }

  vim.iter(M.parse_context_messages(M.cody_context)):each(function(msg)
    table.insert(messages, msg)
  end)

  vim.iter(opts.messages):each(function(msg)
    table.insert(messages, { speaker = M.role_map[msg.role], text = msg.content })
  end)

  -- vim.api.nvim_notify(vim.inspect(messages), 1, {})

  return messages
end

M.parse_response_data = function(data_stream, event_state, opts)
  if event_state == 'done' then
    opts.on_complete()
    return
  end

  if event_state == 'error' then
    vim.notify(vim.inspect { name = 'codyProvider', stream = data_stream, state = event_state, opts = opts }, 1, {})
    opts.on_complete(data_stream)
    return
  end

  if data_stream == nil or data_stream == '' then
    return
  end

  local json = vim.json.decode(data_stream)
  local delta = json.deltaText
  local stopReason = json.stopReason

  if stopReason == 'end_turn' then
    -- opts.on_chunk('\n\n## context files:\n  - ' .. table.concat(M.get_context_file_list(M.cody_context), '\n  - '))
    return
  end

  opts.on_chunk(delta)
end

M.get_context_file_list = function(context)
  local codebase_context = {}

  for _, blob in ipairs(context) do
    local path = blob.blob.path

    table.insert(codebase_context, path)
  end

  return codebase_context
end

M.BASE_PROVIDER_KEYS = {
  'endpoint',
  'model',
  'deployment',
  'api_version',
  'proxy',
  'allow_insecure',
  'api_key_name',
  'timeout',
  -- internal
  'local',
  '_shellenv',
  'tokenizer_id',
  'use_xml_format',
  'role_map',
}

M.parse_config = function(opts)
  local s1 = {}
  local s2 = {}

  for key, value in pairs(opts) do
    if vim.tbl_contains(M.BASE_PROVIDER_KEYS, key) then
      s1[key] = value
    else
      s2[key] = value
    end
  end

  return s1,
    vim
      .iter(s2)
      :filter(function(_, v)
        return type(v) ~= 'function'
      end)
      :fold({}, function(acc, k, v)
        acc[k] = v
        return acc
      end)
end

M.parse_curl_args = function(provider, code_opts)
  local base, body_opts = M.parse_config(provider)

  local api_key = provider.parse_api_key()
  if api_key == nil then
    -- if no api key is available, make a request with a empty api key.
    api_key = ''
  end

  local headers = {
    ['Content-Type'] = 'application/json',
    ['Authorization'] = 'token ' .. api_key,
  }

  -- Get Cody context
  -- local context_query = code_opts.messages[#code_opts.messages].content -- Use the last message as the context query
  -- M.get_cody_context(base.endpoint, context_query, api_key)
  -- vim.api.nvim_notify(api_key.. "\n\n\n\n\n\n", 1, {})

  return {
    url = base.endpoint .. '/.api/completions/stream?api-version=2&client-name=vscode&client-version=1.34.3',
    timeout = base.timeout,
    insecure = false,
    headers = headers,
    body = vim.tbl_deep_extend('force', {
      model = base.model,
      temperature = body_opts.temperature,
      topK = body_opts.topK,
      topP = body_opts.topP,
      maxTokensToSample = M.max_output_tokens,
      stream = true,
      messages = M.parse_messages(code_opts),
    }, {}),
  }
end

M.on_error = function() end

M.get_cody_context = function(endpoint, query, api_key, repo)
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

  local headers = {
    ['Content-Type'] = 'application/json; charset=utf-8',
    ['x-sourcegraph-client'] = endpoint,
    ['Authorization'] = 'token ' .. api_key,
  }

  -- local current_repo = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  -- current_repo = vim.fn.fnamemodify(current_repo, ':t')
  local current_repo = 'UmVwb3NpdG9yeToxNjI='

  local body = {
    query = [[
      query GetCodyContext($repos: [ID!]!, $query: String!, $codeResultsCount: Int!, $textResultsCount: Int!, $filePatterns: [String!]) {
        getCodyContext(repos: $repos, query: $query, codeResultsCount: $codeResultsCount, textResultsCount: $textResultsCount, filePatterns: $filePatterns) {
          ...on FileChunkContext {
            blob {
              path
              repository {
                id
                name
              }
              commit {
                oid
              }
              url
            }
            startLine
            endLine
            chunkContent
            matchedRanges {
              start {
                line
                column: character
              }
              end {
                line
                column: character
              }
            }
          }
        }
      }
    ]],
    variables = {
      repos = { repo or current_repo },
      query = query,
      codeResultsCount = 15,
      textResultsCount = 5,
    },
  }

  local callback = function(response)
    -- Handle the response here
    if response.status == 200 then
      local data = vim.json.decode(response.body)

      vim.api.nvim_notify(vim.inspect(response), 1, {})

      if data.errors ~= nil then
        print('Error: ' .. 'query errors.')
        return nil
      end

      local context = data.data.getCodyContext
      -- Process the data as needed

      M.cody_context = context
    else
      print('Error: ' .. response.status)
      return nil
    end
  end

  if filetype == 'AvanteInput' then
    -- vim.api.nvim_notify('async', 1, {})
    local response = require('plenary.curl').post(endpoint .. '/.api/graphql?GetCodyContext', {
      headers = headers,
      body = vim.fn.json_encode(body),
    })
    callback(response)
  else
    -- vim.api.nvim_notify('sync', 1, {})
    require('plenary.curl').post(endpoint .. '/.api/graphql?GetCodyContext', {
      headers = headers,
      body = vim.fn.json_encode(body),
      callback = callback,
    })
  end
end

return M
