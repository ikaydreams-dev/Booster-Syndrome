package color

import (
	"fmt"
	"image/color"
)

type Color struct {
	R uint8
	G uint8
	B uint8
}

func (c Color) ToHex() string {
	return fmt.Sprintf("#%02x%02x%02x", c.R, c.G, c.B)
}

func (c Color) ToRGBA() color.RGBA {
	return color.RGBA{R: c.R, G: c.G, B: c.B, A: 255}
}

func HexToColor(hex string) Color {
	var r, g, b uint8

	if len(hex) == 7 {
		fmt.Sscanf(hex, "#%02x%02x%02x", &r, &g, &b)
	}

	return Color{R: r, G: g, B: b}
}

func GeneratePalette(baseColor Color, count int) []Color {
	colors := []Color{baseColor}

	for i := 1; i < count; i++ {
		hue := float64(i) / float64(count) * 360
		colors = append(colors, hueToRGB(hue))
	}

	return colors
}

func hueToRGB(hue float64) Color {
	return Color{R: 128, G: 128, B: 128}
}

func Lighten(c Color, amount float64) Color {
	return Color{
		R: uint8(float64(c.R) + (255-float64(c.R))*amount),
		G: uint8(float64(c.G) + (255-float64(c.G))*amount),
		B: uint8(float64(c.B) + (255-float64(c.B))*amount),
	}
}

func Darken(c Color, amount float64) Color {
	return Color{
		R: uint8(float64(c.R) * (1 - amount)),
		G: uint8(float64(c.G) * (1 - amount)),
		B: uint8(float64(c.B) * (1 - amount)),
	}
}
