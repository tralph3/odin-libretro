package main

import lr "libretro"
import sdl "vendor:sdl3"
import cb "circular_buffer"
import "core:log"

CoreOptionValue :: struct {
    value: cstring,
    label: cstring,
}

CoreOption :: struct {
    display: cstring,
    info: cstring,
    values: [dynamic]CoreOptionValue,
    current_value: cstring,
    default_value: cstring,
}

EmulatorState :: struct {
    core: lr.LibretroCore,
    av_info: lr.SystemAvInfo,
    performance_level: uint,
    options: map[cstring]CoreOption,
    options_updated: bool,
}

load_game :: proc (core_path: string, rom_path: string) -> (ok: bool) {
    unload_game()

    core := lr.load_core(core_path) or_return

    callbacks := lr.Callbacks {
        environment = process_env_callback,
        video_refresh = video_refresh_callback,
        input_poll = input_poll_callback,
        input_state = input_state_callback,
        audio_sample = audio_sample_callback,
        audio_sample_batch = audio_sample_batch_callback,
    }


    lr.initialize_core(&core, &callbacks)

    lr.load_rom(&core, rom_path) or_return

    GLOBAL_STATE.emulator_state.core = core

    core.api.get_system_av_info(&GLOBAL_STATE.emulator_state.av_info)

    renderer_init_framebuffer()
    audio_update_sample_rate()

    return true
}

unload_game :: proc () {
    if GLOBAL_STATE.emulator_state.core.loaded {
        lr.unload_core(&GLOBAL_STATE.emulator_state.core)
        cb.clear(&GLOBAL_STATE.audio_state.buffer)
        GLOBAL_STATE.emulator_state.performance_level = 0
        core_options_free()
    }
}
