#include <vector>
#include <cmath>
#include <algorithm>

struct Color {
    unsigned char r, g, b, a;

    Color() : r(0), g(0), b(0), a(255) {}
    Color(unsigned char r, unsigned char g, unsigned char b, unsigned char a = 255)
        : r(r), g(g), b(b), a(a) {}

    static Color blend(const Color& c1, const Color& c2, float t) {
        return Color(
            static_cast<unsigned char>(c1.r * (1 - t) + c2.r * t),
            static_cast<unsigned char>(c1.g * (1 - t) + c2.g * t),
            static_cast<unsigned char>(c1.b * (1 - t) + c2.b * t),
            static_cast<unsigned char>(c1.a * (1 - t) + c2.a * t)
        );
    }
};

struct Point2D {
    int x, y;
    Point2D(int x = 0, int y = 0) : x(x), y(y) {}
};

class Canvas {
private:
    std::vector<Color> pixels;
    int width, height;
    Color fillColor;
    Color strokeColor;

public:
    Canvas(int w, int h) : width(w), height(h) {
        pixels.resize(w * h, Color(255, 255, 255, 255));
        fillColor = Color(0, 0, 0, 255);
        strokeColor = Color(0, 0, 0, 255);
    }

    void setPixel(int x, int y, const Color& color) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
            pixels[y * width + x] = color;
        }
    }

    Color getPixel(int x, int y) const {
        if (x >= 0 && x < width && y >= 0 && y < height) {
            return pixels[y * width + x];
        }
        return Color();
    }

    void clear(const Color& color = Color(255, 255, 255, 255)) {
        std::fill(pixels.begin(), pixels.end(), color);
    }

    void setFillColor(const Color& color) {
        fillColor = color;
    }

    void setStrokeColor(const Color& color) {
        strokeColor = color;
    }

    void drawLine(int x1, int y1, int x2, int y2) {
        int dx = std::abs(x2 - x1);
        int dy = std::abs(y2 - y1);
        int sx = x1 < x2 ? 1 : -1;
        int sy = y1 < y2 ? 1 : -1;
        int err = dx - dy;

        while (true) {
            setPixel(x1, y1, strokeColor);

            if (x1 == x2 && y1 == y2) break;

            int e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x1 += sx;
            }
            if (e2 < dx) {
                err += dx;
                y1 += sy;
            }
        }
    }

    void drawCircle(int cx, int cy, int radius) {
        int x = 0;
        int y = radius;
        int d = 3 - 2 * radius;

        while (y >= x) {
            setPixel(cx + x, cy + y, strokeColor);
            setPixel(cx - x, cy + y, strokeColor);
            setPixel(cx + x, cy - y, strokeColor);
            setPixel(cx - x, cy - y, strokeColor);
            setPixel(cx + y, cy + x, strokeColor);
            setPixel(cx - y, cy + x, strokeColor);
            setPixel(cx + y, cy - x, strokeColor);
            setPixel(cx - y, cy - x, strokeColor);

            x++;

            if (d > 0) {
                y--;
                d = d + 4 * (x - y) + 10;
            } else {
                d = d + 4 * x + 6;
            }
        }
    }

    void fillCircle(int cx, int cy, int radius) {
        for (int y = -radius; y <= radius; y++) {
            for (int x = -radius; x <= radius; x++) {
                if (x * x + y * y <= radius * radius) {
                    setPixel(cx + x, cy + y, fillColor);
                }
            }
        }
    }

    void drawRectangle(int x, int y, int w, int h) {
        drawLine(x, y, x + w, y);
        drawLine(x + w, y, x + w, y + h);
        drawLine(x + w, y + h, x, y + h);
        drawLine(x, y + h, x, y);
    }

    void fillRectangle(int x, int y, int w, int h) {
        for (int dy = 0; dy < h; dy++) {
            for (int dx = 0; dx < w; dx++) {
                setPixel(x + dx, y + dy, fillColor);
            }
        }
    }

    void drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3) {
        drawLine(x1, y1, x2, y2);
        drawLine(x2, y2, x3, y3);
        drawLine(x3, y3, x1, y1);
    }

    void fillTriangle(int x1, int y1, int x2, int y2, int x3, int y3) {
        if (y1 > y2) { std::swap(y1, y2); std::swap(x1, x2); }
        if (y1 > y3) { std::swap(y1, y3); std::swap(x1, x3); }
        if (y2 > y3) { std::swap(y2, y3); std::swap(x2, x3); }

        auto drawScanLine = [&](int sx, int ex, int y) {
            if (sx > ex) std::swap(sx, ex);
            for (int x = sx; x <= ex; x++) {
                setPixel(x, y, fillColor);
            }
        };

        float invSlope1 = (y2 - y1) != 0 ? (float)(x2 - x1) / (y2 - y1) : 0;
        float invSlope2 = (y3 - y1) != 0 ? (float)(x3 - x1) / (y3 - y1) : 0;

        float curx1 = x1;
        float curx2 = x1;

        for (int scanY = y1; scanY <= y2; scanY++) {
            drawScanLine((int)curx1, (int)curx2, scanY);
            curx1 += invSlope1;
            curx2 += invSlope2;
        }

        if (y2 != y3) {
            invSlope1 = (float)(x3 - x2) / (y3 - y2);
            curx1 = x2;

            for (int scanY = y2; scanY <= y3; scanY++) {
                drawScanLine((int)curx1, (int)curx2, scanY);
                curx1 += invSlope1;
                curx2 += invSlope2;
            }
        }
    }

    void drawEllipse(int cx, int cy, int rx, int ry) {
        float dx, dy, d1, d2, x, y;
        x = 0;
        y = ry;

        d1 = (ry * ry) - (rx * rx * ry) + (0.25 * rx * rx);
        dx = 2 * ry * ry * x;
        dy = 2 * rx * rx * y;

        while (dx < dy) {
            setPixel(cx + x, cy + y, strokeColor);
            setPixel(cx - x, cy + y, strokeColor);
            setPixel(cx + x, cy - y, strokeColor);
            setPixel(cx - x, cy - y, strokeColor);

            if (d1 < 0) {
                x++;
                dx = dx + (2 * ry * ry);
                d1 = d1 + dx + (ry * ry);
            } else {
                x++;
                y--;
                dx = dx + (2 * ry * ry);
                dy = dy - (2 * rx * rx);
                d1 = d1 + dx - dy + (ry * ry);
            }
        }

        d2 = ((ry * ry) * ((x + 0.5) * (x + 0.5))) +
             ((rx * rx) * ((y - 1) * (y - 1))) -
             (rx * rx * ry * ry);

        while (y >= 0) {
            setPixel(cx + x, cy + y, strokeColor);
            setPixel(cx - x, cy + y, strokeColor);
            setPixel(cx + x, cy - y, strokeColor);
            setPixel(cx - x, cy - y, strokeColor);

            if (d2 > 0) {
                y--;
                dy = dy - (2 * rx * rx);
                d2 = d2 + (rx * rx) - dy;
            } else {
                y--;
                x++;
                dx = dx + (2 * ry * ry);
                dy = dy - (2 * rx * rx);
                d2 = d2 + dx - dy + (rx * rx);
            }
        }
    }

    int getWidth() const { return width; }
    int getHeight() const { return height; }
};
