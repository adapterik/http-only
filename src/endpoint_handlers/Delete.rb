require_relative './EndpointHandler'

class Delete < EndpointHandler 
  
def initialize(context, input)
  super(context, input)
  # For the generic "news" page content
  @page_id = @context[:endpoint_name]
end
  
  def ensure_can_edit()
     # Ensure authenticated session that can edit.
     if @context[:session].nil?
      raise ClientErrorUnauthorized.new
    end
    if @context[:session]["can_edit"] == 0
      raise ClientErrorForbidden.new
    end
  end

  #
  # The GET method displays the deletion form
  #
  def handle_get()
    ensure_can_edit

    page, content_type = fetch_page


    # This allows the header to highlight the page being edited.
    content_id_to_delete = @context[:arguments][0]
    content_to_delete = @site_db.get_content(content_id_to_delete)
    content_to_delete_content_type = @site_db.get_content_type(content_to_delete['content_type'])

    page['title'] = "Deleting #{content_to_delete_content_type['noun']} \"#{content_to_delete['title']}\""

    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    @context.merge!({
      site: @site,
      page: page,
      content_type: content_type,
      env: {
        request: request
      },
    })

    return_path_success = @context[:params]['return_path_success']
    return_path_cancel = @context[:params]['return_path_cancel']

    @data = {
      :content_id => content_id_to_delete,
      :content => content_to_delete,
      :content_type => content_to_delete_content_type,
      :return_path_success => return_path_success,
      :return_path_cancel => return_path_cancel
    }

    render_template
  end

  def handle_delete(form_data) 
    ensure_can_edit
    content_id_to_delete = @context[:arguments][0]

     @site_db.delete_content(content_id_to_delete)

     ['', 302, {'location' => form_data['return_path_success']}]
  end

  def handle_post()
    ensure_can_edit

    form_data = URI.decode_www_form(@input.gets).to_h

    if not form_data.has_key? '_method'
      raise ClientError('Sorry, need a method')
    end

    fake_method = form_data['_method']
    case fake_method.downcase
      when 'delete'
        handle_delete(form_data)
      else 
        raise ClientError('Sorry, only "delete" supported')
    end
  end

end