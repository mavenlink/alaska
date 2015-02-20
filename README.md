# Alaska

In a rails initializer file (e.g. `config/initializers/execjs.rb`) declare the `ExecJS.runtime` to be an instance of `Alaska`

    require 'alaska'

    if Rails.env == "development" || Rails.env == "test" || ENV["RAILS_GROUPS"] == "assets"
      # use alaska.js pipelining only when precompiling assets
      ExecJS.runtime = Alaska.new(:debug => true)
    end
