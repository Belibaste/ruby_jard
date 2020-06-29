# frozen_string_literal: true

module RubyJard
  module Decorators
    ##
    # Simplify and generate labels to indicate the location of a path.
    # If it's from gem, strip Gem paths, or Bundler paths to expose relative
    # location of the file.
    # If it's from the current working dir, strip the working dir.
    class PathDecorator
      GEM_PATTERN = /(.*)\-(\d+\.\d+[\.\d]*[\.\d]*[\-\.\w]*)/i.freeze
      PATH_TYPES = [
        TYPE_UNKNOWN = :unknown,
        TYPE_PWD = :pwd,
        TYPE_GEM = :gem
      ].freeze

      attr_reader :path, :lineno, :gem, :gem_version

      def initialize(path, lineno)
        @gem = nil
        @gem_version = nil
        @path = path
        @lineno = lineno
        @type = TYPE_UNKNOWN

        decorate
      end

      def decorate
        if path.start_with?(Dir.pwd)
          @type = TYPE_PWD
          @path = @path[Dir.pwd.length..-1]
        else
          decorate_gem_path
        end

        @path = @path[1..-1] if @path.start_with?('/')
      end

      def gem?
        @type == TYPE_GEM
      end

      private

      def decorate_gem_path
        gem_paths.each do |gem_path|
          next unless path.start_with?(gem_path)

          @type = TYPE_GEM
          splitted_path = @path[gem_path.length..-1].split('/')
          @path = splitted_path[1..-1].join('/')
          @gem = splitted_path.first
          match = GEM_PATTERN.match(@gem)
          if match
            @gem = match[1]
            @gem_version = match[2]
          end

          break
        end
      end

      def gem_paths
        paths = []

        if defined?(Gem)
          Gem.path.each do |gem_path|
            paths << File.join(gem_path, 'gems')
            paths << gem_path
          end
        end

        if defined?(Bundler)
          bundle_path = Bundler.bundle_path.to_s
          paths << File.join(bundle_path, 'gems')
          paths << bundle_path
        end

        paths
      end
    end
  end
end
