# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

# session - hash // it's key :lists - is an array - see `session[:lists] ||= []`. it also has keys :error, :success for flash messages
# session[:lists] << { name: list_name, todos: [] }

# list - hash with key :name a value of string, and key :todos which is an array. see `session[:lists] << { name: list_name, todos: [] } `

# todo - each todo item in a list is a hash itself, contained in the array value of list[:todos], `list[:todos] << { name: params[:todo], completed: false }`

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

def error_for_todo(name)
  if !(1..100).cover?(name.size) # if the list_name is NOT between 1 and 100 characters, instead of using >= and <= operators, see:
    'Todo list item must be between 1 and 100 characters.' 
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
  @list_id = params[:id].to_i # converting the "1" in "/lists/1" into an integer to get the list based off index from the hash session[:lists], which returns and is an array. Change from id to @list_id in https://launchschool.com/lessons/9230c94c/assignments/046ee3e0 (about 14-15 mins)
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

# get form for editing an existing todo list
get '/lists/:id/edit' do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

# updates an existing todo list, handles saving from edit_list.erb. much of code is taken from post '/lists' do route
post '/lists/:id' do
  list_name = params[:list_name].strip # for use in checking if name passed in as a param is valid(exists, not too long or short) before saving, see: https://launchschool.com/lessons/9230c94c/assignments/7923bc3a // .strip to remove any leading or trailing whitespace
  id = params[:id].to_i # from edit existing list method above
  @list = session[:lists][id] # from edit existing list method above

  error = error_for_list_name(list_name) # method call returns a string error message from the method if the list_name passed in is invalid, otherwise it will return nil and the first branch of the if statement won't be executed.
  if error
    session[:error] = error # refactored at: https://launchschool.com/lessons/9230c94c/assignments/b47401cd
    erb :edit_list, layout: :layout
  else # create the new list name since the above two validations passed
    @list[:name] = list_name
    session[:success] = 'The list name has been updated.' # flash message for successful list creation https://launchschool.com/lessons/9230c94c/assignments/cfb2f0cb
    redirect "/lists/#{id}"
  end
end

# delete an individual list, https://launchschool.com/lessons/9230c94c/assignments/ace30260
post '/lists/:id/destroy' do
  id = params[:id].to_i # from edit existing list method above
  session[:lists].delete_at(id) # remove the list - which is a hash itself, from the session array - using .delete_at, which will delete at the specified index you pass to it, in our case the id is our index
  session[:success] = 'The list has been deleted.'
  redirect '/lists' # redirect to the home page which is '/lists'
end

# add a todo item to an individual list: https://launchschool.com/lessons/9230c94c/assignments/046ee3e0
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i # from edit existing list method above, id of the list, but since using todo items, we say :list_id
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, completed: false } # params[:todo] is the submitted text taken from form submission at the list.erb page submit form for a todo item, which is named "todo"
    session[:success] = 'The todo item was added to the list'
    redirect "/lists/#{@list_id}" # redirect back to the list we just added the item to
  end
end

post '/lists/:list_id/todos/:id/destroy' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:id].to_i # :id here being the id, or index of the todo list item for this list
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo item has been deleted from the list."
  redirect "/lists/#{@list_id}" # redirect back to the list we just deleted the list item from 
end