require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))
require 'tlspretense/ext_compat/openssl_pkey_read'

module TLSPretense
  module ExtCompat
    describe OpenSSLPKeyRead do
      subject { a = Object.new ; a.extend(OpenSSLPKeyRead) ; a }

      describe "#read" do
        context "when given a PEM-encoded RSA key" do
          let(:pkey) do (<<-QUOTE).gsub(/^\s*/,'')
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

          it "returns an RSA key" do
            subject.read(pkey).should be_a OpenSSL::PKey::RSA
          end
        end
        context "when given a PEM-encoded DSA key" do
          let(:pkey) do (<<-QUOTE).gsub(/^\s*/,'')
            -----BEGIN DSA PRIVATE KEY-----
            MIIDVgIBAAKCAQEA1nTwWYrSmUNZalLgB7hW5F/K7GLpc+8GyNJ+F7XVY6lbrKlY
            4xylX/kOUHvYgq/3C4Mn0lkME7lrvLKkh7rPybCNe1p40olQXB9JPfYc6QiiGLGL
            WlbD1K4MNf1kftpBFB6x/Rs76NE6f8C3Wopp0TnbQhmlZskKo41mD+/MQl0j+d2w
            fKsbLAo+kkW/znMqC2PLWNlOFE3bFrRzGQkU1Bu8HrBYrJT35bCtqbSJoyBkHPgI
            SkYYdn/OuOD8swPO8xlgTxHBIZpwjqkyF3bzkroYOsCyAodu+xqHuTVzn+n/FWpf
            vR3Lx5GRxBdEBqotpfxNBfF11B0fRWsAMUSQJQIhAO8V8dLdD/SYRsKUKUHD8eGC
            ex6/ado7HluBizTjMI/NAoIBAC79cQQwFXb+ODfXTdG5QVYa9Q7fQ9oQZ1yDO1ab
            eZu+awH2E5/PbwVqJEBVOWCF7Suq3CXGrINaInu4zsM6Seo/V61hBTZpWkdt+Xr4
            ILlqQIw0UwaAwtE7Ynymk8Vx9MTFfekChi+Xu/4ReUDqRGKxzO89biZbd9XTOUVb
            W4T4nNE/ONQJ4CKa10E+g7w9Af4quV88JDVfwaTKhC9N5It8N52Pze8cxDYKQPFs
            5LUCjtfACxK6YBplkeF0nWdRkIz97dhMQgvfF70YKPikX5JymLbxLiBqUZkWc3Jv
            JzqOyvn08imGBZJmf6dEYhHDChKJ4OVALL4MpeStLQ01U5MCggEBALwAH7EnbbC/
            G2GziHq0XvhfmDQKCYBcAO5Mmwl7qsyMeECQ639MKcNJmX9rmC4JFC/TB4TQA80d
            YEwbFwlYJkUbJyM20oh7NMP0bsrn0Jzt8nYosRRfVZKman7tIE24QnVnZuEwOTQY
            0C4QLoq+m4jUumm6QsqclipuMzVUH1n0ngJYbx9nyvDU4nxd6j4MfmqHrQRUXIPH
            5namqyq/xELwpRy0i5kOh5Hs/KuyrMSesRzYcty8NwcYOcM1/whspsYAdX/psDjG
            FNdknGUPM5ioDR2in6CA5z6iPDEAuFFQIUHt34Ujv+F4FNFXqnfiCa95BrjaCKNd
            3bRVzJDprc4CICImpd+oInjzy7PeCkbpUxwa4P3A4fHhRp0arIbId6jj
            -----END DSA PRIVATE KEY-----
            QUOTE
          end

          it "returns a DSA key" do
            subject.read(pkey).should be_a OpenSSL::PKey::DSA
          end
        end
        context "when given a PEM-encoded EC key" do

          let(:pkey) do (<<-QUOTE).gsub(/^\s*/,'')
            -----BEGIN EC PRIVATE KEY-----
            MF8CAQEEGFpS6x8iOTNWBDNTO9nrqvyQjUvoaO7uaqAKBggqhkjOPQMBAaE0AzIA
            BLOLCjnMg4a1++NZS5/XTeT2vv8JEANpctfJMjsoG12Uv7fwe8lldQwFFl0XQQZk
            kg==
            -----END EC PRIVATE KEY-----
            QUOTE
          end

          it "returns an EC key" do
            subject.read(pkey).should be_a OpenSSL::PKey::EC
          end
        end
        context "when given a PEM-encoded ENCRYPTED key" do
          let(:pkey) do (<<-QUOTE).gsub(/^\s*/,'')
            -----BEGIN ENCRYPTED PRIVATE KEY-----
            MIICzzBJBgkqhkiG9w0BBQ0wPDAbBgkqhkiG9w0BBQwwDgQIBjDVSsSRDgwCAggA
            MB0GCWCGSAFlAwQBAgQQp6si6kZjtBV0mh+IfcThUQSCAoB6djj/BwG1lHkYw9o1
            AS4pDo+wF3VCDca26OCrMRK41lxsQ52Kdg1mDgkuLdBeAxx3uyuD4ZoytWhgv+st
            oLPypCl85xA7yvYsw3UiR4HaS27KiLIsLu4ex2bkS+wOLOw4t9tjPHLvmZJgVneA
            QFFdRH03woJfQaMHueseI6ok+p58Qs8xNbUetPJC47kwNtzD4tirrbGIsSPC0Mw9
            THsP/UPMYYbfgBi9hOzoznzpDie7Siv/VM5UCFHJuA9JKisliX8Gc9elmZMc5iD8
            QUo5XfquJCTGgdKpz3dLHsHK85kfXX+CpYzDLshIM8Qucf2Zx+fsW5h/1VrAR+H7
            Oft7zeyP01fGxwi1jVXdLpi5emvd1/tVUF/wasXisvQRsicNxE2nmPVrdFYRCisp
            6hIAqgkMUMbz5LGwGSfCqVLLezsC20lk4oVhszG+Jyx64bx5pUVupkuTghm8wZgJ
            ZnLKQIz+Bge+ZbNk3TzN1Z4O/Lpfs0wKbUaI+/glM10zl6s/tG0F+kNDRCp1xhWy
            m1Dq6AE9H+Q8BBYrwR//p9vP6xvFXo3Ie5b3zx1am2WWmgQqlnI4C+W1ThUdf68+
            eh1Qc/P8c5xwfS15kATbZT6lL6eBzkEFJYEN/5b1y2Bipsqn1Rjpcvu9VUOmFKyo
            AsFK2e6QvvhCngRxgLT1O4kNlDACJx65e20qMFXMLWqdXGOzy7VXattEzSs4sV7W
            3c/u+bv0rqaIYn+JcZ9hqukH3i3eyKLHfmbYxERUgQIh6cZjds+46sODsi/7J3R4
            ytZbBGZPeoS23Go6cfA2NEdN4hPH9k2CM0hol4W4ztWmPNoLmkhlFEhZHrdVoMR0
            Tw07
            -----END ENCRYPTED PRIVATE KEY-----
            QUOTE
          end
          context "when given the right password" do
            it "decrypts the key" do
              subject.read(pkey, 'hello').should be_a OpenSSL::PKey::RSA
            end
          end
          context "when given the wrong password" do
            it "raises a generic error" do
              expect { subject.read(pkey, 'hell') }.to raise_error
            end
          end
        end
      end
    end
  end
end
