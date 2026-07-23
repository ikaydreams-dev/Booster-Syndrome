package com.booster.random;

import java.util.Random;
import java.util.List;
import java.util.ArrayList;

public class RandomGenerator {
    private Random random;

    public RandomGenerator() {
        this.random = new Random();
    }

    public RandomGenerator(long seed) {
        this.random = new Random(seed);
    }

    public int nextInt(int min, int max) {
        return random.nextInt(max - min + 1) + min;
    }

    public double nextDouble(double min, double max) {
        return min + (max - min) * random.nextDouble();
    }

    public boolean nextBoolean() {
        return random.nextBoolean();
    }

    public String nextString(int length) {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < length; i++) {
            int index = random.nextInt(chars.length());
            sb.append(chars.charAt(index));
        }

        return sb.toString();
    }

    public String nextAlphanumeric(int length) {
        return nextString(length);
    }

    public String nextNumeric(int length) {
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < length; i++) {
            sb.append(random.nextInt(10));
        }

        return sb.toString();
    }

    public <T> T choice(T[] array) {
        if (array.length == 0) {
            return null;
        }

        return array[random.nextInt(array.length)];
    }

    public <T> T choice(List<T> list) {
        if (list.isEmpty()) {
            return null;
        }

        return list.get(random.nextInt(list.size()));
    }

    public <T> List<T> sample(List<T> list, int count) {
        if (count > list.size()) {
            throw new IllegalArgumentException("Sample size cannot exceed list size");
        }

        List<T> result = new ArrayList<>(list);
        List<T> sample = new ArrayList<>();

        for (int i = 0; i < count; i++) {
            int index = random.nextInt(result.size());
            sample.add(result.remove(index));
        }

        return sample;
    }

    public <T> void shuffle(List<T> list) {
        for (int i = list.size() - 1; i > 0; i--) {
            int j = random.nextInt(i + 1);
            T temp = list.get(i);
            list.set(i, list.get(j));
            list.set(j, temp);
        }
    }

    public double nextGaussian(double mean, double stdDev) {
        return mean + stdDev * random.nextGaussian();
    }
}
