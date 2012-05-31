require 'digest/sha1'
require 'base64'

module Devise
  # Implements a way of adding different encryptions.
  # The class should implement a self.digest method that taks the following params:
  #   - password
  #   - stretches: the number of times the encryption will be applied
  #   - salt: the password salt as defined by devise
  #   - pepper: Devise config option
  #

  module Encryptable
    module Encryptors
      class Ssha < Base
        def self.digest(password, stretches, salt, pepper)
          "{SSHA}"+Base64.encode64(Digest::SHA1.digest(password+salt)+salt).chomp!
        end

        def self.salt(stretches)
          Devise.friendly_token
        end
      end
    end
  end
end
