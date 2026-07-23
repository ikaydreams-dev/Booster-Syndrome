#include <cmath>
#include <vector>

const double PI = 3.14159265358979323846;

struct Point {
    double x, y;

    Point() : x(0), y(0) {}
    Point(double x, double y) : x(x), y(y) {}

    double distance(const Point& other) const {
        double dx = x - other.x;
        double dy = y - other.y;
        return std::sqrt(dx * dx + dy * dy);
    }

    Point operator+(const Point& other) const {
        return Point(x + other.x, y + other.y);
    }

    Point operator-(const Point& other) const {
        return Point(x - other.x, y - other.y);
    }

    Point operator*(double scalar) const {
        return Point(x * scalar, y * scalar);
    }
};

class Circle {
private:
    Point center;
    double radius;

public:
    Circle(Point c, double r) : center(c), radius(r) {}

    double area() const {
        return PI * radius * radius;
    }

    double circumference() const {
        return 2 * PI * radius;
    }

    bool contains(const Point& p) const {
        return center.distance(p) <= radius;
    }

    Point getCenter() const { return center; }
    double getRadius() const { return radius; }
};

class Rectangle {
private:
    Point topLeft;
    double width, height;

public:
    Rectangle(Point tl, double w, double h)
        : topLeft(tl), width(w), height(h) {}

    double area() const {
        return width * height;
    }

    double perimeter() const {
        return 2 * (width + height);
    }

    bool contains(const Point& p) const {
        return p.x >= topLeft.x && p.x <= topLeft.x + width &&
               p.y >= topLeft.y && p.y <= topLeft.y + height;
    }

    Point center() const {
        return Point(topLeft.x + width / 2, topLeft.y + height / 2);
    }
};

class Triangle {
private:
    Point a, b, c;

public:
    Triangle(Point p1, Point p2, Point p3) : a(p1), b(p2), c(p3) {}

    double area() const {
        return std::abs((a.x * (b.y - c.y) +
                        b.x * (c.y - a.y) +
                        c.x * (a.y - b.y)) / 2.0);
    }

    double perimeter() const {
        return a.distance(b) + b.distance(c) + c.distance(a);
    }

    bool contains(const Point& p) const {
        double area1 = Triangle(p, b, c).area();
        double area2 = Triangle(a, p, c).area();
        double area3 = Triangle(a, b, p).area();

        double total = area();
        return std::abs(total - (area1 + area2 + area3)) < 1e-10;
    }

    Point centroid() const {
        return Point((a.x + b.x + c.x) / 3, (a.y + b.y + c.y) / 3);
    }
};

class Polygon {
private:
    std::vector<Point> vertices;

public:
    Polygon(const std::vector<Point>& points) : vertices(points) {}

    void addVertex(const Point& p) {
        vertices.push_back(p);
    }

    double area() const {
        if (vertices.size() < 3) return 0;

        double sum = 0;
        for (size_t i = 0; i < vertices.size(); ++i) {
            size_t j = (i + 1) % vertices.size();
            sum += vertices[i].x * vertices[j].y;
            sum -= vertices[j].x * vertices[i].y;
        }
        return std::abs(sum) / 2.0;
    }

    double perimeter() const {
        if (vertices.size() < 2) return 0;

        double sum = 0;
        for (size_t i = 0; i < vertices.size(); ++i) {
            size_t j = (i + 1) % vertices.size();
            sum += vertices[i].distance(vertices[j]);
        }
        return sum;
    }

    Point centroid() const {
        double cx = 0, cy = 0;
        for (const auto& v : vertices) {
            cx += v.x;
            cy += v.y;
        }
        return Point(cx / vertices.size(), cy / vertices.size());
    }

    bool contains(const Point& p) const {
        int count = 0;
        size_t n = vertices.size();

        for (size_t i = 0; i < n; ++i) {
            Point v1 = vertices[i];
            Point v2 = vertices[(i + 1) % n];

            if ((v1.y <= p.y && p.y < v2.y) || (v2.y <= p.y && p.y < v1.y)) {
                double x = v1.x + (p.y - v1.y) / (v2.y - v1.y) * (v2.x - v1.x);
                if (p.x < x) count++;
            }
        }

        return count % 2 == 1;
    }
};
