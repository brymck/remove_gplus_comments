require 'coffee-script'
require 'fileutils'
require 'haml'
require 'json'
require 'RedCloth'
require 'sass'
require 'shellwords'
require 'uglifier'
require 'yaml'

@debug       = true
ROOT_DIR     = File.expand_path(File.dirname(__FILE__))
CHROME_DIR   = File.join(ROOT_DIR, 'chrome')
EXTERNAL_DIR = File.join(ROOT_DIR, 'ext')
SOURCE_DIR   = File.join(ROOT_DIR, 'src')
STATIC_EXTENSIONS = %w(png)

def verify_directory(path)
  FileUtils.mkdir_p(path) unless File.directory?(path)
end

def verify_extension_structure
  verify_directory CHROME_DIR
  %w(css img js).each do |subdirectory|
    verify_directory File.join(CHROME_DIR, subdirectory)
  end
end

def log(*args)
  puts *args
end

def manifest
  @manifest ||= JSON.parser.new(File.read(File.join(CHROME_DIR, 'manifest.json'))).parse
end

def compile_sources(input_type, opts = {})
  verify_extension_structure

  output_dir = File.join(CHROME_DIR, opts[:output_dir] || '')
  input_dir  = File.join(SOURCE_DIR,    opts[:input_dir]  || '')
  subdir_search = opts[:merge_subdirectories] ? '*' : '**'

  log input_type
  Dir[File.join(input_dir, subdir_search, "*.*.#{input_type}")].each do |path|
    sub_path      = path.sub(input_dir, '').sub(/^[\/.]+/, '')
    output_name   = File.basename(path, '.*')
    relative_path = File.join(File.dirname(sub_path), output_name).sub(/^[\/.]+/, '')
    output_path   = File.join(output_dir, relative_path)

    File.open(output_path, 'w') do |handle|
      log "  #{relative_path}"
      handle.puts yield(File.read(path))
    end
  end

  if opts[:merge_subdirectories]
    Dir[File.join(input_dir, '*', '*/')].each do |subdir|
      files         = Dir[File.join(subdir, "**/*.*.#{input_type}")].sort
      extension     = File.basename(files[0], '.*').split('.').last
      result        = files.map { |p| File.read(p) }.join("\n")
      sub_paths     = subdir.sub(input_dir, '').sub(/^[\/.]+/, '').split('/')
      output_name   = "#{sub_paths.pop}.#{extension}"
      sub_path      = sub_paths.join('/')
      relative_path = File.join(sub_path, output_name).sub(/^[\/.]+/, '')
      output_path   = File.join(output_dir, relative_path)

      File.open(output_path, 'w') do |handle|
        log "  #{relative_path}"
        handle.puts yield(result)
      end

      files.each { |p| log "    #{p.sub(subdir, '')}" }
    end
  end
end

namespace :build do
  desc 'Compile CoffeeScript to JavaScript'
  task :coffee do
    opts = { :merge_subdirectories => true }
    compile_sources('coffee', opts) do |content|
      js = CoffeeScript.compile(content, :bare => true)
      if @debug
        js
      else
        Uglifier.compile js
      end
    end
  end

  desc 'Compile HAML to HTML'
  task :haml do
    compile_sources('haml') do |content|
      Haml::Engine.new(content).render
    end
  end

  desc 'Compile SASS to CSS'
  task :sass do
    compile_sources('sass') do |content|
      Sass::Engine.new(content).render
    end
  end

  desc 'Compile YAML to JSON'
  task :yml do
    compile_sources('yml') do |content|
      json = YAML.load(content).to_json
      JSON.pretty_generate JSON.parse(json)
    end
  end
end

desc 'Copy uncompiled assets from ext/ and src/ to chrome/'
task :raw do
  verify_extension_structure
  STATIC_EXTENSIONS.each do |ext|
    log ext
    Dir[File.join(SOURCE_DIR, '**', "*.#{ext}")].each do |path|
      relative_path = path.sub(SOURCE_DIR, '').sub(/^\//, '')
      log "  #{relative_path}"
      FileUtils.cp path, File.join(CHROME_DIR, relative_path)
    end
  end

  log 'ext'
  FileUtils.cp_r Dir[File.join(EXTERNAL_DIR, '*')], CHROME_DIR

  log 'license'
  %w(BEERWARE-LICENSE MIT-LICENSE).each do |license|
    log "  #{license}"
    FileUtils.cp File.expand_path(license), File.join(CHROME_DIR, license)
  end
end

desc 'Zip extension'
task :zip do
  base_name = "#{manifest['name']}_#{manifest['version']}".shellescape
  full_name = File.join(ROOT_DIR, base_name)

  FileUtils.rm Dir["#{full_name}.*"]

  Dir.chdir(CHROME_DIR) do
    log %x[zip -T #{full_name}.zip *.* **/*.*]
  end
end

desc 'Turn debug off'
task :production do
  @debug = false
end

desc 'Compile and copy over all extension files'
task :build => [:production, 'build:coffee', 'build:haml', 'build:sass', 'build:yml',
                :raw, :zip]

desc 'Compile and copy over all extension files but leave human-readable'
task 'build:debug' => ['build:coffee', 'build:haml', 'build:sass', 'build:yml',
                       :raw, :zip]

desc 'Clean chrome/ directory'
task :clean do
  FileUtils.rm_rf CHROME_DIR
end
