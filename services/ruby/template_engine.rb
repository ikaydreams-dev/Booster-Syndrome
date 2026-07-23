module TemplateEngine
  class Template
    def initialize(source)
      @source = source
      @compiled = nil
    end

    def render(context = {})
      compile unless @compiled
      @compiled.call(context)
    end

    private

    def compile
      code = @source.gsub(/\{\{([^}]+)\}\}/) do
        var_name = $1.strip
        "#{context['#{var_name}']}"
      end

      @compiled = ->(context) { eval("\"#{code}\"") }
    end
  end

  class AdvancedTemplate
    def initialize(source)
      @source = source
    end

    def render(context = {})
      result = @source.dup

      result.gsub!(/\{\{(.+?)\}\}/) do
        expression = $1.strip
        evaluate_expression(expression, context)
      end

      result.gsub!(/\{%\s*if\s+(.+?)\s*%\}(.*?)\{%\s*endif\s*%\}/m) do
        condition = $1.strip
        content = $2
        evaluate_expression(condition, context) ? content : ''
      end

      result.gsub!(/\{%\s*for\s+(\w+)\s+in\s+(.+?)\s*%\}(.*?)\{%\s*endfor\s*%\}/m) do
        var_name = $1
        collection = $2.strip
        content = $3

        items = evaluate_expression(collection, context)
        items.map do |item|
          new_context = context.merge(var_name => item)
          AdvancedTemplate.new(content).render(new_context)
        end.join
      end

      result
    end

    private

    def evaluate_expression(expr, context)
      if expr =~ /^['"](.*)['"]$/
        $1
      elsif expr =~ /^\d+$/
        expr.to_i
      elsif expr =~ /^\d+\.\d+$/
        expr.to_f
      elsif context.key?(expr)
        context[expr]
      elsif expr.include?('.')
        parts = expr.split('.')
        result = context[parts[0]]
        parts[1..-1].each do |part|
          result = result.is_a?(Hash) ? result[part] : result.send(part)
        end
        result
      else
        nil
      end
    end
  end

  class ViewRenderer
    def initialize(template_dir)
      @template_dir = template_dir
      @cache = {}
    end

    def render(template_name, context = {}, layout: nil)
      content = render_template(template_name, context)

      if layout
        layout_context = context.merge('content' => content)
        render_template(layout, layout_context)
      else
        content
      end
    end

    def render_partial(partial_name, context = {})
      render_template("_#{partial_name}", context)
    end

    private

    def render_template(name, context)
      template = load_template(name)
      template.render(context)
    end

    def load_template(name)
      path = File.join(@template_dir, "#{name}.html.erb")

      if @cache.key?(path)
        @cache[path]
      else
        source = File.read(path)
        template = AdvancedTemplate.new(source)
        @cache[path] = template
        template
      end
    end
  end
end
