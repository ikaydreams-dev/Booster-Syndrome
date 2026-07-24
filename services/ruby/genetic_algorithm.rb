module Genetic
  class Individual
    attr_accessor :genes, :fitness

    def initialize(genes)
      @genes = genes
      @fitness = nil
    end

    def mutate!(mutation_rate)
      @genes.each_index do |i|
        if rand < mutation_rate
          @genes[i] = rand
        end
      end
    end

    def crossover(other)
      point = rand(@genes.length)
      child1_genes = @genes[0...point] + other.genes[point..-1]
      child2_genes = other.genes[0...point] + @genes[point..-1]

      [Individual.new(child1_genes), Individual.new(child2_genes)]
    end
  end

  class Population
    attr_reader :individuals, :generation

    def initialize(size, gene_length)
      @individuals = Array.new(size) do
        Individual.new(Array.new(gene_length) { rand })
      end
      @generation = 0
    end

    def evaluate_fitness(&block)
      @individuals.each do |individual|
        individual.fitness = block.call(individual.genes)
      end
    end

    def best
      @individuals.max_by(&:fitness)
    end

    def average_fitness
      @individuals.sum(&:fitness) / @individuals.size.to_f
    end

    def selection
      tournament_size = 3
      tournament = @individuals.sample(tournament_size)
      tournament.max_by(&:fitness)
    end

    def evolve(mutation_rate = 0.01, elitism_count = 2)
      @individuals.sort_by! { |i| -i.fitness }

      new_population = @individuals.take(elitism_count)

      while new_population.size < @individuals.size
        parent1 = selection
        parent2 = selection

        children = parent1.crossover(parent2)

        children.each do |child|
          child.mutate!(mutation_rate)
          new_population << child
        end
      end

      @individuals = new_population.take(@individuals.size)
      @generation += 1
    end
  end

  class GeneticAlgorithm
    def initialize(population_size, gene_length, fitness_function)
      @population = Population.new(population_size, gene_length)
      @fitness_function = fitness_function
      @best_ever = nil
    end

    def run(generations, mutation_rate: 0.01, elitism: 2)
      generations.times do |gen|
        @population.evaluate_fitness(&@fitness_function)

        current_best = @population.best

        if @best_ever.nil? || current_best.fitness > @best_ever.fitness
          @best_ever = current_best
        end

        puts "Generation #{gen + 1}: Best = #{current_best.fitness}, Avg = #{@population.average_fitness}" if gen % 10 == 0

        @population.evolve(mutation_rate, elitism)
      end

      @best_ever
    end

    def best_solution
      @best_ever
    end
  end

  class TravelingSalesman
    def self.solve(cities, generations: 1000, population_size: 100)
      gene_length = cities.size

      fitness_function = ->(genes) do
        total_distance = 0
        genes.each_cons(2) do |i, j|
          city1 = cities[i.round % cities.size]
          city2 = cities[j.round % cities.size]
          total_distance += distance(city1, city2)
        end
        -total_distance
      end

      ga = GeneticAlgorithm.new(population_size, gene_length, fitness_function)
      solution = ga.run(generations)

      route = solution.genes.map { |g| g.round % cities.size }
      total_distance = -solution.fitness

      {
        route: route,
        distance: total_distance,
        cities: route.map { |i| cities[i] }
      }
    end

    def self.distance(city1, city2)
      dx = city1[:x] - city2[:x]
      dy = city1[:y] - city2[:y]
      Math.sqrt(dx * dx + dy * dy)
    end
  end

  class Optimization
    def self.minimize(func, bounds, generations: 100, population_size: 50)
      gene_length = bounds.size

      fitness_function = ->(genes) do
        params = genes.zip(bounds).map do |gene, (min, max)|
          min + gene * (max - min)
        end
        -func.call(params)
      end

      ga = GeneticAlgorithm.new(population_size, gene_length, fitness_function)
      solution = ga.run(generations)

      optimized_params = solution.genes.zip(bounds).map do |gene, (min, max)|
        min + gene * (max - min)
      end

      {
        params: optimized_params,
        value: func.call(optimized_params)
      }
    end
  end
end
