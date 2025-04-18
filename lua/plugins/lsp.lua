local function configure_buffer_attach()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
      map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
      map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
      map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
      map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
      map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, '[T]oggle Inlay [H]ints')
      end
    end,
  })
end

local function configure_notifications()
  vim.lsp.handlers['$/progress'] = function(_, result, ctx)
    local client_id = ctx.client_id
    local val = result.value

    if not val.kind then
      return
    end

    local utils = require 'utils/nvim-notify'

    local notif_data = utils.get_notif_data(client_id, result.token)

    if val.kind == 'begin' then
      local message = utils.format_message(val.message, val.percentage)

      notif_data.notification = vim.notify(message, 'info', {
        title = utils.format_title(val.title, vim.lsp.get_client_by_id(client_id).name),
        icon = utils.spinner_frames[1],
        timeout = false,
        hide_from_history = false,
      })

      notif_data.spinner = 1
      utils.update_spinner(client_id, result.token)
    elseif val.kind == 'report' and notif_data then
      notif_data.notification = vim.notify(utils.format_message(val.message, val.percentage), 'info', {
        replace = notif_data.notification,
        hide_from_history = false,
      })
    elseif val.kind == 'end' and notif_data then
      notif_data.notification = vim.notify(val.message and utils.format_message(val.message) or 'Complete', 'info', {
        icon = '',
        replace = notif_data.notification,
        timeout = 3000,
      })

      notif_data.spinner = nil
    end
  end
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    configure_buffer_attach()
    configure_notifications()

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    local servers = {
      clangd = {},
      rust_analyzer = {},
      ts_ls = {},
      astro = {},
      phpactor = {},
      omnisharp = {},
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
    }

    require('lspconfig')['gdscript'].setup {
      name = 'godot',
      cmd = { 'ncat', '127.0.0.1', '6005' },
    }

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
      'codelldb',
      'clangd',
      'clang-format',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
  end,
}
