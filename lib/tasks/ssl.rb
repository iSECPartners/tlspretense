
desc "Runs all ssl generation code needed."
task :ssl => [ 'ssl:generate:certs' ]
namespace :ssl do
  SSL_DIR = "ssl"
  CA_DIR = File.join(SSL_DIR,"ca")
  CA_FILE = File.join(SSL_DIR,'cacert.pem')
  CA_DER = File.join(SSL_DIR,'cacert.der')

  def certname_from_file(path)  ; File.basename(path,'cert.pem') ; end
  def certfile_from_name(name)  ; File.join(SSL_DIR,name+"cert.pem") ; end
  def keyfile_from_name(name)  ; File.join(SSL_DIR,name+"key-nopass.pem") ; end
  def certconf_from_name(name)  ; File.join(SSL_DIR,name+".cnf") ; end
  def chainfile_from_name(name) ; File.join(SSL_DIR,name+"chain.pem") ; end
  def templatefile_from_name(name) ; File.join(SSL_DIR,name+'.cnf.erb') ; end
  def reqname_from_name(name) ; File.join(SSL_DIR,name+'req.pem') ; end
  def keyfilepass_from_name(name)  ; File.join(SSL_DIR,name+"key-pass.pem") ; end

  # Run cmd without mucking with where its output goes.
  def run(cmd) ; puts cmd ; system(cmd) ; raise "Failed with status #{$?}" if $? != 0 ; end

  # Default key password is in the .cnf file.
  def create_request(name)
    conf = name+".cnf"
    keywpass = name+"key-pass.pem"
    req = name+'req.pem'

    puts "Generating a new certificate request:"
    puts "====================================="
    run "openssl req -config #{conf} -new -keyout #{keywpass} -out #{req} -days 30 -batch 2>&1"
  end

  # The CA is specified in the .cnf file.
  def ca_sign(name)
    conf = name+".cnf"
    cert = name+"cert.pem"
    req = name+'req.pem'
    puts "Now the CA will sign it:"
    puts "========================"
    run "openssl ca -batch -config #{conf} -policy policy_anything -out #{cert} -passin pass:demo -notext -infiles #{req} 2>&1"
  end

  def arbitrary_sign(name, ca)
    conf = name+".cnf"
    cert = name+"cert.pem"
    req = name+'req.pem'
    cacert = ca+"cert.pem"
    cakey = ca+"key-nopass.pem"
    puts "Now the intermediate will sign it:"
    puts "=================================="
    run "openssl x509 -req -days 365 -extfile #{conf} -extensions v3_req -extensions usr_cert -in #{req} -CA #{cacert} -CAkey #{cakey} -out #{cert} -set_serial 01 2>&1"
  end

  def self_sign(name)
    conf = name+".cnf"
    req = name+'req.pem'
    keywpass = name+"key-pass.pem"
    cert = name+"cert.pem"
    puts "Self sign the certificate"
    puts "========================="
    run "openssl x509 -req -days 365 -extfile #{conf} -extensions v3_req -in #{req} -passin pass:demo -signkey #{keywpass} -out #{cert}"
  end

  # just like ca_sign but validity is in the past
  def sign_expired(name)
    conf = name+".cnf"
    cert = name+"cert.pem"
    req = name+'req.pem'
    puts "Now the CA will sign it (with validity in the past:"
    puts "==================================================="
    run "openssl ca -batch -config #{conf} -policy policy_anything -out #{cert} -passin pass:demo -notext -startdate 010101000000Z -enddate 111231000000Z -infiles #{req} 2>&1"
  end

  def remove_passphrase(name, pass='demo')
    keywpass = name+"key-pass.pem"
    keynopass = name+"key-nopass.pem"
    puts "Strip off the passphrase:"
    puts "============================="
    run "openssl rsa -in #{keywpass} -passin pass:#{pass} -out #{keynopass} 2>&1"
  end


  def create_cert(name, ca=nil)
    create_request(name)
    if ca == nil
      ca_sign(name)
    else
      arbitrary_sign(name, ca)
    end
    remove_passphrase(name)
  end

  def create_self_signed_cert(name)
    create_request(name)
    self_sign(name)
    remove_passphrase(name)
  end

  certnames = FileList[SSL_DIR+'/??-*.cnf.erb'].pathmap("%f").map { |fn| fn.gsub(/.cnf.erb$/,'') }
  certfiles = certnames.map { |certname| certfile_from_name(certname) }
  chainfiles = certnames.map { |certname| chainfile_from_name(certname) }

  namespace :generate do
    desc "Create the CA (and CA dir)"
    task :ca => CA_FILE

    file CA_FILE do
      rm_rf CA_DIR
      rm_rf CA_FILE
      cd SSL_DIR
      run './create-ca.sh ca'
      cd ".."
    end


    file CA_DIR => [ CA_FILE ] do ; end

    file CA_DER => [ CA_FILE ] do
      sh "openssl x509 -in #{CA_FILE} -outform DERM -out #{CA_DER}"
    end

    desc "Create the server certificates for the SSL tests."
    task :certs => chainfiles

    certfiles.each do |certfile|
      certname = certname_from_file(certfile)
      chainfile = chainfile_from_name(certname)
      templatefile = templatefile_from_name(certname)
      keyfile = keyfile_from_name(certname)
      certconf = certconf_from_name(certname)

      file certconf => [ templatefile ] do
        puts "Generating #{certconf} from #{templatefile}"
        require 'erb'
        templdata = File.open(templatefile) { |f| f.readlines.join('') }
        erb = ERB.new(templdata)
        erb.filename = templatefile
        def foo(commonname)
          proc { }
        end
        b = foo(CONFIG['commonname'])
        File.open(certconf_from_name(certname),'w') do |f|
          f.write(erb.result(b.binding))
        end
      end

      # Actually creates both the certificate file and the private key.
      file certfile => [CA_DIR, certconf_from_name(certname)] do
        cd SSL_DIR
        case certname
        when "03-selfsigned"
          create_self_signed_cert(certname)
        when "04-unknownca"
          run './create-ca.sh 04ca' unless File.exist? '04ca'
          create_cert(certname)
        when "05-signedbyintermediate"
          create_cert("05intermediate")
          create_cert("05-signedbyintermediate","05intermediate")
        when "06-expired"
          create_request(certname)
          sign_expired(certname)
          remove_passphrase(certname)
        else
          create_cert(certname)
        end
        cd ".."
      end

      file chainfile => [ certfile ] do
        case certname
        when /^03/
          chain = [ keyfile, certfile ]
        when /^04/
          chain = [ keyfile, certfile, File.join(SSL_DIR,"04cacert.pem") ]
#          chain = [ keyfile, File.join(SSL_DIR,"04cacert.pem", certfile) ]
        when /^05/
          chain = [ keyfile, certfile, File.join(SSL_DIR,"05intermediatecert.pem"), File.join(SSL_DIR,"cacert.pem") ]
#          chain = [ keyfile,
#                    File.join(SSL_DIR,"cacert.pem"),
#                    File.join(SSL_DIR,"05intermediatecert.pem"),
#                    certfile,
#          ]
        else
          chain = [ keyfile, certfile, File.join(SSL_DIR, "cacert.pem") ]
        end
        run "cat #{chain.join(' ')} > #{chainfile}"
      end
    end
  end

  desc "Remove the generated CA and certificates"
  task :clean do
    cd SSL_DIR
    run "./clean.sh"
    cd ".."
  end
end
