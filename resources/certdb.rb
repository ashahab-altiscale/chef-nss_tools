actions :update, :delete
default_action :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :directory, :kind_of => [String, NilClass]
attribute :dbprefix, :kind_of => [String, NilClass]
attribute :crt, :kind_of => [String, NilClass]
attribute :key, :kind_of => [String, NilClass]
attribute :ca, :kind_of => [String, Array, NilClass]
attribute :der, :kind_of => [String, NilClass]

attribute :pkcs12, :kind_of => OpenSSL::PKCS12
attribute :pkcs12file, :kind_of => String
