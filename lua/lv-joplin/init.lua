vim = vim
local api = vim.api
local fn = vim.fn

JOPLIN_BUFFER = nil
JOPLIN_LOADED = false
vim.g.joplin_opened = 0

--- Check if joplin is available
local function is_joplin_available()
    return fn.executable("joplin") == 1
end

--- on_exit callback function to delete the open buffer when joplin exits in a neovim terminal
local function on_exit(job_id, code, event)
    print(job_id, code, event)
    if code == 0 then
        -- Close the window where the JOPLIN_BUFFER is
        vim.cmd("silent! :q")
        JOPLIN_BUFFER = nil
        JOPLIN_LOADED = false
        vim.g.joplin_opened = 0
    end
end

--- Call joplin
local function exec_joplin_command(cmd)
    if JOPLIN_LOADED == false then
        -- ensure that the buffer is closed on exit
        vim.g.joplin_opened = 1
        vim.fn.termopen(cmd, { on_exit = on_exit })
    end
    vim.cmd "startinsert"
end

--- open floating window with nice borders
local function open_floating_window()
    local floating_window_scaling_factor = 0.9

    -- Why is this required?
    -- vim.g.joplin_floating_window_scaling_factor returns different types if the value is an integer or float
    if type(floating_window_scaling_factor) == 'table' then
        floating_window_scaling_factor = floating_window_scaling_factor[false]
    end

    local status, plenary = pcall(require, 'plenary.window.float')
    if status then
        plenary.percentage_range_window(floating_window_scaling_factor, floating_window_scaling_factor)
        return
    end

    local height = math.ceil(vim.o.lines * floating_window_scaling_factor) - 1
    local width = math.ceil(vim.o.columns * floating_window_scaling_factor)

    local row = math.ceil(vim.o.lines - height) / 2
    local col = math.ceil(vim.o.columns - width) / 2

    local border_opts = {
        style = "minimal",
        relative = "editor",
        row = row - 1,
        col = col - 1,
        width = width + 2,
        height = height + 2,
    }

    local opts = {
        style = "minimal",
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
    }

    local topleft, topright, botleft, botright
    local corner_chars = {'╭', '╮', '╰', '╯'}
    if type(corner_chars) == "table" and #corner_chars == 4 then
      topleft, topright, botleft, botright = unpack(corner_chars)
    else
      topleft, topright, botleft, botright = '╭', '╮', '╰', '╯'
    end

    local border_lines = {topleft .. string.rep('─', width) .. topright}
    local middle_line = '│' .. string.rep(' ', width) .. '│'
    for i = 1, height do
        table.insert(border_lines, middle_line)
    end
    table.insert(border_lines, botleft .. string.rep('─', width) .. botright)

    -- create a unlisted scratch buffer for the border
    local border_buffer = api.nvim_create_buf(false, true)

    -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
    api.nvim_buf_set_lines(border_buffer, 0, -1, true, border_lines)
    -- create border window
    local border_window = api.nvim_open_win(border_buffer, true, border_opts)
    vim.cmd('set winhl=Normal:Floating')

    -- create a unlisted scratch buffer
    if JOPLIN_BUFFER == nil then
        JOPLIN_BUFFER = api.nvim_create_buf(false, true)
    else
        JOPLIN_LOADED = true
    end
    -- create file window, enter the window, and use the options defined in opts
    local _ = api.nvim_open_win(JOPLIN_BUFFER, true, opts)

    vim.bo[JOPLIN_BUFFER].filetype = 'joplin'

    vim.cmd('setlocal bufhidden=hide')
    vim.cmd('setlocal nocursorcolumn')
    vim.cmd('set winblend=' .. 0)

    -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
    local cmd = [[autocmd WinLeave <buffer> silent! execute 'hide']]
    vim.cmd(cmd)
    cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s']]
    vim.cmd(cmd:format(border_buffer))
end

--- :LazyGit entry point
local function joplin()
    if is_joplin_available() ~= true then
        print("Please install joplin. Check documentation for more information")
        return
    end
    open_floating_window()
    local cmd = "joplin"
    exec_joplin_command(cmd)
end

return {
    joplin = joplin,
}
