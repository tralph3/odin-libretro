package main

import lr "libretro"
import cl "clay"

States :: enum {
    LOGIN,
    MENU,
    RUNNING,
    PAUSED,
}

ProgramState :: struct {
    state: States,
    config: Config,
    input: [16]i16,
    current_user: string,
    video: FrameBuffer,
    audio: AudioBuffer,
    av_info: lr.SystemAvInfo,
    core: lr.LibretroCore,
    clay_arena: cl.Arena,
}

STATE := ProgramState {
    state = .LOGIN,
    video = FrameBuffer {
        pixel_format = lr.RetroPixelFormat.ZRGB1555
    },
    core = {
        loaded = false,
    },
    av_info = {
        timing = {
            fps = 60,
        }
    },
    config = config_load_default(),
}
