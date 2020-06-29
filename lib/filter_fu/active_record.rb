module FilterFu
  module ActiveRecord
    extend ActiveSupport::Concern

    module ClassMethods

      VALID_FILTER_OPTIONS = [:only, :except]

      def filter_fu(opts = {})
        opts = opts.symbolize_keys!
        opts.each_key { |option| raise "Invalid filter_fu option: #{option}" unless VALID_FILTER_OPTIONS.include?(option) }
        raise "Use either :only or :except as a filter_fu option." if opts.has_key?(:only) && opts.has_key?(:except)

        opts[:only]   = [opts[:only]].flatten.collect(&:to_sym) if opts[:only]
        opts[:except] = [opts[:except]].flatten.collect(&:to_sym) if opts[:except]

        @filter_options = opts

        extend SingletonMethods
      end

    end

    module SingletonMethods

      def filtered_by(filter)
        return where('1=1') if !filter || filter.empty?

        filter.inject(self) do |memo, (scope, arg)|
          scope = scope.to_sym
          next if protected?(scope)
          if memo.respond_to?(scope)
            memo.send(scope, arg)
          else
            scope_str = scope.to_s
            return memo.where('1=1') unless column_names.include?(scope_str) && !arg.blank?
            memo.where(scope_str, arg)
          end
        end || where('1=1')
      end

      private

      def protected?(scope)
        if @filter_options.has_key?(:only)
          return !@filter_options[:only].include?(scope)
        elsif @filter_options.has_key?(:except)
          return @filter_options[:except].include?(scope)
        end
        return false
      end

    end

  end
end
