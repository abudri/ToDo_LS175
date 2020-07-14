# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'secret' # setting the session secret, to the string 'secret'
end

before do
  session[:lists] ||= [] # recall that  `session` is a hash, and for key :lists, the value is an array of lists, and each list itself is a hash  # to ensure we at least have an empty array if session[:lists] is non-existent, or nil, https://launchschool.com/lessons/9230c94c/assignments/2f3d171a
end

get '/' do
  redirect '/lists' # so home page "/" will just take user to the "/lists" listing, what we want, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end

# view all of the lists
get '/lists' do # note the flash message for a successful list creation after submitting, is deleted from the `session` hash in the lists.erb view in erb, after it is first displayed there(meaning refreshing /lists will show that deletion and message will be gone)
  @lists = session[:lists] # pull lists from session data
  erb :lists, layout: :layout # added a lists file, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end

# render the create a new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# returns an error messagse if the name of the list attempted to be submitted is not valid and if so returns a string, otherwise will return nil. This is for refactoring validations assignment, https://launchschool.com/lessons/9230c94c/assignments/b47401cd
def error_for_list_name(name) 
  if !(1..100).cover?(name.size) # if the list_name is NOT between 1 and 100 characters, instead of using >= and <= operators, see:
    'The list name must be between 1 and 100 characters.' # https://launchschool.com/lessons/9230c94c/assignments/7923bc3a, refactored into this new method at: https://launchschool.com/lessons/9230c94c/assignments/b47401cd
  elsif session[:lists].any? { |list| list[:name] == name } # iterates through all lists in the session and for each checks if the :name is equal to name the user tried to submit in the form
    'List name must be unique.' # refactored into this method at, https://launchschool.com/lessons/9230c94c/assignments/b47401cd
  end
end

# creates a new list and saves it to session data
post '/lists' do
  list_name = params[:list_name].strip # for use in checking if name passed in as a param is valid(exists, not too long or short) before saving, see: https://launchschool.com/lessons/9230c94c/assignments/7923bc3a // .strip to remove any leading or trailing whitespace

  error = error_for_list_name(list_name) # method call returns a string error message from the method if the list_name passed in is invalid, otherwise it will return nil and the first branch of the if statement won't be executed.
  if error
    session[:error] = error # refactored at: https://launchschool.com/lessons/9230c94c/assignments/b47401cd
    erb :new_list, layout: :layout
  else # create the new list name since the above two validations passed
    session[:lists] << { name: list_name, todos: [] } # remember in our form the <input> tag had a `name` of "list_name", so this is the key, and the value is whatever data we submitted if any, not there yet at this point, and note "list_name" can simply be treated as a symbol by sinatra, so :list_name in params hash
    session[:success] = 'The list has been created.' # flash message for successful list creation https://launchschool.com/lessons/9230c94c/assignments/cfb2f0cb
    redirect '/lists'
  end
end

# view an individual list
get '/lists/:id' do # id in the URL is a parameter that we will be using in this method
  id = params[:id].to_i # converting the "1" in "/lists/1" into an integer to get the list based off index from the hash session[:lists], which returns and is an array
  @list = session[:lists][id]
  erb :list, layout: :layout
end
