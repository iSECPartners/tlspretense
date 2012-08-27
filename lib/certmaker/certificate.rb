
module CertMaker
  class Certificate
    include Run
    include FileUtils

    attr_accessor :ca, :is_a_ca, :validity, :signwith
    attr_accessor :name, :cert, :conf, :keywpass, :keynopass, :req, :pass

    def initialize(name, args={})
      @name = name
      @cert = name+"cert.pem"
      @conf = name+".cnf"
      @conf_template = name+".cnf"
      @keywpass = name+"key-pass.pem"
      @keynopass = name+"key-nopass.pem"
      @req = name+'req.pem'
      @pass = "demo"

      @is_a_ca = args.fetch(:is_a_ca,false)
#      @startdate = args.fetch(:startdate,nil)
#      @enddate = args.fetch(:enddate,nil)
      @validity = args.fetch(:validity,365)
      @signwith = args.fetch(:signwith,nil)

    end

    # Returns the config filename. Also, it generates the file itself if it
    # does not yet exist.
    def conf
      create_conf_from_erb unless File.exist? @conf
      @conf
    end

    def create_conf_from_erb
      template = @conf+".erb"
      require 'erb'
      templdata = File.open(template) { |f| f.readlines.join('') }
      erb = ERB.new(templdata)
      erb.filename = template
      def foo(commonname)
        proc { }
      end
      b = foo(CertMaker::CONFIG['commonname'])
      File.open(@conf,'w') do |f|
        f.write(erb.result(b.binding))
      end
    end

    def keynopass
      create_keynopass unless File.exist? @keynopass
      @keynopass
    end

    def create_keynopass
      puts "Strip the passphrase off #{@name}..."
      run "openssl rsa -in #{self.keywpass} -passin pass:#{self.pass} -out #{@keynopass} 2>&1"
    end

    def keywpass
      create_request unless File.exist? @keywpass
      @keywpass
    end

    def req
      create_request unless File.exist? @req
      @req
    end

    # Creates the files pointed to by @keywpass and @req
    def create_request
      puts "Creating a request for #{@name}..."
      run "openssl req -config #{self.conf} -new -keyout #{@keywpass} -out #{@req} -days 30 -batch 2>&1"
    end

    def cert
      create_cert unless File.exist? @cert or @creating_cert
      @cert
    end

    # Create the #{@name}cert.pem file for this Certificate.
    #
    # Signs it with the CA if it has one, otherwise it signs itself.
    def create_cert
      @creating_cert = true
      create_request unless File.exist? @req

      if @ca != nil
        ca.sign(self)
      else
        sign_self
      end
      remove_instance_variable(:@creating_cert)
    end

    # creates @cert by signing itself.
    def sign_self
      puts "Self sign #{@name}..."
      run "openssl x509 -req -days 365 #{self.signwith ? "-"+self.signwith : ""} -extfile #{self.conf} -extensions #{@is_a_ca ? 'v3_ca' : 'v3_req'} -in #{self.req} -passin pass:#{self.pass} -signkey #{self.keywpass} -out #{@cert} 2>&1"
    end

    # Signs +other+, creating the certificate file for +other+.
    def sign(other)
      puts "Signing #{other.name} with #{self.name}..."

      run "openssl x509 -req -days #{other.validity} #{other.signwith ? "-"+other.signwith : ""} -extfile #{other.conf} -extensions v3_req -extensions usr_cert -in #{other.req} -CA #{self.cert} -CAkey #{self.keynopass} -CAcreateserial -out #{other.cert}  2>&1"
    end

    # Returns all parent node Certificate objects for self.
    def ca_chain
      if @ca
        [@ca].concat @ca.ca_chain
      else
        nil
      end
    end

    # Create a file with a chain of certificates.
    def create_chain
      chain = [ @keynopass, @cert]
      chain.concat ca_chain.map { |ca| ca.cert } if @ca != nil
      run "cat #{@keynopass} #{@cert}"
    end

  end
end
