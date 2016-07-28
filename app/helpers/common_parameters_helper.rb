module CommonParametersHelper
  # Return true if user is authorized for controller/action OR controller/action@type, otherwise false
  # third argument may be specific object (usually for edit and destroy actions)
  def authorized_via_my_scope(controller, action, object = nil)
    authorized_for(:controller => controller, :action => action, :auth_object => object)
  end

  def parameters_title
    _("Parameters that would be associated with hosts in this %s") % (type)
  end

  def parameter_value_field(value)
    source_name = value[:source_name] ? "(#{value[:source_name]})" : nil
    popover_tag = popover('', _("<b>Source:</b> %{type} %{name}") % { :type => _(value[:source]), :name => html_escape(source_name) }, :data => { :placement => 'top' })
    content_tag(:div, parameter_value_content("value_#{value[:safe_value]}", value[:safe_value], :popover => popover_tag, :disabled => true) + fullscreen_input, :class => 'input-group')
  end

  def parameter_value_content(id, value, options)
    content_tag(:span, options[:popover], :class => "input-group-addon") + lookup_key_field(id, value, options)
  end

  def skip_foreman_help(link_title = nil, title = _("Skip prameter"), body = _("Foreman will not manage this parameter."))
    popover(link_title, body, :title => title)
  end

  def hidden_value_field(f, field, disabled, options = {})
    hidden = options.delete(:hidden_value) || f.object.hidden_value?
    html_class = "form-control no-stretch"
    html_class += " masked-input" if hidden

    input = f.text_area(field, options.merge(:disabled => disabled,
                                             :class => html_class,
                                             :rows => 1,
                                             :placeholder => _("Value")))

    input_group(input, input_group_btn(hidden_toggle(f.object.hidden_value?), fullscreen_button("$(this).closest('.input-group').find('input,textarea')")))
  end

  def lookup_key_field(id, value, options)
    lookup_key = options[:lookup_key]

    option_hash = { :rows => 1,
                    :class => 'form-control no-stretch',
                    :'data-property' => 'value',
                    :'data-hidden-value' => LookupKey.hidden_value,
                    :'data-inherited-value' => options[:inherited_value],
                    :name => options[:name].to_s,
                    :disabled => options[:disabled] }

    option_hash[:class] += " masked-input" if lookup_key.present? && options[:lookup_key_hidden_value?]

    case options[:lookup_key_type]
    when "boolean"
      select_tag(id, options_for_select(['true', 'false'], value), option_hash)
    when "integer", "real"
      number_field_tag(id, value, option_hash)
    else
      text_area_tag(id, value, option_hash)
    end
  end
end
