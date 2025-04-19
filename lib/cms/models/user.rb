require_relative './collection'

class User < Collection
  def self.build_config(name: 'Users', use_username: true, use_email: true, use_password: true, use_pfp: false, custom_fields: [])
    fields = []

    fields << { name: 'username', type: 'string', required: true } if use_username
    fields << { name: 'email', type: 'email', required: true } if use_email
    fields << { name: 'password', type: 'password', required: true, admin_visible: false } if use_password
    fields << { name: 'pfp', type: 'upload', relation_to: 'media' } if use_pfp
    fields.push(*custom_fields)

    { name: name, slug: 'users', fields: fields, icon: 'person', __internal_class: :user }
  end
end
