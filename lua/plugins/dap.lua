local function configure_listeners(dap, dapui)
  dap.listeners.after.event_initialized['dapui_config'] = dapui.open
  dap.listeners.before.event_terminated['dapui_config'] = dapui.close
  dap.listeners.before.event_exited['dapui_config'] = dapui.close

  local notify_utils = require 'utils/nvim-notify'

  dap.listeners.before['event_progressStart']['progress-notifications'] = function(session, body)
    local notif_data = notify_utils.get_notif_data('dap', body.progressId)

    local message = format_message(body.message, body.percentage)
    notif_data.notification = vim.notify(message, 'info', {
      title = notify_utils.format_title(body.title, session.config.type),
      icon = notify_utils.spinner_frames[1],
      timeout = false,
      hide_from_history = false,
    })

    notif_data.notification.spinner = 1, notify_utils.update_spinner('dap', body.progressId)
  end

  dap.listeners.before['event_progressUpdate']['progress-notifications'] = function(session, body)
    local notif_data = notify_utils.get_notif_data('dap', body.progressId)
    notif_data.notification = vim.notify(notify_utils.format_message(body.message, body.percentage), 'info', {
      replace = notif_data.notification,
      hide_from_history = false,
    })
  end

  dap.listeners.before['event_progressEnd']['progress-notifications'] = function(session, body)
    local notif_data = client_notifs['dap'][body.progressId]
    notif_data.notification = vim.notify(body.message and notify_utils.format_message(body.message) or 'Complete', 'info', {
      icon = '',
      replace = notif_data.notification,
      timeout = 3000,
    })
    notif_data.spinner = nil
  end
end

local function configure_langs(dap)
  dap.adapters.godot = {
    type = 'server',
    host = '127.0.0.1',
    port = 6006,
  }

  dap.configurations.gdscript = {
    {
      type = 'godot',
      request = 'launch',
      name = 'Launch scene',
      project = '${workspaceFolder}',
      launch_scene = true,
    },
  }
end

local function configure_style()
  vim.api.nvim_set_hl(0, 'DapUIPlayPauseNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIRestartNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIStopNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIUnavailableNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIStepOverNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIStepIntoNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIStepBackNC', { link = 'WinBar' })
  vim.api.nvim_set_hl(0, 'DapUIStepOutNC', { link = 'WinBar' })

  vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#ff869a', bg = '#212432' })
  vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#82b1ff', bg = '#212432' })
  vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#c3e88d', bg = '#212432' })

  vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
  vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
  vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DapBreakpoint', linehl = 'DapBreakpoint', numhl = 'DapBreakpoint' })
  vim.fn.sign_define('DapLogPoint', { text = '󰛿', texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
  vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })
end

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'julianolf/nvim-dap-lldb',
  },
  keys = function(_, keys)
    local dap = require 'dap'
    local dapui = require 'dapui'
    return {
      { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },
      { '<F6>', dap.close, desc = 'Debug: Close' },
      { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
      { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
      { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
      { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>B',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
      { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local daplldb = require 'dap-lldb'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'lldb',
        'php-debug-adapter',
      },
    }

    dapui.setup()
    daplldb.setup {}

    configure_listeners(dap, dapui)
    configure_langs(dap)
    configure_style()
  end,
}
