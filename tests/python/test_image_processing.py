import pytest
import sys
sys.path.append('services/python')
from image_processing import Image, Color, Filter

def test_image_creation():
    img = Image(100, 100)
    assert img.width == 100
    assert img.height == 100

def test_grayscale():
    img = Image(10, 10)
    img.set_pixel(0, 0, Color(255, 0, 0))
    gray = img.grayscale()
    pixel = gray.get_pixel(0, 0)
    assert pixel.r == pixel.g == pixel.b

def test_resize():
    img = Image(100, 100)
    resized = img.resize(50, 50)
    assert resized.width == 50
    assert resized.height == 50

def test_brightness():
    img = Image(10, 10)
    img.set_pixel(0, 0, Color(100, 100, 100))
    bright = img.brightness(1.5)
    pixel = bright.get_pixel(0, 0)
    assert pixel.r == 150
