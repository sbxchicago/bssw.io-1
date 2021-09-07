class RefuseInvalidRequest
  def initialize(app)
    @app = app
  end

  def call(env)
    query = Rack::Utils.parse_nested_query(env['QUERY_STRING'].to_s) rescue :bad_query
    if query == :bad_query
      env['application_controller.instance'].class.action(:render_error).call(env)
    else
      @app.call(env)
    end
  end
end
