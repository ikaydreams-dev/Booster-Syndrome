import java.util.*;

class Node implements Comparable<Node> {
    int x, y;
    double g, h, f;
    Node parent;

    public Node(int x, int y) {
        this.x = x;
        this.y = y;
        this.g = 0;
        this.h = 0;
        this.f = 0;
        this.parent = null;
    }

    @Override
    public int compareTo(Node other) {
        return Double.compare(this.f, other.f);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof Node)) return false;
        Node other = (Node) obj;
        return x == other.x && y == other.y;
    }

    @Override
    public int hashCode() {
        return Objects.hash(x, y);
    }
}

public class AStar {
    private static final int[][] DIRECTIONS = {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1},
        {-1, -1}, {-1, 1}, {1, -1}, {1, 1}
    };

    private int[][] grid;
    private int rows, cols;

    public AStar(int[][] grid) {
        this.grid = grid;
        this.rows = grid.length;
        this.cols = grid[0].length;
    }

    private double heuristic(Node a, Node b) {
        return Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2));
    }

    private boolean isValid(int x, int y) {
        return x >= 0 && x < rows && y >= 0 && y < cols && grid[x][y] == 0;
    }

    private List<Node> getNeighbors(Node node) {
        List<Node> neighbors = new ArrayList<>();

        for (int[] dir : DIRECTIONS) {
            int newX = node.x + dir[0];
            int newY = node.y + dir[1];

            if (isValid(newX, newY)) {
                neighbors.add(new Node(newX, newY));
            }
        }

        return neighbors;
    }

    public List<Node> findPath(int startX, int startY, int endX, int endY) {
        Node start = new Node(startX, startY);
        Node end = new Node(endX, endY);

        PriorityQueue<Node> openSet = new PriorityQueue<>();
        Set<Node> closedSet = new HashSet<>();
        Map<Node, Node> cameFrom = new HashMap<>();

        start.g = 0;
        start.h = heuristic(start, end);
        start.f = start.h;

        openSet.add(start);

        while (!openSet.isEmpty()) {
            Node current = openSet.poll();

            if (current.equals(end)) {
                return reconstructPath(cameFrom, current);
            }

            closedSet.add(current);

            for (Node neighbor : getNeighbors(current)) {
                if (closedSet.contains(neighbor)) {
                    continue;
                }

                double tentativeG = current.g + 1;

                Node existingNeighbor = null;
                for (Node n : openSet) {
                    if (n.equals(neighbor)) {
                        existingNeighbor = n;
                        break;
                    }
                }

                if (existingNeighbor == null || tentativeG < existingNeighbor.g) {
                    neighbor.parent = current;
                    neighbor.g = tentativeG;
                    neighbor.h = heuristic(neighbor, end);
                    neighbor.f = neighbor.g + neighbor.h;

                    if (existingNeighbor != null) {
                        openSet.remove(existingNeighbor);
                    }

                    openSet.add(neighbor);
                    cameFrom.put(neighbor, current);
                }
            }
        }

        return new ArrayList<>();
    }

    private List<Node> reconstructPath(Map<Node, Node> cameFrom, Node current) {
        List<Node> path = new ArrayList<>();
        path.add(current);

        while (cameFrom.containsKey(current)) {
            current = cameFrom.get(current);
            path.add(0, current);
        }

        return path;
    }

    public static void main(String[] args) {
        int[][] grid = {
            {0, 0, 0, 0, 0},
            {0, 1, 1, 0, 0},
            {0, 0, 0, 0, 0},
            {0, 0, 1, 1, 0},
            {0, 0, 0, 0, 0}
        };

        AStar astar = new AStar(grid);
        List<Node> path = astar.findPath(0, 0, 4, 4);

        if (!path.isEmpty()) {
            System.out.println("Path found:");
            for (Node node : path) {
                System.out.println("(" + node.x + ", " + node.y + ")");
            }
        } else {
            System.out.println("No path found");
        }
    }
}
