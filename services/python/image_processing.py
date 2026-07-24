import math
from typing import Tuple, List, Optional
from dataclasses import dataclass

@dataclass
class Color:
    r: int
    g: int
    b: int
    a: int = 255

    def to_tuple(self) -> Tuple[int, int, int, int]:
        return (self.r, self.g, self.b, self.a)

    def to_hex(self) -> str:
        return f'#{self.r:02x}{self.g:02x}{self.b:02x}'

    @classmethod
    def from_hex(cls, hex_color: str) -> 'Color':
        hex_color = hex_color.lstrip('#')
        return cls(
            int(hex_color[0:2], 16),
            int(hex_color[2:4], 16),
            int(hex_color[4:6], 16)
        )

class Image:
    def __init__(self, width: int, height: int, pixels: Optional[List[List[Color]]] = None):
        self.width = width
        self.height = height

        if pixels:
            self.pixels = pixels
        else:
            self.pixels = [[Color(0, 0, 0) for _ in range(width)] for _ in range(height)]

    def get_pixel(self, x: int, y: int) -> Color:
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.pixels[y][x]
        return Color(0, 0, 0)

    def set_pixel(self, x: int, y: int, color: Color):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y][x] = color

    def resize(self, new_width: int, new_height: int) -> 'Image':
        new_image = Image(new_width, new_height)

        x_ratio = self.width / new_width
        y_ratio = self.height / new_height

        for y in range(new_height):
            for x in range(new_width):
                src_x = int(x * x_ratio)
                src_y = int(y * y_ratio)
                new_image.set_pixel(x, y, self.get_pixel(src_x, src_y))

        return new_image

    def crop(self, x: int, y: int, width: int, height: int) -> 'Image':
        cropped = Image(width, height)

        for dy in range(height):
            for dx in range(width):
                color = self.get_pixel(x + dx, y + dy)
                cropped.set_pixel(dx, dy, color)

        return cropped

    def rotate_90(self) -> 'Image':
        rotated = Image(self.height, self.width)

        for y in range(self.height):
            for x in range(self.width):
                rotated.set_pixel(self.height - 1 - y, x, self.get_pixel(x, y))

        return rotated

    def flip_horizontal(self) -> 'Image':
        flipped = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                flipped.set_pixel(self.width - 1 - x, y, self.get_pixel(x, y))

        return flipped

    def flip_vertical(self) -> 'Image':
        flipped = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                flipped.set_pixel(x, self.height - 1 - y, self.get_pixel(x, y))

        return flipped

    def grayscale(self) -> 'Image':
        result = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                color = self.get_pixel(x, y)
                gray = int(0.299 * color.r + 0.587 * color.g + 0.114 * color.b)
                result.set_pixel(x, y, Color(gray, gray, gray))

        return result

    def invert(self) -> 'Image':
        result = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                color = self.get_pixel(x, y)
                result.set_pixel(x, y, Color(255 - color.r, 255 - color.g, 255 - color.b))

        return result

    def brightness(self, factor: float) -> 'Image':
        result = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                color = self.get_pixel(x, y)
                new_color = Color(
                    min(255, int(color.r * factor)),
                    min(255, int(color.g * factor)),
                    min(255, int(color.b * factor))
                )
                result.set_pixel(x, y, new_color)

        return result

    def contrast(self, factor: float) -> 'Image':
        result = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                color = self.get_pixel(x, y)
                new_color = Color(
                    min(255, max(0, int((color.r - 128) * factor + 128))),
                    min(255, max(0, int((color.g - 128) * factor + 128))),
                    min(255, max(0, int((color.b - 128) * factor + 128)))
                )
                result.set_pixel(x, y, new_color)

        return result

    def blur(self, radius: int = 1) -> 'Image':
        result = Image(self.width, self.height)

        for y in range(self.height):
            for x in range(self.width):
                total_r, total_g, total_b = 0, 0, 0
                count = 0

                for dy in range(-radius, radius + 1):
                    for dx in range(-radius, radius + 1):
                        color = self.get_pixel(x + dx, y + dy)
                        total_r += color.r
                        total_g += color.g
                        total_b += color.b
                        count += 1

                result.set_pixel(x, y, Color(
                    total_r // count,
                    total_g // count,
                    total_b // count
                ))

        return result

    def sharpen(self) -> 'Image':
        kernel = [
            [0, -1, 0],
            [-1, 5, -1],
            [0, -1, 0]
        ]
        return self.apply_kernel(kernel)

    def edge_detect(self) -> 'Image':
        kernel = [
            [-1, -1, -1],
            [-1, 8, -1],
            [-1, -1, -1]
        ]
        return self.apply_kernel(kernel)

    def apply_kernel(self, kernel: List[List[float]]) -> 'Image':
        result = Image(self.width, self.height)
        kernel_size = len(kernel)
        offset = kernel_size // 2

        for y in range(self.height):
            for x in range(self.width):
                total_r, total_g, total_b = 0.0, 0.0, 0.0

                for ky in range(kernel_size):
                    for kx in range(kernel_size):
                        px = x + kx - offset
                        py = y + ky - offset
                        color = self.get_pixel(px, py)

                        total_r += color.r * kernel[ky][kx]
                        total_g += color.g * kernel[ky][kx]
                        total_b += color.b * kernel[ky][kx]

                result.set_pixel(x, y, Color(
                    min(255, max(0, int(total_r))),
                    min(255, max(0, int(total_g))),
                    min(255, max(0, int(total_b)))
                ))

        return result

class Filter:
    @staticmethod
    def sepia(image: Image) -> Image:
        result = Image(image.width, image.height)

        for y in range(image.height):
            for x in range(image.width):
                color = image.get_pixel(x, y)

                tr = int(0.393 * color.r + 0.769 * color.g + 0.189 * color.b)
                tg = int(0.349 * color.r + 0.686 * color.g + 0.168 * color.b)
                tb = int(0.272 * color.r + 0.534 * color.g + 0.131 * color.b)

                result.set_pixel(x, y, Color(
                    min(255, tr),
                    min(255, tg),
                    min(255, tb)
                ))

        return result

    @staticmethod
    def vignette(image: Image, strength: float = 0.5) -> Image:
        result = Image(image.width, image.height)
        center_x, center_y = image.width / 2, image.height / 2
        max_distance = math.sqrt(center_x**2 + center_y**2)

        for y in range(image.height):
            for x in range(image.width):
                color = image.get_pixel(x, y)
                distance = math.sqrt((x - center_x)**2 + (y - center_y)**2)
                factor = 1 - (distance / max_distance) * strength

                result.set_pixel(x, y, Color(
                    int(color.r * factor),
                    int(color.g * factor),
                    int(color.b * factor)
                ))

        return result

    @staticmethod
    def posterize(image: Image, levels: int = 4) -> Image:
        result = Image(image.width, image.height)
        step = 256 // levels

        for y in range(image.height):
            for x in range(image.width):
                color = image.get_pixel(x, y)

                result.set_pixel(x, y, Color(
                    (color.r // step) * step,
                    (color.g // step) * step,
                    (color.b // step) * step
                ))

        return result

    @staticmethod
    def threshold(image: Image, threshold: int = 128) -> Image:
        result = Image(image.width, image.height)

        for y in range(image.height):
            for x in range(image.width):
                color = image.get_pixel(x, y)
                gray = int(0.299 * color.r + 0.587 * color.g + 0.114 * color.b)
                value = 255 if gray > threshold else 0

                result.set_pixel(x, y, Color(value, value, value))

        return result

class Draw:
    @staticmethod
    def rectangle(image: Image, x: int, y: int, width: int, height: int, color: Color, filled: bool = False):
        if filled:
            for dy in range(height):
                for dx in range(width):
                    image.set_pixel(x + dx, y + dy, color)
        else:
            for dx in range(width):
                image.set_pixel(x + dx, y, color)
                image.set_pixel(x + dx, y + height - 1, color)

            for dy in range(height):
                image.set_pixel(x, y + dy, color)
                image.set_pixel(x + width - 1, y + dy, color)

    @staticmethod
    def circle(image: Image, cx: int, cy: int, radius: int, color: Color, filled: bool = False):
        for y in range(cy - radius, cy + radius + 1):
            for x in range(cx - radius, cx + radius + 1):
                distance = math.sqrt((x - cx)**2 + (y - cy)**2)

                if filled:
                    if distance <= radius:
                        image.set_pixel(x, y, color)
                else:
                    if abs(distance - radius) < 1:
                        image.set_pixel(x, y, color)

    @staticmethod
    def line(image: Image, x1: int, y1: int, x2: int, y2: int, color: Color):
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy

        x, y = x1, y1

        while True:
            image.set_pixel(x, y, color)

            if x == x2 and y == y2:
                break

            e2 = 2 * err

            if e2 > -dy:
                err -= dy
                x += sx

            if e2 < dx:
                err += dx
                y += sy

class Histogram:
    @staticmethod
    def calculate(image: Image) -> Tuple[List[int], List[int], List[int]]:
        r_hist = [0] * 256
        g_hist = [0] * 256
        b_hist = [0] * 256

        for y in range(image.height):
            for x in range(image.width):
                color = image.get_pixel(x, y)
                r_hist[color.r] += 1
                g_hist[color.g] += 1
                b_hist[color.b] += 1

        return r_hist, g_hist, b_hist

    @staticmethod
    def equalize(image: Image) -> Image:
        gray_image = image.grayscale()
        histogram = [0] * 256

        for y in range(gray_image.height):
            for x in range(gray_image.width):
                color = gray_image.get_pixel(x, y)
                histogram[color.r] += 1

        total_pixels = gray_image.width * gray_image.height
        cumulative = [0] * 256
        cumulative[0] = histogram[0]

        for i in range(1, 256):
            cumulative[i] = cumulative[i - 1] + histogram[i]

        equalized = Image(image.width, image.height)

        for y in range(image.height):
            for x in range(image.width):
                color = gray_image.get_pixel(x, y)
                new_value = int((cumulative[color.r] * 255) / total_pixels)
                equalized.set_pixel(x, y, Color(new_value, new_value, new_value))

        return equalized

class Transformation:
    @staticmethod
    def scale(image: Image, scale_x: float, scale_y: float) -> Image:
        new_width = int(image.width * scale_x)
        new_height = int(image.height * scale_y)
        return image.resize(new_width, new_height)

    @staticmethod
    def rotate(image: Image, angle: float) -> Image:
        rad = math.radians(angle)
        cos_a = math.cos(rad)
        sin_a = math.sin(rad)

        new_width = int(abs(image.width * cos_a) + abs(image.height * sin_a))
        new_height = int(abs(image.width * sin_a) + abs(image.height * cos_a))

        result = Image(new_width, new_height)
        cx, cy = image.width / 2, image.height / 2
        new_cx, new_cy = new_width / 2, new_height / 2

        for y in range(new_height):
            for x in range(new_width):
                rx = x - new_cx
                ry = y - new_cy

                src_x = int(rx * cos_a + ry * sin_a + cx)
                src_y = int(-rx * sin_a + ry * cos_a + cy)

                if 0 <= src_x < image.width and 0 <= src_y < image.height:
                    result.set_pixel(x, y, image.get_pixel(src_x, src_y))

        return result
