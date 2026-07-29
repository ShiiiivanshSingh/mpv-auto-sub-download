# mpv-subliminal-subs
A Lua script for [mpv](https://mpv.io) that automatically downloads English subtitles using [Subliminal](https://github.com/Diaoul/subliminal).

original repo credit : https://github.com/davidde/mpv-autosub

| SEARCH | SUCCESS |
|--------|---------|
| <img src="https://github.com/user-attachments/assets/f8ca03a5-47df-409f-a0b6-4a499cc962c7" width="450"> | <img src="https://github.com/user-attachments/assets/32acc6b4-cf50-4720-a609-57beb5eb39dd" width="450"> |

## Features

- Automatically downloads English subtitles.
- Uses existing English subtitles if available.
- Skips audio files, streams, short videos, and excluded folders.
- Shows simple on-screen status messages.
- Press **`b`** to search for subtitles manually.

## Prerequisites

- [mpv](https://mpv.io)
- Subliminal CLI -> pip install subliminal

# Changes ive made from davidde's version


- Replaced synchronous `utils.subprocess()` with `mp.command_native_async()` for **non-blocking subtitle downloads**.
- Improved variable scope by using **local variables** instead of globals.
- Added **safer nil checks** to prevent runtime errors.
- Simplified audio format detection using **lookup tables**.
- Refactored functions for **better readability and maintainability**.
- Simplified configuration by keeping **English as the default language**.
- Improved logging with clearer status messages.
- Cleaned up path and subtitle track handling.
