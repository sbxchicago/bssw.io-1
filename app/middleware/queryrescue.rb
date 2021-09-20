# frozen_string_literal: true

# render an error page if we get a bad request
class RefuseInvalidRequest
  def initialize(app)
    @app = app
  end

  def call(env)
    query = begin
      Rack::Utils.parse_nested_query(env['QUERY_STRING'].to_s)
    rescue StandardError
      :bad_query
    end
    if query == :bad_query
      env['QUERY_STRING'] = nil
      ApplicationController.action(:render_error).call(env)
    else
      @app.call(env)
    end
  end
end
