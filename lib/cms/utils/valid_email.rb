# @param email [String] the email address to validate
# @return [Boolean]
def valid_email?(email)
  return false unless email.is_a?(String)

  email_regex = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i
  email =~ email_regex
end
