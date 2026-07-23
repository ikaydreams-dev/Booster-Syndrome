#include <vector>
#include <algorithm>
#include <cmath>

struct Pixel {
    unsigned char r, g, b, a;

    Pixel() : r(0), g(0), b(0), a(255) {}
    Pixel(unsigned char r, unsigned char g, unsigned char b, unsigned char a = 255)
        : r(r), g(g), b(b), a(a) {}
};

class Image {
private:
    std::vector<Pixel> pixels;
    int width, height;

public:
    Image(int w, int h) : width(w), height(h) {
        pixels.resize(w * h);
    }

    Pixel& at(int x, int y) {
        return pixels[y * width + x];
    }

    const Pixel& at(int x, int y) const {
        return pixels[y * width + x];
    }

    int getWidth() const { return width; }
    int getHeight() const { return height; }

    void fill(const Pixel& color) {
        std::fill(pixels.begin(), pixels.end(), color);
    }

    Image grayscale() const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                const Pixel& p = at(x, y);
                unsigned char gray = static_cast<unsigned char>(
                    0.299 * p.r + 0.587 * p.g + 0.114 * p.b
                );
                result.at(x, y) = Pixel(gray, gray, gray, p.a);
            }
        }

        return result;
    }

    Image invert() const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                const Pixel& p = at(x, y);
                result.at(x, y) = Pixel(255 - p.r, 255 - p.g, 255 - p.b, p.a);
            }
        }

        return result;
    }

    Image brightness(float factor) const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                const Pixel& p = at(x, y);
                result.at(x, y) = Pixel(
                    std::min(255, static_cast<int>(p.r * factor)),
                    std::min(255, static_cast<int>(p.g * factor)),
                    std::min(255, static_cast<int>(p.b * factor)),
                    p.a
                );
            }
        }

        return result;
    }

    Image contrast(float factor) const {
        Image result(width, height);
        float correction = (259.0f * (factor + 255.0f)) / (255.0f * (259.0f - factor));

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                const Pixel& p = at(x, y);
                result.at(x, y) = Pixel(
                    std::clamp(static_cast<int>(correction * (p.r - 128) + 128), 0, 255),
                    std::clamp(static_cast<int>(correction * (p.g - 128) + 128), 0, 255),
                    std::clamp(static_cast<int>(correction * (p.b - 128) + 128), 0, 255),
                    p.a
                );
            }
        }

        return result;
    }

    Image blur(int radius) const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int r = 0, g = 0, b = 0, count = 0;

                for (int dy = -radius; dy <= radius; dy++) {
                    for (int dx = -radius; dx <= radius; dx++) {
                        int nx = x + dx;
                        int ny = y + dy;

                        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                            const Pixel& p = at(nx, ny);
                            r += p.r;
                            g += p.g;
                            b += p.b;
                            count++;
                        }
                    }
                }

                result.at(x, y) = Pixel(r / count, g / count, b / count, at(x, y).a);
            }
        }

        return result;
    }

    Image sharpen() const {
        Image result(width, height);
        const int kernel[3][3] = {
            { 0, -1,  0},
            {-1,  5, -1},
            { 0, -1,  0}
        };

        for (int y = 1; y < height - 1; y++) {
            for (int x = 1; x < width - 1; x++) {
                int r = 0, g = 0, b = 0;

                for (int dy = -1; dy <= 1; dy++) {
                    for (int dx = -1; dx <= 1; dx++) {
                        const Pixel& p = at(x + dx, y + dy);
                        int weight = kernel[dy + 1][dx + 1];
                        r += p.r * weight;
                        g += p.g * weight;
                        b += p.b * weight;
                    }
                }

                result.at(x, y) = Pixel(
                    std::clamp(r, 0, 255),
                    std::clamp(g, 0, 255),
                    std::clamp(b, 0, 255),
                    at(x, y).a
                );
            }
        }

        return result;
    }

    Image edgeDetect() const {
        Image result(width, height);
        const int kernelX[3][3] = {
            {-1, 0, 1},
            {-2, 0, 2},
            {-1, 0, 1}
        };
        const int kernelY[3][3] = {
            {-1, -2, -1},
            { 0,  0,  0},
            { 1,  2,  1}
        };

        for (int y = 1; y < height - 1; y++) {
            for (int x = 1; x < width - 1; x++) {
                int gx = 0, gy = 0;

                for (int dy = -1; dy <= 1; dy++) {
                    for (int dx = -1; dx <= 1; dx++) {
                        const Pixel& p = at(x + dx, y + dy);
                        int gray = (p.r + p.g + p.b) / 3;
                        gx += gray * kernelX[dy + 1][dx + 1];
                        gy += gray * kernelY[dy + 1][dx + 1];
                    }
                }

                int magnitude = std::min(255, static_cast<int>(std::sqrt(gx * gx + gy * gy)));
                result.at(x, y) = Pixel(magnitude, magnitude, magnitude, at(x, y).a);
            }
        }

        return result;
    }

    Image rotate90() const {
        Image result(height, width);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                result.at(height - 1 - y, x) = at(x, y);
            }
        }

        return result;
    }

    Image flipHorizontal() const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                result.at(width - 1 - x, y) = at(x, y);
            }
        }

        return result;
    }

    Image flipVertical() const {
        Image result(width, height);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                result.at(x, height - 1 - y) = at(x, y);
            }
        }

        return result;
    }
};
