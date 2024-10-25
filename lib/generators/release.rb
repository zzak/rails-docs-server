require 'fileutils'
require 'version_number'
require 'generators/base'
require 'generators/config/release'

module Generators
  class Release < Base
    include Config::Release

    def initialize(tag, basedir)
      super(tag, basedir)
      @version_number = VersionNumber.new(tag)
    end

    def before_generation
      if version_number == '4.2.10'
        # There is a dependency on json that doesn't play well with the following downgrade.
        FileUtils.rm_f('Gemfile.lock')

        patch 'Gemfile' do |contents|
          # See the comment above for 4.2.9.
          contents.sub(/gem 'sdoc'.*/, "gem 'sdoc', '~> 0.4.0'")
        end
      elsif version_number >= '5.1.2' && version_number <= '5.1.4'
        patch 'guides/source/documents.yaml' do |contents|
          # This guide was deleted and prevented Kindle guides from being
          # generated. See https://github.com/rails/rails/issues/29865.
          contents.sub(/^\s+name: Profiling Rails Applications[^-]+-\n/, '')
        end
      elsif Gem::Version.new(version_number) >= Gem::Version.new('6.1.7.9') && version_number < '7.0.0'
        # There is a dependency on nokogiri that doesn't play well with sqlite3
        FileUtils.rm_f('Gemfile.lock')
      elsif version_number >= '6.1.7.5' && version_number < '7.0.0'
        patch 'Gemfile' do |contents|
          contents << "\ngem \"loofah\", \"< 2.21.0\"\n"
        end
      elsif version_number >= '5.2.6'
        run 'gem install bundler'
      end
    end

    def generate_api
      rake 'rdoc'
    end

    def generate_guides
      Dir.chdir('guides') do
        rake 'guides:generate:html',   'RAILS_VERSION' => target
        rake 'guides:generate:kindle', 'RAILS_VERSION' => target
      end
    end

    private

    def version_number
      @version_number
    end
  end
end
