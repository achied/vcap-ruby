require 'cfautoconfig/configuration_helper'
begin
  require 'redis'
  require File.join(File.dirname(__FILE__), 'redis')
  redis_version = Gem.loaded_specs['redis'].version
  if redis_version >= Gem::Version.new(AutoReconfiguration::SUPPORTED_REDIS_VERSION)
    if AutoReconfiguration::ConfigurationHelper.disabled? :redis
      puts "Redis auto-reconfiguration disabled."
      class Redis
        #Remove introduced aliases and methods.
        #This is mostly for testing, as we don't expect this script
        #to run twice during a single app startup
        if method_defined?(:initialize_with_cf)
          undef_method :initialize_with_cf
          alias :initialize :original_initialize
        end
      end
    elsif Redis.public_instance_methods.index :initialize_with_cf
      #Guard against introducing a method that may already exist
      puts "Redis auto-reconfiguration already included."
    else
      #Introduce around alias into Redis class
      class Redis
        include AutoReconfiguration::Redis
      end
    end
  else
    puts "Auto-reconfiguration not supported for this Redis version.  " +
      "Found: #{redis_version}.  Required: #{AutoReconfiguration::SUPPORTED_REDIS_VERSION} or higher."
  end
rescue LoadError
  puts "No Redis Library Found. Skipping auto-reconfiguration."
end
