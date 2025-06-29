package main

import sdl "vendor:sdl3"
import lr "libretro"
import "core:log"
import "core:slice"
import "core:c"

INPUT_MAX_PLAYERS :: 8

InputPlayerState :: struct #no_copy {
    joypad: [lr.RetroDeviceIdJoypad]i16,
    analog: [max(lr.RetroDeviceIdJoypad)]i16,
    gamepad: ^sdl.Gamepad,
}

InputMouseState :: struct #no_copy {
    wheel_movement: [2]f32,
    clicked: bool,
    down: bool,
    position: [2]f32,
}

InputState :: struct #no_copy {
    players: [INPUT_MAX_PLAYERS]InputPlayerState,
    // there's no keyboard input per player
    keyboard: [len(lr.RetroKey)]bool,
    mouse: InputMouseState,
}

input_init :: proc () -> (ok: bool) {
    if !input_open_gamepads() {
        log.warn("A gamepad failed to open. Try reconnecting.")
    }
    return true
}

input_deinit :: proc () {
    input_close_gamepads()
}

input_close_gamepads :: proc () {
    for &player in GLOBAL_STATE.input_state.players {
        sdl.CloseGamepad(player.gamepad)
        player.gamepad = nil
    }
    input_configure_core()
}

input_open_gamepads :: proc () -> (ok:bool) {
    input_close_gamepads()

    count: c.int
    gamepad_ids := sdl.GetGamepads(&count)
    if gamepad_ids == nil {
        log.errorf("Failed getting gamepads: {}", sdl.GetError())
        return false
    }
    defer sdl.free(gamepad_ids)

    ok = true
    for i in 0..<min(count, INPUT_MAX_PLAYERS) {
        gamepad_id := gamepad_ids[i]
        gamepad := sdl.OpenGamepad(gamepad_id)
        if gamepad == nil {
            log.errorf("Failed opening gamepad '{}': {}", gamepad_id, sdl.GetError())
            ok = false
        }

        GLOBAL_STATE.input_state.players[i].gamepad = gamepad
    }

    input_configure_core()

    return
}

input_handle_key_pressed :: proc (event: ^sdl.Event) {
    if event.key.repeat { return }

    #partial switch event.key.scancode {
    // case .LEFT:
    //     gui_focus_left()
    // case .RIGHT:
    //     gui_focus_right()
    // case .UP:
    //     gui_focus_up()
    // case .DOWN:
    //     gui_focus_down()
    case .ESCAPE:
        scene_change(.PAUSE)
    // case .M:
    //     gui_load_framebuffer_shader(crt_mattias_shader_source)
    }
}

input_handle_mouse :: proc (event: ^sdl.Event) {
    assert(event.type == .MOUSE_WHEEL ||
           event.type == .MOUSE_BUTTON_DOWN ||
           event.type == .MOUSE_BUTTON_UP ||
           event.type == .MOUSE_MOTION)

    #partial switch event.type {
    case .MOUSE_MOTION:
        GLOBAL_STATE.input_state.mouse.position = { event.motion.x, event.motion.y }
    case .MOUSE_BUTTON_DOWN:
        GLOBAL_STATE.input_state.mouse.clicked = true
        GLOBAL_STATE.input_state.mouse.down = true
    case .MOUSE_BUTTON_UP:
        GLOBAL_STATE.input_state.mouse.down = false
    case .MOUSE_WHEEL:
        GLOBAL_STATE.input_state.mouse.wheel_movement = { event.wheel.x, event.wheel.y }
    }
}

input_reset :: proc () {
    GLOBAL_STATE.input_state.mouse.wheel_movement = {}
    GLOBAL_STATE.input_state.mouse.clicked = false
}

input_handle_gamepad_pressed :: proc (event: ^sdl.Event) {
    if event.type != .GAMEPAD_BUTTON_DOWN { return }
    #partial switch sdl.GamepadButton(event.gbutton.button) {
    case .GUIDE, .TOUCHPAD:
        scene_change(.PAUSE)
    }
}

input_set_rumble :: proc "c" (port: uint, effect: lr.RetroRumbleEffect, strength: u16) -> (did_rumble: bool) {
    if port >= INPUT_MAX_PLAYERS { return false }

    gamepad := GLOBAL_STATE.input_state.players[port].gamepad

    switch effect {
    case .Strong:
        sdl.RumbleGamepad(gamepad, 0, strength, 5000) or_return
    case .Weak:
        sdl.RumbleGamepad(gamepad, strength, 0, 5000) or_return
    }

    return true
}

input_configure_core :: proc () {
    if !GLOBAL_STATE.emulator_state.core.loaded { return }

    for player, i in GLOBAL_STATE.input_state.players {
        if player.gamepad == nil {
            GLOBAL_STATE.emulator_state.core.api.set_controller_port_device(i32(i), .None)
        } else {
            GLOBAL_STATE.emulator_state.core.api.set_controller_port_device(i32(i), .Joypad)
        }
    }
}

input_update_core_keyboard_state :: proc (event: ^sdl.Event) {
    if GLOBAL_STATE.emulator_state.keyboard_callback == nil { return }

    modifiers := input_get_modifiers_bitmap()

    is_down := event.type == .KEY_DOWN ? true : false
    retro_keycode: lr.RetroKey
    utf32: u32
    #partial switch event.key.scancode {
    case .A..=.Z:
        retro_keycode = auto_cast (i32(event.key.scancode) + (i32(lr.RetroKey.A) - i32(sdl.Scancode.A)))
        utf32 = 0x61 + u32(event.key.scancode) - u32(sdl.Scancode.A)
    case .SPACE:
        retro_keycode = .Space
        utf32 = 0x20
    case .BACKSPACE:
        retro_keycode = .Backspace
        utf32 = 0x08
    case .RETURN:
        retro_keycode = .Return
        utf32 = 0x0D
    }

    GLOBAL_STATE.emulator_state.keyboard_callback(is_down, retro_keycode, utf32, modifiers)
}

input_get_modifiers_bitmap :: proc () -> u16 {
    modifiers: u16 = 0
    keyboard_state := sdl.GetKeyboardState(nil)

    if keyboard_state[sdl.Scancode.LSHIFT] || keyboard_state[sdl.Scancode.RSHIFT] {
        modifiers |= u16(lr.RetroMod.Shift)
    }
    if keyboard_state[sdl.Scancode.LCTRL] || keyboard_state[sdl.Scancode.RCTRL] {
        modifiers |= u16(lr.RetroMod.Ctrl)
    }
    if keyboard_state[sdl.Scancode.LALT] || keyboard_state[sdl.Scancode.RALT] {
        modifiers |= u16(lr.RetroMod.Alt)
    }
    if keyboard_state[sdl.Scancode.LGUI] || keyboard_state[sdl.Scancode.RGUI] {
        modifiers |= u16(lr.RetroMod.Meta)
    }
    if keyboard_state[sdl.Scancode.NUMLOCKCLEAR] {
        modifiers |= u16(lr.RetroMod.NumLock)
    }
    if keyboard_state[sdl.Scancode.CAPSLOCK] {
        modifiers |= u16(lr.RetroMod.CapsLock)
    }
    if keyboard_state[sdl.Scancode.SCROLLLOCK] {
        modifiers |= u16(lr.RetroMod.ScrolLock)
    }

    return modifiers
}
