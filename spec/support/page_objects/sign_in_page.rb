require 'site_prism'

class SignInPage < SitePrism::Page
  set_url '/users/sign_in'
  set_url_matcher /\/users\/sign_in/

  element :slogan,           	'.slogan'
  element :email, 				    '#inputEmail3'
  element :remember_me,       '#user_remember_me'
  element :google_button,     'a', :text => 'Sign in with Google'
  element :more_options,     	'.more-options'
  element :more_options_link,	'.more-options a'
  element :less_options,     	'.less-options'
  element :less_options_link,	'.less-options a'
  element :submit, 		'[value="Sign in with MyUSA"]'
  element :alert,      '.alert'
end
