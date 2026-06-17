function detect_icon_type(icon)
  if icon:match("%.svg$") then
    return "svg"
  elseif icon:match("%.png$") or icon:match("%.jpe?g$") or icon:match("%.webp$") then
    return "png"
  elseif icon:match("^fa[srbldt]?%-.+") then
    return "fa"
  else
    return "bi"  -- fallback: assume Bootstrap Icons
  end
end


function Div(el)
  if el.classes:includes("value-box") then

    -- Existing attributes
    local icon      = el.attributes["icon"] or ""
    local icon_type -- supports "fa" | "bi" | "svg" | "png"
    if el.attributes["icon-type"] then
      icon_type = el.attributes["icon-type"]
    elseif icon ~= "" then
      icon_type = detect_icon_type(icon)
    else
      icon_type = "bi"
    end
    local color     = el.attributes["color"] or "bg-blue"
    local value     = el.attributes["value"] or ""
    local width     = el.attributes["width"] or "80%"
    local height    = el.attributes["height"] or ""
    local align     = el.attributes["align"] or "left"
    local valign = el.attributes["valign"] or ""
    local href      = el.attributes["href"] or ""
    local icon_pos  = el.attributes["icon-position"] or "top" -- "top" | "bottom" | "left" | "right"

    local icon_size_raw = el.attributes["icon-size"]

    -- em units for font-based icons (BI/FA), px for image-based (SVG/PNG)
    local icon_size_font
    local icon_size_img
    if icon_size_raw then
      icon_size_font = icon_size_raw
      icon_size_img  = icon_size_raw
    else
      icon_size_font = "3em"
      icon_size_img  = "128px"
    end

    -- Fragment logic
    local fragment_attr = el.attributes["fragment"]
    local fragment_class = ""
    if fragment_attr then
      fragment_class = " fragment " .. (fragment_attr == "true" and "fade-in-then-semi-out" or fragment_attr)
    end

    -- Fragment Index logic
    local index_attr = el.attributes["index"]
    local index_data = ""
    if index_attr then
      index_data = string.format(' data-fragment-index="%s"', index_attr)
    end

    -- Flex layout styles for left/right icon positioning
    local outer_extra_style = ""
    local icon_extra_style  = ""
    local details_extra_style = ""
    if icon_pos == "left" then
      outer_extra_style  = " display:flex; flex-direction:row; align-items:center; gap:1em;"
      icon_extra_style   = " flex-shrink:0;"
      details_extra_style = " flex:1;"
    elseif icon_pos == "right" then
      outer_extra_style  = " display:flex; flex-direction:row-reverse; align-items:center; gap:1em;"
      icon_extra_style   = " flex-shrink:0;"
      details_extra_style = " flex:1;"
    end

    -- Vertical alignment — requires flex on the outer wrapper
    if valign ~= "" then
      local valign_map = { top = "flex-start", middle = "center", bottom = "flex-end" }
      local align_value = valign_map[valign] or valign  -- fall back to raw value if not a shorthand
      if outer_extra_style:find("display:flex") then
        -- Already flex (left/right icon position) — just override align-items
        outer_extra_style = outer_extra_style:gsub("align%-items:[^;]+;", string.format("align-items:%s;", align_value))
      else
        -- Add flex column layout so justify-content controls vertical alignment
        outer_extra_style = outer_extra_style .. string.format(" display:flex; flex-direction:column; justify-content:%s;", align_value)
      end
    end

    -- Build the outer wrapper
    local html_open
    if href ~= "" then
      html_open = string.format(
        '<a href="%s" class="value-box %s%s" style="width:%s; height:%s; text-align:%s; display:block; text-decoration:none; cursor:pointer;%s"%s>',
        href, color, fragment_class, width, height, align, outer_extra_style, index_data
      )
    else
      html_open = string.format(
        '<div class="value-box %s%s" style="width:%s; height:%s; text-align:%s;%s"%s>',
        color, fragment_class, width, height, align, outer_extra_style, index_data
      )
    end

    -- Build icon HTML (empty string if no icon)
    local icon_html = ""
    if icon ~= "" then
      if icon_type == "fa" then
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">')
        icon_html = string.format(
          '<i class="icon %s" style="font-size:%s;%s"></i>',
          icon, icon_size_font, icon_extra_style
        )

      elseif icon_type == "svg" then
        local svg_file = io.open(icon, "r")
        if svg_file then
          local svg_content = svg_file:read("*all")
          svg_file:close()
          svg_content = svg_content:gsub('<svg', string.format(
            '<svg style="width:%s; height:%s;"', icon_size_img, icon_size_img
          ))
          icon_html = string.format(
            '<span class="icon" style="width:%s; height:%s; display:inline-flex; align-items:center; justify-content:center; font-size:inherit;%s">%s</span>',
            icon_size_img, icon_size_img, icon_extra_style, svg_content
          )
        else
          io.stderr:write(string.format("value-box warning: SVG file not found: %s\n", icon))
        end

      elseif icon_type == "png" then
        local png_file = io.open(icon, "r")
        if png_file then
          png_file:close()
          icon_html = string.format(
            '<img class="icon" src="%s" style="width:%s; height:%s; object-fit:contain; display:block; margin:0 auto;%s" alt="">',
            icon, icon_size_img, icon_size_img, icon_extra_style
          )
        else
          io.stderr:write(string.format("value-box warning: PNG file not found '%s', falling back to Bootstrap Icons\n", icon))
          quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">')
          icon_html = string.format(
            '<i class="icon bi %s" style="font-size:%s;%s"></i>',
            icon, icon_size_font, icon_extra_style
          )
        end

      else
        -- Bootstrap Icons (default)
        quarto.doc.include_text("in-header", '<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">')
        icon_html = string.format(
          '<i class="icon bi %s" style="font-size:%s;%s"></i>',
          icon, icon_size_font, icon_extra_style
        )
      end
    end

    -- For bottom placement, defer icon injection; otherwise inject it now
    if icon_pos ~= "bottom" then
      html_open = html_open .. icon_html
    end

    -- ADD VALUE (if it exists)
    if value ~= "" then
      html_open = html_open .. string.format('<div class="value">%s</div>', value)
    end

    -- Open the details wrapper
    html_open = html_open .. string.format('<div class="details"%s>',
      details_extra_style ~= "" and string.format(' style="%s"', details_extra_style) or "")

    -- Close details, optionally append icon below, then close outer
    local html_close
    if icon_pos == "bottom" then
      html_close = string.format('</div>%s%s',
        icon_html,
        href ~= "" and '</a>' or '</div>'
      )
    else
      html_close = href ~= "" and '</div></a>' or '</div></div>'
    end

    local result = pandoc.List({pandoc.RawBlock("html", html_open)})
    result:extend(el.content)
    result:insert(pandoc.RawBlock("html", html_close))

    quarto.doc.add_html_dependency({
      name = "value-box-styles",
      version = "1.0.0",
      stylesheets = {"value-box.css"}
    })

    return result
  end

end
