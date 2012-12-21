require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

module TLSPretense
module TestHarness
  describe CertificateManager do
    let(:rawfoocert) do (<<-EOF).gsub(/^\s*/,'')
      -----BEGIN CERTIFICATE-----
      MIIDJTCCAg2gAwIBAgIEHokN5TANBgkqhkiG9w0BAQUFADAiMQswCQYDVQQGEwJV
      UzETMBEGA1UEAwwKVHJ1c3RlZCBDQTAeFw0xMjEwMDUxODUxNDRaFw0xMzEwMDUx
      ODUxNDRaMCIxCzAJBgNVBAYTAlVTMRMwEQYDVQQDDApUcnVzdGVkIENBMIIBIjAN
      BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzRehpS5qO9LuW2dqm/Pc2YyPTOE3
      LMzoZSukguefwFuZqi8KVWpn+4Tk5xACaZYnAKMQEHb3F9aC4REU3p3L6WiuEmar
      xvnfxAFahEIlsmJSSiE6TaAxg3mXL3C5QiQxK/N9zjPGXW8QPlCCCs7CKQQ4RIQT
      IkoOn4OvSDbpRWrPZ1H4ZBiCrAfqDQOSqzmHMTchUfhvezSWwDcFUQCfYGBdBkjz
      FEcrtEG6lFjx3aVHZfZmuTKfki0fCEQCRsSd2l+/ZFJHIIphL0M2L/6VvCCDiazi
      HMwxVitnsQ5JURvje7QRAXTKjArIgUl9h/IdfrIT9pbLKDNsDQMx2txfkQIDAQAB
      o2MwYTAOBgNVHQ8BAf8EBAMCAgQwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU
      J8S9VAFA5sv9uRix79JE2chwrWkwHwYDVR0jBBgwFoAUJ8S9VAFA5sv9uRix79JE
      2chwrWkwDQYJKoZIhvcNAQEFBQADggEBADuWNwZW9//eN3bdXOBEIcvOQabsa4lF
      YpniO1yjMw4EAN9bA6CgVvaRO2q3p/HgCKbOfXhGrxvqNIv8ifjQeDJts4HG6/cX
      3/luVw8KN94wLqllB2tE0bVdCoZXJ+glycZzdRLjnaPbUuuSP5StRunBAPP59dm5
      lMKv5KhxJGBVHw7VHtM8rJ0KDsZmK9UCZ7Ztis2yZc5dH/uUlEtBs3HuHM7JddXD
      h07Iwq9FhFsr7dszYHV4AbiA8/VObtnOU+GkAGGWD8EZZtYy035op2xGbDkmPSWU
      SQDk71k6l730oJQtHh2ucrGxTWsWHk07X4lWrvxApydHRYIJElv1uqI=
      -----END CERTIFICATE-----
      EOF
    end
    let(:rawfookey) do (<<-QUOTE).gsub(/^\s*/,'')
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEAzRehpS5qO9LuW2dqm/Pc2YyPTOE3LMzoZSukguefwFuZqi8K
      VWpn+4Tk5xACaZYnAKMQEHb3F9aC4REU3p3L6WiuEmarxvnfxAFahEIlsmJSSiE6
      TaAxg3mXL3C5QiQxK/N9zjPGXW8QPlCCCs7CKQQ4RIQTIkoOn4OvSDbpRWrPZ1H4
      ZBiCrAfqDQOSqzmHMTchUfhvezSWwDcFUQCfYGBdBkjzFEcrtEG6lFjx3aVHZfZm
      uTKfki0fCEQCRsSd2l+/ZFJHIIphL0M2L/6VvCCDiaziHMwxVitnsQ5JURvje7QR
      AXTKjArIgUl9h/IdfrIT9pbLKDNsDQMx2txfkQIDAQABAoIBAQC49fbx4Uotaa1N
      AZdDzkn+aKVT0EjSPnnXw+Q5qmqIMBQFRycqoSvlyZQmTmnej2vdRzHVp3RwKyUd
      lSodGnIrrhxOvAlvCSqkuhPH81/L4KAV+qF6IF6HE8ElJ6Pr4nf2C0IKFOdwnBkq
      GbEtzgmMtCGKqRIYenF1qm0J03vM/Ugn3Xvq9qIUJjLEoX32z0m1x3+QQKmG4k2U
      AZK2Ngs3J3dHNmCjAOzWhJ7yeIEiPPAznP6MV9JCvv3+dAZGMZmQUbNkrXuEy+LG
      tQh7C5GMSj1wrB3q7o+1V2MGdZUu8uNkxaPlCnc3MnjbCHw3WydAJHW1lgurqlv5
      cwDd2BgBAoGBAPh4IdffVxlIRx2CR7++9O1D2UED+zXJjMFHok3sPhrONb/qOzaQ
      ectQFxzznObz4zUEnb9TLCVhkfMyFQ3L/CabLHPa21+ucMigObk8HdZ7nPtf7Xo0
      v54vISFhH7rlpBi73fOf69+bzd7ECEPOvfI639ltfJRv8LgSW6GdoaR5AoGBANNO
      8DbvicZ7+Qq6U05QJLhl4HyLziCS+Rr0Arz5KnbKxjPYoiV3Ujpzec3DAazTCRho
      OCRgzNMO2dEQCp7ZEYK+HK/J6UA2DYExYHcPyfYskrxwQVo5N20oiLa6jLisk5Jf
      vsq6Lbuq5PgYcykXfcX3ZnB6XAt32nC9dzcu2F3ZAoGAbYa/HGKWCU4EEyzvpcVu
      P/yNkwxHOzGKO1TxZboCslw980g0K9xJ4+Z9GcUFYAUYHbHYO5NVPXEiHfrwrvFB
      SF9UnAlYdHf3vWhrqYyndnls/J4Pl7QS147c4tLmYsOBr2l48ECJgDs058KwBfvn
      XRS4wiZyKRijGvD0tWw/6bkCgYEAv1crjZM6XtDDokM2TCOmHJOjwyOVc0mi6BUs
      pZG6MfdLoob3zJVPkD4gfYGncqdmBQPaUpaU4kkAU58C/vPwN0OPFl7vJ4XKlMHx
      Z96UMqYJ+Ths9RX6ao3Zvh0Ob+tVdaXdThVodBc7XqxFG2B6M1jjGdayom/VDWGD
      IiT5J4ECgYBhEHnaEepaK+Z++yMdGD4oZCtrKkY+2FiR3yK4scldzkKp+FLLBSD0
      nD0rF9hlhvpzlWa8HASrHHt2IB+rhKkljNpBuHSk1pK1q2KVYLCePOIunai9O/Mo
      JWJnWLSeS/Fd3rXB9jnNhiudElJRXzkof0jKSm0xnDbxWvWztBUnkA==
      -----END RSA PRIVATE KEY-----
      QUOTE
    end
    let(:rawbarcert) do (<<-EOF).gsub(/^\s*/,'')
        -----BEGIN CERTIFICATE-----
        MIIDLDCCAhSgAwIBAgIEKGSFPzANBgkqhkiG9w0BAQUFADAiMQswCQYDVQQGEwJV
        UzETMBEGA1UEAwwKVHJ1c3RlZCBDQTAeFw0xMjEwMDUxODUyMzlaFw0xMzEwMDUx
        ODUyMzlaMCkxCzAJBgNVBAYTAlVTMRowGAYDVQQDDBFJbnRlcm1lZGlhdGUgQ2Vy
        dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANVqXbGIFUnjzXuOLLzD
        G57ZqWvRK17hkL17cmhvbK1JgdWo7CJ20lCc/MhMbYT7ZTQ52CvGIhZlhbrf8sFV
        wFtBv99ioULGltvBCL3neuyf3LvWDAU6JgNwVxL+//sv4/Whj5yrBEfFMPxjozDq
        z9cOx6jQGHpn0ttQqgDIxmFPKu81DbDMtwQD8pJV+dqZ/Mlu3awWyzTKZpLJpJsH
        8mM4FO9lgdUcO433tK+7hu6VFPOzeItW047Wep6/mQnG8VzPMp1WamKSje+gbeNe
        zUau4rV8ZjO92sSlCf2NOIvZSi1uJbTFkqpguEyCCWxBgBfzylWBAPOzaeXZs+5b
        090CAwEAAaNjMGEwDgYDVR0PAQH/BAQDAgIEMA8GA1UdEwEB/wQFMAMBAf8wHQYD
        VR0OBBYEFM+4kO4HcjypiiVD1TDDoG53yJlNMB8GA1UdIwQYMBaAFCfEvVQBQObL
        /bkYse/SRNnIcK1pMA0GCSqGSIb3DQEBBQUAA4IBAQBprnU1g5nz8ecovTmo3vzy
        5Cq+O18l9GSX4T+6v8LEF30/AsSFe/FYM/KRbTUPLEhvZzX3oJM02e//w+drZTCR
        Sv5mdQZZJTleeYwcf5QDz4o6E+sP7PorUK/YNSD4FQMRnV6aGTDDkeemNKncvNE6
        cPP9mPdR7l1bf88QUy+L6wSWXY77qC7n/dL/PsddypvL5QVZL7G98sds7tU7y82s
        i8j7nF9FFjmbE4+2aVjNTQVgUkn0irCZO50LiYU55jHPCOlsg9K8VBH7fZKghMSe
        soLkjxuB/8Vg27ESlXvnp4sU7a4QcaULXJL1kpdfZxl62VoJU9oWBpy57/ZHPA6U
        -----END CERTIFICATE-----
      EOF
    end
    let(:rawbarkey) do (<<-QUOTE).gsub(/^\s*/,'')
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEA1WpdsYgVSePNe44svMMbntmpa9ErXuGQvXtyaG9srUmB1ajs
      InbSUJz8yExthPtlNDnYK8YiFmWFut/ywVXAW0G/32KhQsaW28EIved67J/cu9YM
      BTomA3BXEv7/+y/j9aGPnKsER8Uw/GOjMOrP1w7HqNAYemfS21CqAMjGYU8q7zUN
      sMy3BAPyklX52pn8yW7drBbLNMpmksmkmwfyYzgU72WB1Rw7jfe0r7uG7pUU87N4
      i1bTjtZ6nr+ZCcbxXM8ynVZqYpKN76Bt417NRq7itXxmM73axKUJ/Y04i9lKLW4l
      tMWSqmC4TIIJbEGAF/PKVYEA87Np5dmz7lvT3QIDAQABAoIBAQCUyD+jeeSli6wA
      XEDyI+9IkiQb50oeLpESmFJNXojcUieyxb5B1KaQzrEoDqg3km+etkjvU4UGKibN
      /jyl7ltZA4B5grA79mjLsUqf4hX/iv9+8B2XM0+3DAWYV7Ar9Nour0CIj20/f8jD
      2860Vq8pFcO5+8Fk7KbCgPzT6STsRtf+2ehgY7gRNkR/o3337qMYumhcdID5orm3
      OCfbX1zSJdzcZmkvtczGUncpf8Bbj/ygFZ+FVX9+Sjt8/RcZ1df8IEKNs1Z98GrO
      WtcZsecZjuZYAATZ2e0K9ykAUEyXJZu3gMWiMd4PH66yT3DNWdIGbkBbfdPVHSgc
      FfuECb/hAoGBAO9b36GG7Z7Ce0BmWBXSpm8xGobSOk4a6H+altAgajEJJH/Gqv97
      0aOOHJD/gQe60Pom2kLZDI+raIpCMLefH6Zf6nKmJPAHsZbhOvYyikmVNrZI9oTd
      Qz8I85L9TZZCW7SFbyHhNslHGqOrcv9EEEz0Sy+yZDI8nZyw6L8vG5fFAoGBAORA
      wAl5eWJ96T0vbS/zX5eG/Csbv7bftnWdEJsYPFxyybYalbXYoKNIjJ1nm3K3fMPV
      hrqOsBo8c/mFeWz+7yjGh+n2B0ephj25Svk5zbDlfoRMQh9unNxU+HCCipZOHhvJ
      x7S7tUos0ZT6uAGQIb0bzTAYfaZOUva5cssVEnU5AoGABtZI/QQtpWtIuf4yZe0u
      c96jM1at860xFvQDes5yOhRYxo2WNNYElvdoOXwS43WiooKZmW85vKDYy5o4agZR
      kR8MQ1obk/+kQvsMBBxNduycM3jCEemAEjzfOEOkA7bBh9aH5h/YwMcXK7WqA0Ce
      dpRD0Yj287hniCJFg7CEyUECgYAgOfgjHlCCFG7q4ZhT7dOwTDGsUHWn9zwGrQ9c
      JnbXQqmyGVzL2PMNOsAHtUogT0HBUJN+IYlBmwlw0GSNfAz+P9GOudrbRlcavd+V
      ApFFCZHsUewADhj9js2o7PVuNUdQ+xNENEBrYZqRozh5mAT7c0JsKPkMkwBpr1NC
      0w3RGQKBgF3VDeZQjCSagMGaS+j1mg0vtwM8H9FJKdKnI0HFb0ffeNiAStb9AATZ
      TTEbmX6Sm9s/SzIgBVgSpVlkmEc0BRuHv+40+UCWd3As6mHxEV8udbtTAJmhcm1W
      Gq8Xuh8WelT7Z5Cqks9mMWnnmJ0ye8RlvmM3Cn09oeVRN8IOCTrX
      -----END RSA PRIVATE KEY-----
      QUOTE
    end
    let(:rawbazcert) do (<<-EOF).gsub(/^\s*/,'')
        -----BEGIN CERTIFICATE-----
        MIIDWTCCAkGgAwIBAgIEBZwKfDANBgkqhkiG9w0BAQUFADAiMQswCQYDVQQGEwJV
        UzETMBEGA1UEAwwKVHJ1c3RlZCBDQTAeFw0xMjEwMDUxODUyNDJaFw0xMzEwMDUx
        ODUyNDJaMD0xCzAJBgNVBAYTAlVTMS4wLAYDVQQDDCVJbnRlcm1lZGlhdGUgd2l0
        aCBubyBiYXNpY0NvbnN0cmFpbnRzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
        CgKCAQEAtqFVxhTBS+MvZFu/KdSB2w2GoF6fahsGkP7B8j3cIARmNJrGovjTWxnR
        YuM7dhXyIf+XsHyV9KSu+LZ/sSUnGL/2jx7mxqk2aFNpSY6idQR/ihlyEYgIGr7+
        VShsmLAJ7dH3z5NxLCabQf5814xWngeqh1P0W6VpJNKgx5ml84JiOswQl9oodpvg
        neSCSqgbLE8iH0j0gofPAfceWVJQAVT3bEw6+qM3REx36Jqee3OYYwSUHPxGqcZb
        VhHI2ZYZ4g09GwqiCC/30aTs0JuhNihPsv0C+e7pmXXcEurMYxwAOK8ugyRjQoP2
        pBnNbV7hJiM+QryG+gmtvWkQgT2jlQIDAQABo3wwejALBgNVHQ8EBAMCBaAwHQYD
        VR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMB8GA1UdIwQYMBaAFCfEvVQBQObL
        /bkYse/SRNnIcK1pMB0GA1UdDgQWBBR4hKt1JMRlRTO59Wr39RgN+yeIMDAMBgNV
        HRMBAf8EAjAAMA0GCSqGSIb3DQEBBQUAA4IBAQB/SDwRip410niqqPYFizQuwcpJ
        v/bWFuejycAIFjl+0T6m6B4VqiN5/KkWL+hdJUaK1lbVqI8eByEYP4vg/pyH23u4
        bvKtAiJLPrqhgqlHoYll0xh4r3o8VkH1yiiK/LYIKNxIMKkRwe6/5RzG9b7kSRt1
        XPMu2112cFIo/jrJ7gk/bGivQ42cDpHs7GZ3U1vvnltKIKkcHAYSnqVd0JWllDCg
        S4pcOJjSUr2YLjy8+qWqIC5XKj1RsZwW3BZKy8tCRnD+gDxfoPq37suDTWF1yncA
        MWHZuq3LeG3jD/5WlLKQjaxtV3an09iwAcG6ByLlDnutORP1+nY9Pn46uDjM
        -----END CERTIFICATE-----
      EOF
    end
    let(:rawbazkey) do (<<-QUOTE).gsub(/^\s*/,'')
      -----BEGIN RSA PRIVATE KEY-----
      MIIEogIBAAKCAQEAtqFVxhTBS+MvZFu/KdSB2w2GoF6fahsGkP7B8j3cIARmNJrG
      ovjTWxnRYuM7dhXyIf+XsHyV9KSu+LZ/sSUnGL/2jx7mxqk2aFNpSY6idQR/ihly
      EYgIGr7+VShsmLAJ7dH3z5NxLCabQf5814xWngeqh1P0W6VpJNKgx5ml84JiOswQ
      l9oodpvgneSCSqgbLE8iH0j0gofPAfceWVJQAVT3bEw6+qM3REx36Jqee3OYYwSU
      HPxGqcZbVhHI2ZYZ4g09GwqiCC/30aTs0JuhNihPsv0C+e7pmXXcEurMYxwAOK8u
      gyRjQoP2pBnNbV7hJiM+QryG+gmtvWkQgT2jlQIDAQABAoIBADTOtcSO382XpW55
      cO8heWLjqFfaxHGj2uQ2JdJrvKitXPg9AM7C8CpZbsgPOHROqDLYev4XKC0TKVzV
      OFr6iTGI4DxGDSjIaOkFpV4VljgL0u0VqnwTP3SsYVIyXCRSUqynl+Y3lfPUPfR5
      J5QUCj+rq81xoyiUzbBODxtn/CpKvhdLcYwKnn5T0lz1qb1qoSXNjtUc0r11a9wq
      Nxj2xNZGsxpphicz7wYsUguDivxl5jpnXuHgIAgggQ3aDj3bC66YrKbQ99Uq5ToD
      OrUSyZsiQsqXtZdwPGqrOFQlkggmjS0gNE1aqqR0dLJVemo1vhhrMhqIo5M6bbBc
      VkRV6YkCgYEA3GEgUkkMdxW27L6KxujUojkHOqqO37ybf6dQTredBKeKwIQ4OwCJ
      2L4pL91lVL9b1Dznq5tLVts0SSSuM6mLTKDjXyvlSsy8X94X0qsxbCPzx36uF6lK
      d4Gyd1D/OmzLWqnQSgEdNqXFohFMtL0l7UzBnfhzg+QiRFBaWlzGJ+8CgYEA1CY4
      cbeo8McumHxF/8BU6QtKb25NFzN0KwUVRcR7lehYeaCNQExQrEgcvXD3HJ1cYnkX
      kXaZmBMVCmgj8/g7TmFyH925Xb3p9MZKAWuPx+P6eGn8uf2k2lhJzAfYaWJaoCik
      IpoyS7jvmLQO+/+8Vte3PZhpnzM4DLAd8QGxCLsCgYB5y8QNNgoJlpquZPBV1kAO
      F+6C4dhsltRpzJJ5rsi81cu9clWRZk7I1u/0YCuslsWtmqt/ECinLCbNddRBASbX
      huOiqaPjnxtM8HXCHJMH7SbBzqVwtkNNoQR9JOqp447P4KIZBFyc4ylC1MTL7u2T
      JKStJa7R6bd2geItprBtSQKBgFHS8ABEQv+jA0DC5civqNA9j5cM5uTk7pBNJJhF
      IRl/hOhcWT6McK0SHyud72F0/BXq+IEdSj5SVdIuunc1rcIcaYUK4pzaS+shs5d6
      ofkJ4CgjUNt3jea9GLF98SUsTyHoqu3BpVZ5XMf74q+lQkIIb19tcod5nMuf/dxf
      t6VTAoGAOxmC70VKaymxS9WF34EIsQKOI4IA/gcVgXlT1p5ULxAjQ+Z//9MmlUsR
      nbK5OUOFN52d9Q9d1bAWrIXPOok1T+dUEePQdXlyoxnct1xtfNOqhrdGp07nGDg3
      qx4mU2NiPm1793+rb9uJ38h4dGApaJ91z3QB7eDYvTBBJFWqSYQ=
      -----END RSA PRIVATE KEY-----
      QUOTE
    end

    before(:each) do
      File.stub(:read).with('certs/foocert.pem').and_return(rawfoocert)
      File.stub(:read).with('certs/barcert.pem').and_return(rawbarcert)
      File.stub(:read).with('certs/bazcert.pem').and_return(rawbazcert)
      File.stub(:read).with('certs/fookey.pem').and_return(rawfookey)
      File.stub(:read).with('certs/barkey.pem').and_return(rawbarkey)
      File.stub(:read).with('certs/bazkey.pem').and_return(rawbazkey)
    end

    describe "#get_chain" do

      it "attempts to load the certificates from disk" do
        File.should_receive(:read).with('certs/foocert.pem').and_return(rawfoocert)
        File.should_receive(:read).with('certs/barcert.pem').and_return(rawbarcert)
        File.should_receive(:read).with('certs/bazcert.pem').and_return(rawbazcert)

        CertificateManager.new({}).get_chain(['foo', 'bar', 'baz'])
      end

      it "returns a list of X509 certs that correspond to the aliases given to it" do
        certlist = CertificateManager.new({}).get_chain(['foo', 'bar', 'baz'])

        certlist.length.should == 3
        certlist.each { |cert| cert.should be_kind_of OpenSSL::X509::Certificate }
        # this might conceivably fail of the PEM data is output at a different width.
        certlist[0].to_pem.should == rawfoocert
        certlist[1].to_pem.should == rawbarcert
        certlist[2].to_pem.should == rawbazcert
      end
    end

    describe "#get_keychain" do
      it "attempts to load the keys from disk" do
        File.should_receive(:read).with('certs/fookey.pem').and_return(rawfookey)
        File.should_receive(:read).with('certs/barkey.pem').and_return(rawbarkey)
        File.should_receive(:read).with('certs/bazkey.pem').and_return(rawbazkey)

        CertificateManager.new({}).get_keychain(['foo', 'bar', 'baz'])
      end

      it "returns a list of keys that correspond to the certificates." do
        certchain = CertificateManager.new({}).get_chain(['foo', 'bar', 'baz'])

        keychain = CertificateManager.new({}).get_keychain(['foo', 'bar', 'baz'])

        keychain.length.should == 3
        keychain.each { |key| key.should be_kind_of OpenSSL::PKey::PKey }

        pairs = certchain.zip keychain
        pairs.each do |pair|
          cert, key = pair
          cert.public_key.to_pem.should == key.public_key.to_pem
        end
      end

    end

  end
end
end
