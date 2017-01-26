require "pngquant/version"
require "open3"
require "unix/whereis"

module Pngquant

  COMMAND = :pngquant

  MATCHERS = [
    /error:\s*(.*)/,
    /exists;\snot\soverwriting/
  ]

  Result = Struct::new(:succeed, :errors)

  # Your code goes here...
  def self.available?
    return Whereis.available? self::COMMAND
  end

  def self.optimize(png_paths, options = {}, &block)
    
    # Files
    if png_paths.kind_of? String
      png_paths = [png_paths]
    end

    # Options
    opts = __options(options)

    # Run
    cmd = "#{self::COMMAND.to_s} #{png_paths.join(' ')} #{opts.map{|opt|"#{opt.first}#{'='+opt.last.to_s unless opt.last.boolean?}"}.join(' ')}"
    o, e, s = Open3.capture3(cmd)

    # Debug
    if options[:debug]
      STDERR.write "#{cmd}\n"
    end

    # Parse output
    succeed, errors = __parse_output(o, e, s)

    if block.nil?
      return self::Result::new(succeed, errors)
    else
      block.call(self::Result::new(succeed, errors))
    end

  end

  private

  def self.__options(options = {})

    opts = {}

    if options[:speed].kind_of? Integer
      opts["--speed"] = options[:speed]
    end

    if options[:posterize].kind_of? Integer
      opts["--posterize"] = options[:posterize]
    end

    if options[:output].kind_of? String
      opts["--output"] = options[:output]
    end

    if options[:quality].kind_of? String
      opts["--quality"] = options[:quality]
    end

    if options[:ext].kind_of? String
      opts["--ext"] = options[:ext]
    end

    unless options[:"skip-if-larger"].nil?
      opts["--skip-if-larger"] = true
    end

    unless options[:nofs].nil?
      opts["--nofs"] = true
    end

    unless options[:verbose].nil?
      opts["--verbose"] = true
    end

    # Override
    opts["--force"] = options[:force].nil?? true: options[:force]

    opts

  end

  def self.__parse_output(o, e, s)
    errors = []
    succeed = {}

    e.each_line do |line|
      if m = line.match(self::MATCHERS[0])
        errors << m[1]
      elsif m = line.match(self::MATCHERS[1])
        errors << m[1]
      end
    end
    return [succeed, errors]

  end


end
