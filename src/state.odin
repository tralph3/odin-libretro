package main

import lr "libretro"
import cl "clay"
import "base:runtime"

GLOBAL_STATE := struct #no_copy {
    current_user: string,

    game_entries: [dynamic]GameEntry,

    config: Config,

    current_scene_id: SceneID,

    frame_counter: u64,
    delta_time: f32,

    event_offset: u32,

    ctx: runtime.Context,
} {
    current_scene_id = .LOGIN,
}

state_get_context :: proc () -> runtime.Context {
    return GLOBAL_STATE.ctx
}
