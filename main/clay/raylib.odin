package clay

import "core:math"
import "core:strings"
import "vendor:raylib"
import "base:runtime"

RaylibFont :: struct {
    fontId: u16,
    font:   raylib.Font,
}

clayColorToRaylibColor :: proc(color: Color) -> raylib.Color {
    return raylib.Color{ u8(color.r), u8(color.g), u8(color.b), u8(color.a) }
}

raylibFonts := [10]RaylibFont{}

measureText :: proc "c" (text: StringSlice, config: ^TextElementConfig, userData: rawptr) -> Dimensions {
    context = runtime.default_context()

    cloned := strings.clone_to_cstring(string(text.chars[:text.length]), context.temp_allocator)
    result := raylib.MeasureTextEx(
        raylibFonts[config.fontId].font,
        cloned,
        f32(config.fontSize),
        f32(config.letterSpacing))

    return {
        width = result.x,
        height = result.y
    }
}

clayRaylibRender :: proc(renderCommands: ^ClayArray(RenderCommand), allocator := context.temp_allocator) {
    for i in 0 ..< int(renderCommands.length) {
        renderCommand := RenderCommandArray_Get(renderCommands, i32(i))
        boundingBox := renderCommand.boundingBox
        switch (renderCommand.commandType) {
        case RenderCommandType.None:
            {}
        case RenderCommandType.Text:
            config := renderCommand.renderData.text
            // Raylib uses standard C strings so isn't compatible with cheap slices, we need to clone the string to append null terminator
            text := string(config.stringContents.chars[:config.stringContents.length])
            cloned := strings.clone_to_cstring(text, allocator)
            fontToUse: raylib.Font = raylibFonts[config.fontId].font
            raylib.DrawTextEx(
                fontToUse,
                cloned,
                raylib.Vector2{boundingBox.x, boundingBox.y},
                f32(config.fontSize),
                f32(config.letterSpacing),
                clayColorToRaylibColor(config.textColor),
            )
        case RenderCommandType.Image:
            config := renderCommand.renderData.image
            tintColor := config.backgroundColor
            if (tintColor.rgba == 0) {
                tintColor = { 255, 255, 255, 255 }
            }
            // TODO image handling
            imageTexture := (^raylib.Texture2D)(config.imageData)
            raylib.DrawTextureEx(imageTexture^, raylib.Vector2{boundingBox.x, boundingBox.y}, 0, boundingBox.width / f32(imageTexture.width), clayColorToRaylibColor(tintColor))
        case RenderCommandType.ScissorStart:
            raylib.BeginScissorMode(
                i32(math.round(boundingBox.x)),
                i32(math.round(boundingBox.y)),
                i32(math.round(boundingBox.width)),
                i32(math.round(boundingBox.height)),
            )
        case RenderCommandType.ScissorEnd:
            raylib.EndScissorMode()
        case RenderCommandType.Rectangle:
            config := renderCommand.renderData.rectangle
            if (config.cornerRadius.topLeft > 0) {
                radius: f32 = (config.cornerRadius.topLeft * 2) / min(boundingBox.width, boundingBox.height)
                raylib.DrawRectangleRounded(raylib.Rectangle{boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height}, radius, 8, clayColorToRaylibColor(config.backgroundColor))
            } else {
                raylib.DrawRectangle(cast(i32)boundingBox.x, cast(i32)boundingBox.y, cast(i32)boundingBox.width, cast(i32)boundingBox.height, clayColorToRaylibColor(config.backgroundColor))
            }
        case RenderCommandType.Border:
            config := renderCommand.renderData.border
            // Left border
            if (config.width.left > 0) {
                raylib.DrawRectangle(
                    cast(i32)math.round(boundingBox.x),
                    cast(i32)math.round(boundingBox.y + config.cornerRadius.topLeft),
                    cast(i32)config.width.left,
                    cast(i32)math.round(boundingBox.height - config.cornerRadius.topLeft - config.cornerRadius.bottomLeft),
                    clayColorToRaylibColor(config.color),
                )
            }
            // Right border
            if (config.width.right > 0) {
                raylib.DrawRectangle(
                    cast(i32)math.round(boundingBox.x + boundingBox.width - cast(f32)config.width.right),
                    cast(i32)math.round(boundingBox.y + config.cornerRadius.topRight),
                    cast(i32)config.width.right,
                    cast(i32)math.round(boundingBox.height - config.cornerRadius.topRight - config.cornerRadius.bottomRight),
                    clayColorToRaylibColor(config.color),
                )
            }
            // Top border
            if (config.width.top > 0) {
                raylib.DrawRectangle(
                    cast(i32)math.round(boundingBox.x + config.cornerRadius.topLeft),
                    cast(i32)math.round(boundingBox.y),
                    cast(i32)math.round(boundingBox.width - config.cornerRadius.topLeft - config.cornerRadius.topRight),
                    cast(i32)config.width.top,
                    clayColorToRaylibColor(config.color),
                )
            }
            // Bottom border
            if (config.width.bottom > 0) {
                raylib.DrawRectangle(
                    cast(i32)math.round(boundingBox.x + config.cornerRadius.bottomLeft),
                    cast(i32)math.round(boundingBox.y + boundingBox.height - cast(f32)config.width.bottom),
                    cast(i32)math.round(boundingBox.width - config.cornerRadius.bottomLeft - config.cornerRadius.bottomRight),
                    cast(i32)config.width.bottom,
                    clayColorToRaylibColor(config.color),
                )
            }
            if (config.cornerRadius.topLeft > 0) {
                raylib.DrawRing(
                    raylib.Vector2{math.round(boundingBox.x + config.cornerRadius.topLeft), math.round(boundingBox.y + config.cornerRadius.topLeft)},
                    math.round(config.cornerRadius.topLeft - cast(f32)config.width.top),
                    config.cornerRadius.topLeft,
                    180,
                    270,
                    10,
                    clayColorToRaylibColor(config.color),
                )
            }
            if (config.cornerRadius.topRight > 0) {
                raylib.DrawRing(
                    raylib.Vector2{math.round(boundingBox.x + boundingBox.width - config.cornerRadius.topRight), math.round(boundingBox.y + config.cornerRadius.topRight)},
                    math.round(config.cornerRadius.topRight - cast(f32)config.width.top),
                    config.cornerRadius.topRight,
                    270,
                    360,
                    10,
                    clayColorToRaylibColor(config.color),
                )
            }
            if (config.cornerRadius.bottomLeft > 0) {
                raylib.DrawRing(
                    raylib.Vector2{math.round(boundingBox.x + config.cornerRadius.bottomLeft), math.round(boundingBox.y + boundingBox.height - config.cornerRadius.bottomLeft)},
                    math.round(config.cornerRadius.bottomLeft - cast(f32)config.width.top),
                    config.cornerRadius.bottomLeft,
                    90,
                    180,
                    10,
                    clayColorToRaylibColor(config.color),
                )
            }
            if (config.cornerRadius.bottomRight > 0) {
                raylib.DrawRing(
                    raylib.Vector2 {
                        math.round(boundingBox.x + boundingBox.width - config.cornerRadius.bottomRight),
                        math.round(boundingBox.y + boundingBox.height - config.cornerRadius.bottomRight),
                    },
                    math.round(config.cornerRadius.bottomRight - cast(f32)config.width.bottom),
                    config.cornerRadius.bottomRight,
                    0.1,
                    90,
                    10,
                    clayColorToRaylibColor(config.color),
                )
            }
        case RenderCommandType.Custom:
        // Implement custom element rendering here
        }
    }
}
