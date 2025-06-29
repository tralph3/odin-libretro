package main

import cl "clay"
import "core:log"

UI_COLOR_BACKGROUND :: cl.Color { 0x18, 0x18, 0x18, 0xFF }
UI_COLOR_SECONDARY_BACKGROUND :: cl.Color { 37, 44, 55, 0xFF }
UI_COLOR_ACCENT :: cl.Color { 4, 114, 77, 0xFF }

UI_COLOR_MAIN_TEXT :: cl.Color { 244, 244, 249, 0xFF }

UI_USER_TILE_SIZE :: 180
UI_USER_TILE_GAP :: UI_SPACING_16

gui_layout_login_user_tile :: proc (username: string) {
    if cl.UI()({
        backgroundColor = UI_COLOR_SECONDARY_BACKGROUND,
        layout = {
            sizing = {
                width = cl.SizingFixed(UI_USER_TILE_SIZE),
                height = cl.SizingFixed(UI_USER_TILE_SIZE),
            },
            childAlignment = {
                x = .Center,
                y = .Center,
            },
        },
        border = (gui_is_focused() ? {
            color = UI_COLOR_ACCENT,
            width = cl.BorderAll(5),
        } : {}),
        cornerRadius = cl.CornerRadiusAll(10),
    }) {
        if gui_is_clicked() {
            user_login(username)
        }

        cl.TextDynamic(username, cl.TextConfig({
            textColor = UI_COLOR_MAIN_TEXT,
            fontSize = UI_FONTSIZE_24,
        }))
    }
}

gui_layout_login_add_user :: proc () {
    if cl.UI()({
        id = cl.ID("Add User"),
        backgroundColor = UI_COLOR_SECONDARY_BACKGROUND,
        layout = {
            sizing = {
                width = cl.SizingFixed(UI_USER_TILE_SIZE),
                height = cl.SizingFixed(UI_USER_TILE_SIZE),
            },
            childAlignment = {
                x = .Center,
                y = .Center,
            },
        },
        border = (gui_is_focused() ? {
            color = UI_COLOR_ACCENT,
            width = cl.BorderAll(5),
        } : {}),
        cornerRadius = cl.CornerRadiusAll(UI_USER_TILE_SIZE / 2),
    }) {
        cl.Text("+", cl.TextConfig({
            textColor = UI_COLOR_MAIN_TEXT,
            fontSize = UI_FONTSIZE_72,
        }))
    }
}

gui_layout_login_screen :: proc () -> cl.ClayArray(cl.RenderCommand) {
    cl.BeginLayout()

    if cl.UI()({
        id = cl.ID("Root"),
        backgroundColor = UI_COLOR_BACKGROUND,
        layout = {
            sizing = {
                width = cl.SizingGrow({}),
                height = cl.SizingGrow({}),
            },
            childAlignment = {
                x = .Center,
                y = .Center,
            },
            childGap = UI_USER_TILE_GAP,
            layoutDirection = .TopToBottom,
        },
    }) {
        if cl.UI()({

        }) {
            cl.Text("Welcome!", &{
                textColor = UI_COLOR_MAIN_TEXT,
                fontSize = UI_FONTSIZE_72,
            })
        }

        if cl.UI()({
            id = cl.ID("Users Container"),
            layout = {
                childGap = UI_USER_TILE_GAP,
            },
        }) {
            usernames := []string{"test", "tralph3"}
            for username in usernames {
                gui_layout_login_user_tile(username)
            }
            gui_layout_login_add_user()
        }
    }

    return cl.EndLayout()
}
