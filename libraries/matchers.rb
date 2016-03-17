if defined?(ChefSpec)
  def update_nss_tools_certdb(name)
    ChefSpec::Matchers::ResourceMatcher.new(:nss_tools_certdb, :write, name)
  end

  def delete_nss_tools_certdb(name)
    ChefSpec::Matchers::ResourceMatcher.new(:nss_tools_certdb, :delete, name)
  end
end
