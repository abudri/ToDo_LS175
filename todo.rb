# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development? # deploying to Heroku/Production lesson: https://launchschool.com/lessons/9230c94c/assignments/7d7b4dd7
require 'sinatra/content_for'
require 'tilt/erubis'

# session - hash // it's key :lists - is an array - see `session[:lists] ||= []`. it also has keys :error, :success for flash messages
# session[:lists] << { name: list_name, todos: [] }

# list - hash with key :name a value of string, and key :todos which is an array. see `session[:lists] << { name: list_name, todos: [] } `

# TODO: - each todo item in a list is a hash itself, contained in the array value of list[:todos], so putting a to item into the array of todos is going to be: `list[:todos] << { name: params[:todo], completed: false }`

configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'secret' # setting the session secret, to the string 'secret'
  set :erb, escape_html: true # Lesson 6, Sanitizing HTML: https://launchschool.com/lessons/31df6daa/assignments/d98e4174
end

helpers do
  def list_complete?(list) # checks to see if all todo items in a list are completed
    todos_count(list) > 0 && todos_remaining_count(list) == 0 # from assignment: https://launchschool.com/lessons/9230c94c/assignments/dd71166b
  end

  def list_class(list)
    'complete' if list_complete?(list) # fills in css class attribute with a string for <section> tag for marking title in list.erb as complete(grey and strikethrough). This is about 10 mins into assignment video: https://launchschool.com/lessons/9230c94c/assignments/dd71166b
  end

  def todos_count(list)
    list[:todos].size # call .size on the  array of todo items, for total of all todos be they complete or not. Assignment: https://launchschool.com/lessons/9230c94c/assignments/dd71166b
  end

  def todos_remaining_count(list)
    list[:todos].reject { |todo| todo[:completed] }.size # gives count of selects how many todo items that are left to be completed int he list[:todos] array. Assignment: https://launchschool.com/lessons/9230c94c/assignments/dd71166b
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }  # this whole method totally refactored in lesson 6 to make room for lists having ids, see: https://launchschool.com/lessons/2c69904e/assignments/a8c93890

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos)
    # from assignment https://launchschool.com/lessons/9230c94c/assignments/5046aba5, sorts todo items for a list in order with ones complete at bottom and ones not complete at top
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] } # refactored version late in assignment

    incomplete_todos.each { |todo| yield todo, todos.index(todo) } # remember each todo is a hash, and our call in lists.erb is `sort_todos(@list[:todos]) do |todo, index|`, so our key is a todo, but is passed to block first in the lists.erb view
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= [] # recall that  `session` is a hash, and for key :lists, the value is an array of lists, and each list itself is a hash  # to ensure we at least have an empty array if session[:lists] is non-existent, or nil, https://launchschool.com/lessons/9230c94c/assignments/2f3d171a
end

# By using a common method to load the list, we have a place to define the code that handles a list not existing. Using redirect in Sinatra interrupts the processing of a request and prevents any later code from executing: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
def load_list(id)
  list = session[:lists].find {|list| list[:id] == id } # Lesson 6, handling invalid URL parameter index passed for a list
  return list if list

  session[:error] = 'The specified list was not found.' # session[:lists] is an array of lists, each list being a hash. if an index is attempted to be accessed that doesn't exist, like /lists/10234, then we want a redirect to home page: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  redirect '/lists' # "/" redirects to "/lists" of course, the home
end

def next_element_id(elements) # for assigning a next available id for either a todo list itself or a todo item.  Was called `next_todo_id` in previous assignment, refactored in this new lesson 6 assignment: https://launchschool.com/lessons/2c69904e/assignments/a8c93890
  max = elements.map { |element| element[:id] }.max || 0 # the `|| 0` handles case of making the first todo item, fro which [].max returns nil, so nil || 0 return 0 and we avoid the nil + 1 error on next line
  max + 1 # || 0 in above line prevents nil + 1 error in case array is emtpy and [].max returns nil, so the || 0 will execute and max = 0 in that case.  So it gets the max id of an existing list or todo item id set(depending on if this is called for a list or a todo item), and then adds 1.  This return value is set as the id for any new list or todo item
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
  unless (1..100).cover?(name.size) # if the list_name is NOT between 1 and 100 characters, instead of using >= and <= operators, see:
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
    id = next_element_id(session[:lists]) # for assigning an :id to a list, a new feature at this point, Lesson 6: https://launchschool.com/lessons/2c69904e/assignments/a8c93890
    session[:lists] << { id: id, name: list_name, todos: [] } # remember in our form the <input> tag had a `name` of "list_name", so this is the key, and the value is whatever data we submitted if any, not there yet at this point, and note "list_name" can simply be treated as a symbol by sinatra, so :list_name in params hash
    session[:success] = 'The list has been created.' # flash message for successful list creation https://launchschool.com/lessons/9230c94c/assignments/cfb2f0cb
    redirect '/lists'
  end
end

# view an individual todo list
get '/lists/:id' do # id in the URL is a parameter that we will be using in this method
  id = params[:id].to_i
  @list = load_list(id)
  # @list_name = list[:name]
  # @list_id = list[:id]
  # @todos = list[:todos] # for some reason this and all the above lines in this method are new in my code but not at this point in lesson 6, in any case: https://launchschool.com/lessons/2c69904e/assignments/a8c93890
  erb :list, layout: :layout
end

# get form for editing an existing todo list
get '/lists/:id/edit' do
  id = params[:id].to_i
  @list = load_list(id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  erb :edit_list, layout: :layout
end

# updates an existing todo list, handles saving from edit_list.erb. much of code is taken from post '/lists' do route
post '/lists/:id' do
  list_name = params[:list_name].strip # for use in checking if name passed in as a param is valid(exists, not too long or short) before saving, see: https://launchschool.com/lessons/9230c94c/assignments/7923bc3a // .strip to remove any leading or trailing whitespace
  id = params[:id].to_i # from edit existing list method above
  @list = load_list(id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2

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
  session[:lists].reject! {|list| list[:id] == id } # remove the list - which is a hash itself, from the session array. refactored in lesson 6 to use Array#reject! and an actual id not based on index, for the list: https://launchschool.com/lessons/2c69904e/assignments/a8c93890
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" # conditional for checking if an AJAX request was made, see Lesson 6: https://launchschool.com/lessons/2c69904e/assignments/94ee8ca2
    '/lists'
  else
    session[:success] = 'The list has been deleted.'
    redirect '/lists' # redirect to the home page which is '/lists'
  end
end

# add a new todo item to an individual list: https://launchschool.com/lessons/9230c94c/assignments/046ee3e0
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i # from edit existing list method above, id of the list, but since using todo items, we say :list_id
  @list = load_list(@list_id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_element_id(@list[:todos]) # assign an id to the new todo item, Lesson 6 assignment: https://launchschool.com/lessons/9230c94c/assignments/046ee3e0, refactored to general method for lists and ids in next assignment: https://launchschool.com/lessons/2c69904e/assignments/a8c93890
    @list[:todos] << { id: id, name: text, completed: false } # params[:todo] is the submitted text taken from form submission at the list.erb page submit form for a todo item, which is named "todo"
    session[:success] = 'The todo item was added to the list'
    redirect "/lists/#{@list_id}" # redirect back to the list we just added the item to
  end
end

# delete a todo item from a list
post '/lists/:list_id/todos/:id/destroy' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  todo_id = params[:id].to_i # :id here being the id, or index of the todo list item for this list
  @list[:todos].reject! {|todo| todo[:id] == todo_id }  # updated Lesson 6, for any existing todo item with an id equal to todo_id `:id` from the url params, delete from todos with Array#reject!, https://launchschool.com/lessons/2c69904e/assignments/af479b47
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" # conditional for checking if an AJAX request was made, see Lesson 6: https://launchschool.com/lessons/2c69904e/assignments/94ee8ca2
    status 204
  else
    session[:success] = 'The todo item has been deleted from the list.' # original existing code from earlier
    redirect "/lists/#{@list_id}" # redirect back to the list we just deleted the list item from
  end
end

# updates status of a todo item. Marks a todo item completed or not completed based on current value, after clicking checkbox
post '/lists/:list_id/todos/:id' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  todo_id = params[:id].to_i # :id here being the id, or index of the todo list item for this list
  is_completed = params[:completed] == 'true'
  todo =  @list[:todos].find {|todo| todo[:id] == todo_id } # refactored in lesson 6 assignment https://launchschool.com/lessons/2c69904e/assignments/af479b47
  todo[:completed] = is_completed
  session[:success] = 'The todo item has been updated.'
  redirect "/lists/#{@list_id}"
end

# Mark all todo items on a list as Complete true
post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i
  @list = load_list(@list_id) # Refactor from Lesson 6 assignment for handling non-existing lists passed to url params: https://launchschool.com/lessons/31df6daa/assignments/cb2ef1d2
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = 'The todo items have all been updated to completed.'
  redirect "/lists/#{@list_id}"
end
