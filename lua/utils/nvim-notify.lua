local client_notifs = {}

local module = {
  spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
}

function module.get_notif_data(client_id, token)
  if not client_notifs[client_id] then
    client_notifs[client_id] = {}
  end

  if not client_notifs[client_id][token] then
    client_notifs[client_id][token] = {}
  end

  return client_notifs[client_id][token]
end

function module.update_spinner(client_id, token)
  local notif_data = module.get_notif_data(client_id, token)

  if notif_data.spinner then
    local new_spinner = (notif_data.spinner + 1) % #module.spinner_frames
    notif_data.spinner = new_spinner

    notif_data.notification = vim.notify(nil, nil, {
      hide_from_history = true,
      icon = module.spinner_frames[new_spinner],
      replace = notif_data.notification,
    })

    vim.defer_fn(function()
      module.update_spinner(client_id, token)
    end, 100)
  end
end

function module.format_title(title, client_name)
  return client_name .. (#title > 0 and ': ' .. title or '')
end

function module.format_message(message, percentage)
  return (percentage and percentage .. '%\t' or '') .. (message or '')
end

return module
