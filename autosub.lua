-- =============================================================================
-- SUBLIMINAL PATH CONFIGURATION
-- Change this path to where Subliminal is installed on your system!
--
-- macOS:   "/Users/YOUR_USERNAME/.venv/bin/subliminal" or "/usr/local/bin/subliminal"
-- Linux:   "/home/YOUR_USERNAME/.local/bin/subliminal" or "/usr/bin/subliminal"
-- Windows: "C:/Python311/Scripts/subliminal.exe" (use forward slashes '/' or '\\')
--
-- TIP: Run 'which subliminal' (macOS/Linux) or 'where subliminal' (Windows)
--      in your terminal/cmd to find your exact path.
-- =============================================================================
local subliminal = "/Users/YOUR_USERNAME/python-envs/subs/bin/subliminal"

local languages = {
    { 'English', 'en', 'eng' },
}

local logins = {}

local bools = {
    auto = true,
    debug = false,
    force = true,
    utf8 = true,
}

local excludes = {
    'no-subs-dl',
}

local includes = {}

local utils = require 'mp.utils'

local function log(msg, secs)
    secs = secs or 2.5
    mp.msg.info(msg)
    mp.osd_message(msg, secs)
end

local function autosub_allowed(directory)
    if not bools.auto then
        mp.msg.info('Auto-sub: Disabled in settings')
        return false
    end

    local duration = mp.get_property_number('duration')
    if duration and duration < 900 then
        mp.msg.info('Auto-sub: Video under 15 min, skipping')
        return false
    end

    if not directory or directory:find('^http') then
        mp.msg.info('Auto-sub: Stream or invalid path, skipping')
        return false
    end

    local active_format = mp.get_property('file-format') or ""
    if active_format:find('^cue') then
        mp.msg.info('Auto-sub: CUE sheet, skipping')
        return false
    end

    local not_allowed = { aiff=true, ape=true, flac=true, mp3=true, ogg=true, wav=true, wv=true, tta=true }
    if not_allowed[active_format] then
        mp.msg.info('Auto-sub: Audio file, skipping')
        return false
    end

    for _, exclude in ipairs(excludes) do
        local escaped_exclude = exclude:gsub('%W', '%%%0')
        if directory:find(escaped_exclude) then
            mp.msg.info('Auto-sub: Excluded path, skipping')
            return false
        end
    end

    if #includes > 0 then
        local is_included = false
        for _, include in ipairs(includes) do
            local escaped_include = include:gsub('%W', '%%%0')
            if directory:find(escaped_include) then
                is_included = true
                break
            end
        end
        if not is_included then
            mp.msg.info('Auto-sub: Path not in include list, skipping')
            return false
        end
    end

    return true
end

local function should_download_subs_in(language, sub_tracks)
    for i, track in ipairs(sub_tracks) do
        local sub_type = track['external'] and 'file' or 'embedded'

        if not track['lang'] and (track['external'] or not track['title']) and i == #sub_tracks then
            log('Unlabeled subtitle track active')
            return false
        elseif track['lang'] == language[3] or track['lang'] == language[2] or
               (track['title'] and track['title']:lower():find(language[3])) then
            if not track['selected'] then
                mp.set_property('sid', track['id'])
                log('Enabled ' .. language[1] .. ' subtitles (' .. sub_type .. ')')
            else
                log(language[1] .. ' subtitles active')
            end
            return false
        end
    end
    mp.msg.info('No ' .. language[1] .. ' subtitles detected. Searching online...')
    return true
end

local function download_subs(language)
    language = language or languages[1]
    if not language or #language == 0 then
        log('No language specified')
        return
    end

    local path = mp.get_property('path')
    if not path then
        log('No media file loaded')
        return
    end

    local directory, filename = utils.split_path(path)
    log('Searching for ' .. language[1] .. ' subtitles...', 30)

    local cmd_args = { subliminal }

    for _, login in ipairs(logins) do
        table.insert(cmd_args, login[1])
        table.insert(cmd_args, login[2])
        table.insert(cmd_args, login[3])
    end

    if bools.debug then table.insert(cmd_args, '--debug') end
    table.insert(cmd_args, 'download')
    if bools.force then table.insert(cmd_args, '-f') end
    if bools.utf8 then
        table.insert(cmd_args, '-e')
        table.insert(cmd_args, 'utf-8')
    end

    table.insert(cmd_args, '-l')
    table.insert(cmd_args, language[2])
    table.insert(cmd_args, '-d')
    table.insert(cmd_args, directory)
    table.insert(cmd_args, filename)

    mp.command_native_async({
        name = "subprocess",
        args = cmd_args,
        capture_stdout = true,
        capture_stderr = true
    }, function(success, result, error)
        if success and result and result.stdout and result.stdout:find('Downloaded 1 subtitle') then
            mp.set_property('slang', language[2])
            mp.commandv('rescan_external_files')
            log(language[1] .. ' subtitles downloaded!')
        else
            log('No ' .. language[1] .. ' subtitles found')
        end
    end)
end

local function control_downloads()
    mp.set_property('sub-auto', 'fuzzy')
    mp.set_property('slang', languages[1][2])
    mp.commandv('rescan_external_files')

    local path = mp.get_property('path')
    if not path then return end

    local directory, _ = utils.split_path(path)

    if not autosub_allowed(directory) then
        return
    end

    local sub_tracks = {}
    local track_list = mp.get_property_native('track-list') or {}
    for _, track in ipairs(track_list) do
        if track['type'] == 'sub' then
            table.insert(sub_tracks, track)
        end
    end

    for _, language in ipairs(languages) do
        if should_download_subs_in(language, sub_tracks) then
            download_subs(language)
            return
        else
            return
        end
    end
end

mp.add_key_binding('b', 'download_subs', function() download_subs(languages[1]) end)
mp.register_event('file-loaded', control_downloads)
