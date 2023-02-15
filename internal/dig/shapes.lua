-- shape definitions for gui/dig
--@ module = true

if not dfhack_flags.module then
    qerror("this script cannot be called directly")
end

-- Base shape class, should not be used directly
Shape = defclass(Shape)
Shape.ATTRS {
    name = "",
    arr = {},
    options = DEFAULT_NIL,
    invert = false,
    width = 1,
    height = 1,
    points = {}
}

function Shape:update(width, height, points)
    self.width = width
    self.height = height
    self.arr = {}
    self.points = points

    for x = 0, self.width do
        self.arr[x] = {}
        for y = 0, self.height do
            local value = self:has_point(x, y)
            if not self.invert then
                self.arr[x][y] = value
            else
                self.arr[x][y] = not value
            end
        end
    end
end

function Shape:has_point(x, y)
    -- This class isn't meant to be used directly
    return false
end

-- Shape definitions
-- All should have a string name, and a function has_point(self, x, y) which returns true or false based
-- on if the x,y point is within the shape
-- Also options can be defined in a table, see existing shapes for example

--Ellipse

Ellipse = defclass(Ellipse, Shape)
Ellipse.ATTRS {
    name = "Ellipse",
}

function Ellipse:init()
    self.options = {
        hollow = {
            name = "Hollow",
            type = "bool",
            value = false,
            key = "CUSTOM_H",
        },
        thickness = {
            name = "Thickness",
            type = "plusminus",
            value = 2,
            enabled = { "hollow", true },
            min = 1,
            max = function(shape) if not shape.height or not shape.width then
                    return nil
                else
                    return math.ceil(math.min(shape.height, shape.width) / 2)

                end
            end,
            keys = { "CUSTOM_T", "CUSTOM_SHIFT_T" },
        },
    }
end

function Ellipse:has_point(x, y)
    local center_x, center_y = self.width / 2, self.height / 2
    local point_x, point_y = x - center_x, y - center_y
    local is_inside =
    (point_x / (self.width / 2)) ^ 2 + (point_y / (self.height / 2)) ^ 2 <= 1

    if self.options.hollow.value and is_inside then
        local all_points_inside = true
        for dx = -self.options.thickness.value, self.options.thickness.value do
            for dy = -self.options.thickness.value, self.options.thickness.value do
                if dx ~= 0 or dy ~= 0 then
                    local surrounding_x, surrounding_y = x + dx, y + dy
                    local surrounding_point_x, surrounding_point_y =
                    surrounding_x - center_x,
                        surrounding_y - center_y
                    if (surrounding_point_x / (self.width / 2)) ^ 2 + (surrounding_point_y / (self.height / 2)) ^ 2 >
                        1 then
                        all_points_inside = false
                        break
                    end
                end
            end
            if not all_points_inside then
                break
            end
        end
        return not all_points_inside
    else
        return is_inside
    end
end

Rectangle = defclass(Rectangle, Shape)
Rectangle.ATTRS {
    name = "Rectangle",
}

function Rectangle:init()
    self.options = {
        hollow = {
            name = "Hollow",
            type = "bool",
            value = false,
            key = "CUSTOM_H",
        },
        thickness = {
            name = "Thickness",
            type = "plusminus",
            value = 2,
            enabled = { "hollow", true },
            min = 1,
            max = function(shape) if not shape.height or not shape.width then
                    return nil
                else
                    return math.ceil(math.min(shape.height, shape.width) / 2)
                end
            end,
            keys = { "CUSTOM_T", "CUSTOM_SHIFT_T" },
        },
    }
end

function Rectangle:has_point(x, y)
    if self.options.hollow.value == false then
        if (x >= 0 and x <= self.width) and (y >= 0 and y <= self.height) then
            return true
        end
    else
        if (x >= self.options.thickness.value and x <= self.width - self.options.thickness.value) and
            (y >= self.options.thickness.value and y <= self.height - self.options.thickness.value) then
            return false
        else
            return true
        end
    end
    return false
end

Rows = defclass(Rows, Shape)
Rows.ATTRS {
    name = "Rows",
}

function Rows:init()
    self.options = {
        vertical = {
            name = "Vertical",
            type = "bool",
            value = true,
            key = "CUSTOM_V",
        },
        horizontal = {
            name = "Horizontal",
            type = "bool",
            value = false,
            key = "CUSTOM_H",
        },
        spacing = {
            name = "Spacing",
            type = "plusminus",
            value = 3,
            min = 1,
            keys = { "CUSTOM_T", "CUSTOM_SHIFT_T" },
        },
    }
end

function Rows:has_point(x, y)
    if self.options.vertical.value and x % self.options.spacing.value == 0 or
        self.options.horizontal.value and y % self.options.spacing.value == 0 then
        return true
    else
        return false
    end
end

Diag = defclass(Diag, Shape)
Diag.ATTRS {
    name = "Diagonal",
}

function Diag:init()
    self.options = {
        spacing = {
            name = "Spacing",
            type = "plusminus",
            value = 5,
            min = 1,
            keys = { "CUSTOM_T", "CUSTOM_SHIFT_T" },
        },
        reverse = {
            name = "Reverse",
            type = "bool",
            value = false,
            key = "CUSTOM_R",
        },
    }
end

function Diag:has_point(x, y)
    local mult = 1
    if self.options.reverse.value then
        mult = -1
    end

    if (x + mult * y) % self.options.spacing.value == 0 then
        return true
    else
        return false
    end
end

-- module users can get shapes through this global, shape option values
Line = defclass(Line, Shape)
Line.ATTRS {
    name = "Line Segments",
}

function Line:init()
    self.options = {
        complex = {
            name = "Complex",
            type = "const",
            value = true,
        },
        thickness = {
            name = "Thickness",
            type = "plusminus",
            value = 1,
            min = 1,
            max = function(shape) if not shape.height or not shape.width then
                    return nil
                else
                    return math.max(shape.height, shape.width)

                end
            end,
            keys = { "CUSTOM_T", "CUSTOM_SHIFT_T" },
        },
    }
end

function Line:update(width, height, points)
    self.width = width
    self.height = height
    self.points = points
    self.arr = {}

    local x0, y0 = self.points[1][1], self.points[1][2]
    local x1, y1 = self.points[2][1], self.points[2][2]
    local dx = math.abs(x1 - x0)
    local sx = x0 < x1 and 1 or -1
    local dy = -math.abs(y1 - y0)
    local sy = y0 < y1 and 1 or -1
    local err = dx + dy
    local e2

    while true do
        self.arr[x0] = self.arr[x0] or {}
        self.arr[x0][y0] = true
        
        -- Add line thickness
        if (math.abs(dx) > math.abs(dy)) then
            local i = 1
            while i < self.options.thickness.value do
                if y0 >= i then
                    if not self.arr[x0] then self.arr[x0] = {} end
                    self.arr[x0][y0 - math.ceil(i / 2)] = true
                end
                i = i + 1

                if y0 + i - 1 <= self.height and self.options.thickness.value > i then
                    if not self.arr[x0] then self.arr[x0] = {} end
                    self.arr[x0][y0 + math.ceil(i / 2) ] = true
                    i = i + 1
                end
            end
        elseif (math.abs(dx) <= math.abs(dy)) then
            local i = 1
            while i < self.options.thickness.value do
                if x0 >= i then
                    if not self.arr[x0 - math.ceil(i / 2)] then self.arr[x0 - math.ceil(i / 2)] = {} end
                    self.arr[x0 - math.ceil(i / 2)][y0] = true
                end
                i = i + 1

                if x0 + i - 1 <= self.width and self.options.thickness.value > i then
                    if not self.arr[x0 - math.ceil(i / 2)] then self.arr[x0 - math.ceil(i / 2)] = {} end
                    self.arr[x0 + math.ceil(i / 2)][y0] = true
                    i = i + 1
                end
            end
        end

        if x0 == x1 and y0 == y1 then
            break
        end

        e2 = 2 * err

        if e2 >= dy then
            err = err + dy
            x0 = x0 + sx
        end

        if e2 <= dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function Line:has_point(x, y) if self.arr[x] and self.arr[x][y] then return true else return false end end

-- persist in these as long as the module is loaded
-- idk enough lua to know if this is okay to do or not
all_shapes = { Rectangle {}, Ellipse {}, Rows {}, Diag {}, Line {} }
