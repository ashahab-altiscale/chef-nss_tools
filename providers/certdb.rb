require 'tempfile'
require 'openssl'

#use_inline_resources

def whyrun_supported?
  true
end

action :update do
  load_new_pkcs12

  if @pkcs12_current && pkcs12_equal?(@pkcs12_new, @pkcs12_current)
    Chef::Log.debug 'Certificate database already up to date'
  else
    converge_by "Updating #{@new_resource.name} in database #{@new_resource.directory}" do
      delete
      ret = add
      if ret[2] != 0
        Chef::Log.error ret[0]
        Chef::Log.error ret[1]
        raise "Failed to add certificate to database! (#{ret[2]})\n\n#{ret[0]}\n#{ret[1]}"
      end
      @pkcs12file_new.close!
    end
  end
end

action :delete do
  converge_by "Removing #{@new_resource.name} from database #{@new_resource.directory}" do
    delete
  end
end

def load_current_resource
  @current_resource = Chef::Resource::NssToolsCertdb.new(@new_resource.name)
  @current_resource.directory(@new_resource.directory)
  @current_resource.dbprefix(@new_resource.dbprefix)

  @pkcs12file_new = Tempfile.new([@new_resource.name,'.p12'])
  @pkcs12file_current = Tempfile.new([@current_resource.name,'.p12'])

  # Export the current db with name to a pkcs12 format for inspection
  ret = pk12util("-o #{@pkcs12file_current.path} -n '#{@current_resource.name}' -W '' -K ''",
    @current_resource.directory,
    @current_resource.dbprefix)[2]

  case ret
  when 255
    @dbexist = false
    @nameexists = false
  when 24
    @dbexists = true
    @nameexists = false
  else
    @dbexists = true
    @nameexists = true
  end

  # Read in current sutff
  if @dbexists && @nameexists
    @pkcs12_current = ::OpenSSL::PKCS12.new(::File.read(@pkcs12file_current.path))
  end

  @pkcs12file_current.close!
  @current_resource
end

def nsscmd(command, args, dir = nil, prefix = nil)
  cmdstr = command.dup
  cmdstr << " -d #{dir}" unless dir.nil?
  cmdstr << " -P #{prefix}" unless prefix.nil?
  cmdstr << ' ' << args

  cmd = Mixlib::ShellOut.new(cmdstr)
  Chef::Log.debug "nss_tool_certdb #{command} CMD: #{cmdstr}"
  cmd.run_command
  Chef::Log.debug "nss_tool_certdb #{command} RET: #{cmd.exitstatus}"
  Chef::Log.debug "nss_tool_certdb #{command} OUT: #{cmd.stdout}"
  Chef::Log.debug "nss_tool_certdb #{command} ERR: #{cmd.stderr}"

  return [cmd.stdout, cmd.stderr, cmd.exitstatus]
end

def certutil(args, dir = nil, prefix = nil)
  nsscmd('certutil', args, dir, prefix)
end

def pk12util(args, dir = nil, prefix = nil)
  nsscmd('pk12util', args, dir, prefix)
end

def delete
  certutil("-D -n '#{@new_resource.name}'",
           @new_resource.directory,
           @new_resource.dbprefix)
end

def add
  @pkcs12file_new.rewind
  @pkcs12file_new.write @pkcs12_new.to_der
  @pkcs12file_new.close
  Chef::Log.info "Updating #{@new_resource.name} certificate database in "\
    "#{@new_resource.directory}"
  pk12util("-i #{@pkcs12file_new.path} -W '' -K ''",
           @new_resource.directory,
           @new_resource.dbprefix)
end

def load_new_pkcs12
  # Load new certificates
  if @new_resource.crt && @new_resource.key
    Chef::Log.debug "Got PEM cert and key pair"
    Chef::Log.debug "CRT: #{@new_resource.crt}"
    Chef::Log.debug "KEY: #{@new_resource.key}"

    if @new_resource.ca
      Chef::Log.debug "Also got CA certificate(s)"

      @new_resource.ca([@new_resource.ca]) unless @new_resource.ca.is_a? Array

      cas = []
      @new_resource.ca.each do |ca_file|
        Chef::Log.debug "CA: #{ca_file}"

        # Load each certificate as an array
        pems = ::File.read(ca_file).split(/(-----END CERTIFICATE-----\n)/).each_slice(2).map(&:join)
        pems.each do |pem|
          cas << ::OpenSSL::X509::Certificate.new(pem)
        end
      end

      @pkcs12_new = ::OpenSSL::PKCS12.create '',
        @new_resource.name,
        ::OpenSSL::PKey.read(::File.open(@new_resource.key)),
        ::OpenSSL::X509::Certificate.new(::File.read(@new_resource.crt)),
        cas
    else
      @pkcs12_new = ::OpenSSL::PKCS12.create '',
        @new_resource.name,
        ::OpenSSL::PKey.new(::File.read(@new_resource.key)),
        ::OpenSSL::X509::Certificate.new(::File.read(@new_resource.crt))
    end
  # Load new DER
  elsif @new_resource.der
    Chef::Log.debug "Got DER PKCS12 file: #{@new_resource.der}"
    @pkcs12_new = ::OpenSSL::PKCS12.new(::File.read(@new_resource.der))
  else
    raise 'You must pass pem cert, key, and optionally ca(s) or a der!'
  end
end

def pkcs12_equal?(a, b)
  return false unless a.key.to_s == b.key.to_s
  return false unless a.certificate.to_s == b.certificate.to_s
  return false unless a.ca_certs.count == b.ca_certs.count

  a.ca_certs.each do |ca_cert|
    ret = true
    b.ca_certs.each do |b_ca_cert|
      if ca_cert == b_ca_cert
        next
      end
    end
    return false unless ret
  end
end
