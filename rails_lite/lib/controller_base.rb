require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'active_support/inflector'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = nil)
    @req = req
    @res = res
    @params = params
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double redirect error" if already_built_response?
    @already_built_response = true
    @res["Location"] = url
    @res.status = 302
    self.session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Double render error" if already_built_response?
    @already_built_response = true
    @res.write(content)
    @res["Content-Type"] = content_type
    self.session.store_session(@res)
  end

  # "views/#{controller_name}/#{template_name}.html.erb"
  
  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.to_s.underscore
    absolute_path = File.dirname(File.dirname(__FILE__))
    
    path = File.join(
      absolute_path,
      "views",
      controller_name,
      template_name.to_s
    ) + ".html.erb"

    content = ERB.new(File.read(path)).result(binding)
    render_content(content, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    self.render(name) unless already_built_response?
  end
end

