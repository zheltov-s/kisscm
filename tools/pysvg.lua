-- Taken from diagram.lua

local function diagram_options(cb)
    local attribs = cb.attributes or {}
    local caption = attribs.caption and pandoc.read(attribs.caption).blocks
    local image_attrs = {}
    for attr, value in pairs(attribs) do
        if attr ~= "caption" then image_attrs[attr] = value end
    end
    return {
        alt = caption and pandoc.utils.blocks_to_inlines(caption) or {},
        caption = caption,
        figure_attrs = {id = cb.identifier},
        image_attrs = image_attrs
    }
end

local RSVG = "tools\\rsvg-convert.exe"
local function svg_to_png(svg)
    local base = "build\\pandoc_" .. pandoc.sha1(svg)
    local svg_path, png_path = base .. ".svg", base .. ".png"

    local f = io.open(svg_path, "wb"); f:write(svg); f:close()
    os.execute(string.format('%s "%s" -o "%s"', RSVG, svg_path, png_path))
    os.remove(svg_path)

    local pf = io.open(png_path, "rb")
    if not pf then error("[pysvg] rsvg-convert failed: " .. png_path) end
    local png = pf:read("*a"); pf:close()
    os.remove(png_path)
    return png
end

function CodeBlock(el)
    if el.attr.classes[1] == "pysvg" then
        local svg = pandoc.pipe("python", {"-"}, "from tools.pysvg import *\n" .. el.text)
        local png = svg_to_png(svg)
        local fname = pandoc.sha1(png) .. ".png"
        pandoc.mediabag.insert(fname, "image/png", png)
        local options = diagram_options(el)
        local image = pandoc.Image(options.alt, fname, "", options.image_attrs)
        local plain = pandoc.Plain {image}
        return options.caption and
            pandoc.Figure(plain, options.caption, options.figure_attrs) or
            plain
    end
end
