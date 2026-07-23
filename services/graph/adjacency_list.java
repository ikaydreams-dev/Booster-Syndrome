package com.booster.graph;

import java.util.*;

public class Graph {
    private Map<Integer, List<Integer>> adjacencyList;
    private boolean directed;

    public Graph(boolean directed) {
        this.adjacencyList = new HashMap<>();
        this.directed = directed;
    }

    public void addVertex(int vertex) {
        adjacencyList.putIfAbsent(vertex, new ArrayList<>());
    }

    public void addEdge(int source, int destination) {
        addVertex(source);
        addVertex(destination);

        adjacencyList.get(source).add(destination);

        if (!directed) {
            adjacencyList.get(destination).add(source);
        }
    }

    public List<Integer> getNeighbors(int vertex) {
        return adjacencyList.getOrDefault(vertex, new ArrayList<>());
    }

    public List<Integer> bfs(int start) {
        List<Integer> result = new ArrayList<>();
        Set<Integer> visited = new HashSet<>();
        Queue<Integer> queue = new LinkedList<>();

        queue.offer(start);
        visited.add(start);

        while (!queue.isEmpty()) {
            int vertex = queue.poll();
            result.add(vertex);

            for (int neighbor : getNeighbors(vertex)) {
                if (!visited.contains(neighbor)) {
                    visited.add(neighbor);
                    queue.offer(neighbor);
                }
            }
        }

        return result;
    }

    public List<Integer> dfs(int start) {
        List<Integer> result = new ArrayList<>();
        Set<Integer> visited = new HashSet<>();
        dfsHelper(start, visited, result);
        return result;
    }

    private void dfsHelper(int vertex, Set<Integer> visited, List<Integer> result) {
        visited.add(vertex);
        result.add(vertex);

        for (int neighbor : getNeighbors(vertex)) {
            if (!visited.contains(neighbor)) {
                dfsHelper(neighbor, visited, result);
            }
        }
    }

    public boolean hasPath(int source, int destination) {
        Set<Integer> visited = new HashSet<>();
        return hasPathHelper(source, destination, visited);
    }

    private boolean hasPathHelper(int current, int destination, Set<Integer> visited) {
        if (current == destination) return true;
        if (visited.contains(current)) return false;

        visited.add(current);

        for (int neighbor : getNeighbors(current)) {
            if (hasPathHelper(neighbor, destination, visited)) {
                return true;
            }
        }

        return false;
    }

    public int getVertexCount() {
        return adjacencyList.size();
    }

    public int getEdgeCount() {
        int count = 0;
        for (List<Integer> neighbors : adjacencyList.values()) {
            count += neighbors.size();
        }
        return directed ? count : count / 2;
    }
}
