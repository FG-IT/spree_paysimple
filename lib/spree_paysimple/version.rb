module SpreePaysimple
  VERSION = '0.0.2'

  module_function

  # Returns the version of the currently loaded SpreePaysimple as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION
  end
end
